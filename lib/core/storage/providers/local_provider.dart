import 'dart:async';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages

import '../models/connection_profile.dart';
import '../models/file_entry.dart';
import '../models/transfer_progress.dart';
import '../storage_provider.dart';

/// A [StorageProvider] that operates on the local filesystem using `dart:io`.
///
/// This is the primary provider for desktop platforms (Windows, macOS, Linux).
/// On mobile platforms, a SAF-based provider replaces this for scoped storage
/// compliance (Sprint 2).
class LocalProvider implements StorageProvider {
  LocalProvider({this.homePathOverride});

  /// Override for the home path (useful for testing)
  final String? homePathOverride;

  @override
  ConnectionProfile? get profile => null;

  @override
  String get displayName => 'Local';

  @override
  bool get isConnected => true;

  @override
  Stream<bool> get connectionStateChanges => const Stream.empty();

  @override
  Future<void> connect() async {
    // No-op for local filesystem
  }

  @override
  Future<void> disconnect() async {
    // No-op for local filesystem
  }

  @override
  Future<List<FileEntry>> list(String path, [ListOptions? options]) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      throw StorageException(
        'Directory not found',
        code: StorageException.notFound,
        path: path,
      );
    }

    // Load active macOS SMB sharing paths
    final sharedPaths = <String>{};
    try {
      final res = await Process.run('sharing', ['-l']);
      if (res.exitCode == 0) {
        final output = res.stdout as String;
        final lines = output.split('\n');
        for (final line in lines) {
          if (line.contains('path:')) {
            final sharePath = line.split('path:')[1].trim();
            if (sharePath.isNotEmpty) {
              sharedPaths.add(sharePath);
            }
          }
        }
      }
    } catch (_) {}

    final showHidden = options?.showHidden ?? false;
    final result = <FileEntry>[];

    final stream = dir.list().handleError((e) {
      // Ignore concurrent modification or permission errors during listing
    });

    await for (final entity in stream) {
      final name = p.basename(entity.path);

      // Filter hidden files (Unix dotfiles)
      if (!showHidden && name.startsWith('.')) continue;

      try {
        var entry = await _entityToFileEntry(entity);
        if (sharedPaths.contains(entity.path)) {
          entry = entry.copyWith(isShared: true);
        }
        result.add(entry);
      } catch (e) {
        // Skip files that were deleted or unreadable before stat completed
      }
    }

    return result;
  }

  @override
  Future<FileEntry> stat(String path) async {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.notFound) {
      throw StorageException(
        'Not found',
        code: StorageException.notFound,
        path: path,
      );
    }

    return _pathToFileEntry(path);
  }

  @override
  Stream<TransferProgress> read(String path, {CancelToken? cancelToken}) async* {
    final file = File(path);
    if (!file.existsSync()) {
      yield TransferProgress(
        operation: TransferOperation.read,
        state: TransferState.failed,
        error: 'File not found: $path',
      );
      return;
    }

    final totalBytes = file.lengthSync();
    final entry = await _pathToFileEntry(path);
    var bytesTransferred = 0;

    yield TransferProgress(
      operation: TransferOperation.read,
      state: TransferState.inProgress,
      currentFile: entry,
      bytesTransferred: 0,
      totalBytes: totalBytes,
    );

    final raf = file.openSync();
    try {
      const chunkSize = 64 * 1024; // 64KB chunks
      while (bytesTransferred < totalBytes) {
        if (cancelToken?.isCancelled ?? false) {
          yield TransferProgress(
            operation: TransferOperation.read,
            state: TransferState.cancelled,
          );
          return;
        }

        final remaining = totalBytes - bytesTransferred;
        final readSize = remaining < chunkSize ? remaining : chunkSize;
        final data = raf.readSync(readSize);
        bytesTransferred += data.length;

        yield TransferProgress(
          operation: TransferOperation.read,
          state: TransferState.inProgress,
          currentFile: entry,
          bytesTransferred: bytesTransferred,
          totalBytes: totalBytes,
        );
      }

      yield TransferProgress(
        operation: TransferOperation.read,
        state: TransferState.completed,
        currentFile: entry,
        bytesTransferred: totalBytes,
        totalBytes: totalBytes,
      );
    } finally {
      raf.closeSync();
    }
  }

  @override
  Stream<TransferProgress> write(
    String path,
    Stream<List<int>> data, {
    CancelToken? cancelToken,
  }) async* {
    final file = File(path);
    final sink = file.openWrite();
    var bytesTransferred = 0;

    try {
      await for (final chunk in data) {
        if (cancelToken?.isCancelled ?? false) {
          await sink.close();
          // Clean up partial file
          if (file.existsSync()) {
            file.deleteSync();
          }
          yield TransferProgress(
            operation: TransferOperation.write,
            state: TransferState.cancelled,
          );
          return;
        }

        sink.add(chunk);
        bytesTransferred += chunk.length;

        yield TransferProgress(
          operation: TransferOperation.write,
          state: TransferState.inProgress,
          bytesTransferred: bytesTransferred,
        );
      }

      await sink.flush();
      await sink.close();

      yield TransferProgress(
        operation: TransferOperation.write,
        state: TransferState.completed,
        bytesTransferred: bytesTransferred,
      );
    } catch (e) {
      await sink.close();
      yield TransferProgress(
        operation: TransferOperation.write,
        state: TransferState.failed,
        error: e.toString(),
      );
    }
  }

  @override
  Stream<TransferProgress> copy(
    String sourcePath,
    StorageProvider destProvider,
    String destPath, {
    CopyOptions options = const CopyOptions(),
    CancelToken? cancelToken,
  }) async* {
    final sourceEntry = await stat(sourcePath);

    if (sourceEntry.isDirectory) {
      yield* _copyDirectory(sourcePath, destProvider, destPath, options, cancelToken);
    } else {
      yield* _copyFile(sourcePath, destProvider, destPath, cancelToken);
    }
  }

  Stream<TransferProgress> _copyFile(
    String sourcePath,
    StorageProvider destProvider,
    String destPath,
    CancelToken? cancelToken,
  ) async* {
    // If same provider, use native copy
    if (destProvider is LocalProvider) {
      if (p.normalize(sourcePath) == p.normalize(destPath)) {
        yield TransferProgress(
          operation: TransferOperation.copy,
          state: TransferState.failed,
          error: 'Source and destination are the same file',
        );
        return;
      }

      final sourceFile = File(sourcePath);
      final destFile = File(destPath);

      // Ensure dest directory exists
      final destDir = Directory(p.dirname(destPath));
      if (!destDir.existsSync()) {
        destDir.createSync(recursive: true);
      }

      final totalBytes = sourceFile.lengthSync();
      var bytesTransferred = 0;

      yield TransferProgress(
        operation: TransferOperation.copy,
        state: TransferState.inProgress,
        bytesTransferred: 0,
        totalBytes: totalBytes,
      );

      // Use stream-based copy for progress
      final sourceRaf = sourceFile.openSync();
      final destRaf = destFile.openSync(mode: FileMode.write);
      try {
        const chunkSize = 64 * 1024;
        while (bytesTransferred < totalBytes) {
          if (cancelToken?.isCancelled ?? false) {
            destRaf.closeSync();
            sourceRaf.closeSync();
            if (destFile.existsSync()) destFile.deleteSync();
            yield TransferProgress(
              operation: TransferOperation.copy,
              state: TransferState.cancelled,
            );
            return;
          }

          final remaining = totalBytes - bytesTransferred;
          final readSize = remaining < chunkSize ? remaining : chunkSize;
          final data = sourceRaf.readSync(readSize);
          destRaf.writeFromSync(data);
          bytesTransferred += data.length;

          yield TransferProgress(
            operation: TransferOperation.copy,
            state: TransferState.inProgress,
            bytesTransferred: bytesTransferred,
            totalBytes: totalBytes,
          );
        }

        destRaf.closeSync();
        sourceRaf.closeSync();

        yield TransferProgress(
          operation: TransferOperation.copy,
          state: TransferState.completed,
          bytesTransferred: totalBytes,
          totalBytes: totalBytes,
        );
      } catch (e) {
        destRaf.closeSync();
        sourceRaf.closeSync();
        yield TransferProgress(
          operation: TransferOperation.copy,
          state: TransferState.failed,
          error: e.toString(),
        );
      }
    } else {
      // Cross-provider: read from this, write to dest
      final totalBytes = File(sourcePath).lengthSync();
      var bytesTransferred = 0;

      // Pipe read stream to write
      final controller = StreamController<List<int>>();

      // Start reading in background
      final readStream = File(sourcePath).openRead();
      readStream.listen(
        (chunk) {
          bytesTransferred += chunk.length;
          controller.add(chunk);
        },
        onDone: () => controller.close(),
        onError: (Object e) => controller.addError(e),
      );

      // Write to dest provider
      await for (final progress
          in destProvider.write(destPath, controller.stream, cancelToken: cancelToken)) {
        if (progress.state == TransferState.inProgress) {
          yield progress.copyWith(
            operation: TransferOperation.copy,
            bytesTransferred: bytesTransferred,
            totalBytes: totalBytes,
          );
        } else if (progress.state == TransferState.completed) {
          yield progress.copyWith(
            operation: TransferOperation.copy,
            bytesTransferred: totalBytes,
            totalBytes: totalBytes,
          );
        } else {
          yield progress.copyWith(operation: TransferOperation.copy);
        }
      }
    }
  }

  Stream<TransferProgress> _copyDirectory(
    String sourcePath,
    StorageProvider destProvider,
    String destPath,
    CopyOptions options,
    CancelToken? cancelToken,
  ) async* {
    final entries = await list(sourcePath);
    var filesTransferred = 0;
    final totalFiles = entries.length;

    // Create dest directory
    await destProvider.mkdir(destPath);

    for (final entry in entries) {
      if (cancelToken?.isCancelled ?? false) {
        yield TransferProgress(
          operation: TransferOperation.copy,
          state: TransferState.cancelled,
          filesTransferred: filesTransferred,
          totalFiles: totalFiles,
        );
        return;
      }

      final sourceEntryPath = joinPath(sourcePath, entry.name);
      final destEntryPath = joinPath(destPath, entry.name);

      if (entry.isDirectory) {
        yield* _copyDirectory(sourceEntryPath, destProvider, destEntryPath, options, cancelToken);
      } else {
        yield* _copyFile(sourceEntryPath, destProvider, destEntryPath, cancelToken);
      }

      filesTransferred++;
      yield TransferProgress(
        operation: TransferOperation.copy,
        state: TransferState.inProgress,
        filesTransferred: filesTransferred,
        totalFiles: totalFiles,
      );
    }

    yield TransferProgress(
      operation: TransferOperation.copy,
      state: TransferState.completed,
      filesTransferred: filesTransferred,
      totalFiles: totalFiles,
    );
  }

  @override
  Future<void> move(String sourcePath, String destPath) async {
    final source = FileSystemEntity.typeSync(sourcePath);
    if (source == FileSystemEntityType.notFound) {
      throw StorageException(
        'Source not found',
        code: StorageException.notFound,
        path: sourcePath,
      );
    }

    // Ensure dest directory exists
    final destDir = Directory(p.dirname(destPath));
    if (!destDir.existsSync()) {
      destDir.createSync(recursive: true);
    }

    try {
      if (source == FileSystemEntityType.directory) {
        Directory(sourcePath).renameSync(destPath);
      } else {
        File(sourcePath).renameSync(destPath);
      }
    } catch (e) {
      throw StorageException(
        'Move failed: $e',
        code: StorageException.accessDenied,
        path: sourcePath,
        cause: e,
      );
    }
  }

  @override
  Future<void> rename(String path, String newName) async {
    final parent = p.dirname(path);
    final newPath = p.join(parent, newName);
    await move(path, newPath);
  }

  @override
  Future<void> delete(String path) async {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.notFound) {
      throw StorageException(
        'Not found',
        code: StorageException.notFound,
        path: path,
      );
    }

    try {
      if (type == FileSystemEntityType.directory) {
        Directory(path).deleteSync(recursive: true);
      } else {
        File(path).deleteSync();
      }
    } catch (e) {
      throw StorageException(
        'Delete failed: $e',
        code: StorageException.accessDenied,
        path: path,
        cause: e,
      );
    }
  }

  @override
  Future<void> mkdir(String path) async {
    final dir = Directory(path);
    if (dir.existsSync()) {
      throw StorageException(
        'Already exists',
        code: StorageException.alreadyExists,
        path: path,
      );
    }

    try {
      dir.createSync(recursive: true);
    } catch (e) {
      throw StorageException(
        'Mkdir failed: $e',
        code: StorageException.accessDenied,
        path: path,
        cause: e,
      );
    }
  }

  @override
  Future<bool> exists(String path) async {
    return FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
  }

  @override
  Future<String> get homePath async {
    if (homePathOverride != null) return homePathOverride!;

    try {
      final home = await getApplicationDocumentsDirectory();
      return home.path;
    } catch (_) {
      // Fallback to environment variable
      final env = Platform.environment;
      if (Platform.isWindows) {
        return env['USERPROFILE'] ?? env['HOMEPATH'] ?? 'C:\\';
      }
      return env['HOME'] ?? '/';
    }
  }

  @override
  Future<int?> getFreeSpace(String path) async {
    // dart:io doesn't directly expose free space
    // This would need platform channels for accurate values
    return null;
  }

  @override
  String normalizePath(String path) => p.normalize(path);

  @override
  String joinPath(String parent, String child) => p.join(parent, child);

  @override
  String basename(String path) => p.basename(path);

  @override
  String dirname(String path) => p.dirname(path);

  @override
  bool supports(ProviderCapability capability) {
    switch (capability) {
      case ProviderCapability.read:
      case ProviderCapability.write:
      case ProviderCapability.delete:
      case ProviderCapability.move:
      case ProviderCapability.mkdir:
      case ProviderCapability.list:
      case ProviderCapability.streaming:
      case ProviderCapability.search:
        return true;
      case ProviderCapability.freeSpace:
        return false; // Would need platform channels
      case ProviderCapability.symlinks:
        return true;
      case ProviderCapability.permissions:
        return !Platform.isWindows;
    }
  }

  // ─── Private helpers ────────────────────────────────────────────

  Future<FileEntry> _entityToFileEntry(FileSystemEntity entity) async {
    final name = p.basename(entity.path);
    final stat = entity.statSync();

    final isDir = entity is Directory;
    final isSymlink = stat.type == FileSystemEntityType.link;

    String? symlinkTarget;
    if (isSymlink) {
      try {
        final link = Link(entity.path);
        symlinkTarget = link.resolveSymbolicLinksSync();
      } catch (_) {
        // Broken symlink
      }
    }

    return FileEntry(
      name: name,
      path: entity.path,
      isDirectory: isDir,
      size: isDir ? 0 : stat.size,
      modified: stat.modified,
      permissions: _permissionsToString(stat.mode),
      mimeType: isDir ? null : lookupMimeType(entity.path),
      hidden: name.startsWith('.'),
      symlink: isSymlink,
      symlinkTarget: symlinkTarget,
    );
  }

  Future<FileEntry> _pathToFileEntry(String path) async {
    final stat = FileStat.statSync(path);
    final name = p.basename(path);
    final isDir = stat.type == FileSystemEntityType.directory;
    final isSymlink = stat.type == FileSystemEntityType.link;

    return FileEntry(
      name: name,
      path: path,
      isDirectory: isDir,
      size: isDir ? 0 : stat.size,
      modified: stat.modified,
      permissions: _permissionsToString(stat.mode),
      mimeType: isDir ? null : lookupMimeType(path),
      hidden: name.startsWith('.'),
      symlink: isSymlink,
    );
  }

  @override
  Future<List<FileEntry>> search(String path, String query, {bool recursive = false}) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      throw StorageException('Directory not found', code: StorageException.notFound, path: path);
    }

    // Replace Turkish characters to make it truly case-insensitive for Turkish users
    String trToLower(String s) {
      return s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
    }

    final queryLower = trToLower(query);
    final results = <FileEntry>[];

    try {
      final stream = dir.list(recursive: recursive, followLinks: false).handleError((e) {
        // Ignore file system exceptions like permission denied during recursive search
      });
      
      await for (final entity in stream) {
        final name = p.basename(entity.path);
        if (trToLower(name).contains(queryLower)) {
          try {
            final entry = await _entityToFileEntry(entity);
            results.add(entry);
          } catch (_) {
            // Ignore if file was deleted or we lack stat permissions
          }
        }
      }
    } catch (e) {
      throw StorageException(
        'Search failed: $e',
        code: StorageException.networkError,
        path: path,
        cause: e,
      );
    }
    return results;
  }

  String _permissionsToString(int mode) {
    // Convert Unix mode bits to rwx string
    // Using decimal values (octal 0o400 = 256, etc.)
    final perms = StringBuffer();
    perms.write((mode & 256) != 0 ? 'r' : '-');
    perms.write((mode & 128) != 0 ? 'w' : '-');
    perms.write((mode & 64) != 0 ? 'x' : '-');
    perms.write((mode & 32) != 0 ? 'r' : '-');
    perms.write((mode & 16) != 0 ? 'w' : '-');
    perms.write((mode & 8) != 0 ? 'x' : '-');
    perms.write((mode & 4) != 0 ? 'r' : '-');
    perms.write((mode & 2) != 0 ? 'w' : '-');
    perms.write((mode & 1) != 0 ? 'x' : '-');
    return perms.toString();
  }
}