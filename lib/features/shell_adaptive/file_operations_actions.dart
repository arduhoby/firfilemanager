import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../l10n/generated/app_localizations.dart' as gen;
import '../../core/storage/models/file_entry.dart';
import '../../core/storage/storage_provider.dart';
import '../../core/storage/storage_provider_service.dart';
import '../file_operations/archive_service.dart';
import '../file_operations/file_open_service.dart';
import '../file_operations/file_operations_service.dart';
import '../file_operations/file_operations_state.dart';
import '../file_operations/sync_models.dart';
import 'panel_controller.dart';
import 'sync_preview_dialog.dart';
import '../../core/storage/models/transfer_progress.dart';
import 'flying_file_animation.dart';

part 'file_operations_actions.g.dart';

/// Actions provider that bridges UI interactions (context menu, dialogs)
/// with the [FileOperationsService].
///
/// Handles clipboard operations, rename/delete/new folder dialogs,
/// and properties display.
@Riverpod(keepAlive: true)
class FileOperationsActions extends _$FileOperationsActions {
  @override
  void build() {
    // Service provider — no state
  }

  void _triggerAnimation(BuildContext context, PanelSide activeSide, TransferOperation operation, bool isDir) {
    if (!context.mounted) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final panelA = Offset(screenWidth * 0.25, screenHeight * 0.5);
    final panelB = Offset(screenWidth * 0.75, screenHeight * 0.5);
    
    final start = activeSide == PanelSide.a ? panelA : panelB;
    final end = operation == TransferOperation.delete 
        ? Offset(screenWidth * 0.5, screenHeight - 50)
        : (activeSide == PanelSide.a ? panelB : panelA);
    
    final icon = operation == TransferOperation.delete
        ? Icons.delete_outline
        : (isDir ? Icons.folder : Icons.insert_drive_file);

    final color = operation == TransferOperation.delete
        ? Colors.red
        : Theme.of(context).colorScheme.primary;

    FlyingFileAnimation.show(
      context,
      start: start,
      end: end,
      icon: icon,
      color: color,
    );
  }

  StorageProvider _getProviderForSide(PanelSide side) {
    final panelState = side == PanelSide.a
        ? ref.read(panelAProvider)
        : ref.read(panelBProvider);

    if (panelState.activeTab.providerId == 'local') {
      return ref.read(localStorageProviderProvider);
    }

    final provider = ref.read(storageProviderRegistryProvider)[panelState.activeTab.providerId];
    if (provider == null) {
      throw Exception('Connection is not active or disconnected.');
    }
    return provider;
  }

  /// Copy selected entries to clipboard
  void copyToClipboard(PanelSide side, List<FileEntry> entries) {
    final panelState = side == PanelSide.a
        ? ref.read(panelAProvider)
        : ref.read(panelBProvider);
    final providerId = panelState.activeTab.providerId;
    final paths = entries.map((e) => e.path).toList();
    ref.read(fileClipboardProvider.notifier).copy(paths, side, providerId);
  }

  /// Cut selected entries to clipboard
  void cutToClipboard(PanelSide side, List<FileEntry> entries) {
    final panelState = side == PanelSide.a
        ? ref.read(panelAProvider)
        : ref.read(panelBProvider);
    final providerId = panelState.activeTab.providerId;
    final paths = entries.map((e) => e.path).toList();
    ref.read(fileClipboardProvider.notifier).cut(paths, side, providerId);
  }

  /// Paste from clipboard to the given panel's current directory
  Future<void> paste(BuildContext context, PanelSide destSide) async {
    final destState = destSide == PanelSide.a
        ? ref.read(panelAProvider)
        : ref.read(panelBProvider);

    final provider = _getProviderForSide(destSide);
    final service = ref.read(fileOperationsServiceProvider.notifier);

    final clipboard = ref.read(fileClipboardProvider);
    if (clipboard.items.isNotEmpty) {
      final sourceSide = clipboard.sourceSide ?? (destSide == PanelSide.a ? PanelSide.b : PanelSide.a);
      final operation = clipboard.isCut ? TransferOperation.move : TransferOperation.copy;
      // We assume it might be a dir, but it's just for icon
      _triggerAnimation(context, sourceSide, operation, false);
    }

    await service.paste(
      destProvider: provider,
      destPath: destState.activeTab.currentPath,
    );

    // Refresh the destination panel
    await ref.read(panelControllerProvider.notifier).refresh(destSide);
  }

  /// Show rename dialog
  Future<void> showRenameDialog(
    BuildContext context,
    PanelSide side,
    FileEntry entry,
  ) async {
    final l10n = gen.AppLocalizations.of(context)!;
    final controller = TextEditingController(text: entry.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.actionRename),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.propertiesName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null || result.isEmpty || result == entry.name) return;

    final provider = _getProviderForSide(side);
    final service = ref.read(fileOperationsServiceProvider.notifier);

    try {
      await service.rename(
        provider: provider,
        entry: entry,
        newName: result,
      );
      await ref.read(panelControllerProvider.notifier).refresh(side);
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    }
  }

  /// Show delete confirmation dialog
  Future<void> showDeleteDialog(
    BuildContext context,
    PanelSide side,
    List<FileEntry> entries,
  ) async {
    final l10n = gen.AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteMessage(entries.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );

    if (result != true) return;

    final provider = _getProviderForSide(side);
    final service = ref.read(fileOperationsServiceProvider.notifier);

    _triggerAnimation(context, side, TransferOperation.delete, entries.isNotEmpty && entries.first.isDirectory);

    await service.delete(
      provider: provider,
      entries: entries,
    );

    // Clear selection and refresh
    if (side == PanelSide.a) {
      ref.read(panelAProvider.notifier).clearSelection();
    } else {
      ref.read(panelBProvider.notifier).clearSelection();
    }

    await ref.read(panelControllerProvider.notifier).refresh(side);
  }

  /// Show new folder dialog
  Future<void> showNewFolderDialog(
    BuildContext context,
    PanelSide side,
  ) async {
    final l10n = gen.AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.actionNewFolder),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.propertiesName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null || result.isEmpty) return;

    final panelState = side == PanelSide.a
        ? ref.read(panelAProvider)
        : ref.read(panelBProvider);

    final provider = _getProviderForSide(side);
    final service = ref.read(fileOperationsServiceProvider.notifier);

    try {
      await service.mkdir(
        provider: provider,
        parentPath: panelState.activeTab.currentPath,
        name: result,
      );
      await ref.read(panelControllerProvider.notifier).refresh(side);
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    }
  }

  /// Show file properties dialog
  Future<void> showPropertiesDialog(
    BuildContext context,
    FileEntry entry,
  ) async {
    final l10n = gen.AppLocalizations.of(context)!;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.actionProperties),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _propertyRow(l10n.propertiesName, entry.name),
            _propertyRow(l10n.propertiesPath, entry.path),
            _propertyRow(
              l10n.propertiesType,
              entry.isDirectory ? l10n.propertiesFolder : l10n.propertiesFile,
            ),
            if (!entry.isDirectory)
              _propertyRow(l10n.propertiesSize, _formatSize(entry.size)),
            if (entry.modified != null)
              _propertyRow(
                l10n.propertiesModified,
                entry.modified.toString(),
              ),
            if (entry.permissions != null)
              _propertyRow(l10n.propertiesPermissions, entry.permissions!),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionClose),
          ),
        ],
      ),
    );
  }  /// Copy selected entries from source panel to the other panel
  Future<void> copyToOtherPanel(BuildContext context, PanelSide sourceSide) async {
    print('ACTION: copyToOtherPanel called for $sourceSide');
    final sourceState = sourceSide == PanelSide.a
        ? ref.read(panelAProvider)
        : ref.read(panelBProvider);

    if (!sourceState.activeTab.hasSelection) return;

    final destSide = sourceSide == PanelSide.a ? PanelSide.b : PanelSide.a;
    final destState = destSide == PanelSide.a
        ? ref.read(panelAProvider)
        : ref.read(panelBProvider);

    final l10n = gen.AppLocalizations.of(context)!;
    final destPath = await _showTransferDialog(
      context,
      '${l10n.actionCopy} (${sourceState.activeTab.selectionCount} items)',
      l10n.actionCopy,
      destState.activeTab.currentPath,
    );

    if (destPath == null || destPath.isEmpty) return;

    final sourceProvider = _getProviderForSide(sourceSide);
    final destProvider = _getProviderForSide(destSide);
    final service = ref.read(fileOperationsServiceProvider.notifier);

    final entries = sourceState.activeTab.selectedEntries;
    _triggerAnimation(context, sourceSide, TransferOperation.copy, entries.isNotEmpty && entries.first.isDirectory);

    print('ACTION: Starting service.copy to $destPath');
    await service.copy(
      sourceProvider: sourceProvider,
      entries: sourceState.activeTab.selectedEntries,
      destProvider: destProvider,
      destPath: destPath,
    );
    print('ACTION: service.copy completed');

    await ref.read(panelControllerProvider.notifier).refresh(destSide);
  }

  /// Move selected entries from source panel to the other panel
  Future<void> moveToOtherPanel(BuildContext context, PanelSide sourceSide) async {
    final sourceState = sourceSide == PanelSide.a
        ? ref.read(panelAProvider)
        : ref.read(panelBProvider);

    if (!sourceState.activeTab.hasSelection) return;

    final destSide = sourceSide == PanelSide.a ? PanelSide.b : PanelSide.a;
    final destState = destSide == PanelSide.a
        ? ref.read(panelAProvider)
        : ref.read(panelBProvider);

    final l10n = gen.AppLocalizations.of(context)!;
    final destPath = await _showTransferDialog(
      context,
      '${l10n.actionMove} (${sourceState.activeTab.selectionCount} items)',
      l10n.actionMove,
      destState.activeTab.currentPath,
    );

    if (destPath == null || destPath.isEmpty) return;

    final provider = _getProviderForSide(sourceSide);
    final service = ref.read(fileOperationsServiceProvider.notifier);

    final entries = sourceState.activeTab.selectedEntries;
    _triggerAnimation(context, sourceSide, TransferOperation.move, entries.isNotEmpty && entries.first.isDirectory);

    await service.move(
      provider: provider,
      entries: sourceState.activeTab.selectedEntries,
      destPath: destPath,
    );

    // Clear selection and refresh both panels
    if (sourceSide == PanelSide.a) {
      ref.read(panelAProvider.notifier).clearSelection();
    } else {
      ref.read(panelBProvider.notifier).clearSelection();
    }

    await ref.read(panelControllerProvider.notifier).refresh(sourceSide);
    await ref.read(panelControllerProvider.notifier).refresh(destSide);
  }

  Future<String?> _showTransferDialog(
    BuildContext context,
    String title,
    String buttonLabel,
    String initialDestPath,
  ) async {
    final l10n = gen.AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initialDestPath);
    final theme = Theme.of(context);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.drive_file_move_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Destination Path:', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                autofocus: true,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.folder_open, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please review the destination path before proceeding.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            icon: const Icon(Icons.check, size: 18),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  /// Synchronize selected panel to the other panel
  Future<void> syncPanels(BuildContext context, PanelSide sourceSide) async {
    final destSide = sourceSide == PanelSide.a ? PanelSide.b : PanelSide.a;

    final sourceState = sourceSide == PanelSide.a ? ref.read(panelAProvider) : ref.read(panelBProvider);
    final destState = destSide == PanelSide.a ? ref.read(panelAProvider) : ref.read(panelBProvider);

    final sourcePath = sourceState.activeTab.currentPath;
    final destPath = destState.activeTab.currentPath;

    final sourceProvider = _getProviderForSide(sourceSide);
    final destProvider = _getProviderForSide(destSide);
    
    final service = ref.read(fileOperationsServiceProvider.notifier);

    // Step 1: Analyze
    final syncItems = await service.analyzeSync(
      sourceProvider: sourceProvider,
      sourcePath: sourcePath,
      destProvider: destProvider,
      destPath: destPath,
    );

    if (syncItems.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes found. Directories are already synchronized.')),
        );
      }
      return;
    }

    // Step 2: Show Preview Dialog
    if (!context.mounted) return;
    
    final selectedItems = await showDialog<List<SyncItem>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SyncPreviewDialog(
        sourcePath: sourcePath,
        destPath: destPath,
        items: syncItems,
      ),
    );

    if (selectedItems == null || selectedItems.isEmpty) return;

    // Step 3: Execute Sync
    await service.executeSync(
      sourceProvider: sourceProvider,
      destProvider: destProvider,
      destPath: destPath,
      selectedItems: selectedItems,
    );

    // Refresh panels after sync
    await ref.read(panelControllerProvider.notifier).refresh(sourceSide);
    await ref.read(panelControllerProvider.notifier).refresh(destSide);
  }

  /// Handle Drag and Drop between panels (instant copy)
  Future<void> handleDragAndDrop(
    BuildContext context,
    PanelSide sourceSide,
    PanelSide destSide,
    List<FileEntry> entries,
  ) async {
    if (sourceSide == destSide) return;
    if (entries.isEmpty) return;

    final destState = destSide == PanelSide.a
        ? ref.read(panelAProvider)
        : ref.read(panelBProvider);

    final destPath = destState.activeTab.currentPath;

    final sourceProvider = _getProviderForSide(sourceSide);
    final destProvider = _getProviderForSide(destSide);
    final service = ref.read(fileOperationsServiceProvider.notifier);

    _triggerAnimation(context, sourceSide, TransferOperation.copy, entries.isNotEmpty && entries.first.isDirectory);

    await service.copy(
      sourceProvider: sourceProvider,
      entries: entries,
      destProvider: destProvider,
      destPath: destPath,
    );

    await ref.read(panelControllerProvider.notifier).refresh(destSide);
  }

  /// Delete selected entries from the given panel without confirmation
  Future<void> deleteSelected(BuildContext context, PanelSide side) async {
    final state = side == PanelSide.a
        ? ref.read(panelAProvider)
        : ref.read(panelBProvider);

    if (!state.activeTab.hasSelection) return;

    final provider = _getProviderForSide(side);
    final service = ref.read(fileOperationsServiceProvider.notifier);

    final entries = state.activeTab.selectedEntries;
    _triggerAnimation(context, side, TransferOperation.delete, entries.isNotEmpty && entries.first.isDirectory);

    await service.delete(
      provider: provider,
      entries: state.activeTab.selectedEntries,
    );

    if (side == PanelSide.a) {
      ref.read(panelAProvider.notifier).clearSelection();
    } else {
      ref.read(panelBProvider.notifier).clearSelection();
    }

    await ref.read(panelControllerProvider.notifier).refresh(side);
  }

  /// Open a file with the system default application
  Future<void> openWithDefault(BuildContext context, FileEntry entry) async {
    final openService = ref.read(fileOpenServiceProvider.notifier);
    final success = await openService.openWithDefault(entry.path);

    if (!success && context.mounted) {
      _showErrorSnackBar(context, 'Failed to open: ${entry.name}');
    }
  }

  /// Reveal a file in Finder/Explorer
  Future<void> revealInFileManager(BuildContext context, FileEntry entry) async {
    final openService = ref.read(fileOpenServiceProvider.notifier);
    final success = await openService.revealInFileManager(entry.path);

    if (!success && context.mounted) {
      _showErrorSnackBar(context, 'Failed to reveal: ${entry.name}');
    }
  }

  /// Compress selected entries into an archive
  Future<void> compressEntries(
    BuildContext context,
    PanelSide side,
    List<FileEntry> entries,
    ArchiveFormat format,
  ) async {
    final l10n = gen.AppLocalizations.of(context)!;
    final panelState = side == PanelSide.a
        ? ref.read(panelAProvider)
        : ref.read(panelBProvider);

    // Suggest archive name based on first entry or selection
    final suggestedName = entries.length == 1
        ? entries.first.name
        : 'archive';

    final controller = TextEditingController(text: suggestedName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.actionCompress),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.propertiesName,
            suffixText: switch (format) {
              ArchiveFormat.zip => '.zip',
              ArchiveFormat.tar => '.tar',
              ArchiveFormat.tarGz => '.tar.gz',
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null || result.isEmpty) return;

    final archiveService = ref.read(archiveServiceProvider.notifier);

    try {
      await archiveService.compress(
        entries: entries,
        destDir: panelState.activeTab.currentPath,
        archiveName: result,
        format: format,
      );
      await ref.read(panelControllerProvider.notifier).refresh(side);
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    }
  }

  /// Extract an archive to the current directory
  Future<void> extractArchive(
    BuildContext context,
    PanelSide side,
    FileEntry entry,
  ) async {
    final panelState = side == PanelSide.a
        ? ref.read(panelAProvider)
        : ref.read(panelBProvider);

    final archiveService = ref.read(archiveServiceProvider.notifier);

    try {
      await archiveService.extract(
        archivePath: entry.path,
        destDir: panelState.activeTab.currentPath,
      );
      await ref.read(panelControllerProvider.notifier).refresh(side);
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    }
  }

  /// Check if a file is a supported archive
  bool isArchiveFile(FileEntry entry) {
    if (entry.isDirectory) return false;
    final archiveService = ref.read(archiveServiceProvider.notifier);
    return archiveService.isArchive(entry.path);
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _propertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Show dialog to share a file or folder via SMB
  Future<void> showShareSmbDialog(BuildContext context, FileEntry entry) async {
    // 1. Get local IPs
    final ips = <String>[];
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            ips.add(addr.address);
          }
        }
      }
    } catch (_) {}
    if (ips.isEmpty) ips.add('127.0.0.1');

    // 2. Fetch existing share points from macOS sharing command
    String shareName = entry.name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    if (shareName.isEmpty) shareName = 'shared_folder';
    String relativePath = '';
    bool isShared = false;
    String matchedShareName = shareName;

    try {
      final res = await Process.run('sharing', ['-l']);
      if (res.exitCode == 0) {
        final output = res.stdout as String;
        final lines = output.split('\n');
        String? currentName;
        String? currentPath;
        
        for (final line in lines) {
          final trimmed = line.trim();
          if (line.startsWith('name:')) {
            currentName = line.split('name:')[1].trim();
          } else if (trimmed.startsWith('path:')) {
            currentPath = line.split('path:')[1].trim();
            
            if (currentName != null && currentPath != null) {
              final ep = entry.path.replaceAll(RegExp(r'/+$'), '');
              final sp = currentPath.replaceAll(RegExp(r'/+$'), '');
              if (ep == sp) {
                isShared = true;
                matchedShareName = currentName;
                relativePath = '';
                break;
              } else if (ep.startsWith(sp + '/')) {
                isShared = true;
                matchedShareName = currentName;
                relativePath = ep.substring(sp.length);
                break;
              }
            }
          }
        }
      }
    } catch (_) {}

    if (context.mounted) {
      showDialog<void>(
        context: context,
        builder: (context) {
          return _SmbShareDialog(
            entry: entry,
            localIps: ips,
            defaultShareName: shareName,
            matchedShareName: matchedShareName,
            relativePath: relativePath,
            isAlreadyShared: isShared,
          );
        },
      ).then((_) {
        // Automatically refresh panels when the dialog is closed
        ref.read(panelControllerProvider.notifier).refresh(PanelSide.a);
        ref.read(panelControllerProvider.notifier).refresh(PanelSide.b);
      });
    }
  }
}

class _SmbShareDialog extends StatefulWidget {
  final FileEntry entry;
  final List<String> localIps;
  final String defaultShareName;
  final String matchedShareName;
  final String relativePath;
  final bool isAlreadyShared;

  const _SmbShareDialog({
    required this.entry,
    required this.localIps,
    required this.defaultShareName,
    required this.matchedShareName,
    required this.relativePath,
    required this.isAlreadyShared,
  });

  @override
  State<_SmbShareDialog> createState() => _SmbShareDialogState();
}

class _SmbShareDialogState extends State<_SmbShareDialog> {
  late String _selectedIp;
  bool _isProcessing = false;

  Future<void> _executeSharingCommand({
    required List<String> normalArgs,
    required String privilegeCommand,
  }) async {
    setState(() => _isProcessing = true);
    try {
      // First attempt to execute without sudo (passwordless)
      final res = await Process.run('sharing', normalArgs);
      if (res.exitCode == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Operation completed successfully!')),
          );
          Navigator.pop(context);
        }
        return;
      }

      // If passwordless failed, request administrator privileges
      final privilegedRes = await Process.run('osascript', [
        '-e',
        'do shell script "$privilegeCommand" with administrator privileges',
      ]);
      if (privilegedRes.exitCode == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Operation completed successfully (with admin privileges)!')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${privilegedRes.stderr}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedIp = widget.localIps.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shareName = widget.isAlreadyShared ? widget.matchedShareName : widget.defaultShareName;
    final relPath = widget.relativePath.replaceAll('/', '\\');
    
    // Construct URLs
    final macUrl = 'smb://$_selectedIp/$shareName${widget.relativePath}';
    final winUrl = '\\\\$_selectedIp\\$shareName$relPath';
    
    final cliCommandSecure = 'sudo sharing -a "${widget.entry.path}" -n "$shareName"';
    final cliCommandGuest = 'sudo sharing -a "${widget.entry.path}" -n "$shareName" -g';
    final stopCliCommand = 'sudo sharing -r "$shareName"';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 520,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.share, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Share via SMB',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // IP Selector
            Row(
              children: [
                const Text('Select IP Address:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedIp,
                  items: widget.localIps.map((ip) {
                    return DropdownMenuItem<String>(
                      value: ip,
                      child: Text(ip),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedIp = val);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Share Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isAlreadyShared 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.isAlreadyShared ? Colors.green : Colors.amber,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isAlreadyShared ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: widget.isAlreadyShared ? Colors.green : Colors.amber,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isAlreadyShared
                        ? 'This path is active inside the shared folder: "$shareName"'
                        : 'This directory is not shared yet on your Mac.',
                      style: TextStyle(
                        color: widget.isAlreadyShared ? Colors.green[800] : Colors.amber[800],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mac URL Card
            _buildUrlCard(
              title: 'macOS / Linux Link',
              url: macUrl,
              icon: Icons.apple,
            ),
            const SizedBox(height: 12),

            // Windows URL Card
            _buildUrlCard(
              title: 'Windows Network Path',
              url: winUrl,
              icon: Icons.window,
            ),
            const SizedBox(height: 20),

            if (_isProcessing) ...[
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Processing sharing configuration...',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              if (!widget.isAlreadyShared) ...[
                // Share action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        icon: const Icon(Icons.security, size: 16),
                        label: const Text('Share (Secure)', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          _executeSharingCommand(
                            normalArgs: ['-a', widget.entry.path, '-n', shareName],
                            privilegeCommand: 'sharing -a \\"${widget.entry.path}\\" -n \\"$shareName\\"',
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                        ),
                        icon: const Icon(Icons.people_outline, size: 16),
                        label: const Text('Share (Guest)', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          _executeSharingCommand(
                            normalArgs: ['-a', widget.entry.path, '-n', shareName, '-g'],
                            privilegeCommand: 'sharing -a \\"${widget.entry.path}\\" -n \\"$shareName\\" -g',
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 20),
                
                Text(
                  'Or copy Terminal Command to Share (macOS):',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          cliCommandSecure,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: cliCommandSecure));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password protected command copied')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Alternatively, enable "File Sharing" in System Settings > Sharing, and add this folder.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ] else ...[
                // Stop Share action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                    icon: const Icon(Icons.link_off, size: 16),
                    label: const Text('Stop Sharing Now'),
                    onPressed: () {
                      _executeSharingCommand(
                        normalArgs: ['-r', shareName],
                        privilegeCommand: 'sharing -r \\"$shareName\\"',
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 20),

                Text(
                  'Or copy Terminal Command to Stop Sharing (macOS):',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          stopCliCommand,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: stopCliCommand));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Remove command copied to clipboard')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUrlCard({
    required String title,
    required String url,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                SelectableText(
                  url,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Colors.blueAccent),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title copied to clipboard')),
              );
            },
          ),
        ],
      ),
    );
  }
}