import 'dart:async';
import 'dart:io';

import 'package:ftpconnect/ftpconnect.dart';
import 'package:path/path.dart' as p;

import '../models/connection_profile.dart';
import '../models/file_entry.dart';
import '../models/transfer_progress.dart';
import '../storage_provider.dart';

/// A [StorageProvider] that connects to FTP/FTPS servers using `ftpconnect`.
class FtpProvider implements StorageProvider {
  FtpProvider({
    required this.profile,
    required this.password,
  });

  @override
  final ConnectionProfile profile;

  final String? password;

  FTPConnect? _ftp;
  bool _isConnected = false;
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  @override
  String get displayName => '${profile.type == ConnectionType.ftps ? "FTPS" : "FTP"}: ${profile.name}';

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<bool> get connectionStateChanges => _connectionController.stream;

  @override
  Future<void> connect() async {
    try {
      final user = profile.authMethod == AuthMethod.anonymous
          ? 'anonymous'
          : (profile.username ?? 'anonymous');
      final pass = profile.authMethod == AuthMethod.anonymous
          ? 'anonymous@'
          : (password ?? '');

      _ftp = FTPConnect(
        profile.host!,
        port: profile.effectivePort,
        user: user,
        pass: pass,
        securityType: profile.type == ConnectionType.ftps ? SecurityType.ftps : SecurityType.ftp,
      );

      await _ftp!.connect();
      _isConnected = true;
      _connectionController.add(true);
    } catch (e) {
      _isConnected = false;
      throw StorageException(
        'FTP connection failed: $e',
        code: StorageException.networkError,
        cause: e,
      );
    }
  }

  @override
  Future<void> disconnect() async {
    if (_ftp != null) {
      try {
        await _ftp!.disconnect();
      } catch (_) {}
      _ftp = null;
    }
    _isConnected = false;
    if (!_connectionController.isClosed) {
      _connectionController.add(false);
      await _connectionController.close();
    }
  }

  @override
  Future<List<FileEntry>> list(String path, [ListOptions? options]) async {
    if (!_isConnected || _ftp == null) {
      throw StorageException('Not connected', code: StorageException.networkError);
    }

    try {
      // Change to directory first, then list
      await _ftp!.changeDirectory(path);
      final items = await _ftp!.listDirectoryContent();
      final showHidden = options?.showHidden ?? false;

      return items
          .where((item) {
            if (!showHidden && item.name.startsWith('.')) return false;
            return true;
          })
          .map((item) => FileEntry(
                name: item.name,
                path: p.join(path, item.name),
                isDirectory: item.type == FTPEntryType.dir,
                size: item.size ?? 0,
                modified: item.modifyTime,
                hidden: item.name.startsWith('.'),
              ))
          .toList();
    } catch (e) {
      throw StorageException(
        'FTP list failed: $e',
        code: StorageException.networkError,
        path: path,
        cause: e,
      );
    }
  }

  @override
  Future<FileEntry> stat(String path) async {
    if (!_isConnected || _ftp == null) {
      throw StorageException('Not connected', code: StorageException.networkError);
    }

    // FTP doesn't have a direct stat command, use listdir on parent
    final parent = p.dirname(path);
    final name = p.basename(path);
    final entries = await list(parent);
    final entry = entries.where((e) => e.name == name).firstOrNull;
    if (entry == null) {
      throw StorageException('Not found', code: StorageException.notFound, path: path);
    }
    return entry;
  }

  @override
  Stream<TransferProgress> read(String path, {CancelToken? cancelToken}) async* {
    if (!_isConnected || _ftp == null) {
      yield TransferProgress(
        operation: TransferOperation.read,
        state: TransferState.failed,
        error: 'Not connected',
      );
      return;
    }

    try {
      // FTPConnect downloads to a local file, then we read it
      // This is a limitation of ftpconnect — it doesn't support streaming directly
      final tempDir = await Directory.systemTemp.createTemp('ftp_download_');
      final tempFile = File('${tempDir.path}/${p.basename(path)}');

      await _ftp!.downloadFile(path, tempFile);

      final bytes = tempFile.readAsBytesSync();
      yield TransferProgress(
        operation: TransferOperation.read,
        state: TransferState.completed,
        bytesTransferred: bytes.length,
        totalBytes: bytes.length,
      );

      // Clean up temp file
      tempFile.deleteSync();
      tempDir.deleteSync();
    } catch (e) {
      yield TransferProgress(
        operation: TransferOperation.read,
        state: TransferState.failed,
        error: e.toString(),
      );
    }
  }

  @override
  Stream<TransferProgress> write(
    String path,
    Stream<List<int>> data, {
    CancelToken? cancelToken,
  }) async* {
    if (!_isConnected || _ftp == null) {
      yield TransferProgress(
        operation: TransferOperation.write,
        state: TransferState.failed,
        error: 'Not connected',
      );
      return;
    }

    try {
      // Write to temp file first, then upload
      final tempDir = await Directory.systemTemp.createTemp('ftp_upload_');
      final tempFile = File('${tempDir.path}/${p.basename(path)}');

      final sink = tempFile.openWrite();
      var bytesWritten = 0;

      await for (final chunk in data) {
        if (cancelToken?.isCancelled ?? false) {
          await sink.close();
          tempFile.deleteSync();
          tempDir.deleteSync();
          yield TransferProgress(
            operation: TransferOperation.write,
            state: TransferState.cancelled,
          );
          return;
        }
        sink.add(chunk);
        bytesWritten += chunk.length;
        yield TransferProgress(
          operation: TransferOperation.write,
          state: TransferState.inProgress,
          bytesTransferred: bytesWritten,
        );
      }

      await sink.flush();
      await sink.close();

      await _ftp!.uploadFile(tempFile);

      // Clean up
      tempFile.deleteSync();
      tempDir.deleteSync();

      yield TransferProgress(
        operation: TransferOperation.write,
        state: TransferState.completed,
        bytesTransferred: bytesWritten,
      );
    } catch (e) {
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
    // Cross-provider: pipe read to write
    final controller = StreamController<List<int>>();
    var bytesTransferred = 0;

    // Start reading in background
    read(sourcePath, cancelToken: cancelToken).listen((progress) {
      if (progress.state == TransferState.failed) {
        controller.addError(progress.error ?? 'Read failed');
      }
    });

    // For FTP, we need to download to temp then stream
    try {
      final tempDir = await Directory.systemTemp.createTemp('ftp_copy_');
      final tempFile = File('${tempDir.path}/${p.basename(sourcePath)}');

      await _ftp!.downloadFile(sourcePath, tempFile);
      final bytes = tempFile.readAsBytesSync();
      bytesTransferred = bytes.length;

      controller.add(bytes);
      controller.close();

      // Write to dest
      await for (final progress in destProvider.write(destPath, controller.stream, cancelToken: cancelToken)) {
        yield progress.copyWith(
          operation: TransferOperation.copy,
          bytesTransferred: bytesTransferred,
        );
      }

      tempFile.deleteSync();
      tempDir.deleteSync();
    } catch (e) {
      yield TransferProgress(
        operation: TransferOperation.copy,
        state: TransferState.failed,
        error: e.toString(),
      );
    }
  }

  @override
  Future<void> move(String sourcePath, String destPath) async {
    if (!_isConnected || _ftp == null) {
      throw StorageException('Not connected', code: StorageException.networkError);
    }

    try {
      await _ftp!.rename(sourcePath, destPath);
    } catch (e) {
      throw StorageException(
        'FTP move failed: $e',
        code: StorageException.networkError,
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
    if (!_isConnected || _ftp == null) {
      throw StorageException('Not connected', code: StorageException.networkError);
    }

    try {
      // Check if it's a directory or file
      final entry = await stat(path);
      if (entry.isDirectory) {
        // Recursively delete
        final entries = await list(path);
        for (final e in entries) {
          await delete(e.path);
        }
        await _ftp!.deleteDirectory(path);
      } else {
        await _ftp!.deleteFile(path);
      }
    } catch (e) {
      throw StorageException(
        'FTP delete failed: $e',
        code: StorageException.networkError,
        path: path,
        cause: e,
      );
    }
  }

  @override
  Future<void> mkdir(String path) async {
    if (!_isConnected || _ftp == null) {
      throw StorageException('Not connected', code: StorageException.networkError);
    }

    try {
      await _ftp!.makeDirectory(path);
    } catch (e) {
      throw StorageException(
        'FTP mkdir failed: $e',
        code: StorageException.networkError,
        path: path,
        cause: e,
      );
    }
  }

  @override
  Future<bool> exists(String path) async {
    try {
      await stat(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> get homePath async => profile.defaultPath;

  @override
  Future<DiskSpaceInfo?> getDiskSpaceInfo(String path) async => null;

  @override
  String normalizePath(String path) => p.normalize(path);

  @override
  String joinPath(String parent, String child) => p.join(parent, child);

  @override
  String basename(String path) => p.basename(path);

  @override
  String dirname(String path) => p.dirname(path);

  @override
  Future<List<FileEntry>> search(String path, String query, {bool recursive = false}) async {
    final results = <FileEntry>[];
    final queryLower = query.toLowerCase();

    Future<void> doSearch(String currentPath) async {
      final entries = await list(currentPath);
      for (final entry in entries) {
        if (entry.name.toLowerCase().contains(queryLower)) {
          results.add(entry);
        }
        if (recursive && entry.isDirectory) {
          try {
            await doSearch(entry.path);
          } catch (_) {
            // Ignore directory list errors
          }
        }
      }
    }

    await doSearch(path);
    return results;
  }

  @override
  bool supports(ProviderCapability capability) {
    switch (capability) {
      case ProviderCapability.read:
      case ProviderCapability.write:
      case ProviderCapability.delete:
      case ProviderCapability.move:
      case ProviderCapability.mkdir:
      case ProviderCapability.list:
      case ProviderCapability.search:
        return true;
      case ProviderCapability.streaming:
      case ProviderCapability.freeSpace:
      case ProviderCapability.symlinks:
      case ProviderCapability.permissions:
        return false;
    }
  }
}