import 'dart:io';
import 'dart:convert';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/storage/models/file_entry.dart';
import '../../core/storage/models/transfer_progress.dart';
import 'file_operations_state.dart';

part 'archive_service.g.dart';

/// Supported archive formats
enum ArchiveFormat {
  zip,
  tar,
  tarGz,
}

/// Service for compressing and extracting archives.
///
/// Supports:
/// - ZIP (create + extract)
/// - TAR (create + extract)
/// - TAR.GZ (create + extract)
@Riverpod(keepAlive: true)
class ArchiveService extends _$ArchiveService {
  @override
  void build() {
    // No state needed
  }

  /// Helper class to represent a file to be archived
  List<_ArchiveItem> _collectArchiveItems(List<FileEntry> entries) {
    final items = <_ArchiveItem>[];
    for (final entry in entries) {
      if (entry.isDirectory) {
        final dir = Directory(entry.path);
        if (!dir.existsSync()) continue;
        final entities = dir.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is File) {
            final relativePath = p.relative(entity.path, from: entry.path);
            final entryName = p.join(entry.name, relativePath);
            try {
              items.add(_ArchiveItem(entity.path, entryName, entity.lengthSync()));
            } catch (_) {}
          }
        }
      } else {
        final file = File(entry.path);
        if (!file.existsSync()) continue;
        try {
          items.add(_ArchiveItem(entry.path, entry.name, file.lengthSync()));
        } catch (_) {}
      }
    }
    return items;
  }

  /// Compress files/directories into an archive
  Stream<TransferProgress> compress({
    required List<FileEntry> entries,
    required String destDir,
    required String archiveName,
    required ArchiveFormat format,
  }) async* {
    if (Platform.isMacOS || Platform.isLinux) {
      yield* _compressNative(
        entries: entries,
        destDir: destDir,
        archiveName: archiveName,
        format: format,
      );
    } else {
      yield* _compressDart(
        entries: entries,
        destDir: destDir,
        archiveName: archiveName,
        format: format,
      );
    }
  }

  /// Compress using native OS commands (extremely fast, low memory)
  Stream<TransferProgress> _compressNative({
    required List<FileEntry> entries,
    required String destDir,
    required String archiveName,
    required ArchiveFormat format,
  }) async* {
    final ext = switch (format) {
      ArchiveFormat.zip => '.zip',
      ArchiveFormat.tar => '.tar',
      ArchiveFormat.tarGz => '.tar.gz',
    };

    final outputPath = p.join(destDir, '$archiveName$ext');
    final sourceDir = p.dirname(entries.first.path);
    final sourceNames = entries.map((e) => p.basename(e.path)).toList();

    // 1. Calculate total files and bytes recursively for accurate progress
    int totalFiles = 0;
    int totalBytes = 0;
    for (final entry in entries) {
      if (entry.isDirectory) {
        final dir = Directory(entry.path);
        if (dir.existsSync()) {
          try {
            final list = dir.listSync(recursive: true);
            for (final f in list) {
              if (f is File) {
                totalFiles++;
                totalBytes += f.lengthSync();
              }
            }
          } catch (_) {}
        }
      } else {
        totalFiles++;
        try {
          totalBytes += File(entry.path).lengthSync();
        } catch (_) {}
      }
    }

    if (totalFiles == 0) totalFiles = 1;
    if (totalBytes == 0) totalBytes = 1;

    // Send initial progress so progress bar appears immediately
    yield TransferProgress(
      operation: TransferOperation.zip,
      state: TransferState.inProgress,
      totalFiles: totalFiles,
      filesTransferred: 0,
      totalBytes: totalBytes,
      bytesTransferred: 0,
    );

    Process process;
    if (format == ArchiveFormat.zip) {
      process = await Process.start(
        'zip',
        ['-r', outputPath, ...sourceNames],
        workingDirectory: sourceDir,
      );
    } else {
      // Tar / Tar.Gz
      final flags = format == ArchiveFormat.tarGz ? '-czvf' : '-cvf';
      process = await Process.start(
        'tar',
        [flags, outputPath, '-C', sourceDir, ...sourceNames],
      );
    }

    final lineStream = process.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter());

    int filesProcessed = 0;
    await for (final line in lineStream) {
      String? matchedFile;
      if (format == ArchiveFormat.zip) {
        // macOS zip format: "  adding: path/to/file (deflated 42%)"
        if (line.contains('adding:')) {
          matchedFile = line
              .replaceAll(RegExp(r'^\s*adding:\s*'), '')
              .split(' (')
              .first
              .trim();
        }
      } else {
        // Tar outputs added files directly to stdout line by line
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) matchedFile = trimmed;
      }

      if (matchedFile != null && matchedFile.isNotEmpty && !matchedFile.endsWith('/')) {
        filesProcessed++;
        final progressBytes = (totalBytes * (filesProcessed / totalFiles)).round();
        
        yield TransferProgress(
          operation: TransferOperation.zip,
          state: TransferState.inProgress,
          currentFile: FileEntry(
            name: p.basename(matchedFile),
            path: p.join(sourceDir, matchedFile),
            isDirectory: false,
            size: 0,
            modified: DateTime.now(),
          ),
          totalFiles: totalFiles,
          filesTransferred: filesProcessed,
          totalBytes: totalBytes,
          bytesTransferred: progressBytes > totalBytes ? totalBytes : progressBytes,
        );
      }
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Arşivleme hatası. Exit code: $exitCode');
    }

    yield TransferProgress(
      operation: TransferOperation.zip,
      state: TransferState.completed,
      totalFiles: totalFiles,
      filesTransferred: totalFiles,
      totalBytes: totalBytes,
      bytesTransferred: totalBytes,
    );
  }

  /// Compress using Dart implementation (fallback for Windows)
  Stream<TransferProgress> _compressDart({
    required List<FileEntry> entries,
    required String destDir,
    required String archiveName,
    required ArchiveFormat format,
  }) async* {
    final ext = switch (format) {
      ArchiveFormat.zip => '.zip',
      ArchiveFormat.tar => '.tar',
      ArchiveFormat.tarGz => '.tar.gz',
    };

    final outputPath = p.join(destDir, '$archiveName$ext');

    final receivePort = ReceivePort();
    final config = _CompressConfig(
      paths: entries.map((e) => e.path).toList(),
      names: entries.map((e) => e.name).toList(),
      isDirs: entries.map((e) => e.isDirectory).toList(),
      destDir: destDir,
      archiveName: archiveName,
      format: format,
      sendPort: receivePort.sendPort,
    );

    await Isolate.spawn(_compressIsolateEntry, config);

    await for (final msg in receivePort) {
      if (msg is Map) {
        final type = msg['type'] as String;
        final totalBytes = msg['totalBytes'] as int;
        
        if (type == 'progress') {
          final fileName = msg['fileName'] as String;
          final filePath = msg['filePath'] as String;
          final size = msg['size'] as int;
          final transferredBytes = msg['transferredBytes'] as int;

          yield TransferProgress(
            operation: TransferOperation.zip,
            state: TransferState.inProgress,
            currentFile: FileEntry(
              name: fileName,
              path: filePath,
              isDirectory: false,
              size: size,
              modified: DateTime.now(),
            ),
            totalBytes: totalBytes == 0 ? 1 : totalBytes,
            bytesTransferred: transferredBytes,
          );
        } else if (type == 'encoding') {
          final transferredBytes = msg['transferredBytes'] as int;
          yield TransferProgress(
            operation: TransferOperation.zip,
            state: TransferState.inProgress,
            currentFile: FileEntry(
              name: 'Encoding...',
              path: outputPath,
              isDirectory: false,
              size: 0,
              modified: DateTime.now(),
            ),
            totalBytes: totalBytes == 0 ? 1 : totalBytes,
            bytesTransferred: transferredBytes,
          );
        } else if (type == 'completed') {
          yield TransferProgress(
            operation: TransferOperation.zip,
            state: TransferState.completed,
            totalBytes: totalBytes == 0 ? 1 : totalBytes,
            bytesTransferred: totalBytes == 0 ? 1 : totalBytes,
          );
          receivePort.close();
          break;
        }
      }
    }
  }

  /// Extract an archive to a directory
  ///
  /// [archivePath] — path to the archive file
  /// [destDir] — destination directory
  /// Extract an archive to a directory asynchronously without blocking RAM.
  Stream<TransferProgress> extract({
    required String archivePath,
    required String destDir,
    String? password,
  }) async* {
    final inputFile = File(archivePath);
    if (!inputFile.existsSync()) {
      throw Exception('Archive not found: $archivePath');
    }
    
    final totalBytes = inputFile.lengthSync();
    final ext = p.extension(archivePath).toLowerCase();
    final ext2 = p.extension(p.basenameWithoutExtension(archivePath)).toLowerCase();
    
    // Create smart dest dir. We name it by archive name without extension
    final archiveName = p.basenameWithoutExtension(archivePath);
    final smartDestDir = p.join(destDir, archiveName);
    Directory(smartDestDir).createSync(recursive: true);

    Process process;
    
    if (ext == '.zip') {
      if (password != null && password.isNotEmpty) {
        process = await Process.start(
          'unzip',
          ['-P', '-', '-o', archivePath, '-d', smartDestDir, '-x', '__MACOSX/*', '*/._*'],
        );
        process.stdin.writeln(password);
        await process.stdin.close();
      } else {
        process = await Process.start(
          'unzip',
          ['-o', archivePath, '-d', smartDestDir, '-x', '__MACOSX/*', '*/._*'],
        );
      }
    } else if (ext == '.tar' || (ext2 == '.tar' && ext == '.gz') || (ext2 == '.tgz')) {
      final flags = ext == '.gz' ? '-xzf' : '-xf';
      process = await Process.start(
        'tar',
        [flags, archivePath, '-C', smartDestDir],
      );
    } else if (ext == '.gz') {
      // Plain gzip
      final outputFile = p.join(smartDestDir, archiveName);
      process = await Process.start(
        'sh',
        ['-c', 'gunzip -c "$archivePath" > "$outputFile"'],
      );
    } else {
      throw Exception('Unsupported archive format: $ext');
    }

    final stdoutStream = process.stdout.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter());
    final stderrStream = process.stderr.transform(utf8.decoder).transform(const LineSplitter());
    
    final stderrBuffer = StringBuffer();
    stderrStream.listen((line) {
      stderrBuffer.writeln(line);
    });

    int filesProcessed = 0;
    
    await for (final line in stdoutStream) {
      String? fileName;
      if (ext == '.zip') {
        if (line.contains('inflating: ') || line.contains('extracting: ')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            fileName = parts[1].trim();
          }
        }
      } else {
        fileName = line.trim();
      }

      if (fileName != null && fileName.isNotEmpty && !fileName.endsWith('/')) {
        filesProcessed++;
        // Approximate bytes based on files
        int progressBytes = (filesProcessed * 1024 * 1024); // fake progress
        if (progressBytes > totalBytes) progressBytes = totalBytes;

        yield TransferProgress(
          operation: TransferOperation.unzip,
          state: TransferState.inProgress,
          currentFile: FileEntry(
            name: p.basename(fileName),
            path: p.join(smartDestDir, fileName),
            isDirectory: false,
            size: 0,
            modified: DateTime.now(),
          ),
          totalBytes: totalBytes,
          bytesTransferred: progressBytes,
        );
      }
    }

    final exitCode = await process.exitCode;
    
    if (exitCode != 0 && exitCode != 1 && exitCode != 2) {
      if (exitCode == 82) {
        throw Exception('Hatalı şifre (Wrong password).');
      }
      throw Exception('Arşiv çıkarma hatası (Exit code: $exitCode): ${stderrBuffer.toString()}');
    }

    yield TransferProgress(
      operation: TransferOperation.unzip,
      state: TransferState.completed,
      totalBytes: totalBytes,
      bytesTransferred: totalBytes,
    );
  }

  /// Evaluates if the archive should be extracted into a subfolder to prevent clutter.
  String _getSmartExtractDir(Archive archive, String destDir, String archivePath) {
    final rootItems = <String>{};
    for (final file in archive) {
      final parts = p.split(file.name);
      if (parts.isNotEmpty) {
        rootItems.add(parts.first);
      }
    }

    // If multiple root items exist, extract into a folder named after the archive
    if (rootItems.length > 1) {
      final name = p.basenameWithoutExtension(archivePath);
      return p.join(destDir, name);
    }
    return destDir;
  }

  /// Check if a file is a supported archive format
  bool isArchive(String path) {
    final ext = p.extension(path).toLowerCase();
    final ext2 = p.extension(p.basenameWithoutExtension(path)).toLowerCase();
    return ext == '.zip' ||
        ext == '.tar' ||
        ext == '.gz' ||
        (ext2 == '.tar' && ext == '.gz');
  }

  void _addFileToArchive(Archive archive, String filePath, String archiveName) {
    final file = File(filePath);
    if (!file.existsSync()) return;

    final data = file.readAsBytesSync();
    archive.addFile(
      ArchiveFile(archiveName, data.length, data),
    );
  }

  void _addDirectoryToArchive(Archive archive, String dirPath, String archiveName) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return;

    // Add all files in the directory recursively
    final entities = dir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: dirPath);
        final entryName = p.join(archiveName, relativePath);
        _addFileToArchive(archive, entity.path, entryName);
      }
    }
  }

  /// Check if the zip file is encrypted (requires macOS native `unzip`)
  Future<bool> isEncryptedZip(String archivePath) async {
    final ext = p.extension(archivePath).toLowerCase();
    if (ext != '.zip') return false;

    try {
      final result = await Process.run('unzip', ['-Z', '-v', archivePath]);
      return result.stdout.toString().toLowerCase().contains('encrypted');
    } catch (e) {
      return false;
    }
  }

}

class _ArchiveItem {
  final String filePath;
  final String archiveName;
  final int size;
  _ArchiveItem(this.filePath, this.archiveName, this.size);
}

class _CompressConfig {
  final List<String> paths;
  final List<String> names;
  final List<bool> isDirs;
  final String destDir;
  final String archiveName;
  final ArchiveFormat format;
  final SendPort sendPort;

  _CompressConfig({
    required this.paths,
    required this.names,
    required this.isDirs,
    required this.destDir,
    required this.archiveName,
    required this.format,
    required this.sendPort,
  });
}

Future<void> _compressIsolateEntry(_CompressConfig config) async {
  final items = <_ArchiveItem>[];
  
  // Collect all items to compress
  for (int i = 0; i < config.paths.length; i++) {
    final path = config.paths[i];
    final name = config.names[i];
    final isDir = config.isDirs[i];

    if (isDir) {
      final dir = Directory(path);
      if (dir.existsSync()) {
        try {
          final entities = dir.listSync(recursive: true);
          for (final entity in entities) {
            if (entity is File) {
              final relativePath = p.relative(entity.path, from: path);
              final entryName = p.join(name, relativePath);
              try {
                items.add(_ArchiveItem(entity.path, entryName, entity.lengthSync()));
              } catch (_) {}
            }
          }
        } catch (_) {}
      }
    } else {
      final file = File(path);
      if (file.existsSync()) {
        try {
          items.add(_ArchiveItem(path, name, file.lengthSync()));
        } catch (_) {}
      }
    }
  }

  final totalBytes = items.fold<int>(0, (sum, item) => sum + item.size);
  int transferredBytes = 0;

  final archive = Archive();

  for (final item in items) {
    final file = File(item.filePath);
    if (file.existsSync()) {
      try {
        final data = file.readAsBytesSync();
        archive.addFile(
          ArchiveFile(item.archiveName, data.length, data),
        );
      } catch (_) {}
    }
    transferredBytes += item.size;
    
    config.sendPort.send({
      'type': 'progress',
      'fileName': p.basename(item.filePath),
      'filePath': item.filePath,
      'size': item.size,
      'totalBytes': totalBytes,
      'transferredBytes': transferredBytes,
    });
  }

  // Encoding phase
  config.sendPort.send({
    'type': 'encoding',
    'totalBytes': totalBytes,
    'transferredBytes': transferredBytes,
  });

  final ext = switch (config.format) {
    ArchiveFormat.zip => '.zip',
    ArchiveFormat.tar => '.tar',
    ArchiveFormat.tarGz => '.tar.gz',
  };

  final outputPath = p.join(config.destDir, '${config.archiveName}$ext');
  final outputFile = File(outputPath);
  final outputSink = outputFile.openWrite();

  try {
    switch (config.format) {
      case ArchiveFormat.zip:
        final zipBytes = ZipEncoder().encode(archive);
        if (zipBytes != null) {
          outputSink.add(zipBytes);
        }
      case ArchiveFormat.tar:
        final tarBytes = TarEncoder().encode(archive);
        outputSink.add(tarBytes);
      case ArchiveFormat.tarGz:
        final tarBytes = TarEncoder().encode(archive);
        final gzBytes = GZipEncoder().encode(tarBytes);
        if (gzBytes != null) {
          outputSink.add(gzBytes);
        }
    }
  } catch (_) {
  } finally {
    await outputSink.flush();
    await outputSink.close();
  }

  config.sendPort.send({
    'type': 'completed',
    'totalBytes': totalBytes,
  });
}