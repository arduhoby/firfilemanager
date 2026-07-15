import 'dart:io';
import 'dart:convert';

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

  /// Compress files/directories into an archive
  ///
  /// [entries] — files/dirs to compress
  /// [destPath] — full path for the output archive (without extension)
  /// [format] — archive format (zip, tar, tar.gz)
  ///
  /// Returns the full path of the created archive.
  Future<String> compress({
    required List<FileEntry> entries,
    required String destDir,
    required String archiveName,
    required ArchiveFormat format,
  }) async {
    final ext = switch (format) {
      ArchiveFormat.zip => '.zip',
      ArchiveFormat.tar => '.tar',
      ArchiveFormat.tarGz => '.tar.gz',
    };

    final outputPath = p.join(destDir, '$archiveName$ext');

    // Build archive
    final archive = Archive();

    for (final entry in entries) {
      if (entry.isDirectory) {
        _addDirectoryToArchive(archive, entry.path, entry.name);
      } else {
        _addFileToArchive(archive, entry.path, entry.name);
      }
    }

    // Create output file
    final outputFile = File(outputPath);
    final outputSink = outputFile.openWrite();

    try {
      switch (format) {
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
    } finally {
      await outputSink.flush();
      await outputSink.close();
    }

    return outputPath;
  }

  /// Extract an archive to a directory
  ///
  /// [archivePath] — path to the archive file
  /// [destDir] — destination directory
  Stream<TransferProgress> extract({
    required String archivePath,
    required String destDir,
  }) async* {
    final inputFile = File(archivePath);
    final inputBytes = inputFile.readAsBytesSync();

    final ext = p.extension(archivePath).toLowerCase();
    final ext2 = p.extension(p.basenameWithoutExtension(archivePath)).toLowerCase();

    Archive? archive;

    if (ext == '.zip') {
      archive = ZipDecoder().decodeBytes(inputBytes);
    } else if (ext == '.tar' || (ext2 == '.tar' && ext == '.gz') || (ext2 == '.tgz')) {
      // Check if it's tar.gz
      if (ext == '.gz') {
        final decompressed = GZipDecoder().decodeBytes(inputBytes);
        archive = TarDecoder().decodeBytes(decompressed);
      } else {
        archive = TarDecoder().decodeBytes(inputBytes);
      }
    } else if (ext == '.gz') {
      // Plain gzip (single file)
      final decompressed = GZipDecoder().decodeBytes(inputBytes);
      final outputName = p.basenameWithoutExtension(archivePath);
      final outputFile = File(p.join(destDir, outputName));
      outputFile.writeAsBytesSync(decompressed);
      final entry = FileEntry(
        name: outputName,
        path: outputFile.path,
        isDirectory: false,
        size: decompressed.length,
        modified: DateTime.now(),
      );
      yield TransferProgress(
        operation: TransferOperation.copy,
        state: TransferState.completed,
        currentFile: entry,
        totalBytes: decompressed.length,
        bytesTransferred: decompressed.length,
      );
      return;
    }

    if (archive == null) {
      throw Exception('Unsupported archive format: $ext');
    }

    final smartDestDir = _getSmartExtractDir(archive, destDir, archivePath);

    int totalBytes = 0;
    for (final file in archive) {
      totalBytes += file.size;
    }
    int transferredBytes = 0;

    // Extract all files
    final normalizedDestDir = p.normalize(smartDestDir);
    for (final file in archive) {
      final filePath = p.join(smartDestDir, file.name);

      if (file.isFile) {
        // --- ZIP SLIP KORUMASI ---
        final resolvedPath = p.normalize(filePath);
        if (!resolvedPath.startsWith(normalizedDestDir)) {
          throw Exception(
            'Güvenlik ihlali: Arşiv hedef dizin dışına yazma girişiminde bulundu (Zip Slip). Dosya: ${file.name}',
          );
        }
        // -------------------------
        final entry = FileEntry(
          name: file.name,
          path: filePath,
          isDirectory: false,
          size: file.size,
          modified: DateTime.now(),
        );
        yield TransferProgress(
          operation: TransferOperation.copy,
          state: TransferState.inProgress,
          currentFile: entry,
          totalBytes: totalBytes,
          bytesTransferred: transferredBytes,
        );
        final data = file.content as List<int>;
        final outFile = File(filePath);
        outFile.createSync(recursive: true);
        await outFile.writeAsBytes(data);
        transferredBytes += file.size;

        // Yield to the event loop so the UI (progress bar & animation) can update
        await Future.delayed(const Duration(milliseconds: 16));
      } else {
        Directory(filePath).createSync(recursive: true);
      }
    }
    
    yield TransferProgress(
      operation: TransferOperation.copy,
      state: TransferState.completed,
      totalBytes: totalBytes,
      bytesTransferred: transferredBytes,
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

  /// Extract an encrypted ZIP using macOS native `unzip` with password.
  /// Applies Smart Extract logic by peeking into the ZIP via the Dart archive package.
  Stream<TransferProgress> extractWithPassword({
    required String archivePath,
    required String destDir,
    required String password,
  }) async* {
    // 1. Determine smart extract directory
    final inputFile = File(archivePath);
    final inputBytes = inputFile.readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(inputBytes, verify: false);
    
    final smartDestDir = _getSmartExtractDir(archive, destDir, archivePath);
    Directory(smartDestDir).createSync(recursive: true);
    
    int totalBytes = 0;
    for (final file in archive) {
      totalBytes += file.size;
    }
    int transferredBytes = 0;

    // 2. Extract using native unzip (since dart archive package doesn't support decryption)
    // Exclude macOS specific resource forks and hidden files to avoid clutter
    // GÜVENLIK: Şifreyi -P argümanı yerine stdin üzerinden gönderiyoruz,
    // böylece `ps aux` ile şifre görünmez.
    final process = await Process.start(
      'unzip',
      ['-P', '-', '-o', archivePath, '-d', smartDestDir, '-x', '__MACOSX/*', '*/._*'],
    );
    // stdin'e şifreyi yaz ve kapat
    process.stdin.writeln(password);
    await process.stdin.close();

    final stdoutStream = process.stdout.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter());
    final stderrStream = process.stderr.transform(utf8.decoder).transform(const LineSplitter());
    
    final stderrBuffer = StringBuffer();
    stderrStream.listen((line) {
      stderrBuffer.writeln(line);
    });

    await for (final line in stdoutStream) {
      if (line.contains('inflating: ') || line.contains('extracting: ')) {
        final parts = line.split(':');
        if (parts.length > 1) {
          final fileName = parts[1].trim();
          // Approximate progress
          transferredBytes += (totalBytes / archive.length).round();
          if (transferredBytes > totalBytes) transferredBytes = totalBytes;
          
          final filePath = p.join(smartDestDir, fileName);
          final entry = FileEntry(
            name: fileName,
            path: filePath,
            isDirectory: false,
            size: 0,
            modified: DateTime.now(),
          );
          yield TransferProgress(
            operation: TransferOperation.copy,
            state: TransferState.inProgress,
            currentFile: entry,
            totalBytes: totalBytes,
            bytesTransferred: transferredBytes,
          );
        }
      }
    }

    final exitCode = await process.exitCode;

    // unzip returns:
    // 0 = normal
    // 1 = warning (often non-fatal like symlink creation fail or extra bytes)
    // 2 = generic error (can often still complete successfully)
    // 82 = wrong password
    if (exitCode != 0 && exitCode != 1 && exitCode != 2) {
      if (exitCode == 82) {
        throw Exception('Hatalı şifre (Wrong password).');
      }
      throw Exception('Arşiv çıkarma hatası (Exit code: $exitCode): ${stderrBuffer.toString()}');
    }
    
    yield TransferProgress(
      operation: TransferOperation.copy,
      state: TransferState.completed,
      totalBytes: totalBytes,
      bytesTransferred: totalBytes,
    );
  }
}