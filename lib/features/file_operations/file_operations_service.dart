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
  final Set<CancelToken> _activeTokens = {};

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
    bool isMove = false,
  }) async {
    if (entries.isEmpty) return;

    final cancelToken = CancelToken();
    _activeTokens.add(cancelToken);
    final progress = ref.read(operationProgressProvider.notifier);

    for (var i = 0; i < entries.length; i++) {
      if (cancelToken.isCancelled) break;

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
        operation: isMove ? TransferOperation.move : TransferOperation.copy,
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
        cancelToken: cancelToken,
      );

      await for (final p in stream) {
        progress.setProgress(p.copyWith(
          operation: isMove ? TransferOperation.move : TransferOperation.copy,
          filesTransferred: i,
          totalFiles: entries.length,
        ));
      }
      } catch (e) {
        // Rollback partial file/folder on failure
        try {
          if (await destProvider.exists(destEntryPath)) {
            await destProvider.delete(destEntryPath);
          }
        } catch (_) {}

        progress.setProgress(TransferProgress(
          operation: isMove ? TransferOperation.move : TransferOperation.copy,
          state: TransferState.failed,
          error: e.toString(),
          currentFile: entry,
        ));
        // Continue with next file
      }
    }

    progress.setProgress(TransferProgress(
      operation: isMove ? TransferOperation.move : TransferOperation.copy,
      state: cancelToken.isCancelled
          ? TransferState.cancelled
          : TransferState.completed,
      filesTransferred: entries.length,
      totalFiles: entries.length,
    ));

    _activeTokens.remove(cancelToken);
  }

  /// Move entries
  Future<void> move({
    required StorageProvider sourceProvider,
    required List<FileEntry> entries,
    required StorageProvider destProvider,
    required String destPath,
  }) async {
    if (entries.isEmpty) return;

    if (sourceProvider == destProvider) {
      final progress = ref.read(operationProgressProvider.notifier);
      bool useFallback = false;

      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final destEntryPath = sourceProvider.joinPath(destPath, entry.name);

        progress.setProgress(TransferProgress(
          operation: TransferOperation.move,
          state: TransferState.inProgress,
          currentFile: entry,
          filesTransferred: i,
          totalFiles: entries.length,
        ));

        try {
          await sourceProvider.move(entry.path, destEntryPath);
        } catch (e) {
          useFallback = true;
          break;
        }
      }

      if (!useFallback) {
        progress.setProgress(TransferProgress(
          operation: TransferOperation.move,
          state: TransferState.completed,
          filesTransferred: entries.length,
          totalFiles: entries.length,
        ));
        return;
      }
    }

    // Fallback cross-provider or cross-device
    await copy(
      sourceProvider: sourceProvider,
      entries: entries,
      destProvider: destProvider,
      destPath: destPath,
      isMove: true,
    );

    // Delete sources after successful move copy
    final currentProgress = ref.read(operationProgressProvider);
    if (currentProgress?.state != TransferState.failed && currentProgress?.state != TransferState.cancelled) {
      await delete(provider: sourceProvider, entries: entries, hideProgress: true);
    }
  }

  /// Synchronize source directory to destination directory
  Future<void> syncDirectories({
    required StorageProvider sourceProvider,
    required String sourcePath,
    required StorageProvider destProvider,
    required String destPath,
  }) async {
    final cancelToken = CancelToken();
    _activeTokens.add(cancelToken);
    final progress = ref.read(operationProgressProvider.notifier);

    progress.setProgress(TransferProgress(
      operation: TransferOperation.sync,
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
        if (cancelToken.isCancelled) return;

        try {
          final entries = await sourceProvider.list(currentPath, const ListOptions(showHidden: true));
          for (final entry in entries) {
            if (cancelToken.isCancelled) return;

            scannedCount++;
            if (scannedCount % 50 == 0) {
              progress.setProgress(TransferProgress(
                operation: TransferOperation.sync,
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
          // İzin hatalarını yutuyoruz ama ilerlemede belirtiyoruz
          progress.setProgress(TransferProgress(
            operation: TransferOperation.sync,
            state: TransferState.inProgress,
            currentFile: FileEntry(
              name: 'Uyarı: Klasör okunamadı — ${e.toString().split('\n').first}',
              path: currentPath,
              isDirectory: true,
              size: 0,
            ),
          ));
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // 1. Scan recursively with progress updates
      await scanDirectory(sourcePath);

      if (cancelToken.isCancelled) {
        progress.setProgress(TransferProgress(
          operation: TransferOperation.sync,
          state: TransferState.cancelled,
        ));
        _activeTokens.remove(cancelToken);
        return;
      }

      // Now copy the filtered files
      for (var i = 0; i < filesToSync.length; i++) {
        if (cancelToken.isCancelled) break;

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
          operation: TransferOperation.sync,
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
            cancelToken: cancelToken,
          );

          await for (final p in stream) {
            progress.setProgress(p.copyWith(
              operation: TransferOperation.sync,
              filesTransferred: i,
              totalFiles: filesToSync.length,
            ));
          }
        } catch (e) {
          // Rollback partial file/folder on failure
          try {
            if (await destProvider.exists(destEntryPath)) {
              await destProvider.delete(destEntryPath);
            }
          } catch (_) {}
          
          progress.setProgress(TransferProgress(
            operation: TransferOperation.sync,
            state: TransferState.failed,
            error: e.toString(),
            currentFile: entry,
          ));
        }
      }

      progress.setProgress(TransferProgress(
        operation: TransferOperation.sync,
        state: cancelToken.isCancelled
            ? TransferState.cancelled
            : TransferState.completed,
        filesTransferred: filesToSync.length,
        totalFiles: filesToSync.length,
      ));
    } catch (e) {
      progress.setProgress(TransferProgress(
        operation: TransferOperation.sync,
        state: TransferState.failed,
        error: e.toString(),
      ));
    }

    _activeTokens.remove(cancelToken);
  }

  /// Delete entries
  Future<void> delete({
    required StorageProvider provider,
    required List<FileEntry> entries,
    bool hideProgress = false,
  }) async {
    if (entries.isEmpty) return;

    final progress = ref.read(operationProgressProvider.notifier);

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];

      if (!hideProgress) {
        progress.setProgress(TransferProgress(
          operation: TransferOperation.delete,
          state: TransferState.inProgress,
          currentFile: entry,
          filesTransferred: i,
          totalFiles: entries.length,
        ));
      }

      try {
        await provider.delete(entry.path);
      } catch (e) {
        if (!hideProgress) {
          progress.setProgress(TransferProgress(
            operation: TransferOperation.delete,
            state: TransferState.failed,
            error: e.toString(),
            currentFile: entry,
          ));
        }
        throw Exception('Silme hatası: $e');
      }
    }

    if (!hideProgress) {
      progress.setProgress(TransferProgress(
        operation: TransferOperation.delete,
        state: TransferState.completed,
        filesTransferred: entries.length,
        totalFiles: entries.length,
      ));
    }
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

  /// Create a new empty file
  Future<void> createFile({
    required StorageProvider provider,
    required String parentPath,
    required String name,
  }) async {
    final newPath = provider.joinPath(parentPath, name);
    await provider.write(newPath, const Stream.empty()).last;
  }

  /// Cancel the current operation
  void cancelOperation() {
    for (final token in _activeTokens) {
      token.cancel();
    }
    _activeTokens.clear();
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
          sourceProvider: destProvider,
          entries: entries,
          destProvider: destProvider,
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
    final cancelToken = CancelToken();
    _activeTokens.add(cancelToken);
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
        if (cancelToken.isCancelled) return;

        try {
          final entries = await sourceProvider.list(currentPath, const ListOptions(showHidden: true));
          for (final entry in entries) {
            if (cancelToken.isCancelled) return;

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
          // İzin hatalarını yutuyoruz ama logluyoruz
          progress.setProgress(TransferProgress(
            operation: TransferOperation.copy,
            state: TransferState.inProgress,
            currentFile: FileEntry(
              name: 'Uyarı: Klasör okunamadı — ${e.toString().split('\n').first}',
              path: currentPath,
              isDirectory: true,
              size: 0,
            ),
          ));
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      await scanDirectory(sourcePath);

      if (cancelToken.isCancelled) {
        progress.setProgress(TransferProgress(
          operation: TransferOperation.copy,
          state: TransferState.cancelled,
        ));
        _activeTokens.remove(cancelToken);
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
      _activeTokens.remove(cancelToken);
    }
  }

  Future<void> executeSync({
    required StorageProvider sourceProvider,
    required StorageProvider destProvider,
    required String destPath,
    required List<SyncItem> selectedItems,
  }) async {
    final cancelToken = CancelToken();
    _activeTokens.add(cancelToken);
    final progress = ref.read(operationProgressProvider.notifier);

    progress.setProgress(TransferProgress(
      operation: TransferOperation.copy,
      state: TransferState.inProgress,
    ));

    try {
      for (var i = 0; i < selectedItems.length; i++) {
        if (cancelToken.isCancelled) break;

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
            cancelToken: cancelToken,
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
          // Dosya kopyalama hatası — kullanıcıya bildir ama diğer dosyalara devam et
          progress.setProgress(TransferProgress(
            operation: TransferOperation.copy,
            state: TransferState.inProgress,
            currentFile: FileEntry(
              name: 'Hata: ${item.relativePath} — ${e.toString().split('\n').first}',
              path: item.relativePath,
              isDirectory: false,
              size: 0,
            ),
            filesTransferred: i,
            totalFiles: selectedItems.length,
          ));
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }

      if (cancelToken.isCancelled) {
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
      _activeTokens.remove(cancelToken);
    }
  }
}