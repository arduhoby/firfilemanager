import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/storage/models/file_entry.dart';
import '../../core/storage/models/transfer_progress.dart';
import '../../core/storage/storage_provider.dart';
import '../../core/storage/storage_provider_service.dart';
import 'file_open_service.dart';
import 'sync_models.dart';
import 'file_operations_state.dart';

part 'file_operations_service.g.dart';

/// Service that executes file operations (copy, move, delete, rename, mkdir)
/// and updates the [OperationProgress] state.
///
/// All operations are async and report progress via [OperationProgress] provider.
/// Operations can be cancelled via [CancelToken].
@Riverpod(keepAlive: true)
class FileOperationsService extends _$FileOperationsService {
  CancelToken? _activeCancelToken;

  @override
  void build() {
    // No state needed — this is a service provider
  }

  /// Copy selected entries from source panel to dest path
  Future<void> copy({
    required StorageProvider sourceProvider,
    required List<FileEntry> entries,
    required StorageProvider destProvider,
    required String destPath,
  }) async {
    if (entries.isEmpty) return;

    _activeCancelToken = CancelToken();
    final progress = ref.read(operationProgressProvider.notifier);

    for (var i = 0; i < entries.length; i++) {
      if (_activeCancelToken!.isCancelled) break;

      final entry = entries[i];
      final dirName = destProvider.normalizePath(destPath);
      var destEntryPath = destProvider.joinPath(dirName, entry.name);

      var counter = 1;
      final originalName = destProvider.basename(destEntryPath);
      while (await destProvider.exists(destEntryPath)) {
        if (!entry.isDirectory && originalName.contains('.')) {
          final dotIndex = originalName.lastIndexOf('.');
          final base = originalName.substring(0, dotIndex);
          final ext = originalName.substring(dotIndex);
          destEntryPath = destProvider.joinPath(dirName, '$base copy $counter$ext');
        } else {
          destEntryPath = destProvider.joinPath(dirName, '$originalName copy $counter');
        }
        counter++;
      }
      progress.setProgress(TransferProgress(
        operation: TransferOperation.copy,
        state: TransferState.inProgress,
        currentFile: entry,
        filesTransferred: i,
        totalFiles: entries.length,
      ));

      try {
      final stream = sourceProvider.copy(
        entry.path,
        destProvider,
        destEntryPath,
        cancelToken: _activeCancelToken,
      );

      await for (final p in stream) {
        progress.setProgress(p.copyWith(
          filesTransferred: i,
          totalFiles: entries.length,
        ));
      }
      } catch (e) {
        progress.setProgress(TransferProgress(
          operation: TransferOperation.copy,
          state: TransferState.failed,
          error: e.toString(),
          currentFile: entry,
        ));
        // Continue with next file
      }
    }

    progress.setProgress(TransferProgress(
      operation: TransferOperation.copy,
      state: _activeCancelToken!.isCancelled
          ? TransferState.cancelled
          : TransferState.completed,
      filesTransferred: entries.length,
      totalFiles: entries.length,
    ));

    _activeCancelToken = null;
  }

  /// Move entries within the same provider
  Future<void> move({
    required StorageProvider provider,
    required List<FileEntry> entries,
    required String destPath,
  }) async {
    if (entries.isEmpty) return;

    final progress = ref.read(operationProgressProvider.notifier);

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final destEntryPath = provider.joinPath(destPath, entry.name);

      progress.setProgress(TransferProgress(
        operation: TransferOperation.move,
        state: TransferState.inProgress,
        currentFile: entry,
        filesTransferred: i,
        totalFiles: entries.length,
      ));

      try {
        await provider.move(entry.path, destEntryPath);
      } catch (e) {
        progress.setProgress(TransferProgress(
          operation: TransferOperation.move,
          state: TransferState.failed,
          error: e.toString(),
          currentFile: entry,
        ));
      }
    }

    progress.setProgress(TransferProgress(
      operation: TransferOperation.move,
      state: TransferState.completed,
      filesTransferred: entries.length,
      totalFiles: entries.length,
    ));
  }

  /// Synchronize source directory to destination directory
  Future<void> syncDirectories({
    required StorageProvider sourceProvider,
    required String sourcePath,
    required StorageProvider destProvider,
    required String destPath,
  }) async {
    _activeCancelToken = CancelToken();
    final progress = ref.read(operationProgressProvider.notifier);

    progress.setProgress(TransferProgress(
      operation: TransferOperation.copy,
      state: TransferState.inProgress,
      currentFile: FileEntry(
        name: 'Scanning...',
        path: '',
        isDirectory: true,
        size: 0,
      ),
    ));

    try {
      int scannedCount = 0;
      final filesToSync = <FileEntry>[];

      Future<void> scanDirectory(String currentPath) async {
        if (_activeCancelToken!.isCancelled) return;

        try {
          final entries = await sourceProvider.list(currentPath, const ListOptions(showHidden: true));
          for (final entry in entries) {
            if (_activeCancelToken!.isCancelled) return;

            scannedCount++;
            if (scannedCount % 50 == 0) {
              progress.setProgress(TransferProgress(
                operation: TransferOperation.copy,
                state: TransferState.inProgress,
                currentFile: FileEntry(
                  name: 'Scanning: $scannedCount files... (${filesToSync.length} changes found)',
                  path: '',
                  isDirectory: true,
                  size: 0,
                ),
              ));
              // Small yield to not freeze UI
              await Future.delayed(const Duration(milliseconds: 1));
            }

            if (entry.isDirectory) {
              await scanDirectory(sourceProvider.joinPath(currentPath, entry.name));
            } else {
              final relativePath = sourceProvider.normalizePath(entry.path).replaceFirst(sourceProvider.normalizePath(sourcePath), '');
              final cleanRelative = relativePath.startsWith('/') || relativePath.startsWith('\\') 
                  ? relativePath.substring(1) 
                  : relativePath;

              final destEntryPath = destProvider.joinPath(destPath, cleanRelative);

              if (await destProvider.exists(destEntryPath)) {
                final dEntry = await destProvider.stat(destEntryPath);
                final sMod = entry.modified;
                final dMod = dEntry.modified;
                if (sMod != null && dMod != null && sMod.isAfter(dMod)) {
                  filesToSync.add(entry);
                } else if (entry.size != dEntry.size) {
                  filesToSync.add(entry);
                }
              } else {
                filesToSync.add(entry);
              }
            }
          }
        } catch (e) {
          // Ignore permission issues for individual folders
        }
      }

      // 1. Scan recursively with progress updates
      await scanDirectory(sourcePath);

      if (_activeCancelToken!.isCancelled) {
        progress.setProgress(TransferProgress(
          operation: TransferOperation.copy,
          state: TransferState.cancelled,
        ));
        _activeCancelToken = null;
        return;
      }

      // Now copy the filtered files
      for (var i = 0; i < filesToSync.length; i++) {
        if (_activeCancelToken!.isCancelled) break;

        final entry = filesToSync[i];
        final relativePath = sourceProvider.normalizePath(entry.path).replaceFirst(sourceProvider.normalizePath(sourcePath), '');
        final cleanRelative = relativePath.startsWith('/') || relativePath.startsWith('\\') 
            ? relativePath.substring(1) 
            : relativePath;
        final destEntryPath = destProvider.joinPath(destPath, cleanRelative);

        // Ensure dest parent directory exists
        final parentDir = destProvider.dirname(destEntryPath);
        if (!(await destProvider.exists(parentDir))) {
          await destProvider.mkdir(parentDir);
        }

        progress.setProgress(TransferProgress(
          operation: TransferOperation.copy,
          state: TransferState.inProgress,
          currentFile: entry,
          filesTransferred: i,
          totalFiles: filesToSync.length,
        ));

        try {
          final stream = sourceProvider.copy(
            entry.path,
            destProvider,
            destEntryPath,
            options: const CopyOptions(overwrite: true),
            cancelToken: _activeCancelToken,
          );

          await for (final p in stream) {
            progress.setProgress(p.copyWith(
              filesTransferred: i,
              totalFiles: filesToSync.length,
            ));
          }
        } catch (e) {
          progress.setProgress(TransferProgress(
            operation: TransferOperation.copy,
            state: TransferState.failed,
            error: e.toString(),
            currentFile: entry,
          ));
        }
      }

      progress.setProgress(TransferProgress(
        operation: TransferOperation.copy,
        state: _activeCancelToken!.isCancelled
            ? TransferState.cancelled
            : TransferState.completed,
        filesTransferred: filesToSync.length,
        totalFiles: filesToSync.length,
      ));
    } catch (e) {
      progress.setProgress(TransferProgress(
        operation: TransferOperation.copy,
        state: TransferState.failed,
        error: e.toString(),
      ));
    }

    _activeCancelToken = null;
  }

  /// Delete entries
  Future<void> delete({
    required StorageProvider provider,
    required List<FileEntry> entries,
  }) async {
    if (entries.isEmpty) return;

    final progress = ref.read(operationProgressProvider.notifier);

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];

      progress.setProgress(TransferProgress(
        operation: TransferOperation.delete,
        state: TransferState.inProgress,
        currentFile: entry,
        filesTransferred: i,
        totalFiles: entries.length,
      ));

      try {
        await provider.delete(entry.path);
      } catch (e) {
        progress.setProgress(TransferProgress(
          operation: TransferOperation.delete,
          state: TransferState.failed,
          error: e.toString(),
          currentFile: entry,
        ));
      }
    }

    progress.setProgress(TransferProgress(
      operation: TransferOperation.delete,
      state: TransferState.completed,
      filesTransferred: entries.length,
      totalFiles: entries.length,
    ));
  }

  /// Rename a single entry
  Future<void> rename({
    required StorageProvider provider,
    required FileEntry entry,
    required String newName,
  }) async {
    final progress = ref.read(operationProgressProvider.notifier);

    progress.setProgress(TransferProgress(
      operation: TransferOperation.move,
      state: TransferState.inProgress,
      currentFile: entry,
    ));

    try {
      await provider.rename(entry.path, newName);
      progress.setProgress(TransferProgress(
        operation: TransferOperation.move,
        state: TransferState.completed,
        currentFile: entry,
      ));
    } catch (e) {
      progress.setProgress(TransferProgress(
        operation: TransferOperation.move,
        state: TransferState.failed,
        error: e.toString(),
        currentFile: entry,
      ));
      rethrow;
    }
  }

  /// Create a new directory
  Future<void> mkdir({
    required StorageProvider provider,
    required String parentPath,
    required String name,
  }) async {
    final newPath = provider.joinPath(parentPath, name);
    await provider.mkdir(newPath);
  }

  /// Cancel the current operation
  void cancelOperation() {
    _activeCancelToken?.cancel();
  }

  /// Paste from clipboard to the given destination
  Future<void> paste({
    required StorageProvider destProvider,
    required String destPath,
  }) async {
    final clipboard = ref.read(fileClipboardProvider);
    if ((clipboard == null)) return;

    final registry = ref.read(storageProviderRegistryProvider.notifier);
    final sourceProvider = clipboard.sourceProviderId != null
        ? registry.get(clipboard.sourceProviderId!)
        : registry.local;

    if (sourceProvider == null) return;

    final entries = <FileEntry>[];
    for (final path in clipboard.sourcePaths) {
      try {
        entries.add(await sourceProvider.stat(path));
      } catch (_) {
        // Skip missing files
      }
    }

    if (clipboard.operation == ClipboardOperation.copy) {
      await copy(
        sourceProvider: sourceProvider,
        entries: entries,
        destProvider: destProvider,
        destPath: destPath,
      );
    } else {
      // For move within same provider, use move
      if (sourceProvider == destProvider) {
        await move(
          provider: destProvider,
          entries: entries,
          destPath: destPath,
        );
      } else {
        // Cross-provider move = copy + delete
        await copy(
          sourceProvider: sourceProvider,
          entries: entries,
          destProvider: destProvider,
          destPath: destPath,
        );
        await delete(
          provider: sourceProvider,
          entries: entries,
        );
      }
    }

    ref.read(fileClipboardProvider.notifier).clear();
  }

  Future<List<SyncItem>> analyzeSync({
    required StorageProvider sourceProvider,
    required String sourcePath,
    required StorageProvider destProvider,
    required String destPath,
  }) async {
    _activeCancelToken = CancelToken();
    final progress = ref.read(operationProgressProvider.notifier);

    progress.setProgress(TransferProgress(
      operation: TransferOperation.copy,
      state: TransferState.inProgress,
      currentFile: FileEntry(
        name: 'Scanning...',
        path: '',
        isDirectory: true,
        size: 0,
      ),
    ));

    try {
      int scannedCount = 0;
      final syncItems = <SyncItem>[];

      Future<void> scanDirectory(String currentPath) async {
        if (_activeCancelToken!.isCancelled) return;

        try {
          final entries = await sourceProvider.list(currentPath, const ListOptions(showHidden: true));
          for (final entry in entries) {
            if (_activeCancelToken!.isCancelled) return;

            scannedCount++;
            if (scannedCount % 50 == 0) {
              progress.setProgress(TransferProgress(
                operation: TransferOperation.copy,
                state: TransferState.inProgress,
                currentFile: FileEntry(
                  name: 'Scanning: $scannedCount files...',
                  path: '',
                  isDirectory: true,
                  size: 0,
                ),
              ));
              await Future.delayed(const Duration(milliseconds: 1));
            }

            if (entry.isDirectory) {
              await scanDirectory(sourceProvider.joinPath(currentPath, entry.name));
            } else {
              final relativePath = sourceProvider.normalizePath(entry.path).replaceFirst(sourceProvider.normalizePath(sourcePath), '');
              final cleanRelative = relativePath.startsWith('/') || relativePath.startsWith('\\') 
                  ? relativePath.substring(1) 
                  : relativePath;

              final destEntryPath = destProvider.joinPath(destPath, cleanRelative);
              final depth = cleanRelative.split('/').length - 1;

              if (await destProvider.exists(destEntryPath)) {
                final dEntry = await destProvider.stat(destEntryPath);
                final sMod = entry.modified;
                final dMod = dEntry.modified;
                
                if (sMod != null && dMod != null && sMod.isAfter(dMod)) {
                  syncItems.add(SyncItem(
                    sourceEntry: entry, relativePath: cleanRelative, depth: depth, status: SyncStatus.modified, isSelected: true
                  ));
                } else if (entry.size != dEntry.size) {
                  syncItems.add(SyncItem(
                    sourceEntry: entry, relativePath: cleanRelative, depth: depth, status: SyncStatus.modified, isSelected: true
                  ));
                } else {
                  syncItems.add(SyncItem(
                    sourceEntry: entry, relativePath: cleanRelative, depth: depth, status: SyncStatus.identical, isSelected: false
                  ));
                }
              } else {
                syncItems.add(SyncItem(
                  sourceEntry: entry, relativePath: cleanRelative, depth: depth, status: SyncStatus.missing, isSelected: true
                ));
              }
            }
          }
        } catch (e) {
          // Ignore
        }
      }

      await scanDirectory(sourcePath);

      if (_activeCancelToken!.isCancelled) {
        progress.setProgress(TransferProgress(
          operation: TransferOperation.copy,
          state: TransferState.cancelled,
        ));
        _activeCancelToken = null;
        return [];
      }

      progress.setProgress(TransferProgress(
        operation: TransferOperation.copy,
        state: TransferState.completed,
      ));

      // Sort by relative path alphabetically
      syncItems.sort((a, b) => a.relativePath.compareTo(b.relativePath));

      return syncItems;
    } catch (e) {
      progress.setProgress(TransferProgress(
        operation: TransferOperation.copy,
        state: TransferState.failed,
        error: e.toString(),
      ));
      rethrow;
    } finally {
      _activeCancelToken = null;
    }
  }

  Future<void> executeSync({
    required StorageProvider sourceProvider,
    required StorageProvider destProvider,
    required String destPath,
    required List<SyncItem> selectedItems,
  }) async {
    _activeCancelToken = CancelToken();
    final progress = ref.read(operationProgressProvider.notifier);

    progress.setProgress(TransferProgress(
      operation: TransferOperation.copy,
      state: TransferState.inProgress,
    ));

    try {
      for (var i = 0; i < selectedItems.length; i++) {
        if (_activeCancelToken!.isCancelled) break;

        final item = selectedItems[i];
        final destEntryPath = destProvider.joinPath(destPath, item.relativePath);

        final parentDir = destProvider.dirname(destEntryPath);
        if (!(await destProvider.exists(parentDir))) {
          await destProvider.mkdir(parentDir);
        }

        progress.setProgress(TransferProgress(
          operation: TransferOperation.copy,
          state: TransferState.inProgress,
          currentFile: item.sourceEntry,
          filesTransferred: i,
          totalFiles: selectedItems.length,
        ));

        try {
          final stream = sourceProvider.copy(
            item.sourceEntry.path,
            destProvider,
            destEntryPath,
            options: const CopyOptions(overwrite: true),
            cancelToken: _activeCancelToken,
          );

          await for (final p in stream) {
            progress.setProgress(TransferProgress(
              operation: TransferOperation.copy,
              state: TransferState.inProgress,
              currentFile: item.sourceEntry,
              filesTransferred: i,
              totalFiles: selectedItems.length,
              bytesTransferred: p.bytesTransferred,
              totalBytes: p.totalBytes,
            ));
          }
        } catch (e) {
          // Continue copying other files
        }
      }

      if (_activeCancelToken!.isCancelled) {
        progress.setProgress(TransferProgress(
          operation: TransferOperation.copy,
          state: TransferState.cancelled,
        ));
      } else {
        progress.setProgress(TransferProgress(
          operation: TransferOperation.copy,
          state: TransferState.completed,
        ));
      }
    } catch (e) {
      progress.setProgress(TransferProgress(
        operation: TransferOperation.copy,
        state: TransferState.failed,
        error: e.toString(),
      ));
    } finally {
      _activeCancelToken = null;
    }
  }
}