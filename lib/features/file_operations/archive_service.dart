import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/storage/models/file_entry.dart';
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
  Future<void> extract({
    required String archivePath,
    required String destDir,
  }) async {
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
      return;
    }

    if (archive == null) {
      throw Exception('Unsupported archive format: $ext');
    }

    // Extract all files
    for (final file in archive) {
      final filePath = p.join(destDir, file.name);

      if (file.isFile) {
        final data = file.content as List<int>;
        final outFile = File(filePath);
        outFile.parent.createSync(recursive: true);
        outFile.writeAsBytesSync(data);
      } else {
        final dir = Directory(filePath);
        dir.createSync(recursive: true);
      }
    }
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
}