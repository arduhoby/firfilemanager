import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/models/connection_profile.dart';
import '../../core/storage/storage_provider.dart';
import '../../core/storage/storage_provider_service.dart';
import '../../core/settings/recent_service.dart';
import '../connections/connection_repository.dart';
import '../file_operations/file_operations_state.dart';
import '../file_operations/file_open_service.dart';
import 'panel_controller.dart';
import '../../widgets/cascade_menu/cascade_menu.dart';

/// A bar showing available local drives/mounts and active cloud/network connections.
class PanelDriveBar extends ConsumerStatefulWidget {
  const PanelDriveBar({required this.side, super.key});
  
  final PanelSide side;

  @override
  ConsumerState<PanelDriveBar> createState() => _PanelDriveBarState();
}

class _PanelDriveBarState extends ConsumerState<PanelDriveBar> {
  List<_DriveItem> _localDrives = [];

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadLocalDrives();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _loadLocalDrives();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLocalDrives() async {
    final drives = <_DriveItem>[];
    
    // Default home directory
    final localProvider = ref.read(localStorageProviderProvider);
    final homePath = await localProvider.homePath;
    
    drives.add(_DriveItem(
      id: 'local',
      path: homePath,
      name: 'Home',
      icon: Icons.home_filled,
      isLocal: true,
    ));
    
    // Platform specific mounts
    try {
      if (Platform.isMacOS) {
        final volumes = Directory('/Volumes');
        if (volumes.existsSync()) {
          for (final entity in volumes.listSync().whereType<Directory>()) {
            final name = entity.path.split('/').last;
            // Akıllı filtre: gizli veya virtual driveları gizle
            if (!name.startsWith('.') && 
                !name.startsWith('com.apple.') && 
                name != 'Recovery' && 
                name != 'VM' && 
                name != 'Preboot' &&
                name != 'Update') {
              
              String displayName = name;
              if (name == 'Macintosh HD') displayName = 'AnaDisk';
              
              drives.add(_DriveItem(
                id: 'local',
                path: entity.path,
                name: displayName,
                icon: Icons.storage,
                isLocal: true,
              ));
            }
          }
        }
      } else if (Platform.isLinux) {
        for (final baseDir in ['/media', '/mnt']) {
          final dir = Directory(baseDir);
          if (dir.existsSync()) {
            for (final userDir in dir.listSync().whereType<Directory>()) {
               if (baseDir == '/media') {
                 for (final mount in userDir.listSync().whereType<Directory>()) {
                   drives.add(_DriveItem(
                     id: 'local',
                     path: mount.path,
                     name: mount.path.split('/').last,
                     icon: Icons.storage,
                     isLocal: true,
                   ));
                 }
               } else {
                 drives.add(_DriveItem(
                   id: 'local',
                   path: userDir.path,
                   name: userDir.path.split('/').last,
                   icon: Icons.storage,
                   isLocal: true,
                 ));
               }
            }
          }
        }
        // Root
        drives.add(const _DriveItem(
          id: 'local',
          path: '/',
          name: 'Root',
          icon: Icons.computer,
          isLocal: true,
        ));
      } else if (Platform.isWindows) {
        for (var i = 67; i <= 90; i++) { // C to Z
          final letter = String.fromCharCode(i);
          final path = '$letter:\\';
          if (Directory(path).existsSync()) {
            drives.add(_DriveItem(
              id: 'local',
              path: path,
              name: '$letter:',
              icon: Icons.storage,
              isLocal: true,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load local drives: $e');
    }

    if (mounted) {
      setState(() {
        _localDrives = drives;
      });
    }
  }

  String _formatName(String name) {
    if (name.length <= 10) return name;
    return '${name.substring(0, 8)}..';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final registry = ref.watch(storageProviderRegistryProvider);
    final connections = ref.watch(connectionRepositoryProvider);
    final activeState = widget.side == PanelSide.a
        ? ref.watch(panelAProvider)
        : ref.watch(panelBProvider);
    
    final currentProviderId = activeState.activeTab.providerId;
    final currentPath = activeState.activeTab.currentPath;

    final allItems = <_DriveItem>[..._localDrives];

    // Add active remote connections
    for (final profile in connections) {
      final provider = registry[profile.id];
      if (provider != null && provider.isConnected) {
        allItems.add(_DriveItem(
          id: profile.id,
          path: '/', // Root of the connection
          name: profile.name,
          icon: _getIconForType(profile.type),
          color: _getColorForType(profile.type, theme),
          isLocal: false,
        ));
      }
    }

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allItems.length,
              itemBuilder: (context, index) {
                final item = allItems[index];
          // Check if active
          final isSelected = item.id == currentProviderId && 
             (item.isLocal ? currentPath.startsWith(item.path) : true);
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Material(
              color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4) : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
                side: BorderSide(
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () async {
                  if (item.isLocal) {
                    ref.read(panelControllerProvider.notifier).navigate(
                      widget.side,
                      item.path,
                      providerId: 'local',
                    );
                  } else {
                    try {
                      final provider = registry[item.id]!;
                      final homePath = await provider.homePath;
                      ref.read(panelControllerProvider.notifier).navigate(
                        widget.side,
                        homePath,
                        providerId: item.id,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Cannot open: $e')),
                        );
                      }
                    }
                  }
                },
                child: Container(
                  width: 44, // reduced from 56 to take up less width
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 15, // reduced from 20 for a slimmer profile
                        color: isSelected 
                           ? theme.colorScheme.onPrimaryContainer
                           : (item.color ?? theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _formatName(item.name),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isSelected 
                             ? theme.colorScheme.onPrimaryContainer
                             : theme.colorScheme.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 8.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
          ),
          // Disk Space Indicator (also shown in status bar now, but kept here for now or we can remove it from here)
          // Removing from here to avoid duplication. It will be moved to the status bar.
          // Recents Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.history, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 12,
                  onPressed: () => _showRecentsMenu(context, theme),
                  tooltip: 'Son Kullanılanlar',
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  void _showRecentsMenu(BuildContext context, ThemeData theme) {
    final recentState = ref.read(recentServiceProvider);
    
    final items = <CascadeMenuItem>[
      CascadeMenuItem(
        value: 'header_folders',
        label: 'Son Klasörler',
        icon: Icons.folder,
        children: recentState.recentFolders.map((path) => CascadeMenuItem(
          value: 'folder_$path',
          label: path.split('/').last.isEmpty ? path : path.split('/').last,
          icon: Icons.folder_open,
        )).toList(),
      ),
      CascadeMenuItem(
        value: 'header_files',
        label: 'Son Dosyalar',
        icon: Icons.insert_drive_file,
        children: recentState.recentFiles.map((path) => CascadeMenuItem(
          value: 'file_$path',
          label: path.split('/').last,
          icon: Icons.file_present,
        )).toList(),
      ),
    ];

    final RenderBox button = context.findRenderObject() as RenderBox;
    final position = button.localToGlobal(Offset(0, button.size.height));

    showCascadeMenu(
      context: context,
      position: position,
      items: items,
    ).then((value) {
      if (value == null) return;
      if (value.startsWith('folder_')) {
        final path = value.substring('folder_'.length);
        ref.read(panelControllerProvider.notifier).navigate(widget.side, path, providerId: 'local');
      } else if (value.startsWith('file_')) {
        final path = value.substring('file_'.length);
        ref.read(fileOpenServiceProvider.notifier).openWithDefault(path);
      }
    });
  }

  IconData _getIconForType(ConnectionType type) {
    return switch (type) {
      ConnectionType.sftp => Icons.dns,
      ConnectionType.ftp => Icons.dns,
      ConnectionType.ftps => Icons.dns,
      ConnectionType.webdav => Icons.cloud,
      ConnectionType.smb => Icons.router,
      ConnectionType.gdrive => Icons.add_to_drive,
      ConnectionType.dropbox => Icons.cloud_queue,
      ConnectionType.onedrive => Icons.cloud_circle,
      ConnectionType.nextcloud => Icons.cloud_sync,
      ConnectionType.local => Icons.storage,
    };
  }

  Color _getColorForType(ConnectionType type, ThemeData theme) {
    return switch (type) {
      ConnectionType.sftp => Colors.green,
      ConnectionType.ftp => Colors.orange,
      ConnectionType.ftps => Colors.deepOrange,
      ConnectionType.webdav => Colors.blue,
      ConnectionType.smb => Colors.purple,
      ConnectionType.gdrive => Colors.red,
      ConnectionType.dropbox => Colors.indigo,
      ConnectionType.onedrive => Colors.blueAccent,
      ConnectionType.nextcloud => Colors.lightBlue,
      ConnectionType.local => theme.colorScheme.primary,
    };
  }
}

class _DriveItem {
  final String id;
  final String path;
  final String name;
  final IconData icon;
  final Color? color;
  final bool isLocal;

  const _DriveItem({
    required this.id,
    required this.path,
    required this.name,
    required this.icon,
    this.color,
    required this.isLocal,
  });
}

class DiskSpaceIndicator extends ConsumerStatefulWidget {
  final String providerId;
  final String path;

  const DiskSpaceIndicator({required this.providerId, required this.path});

  @override
  ConsumerState<DiskSpaceIndicator> createState() => _DiskSpaceIndicatorState();
}

class _DiskSpaceIndicatorState extends ConsumerState<DiskSpaceIndicator> {
  DiskSpaceInfo? _info;
  bool _isLoading = false;
  String _lastPath = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchSpace();
  }

  @override
  void didUpdateWidget(covariant DiskSpaceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.providerId != widget.providerId || oldWidget.path != widget.path) {
      _fetchSpace();
    }
  }

  Future<void> _fetchSpace() async {
    if (widget.providerId.isEmpty || widget.path.isEmpty) return;
    if (_lastPath == widget.path && _info != null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final registry = ref.read(storageProviderRegistryProvider);
      final provider = widget.providerId == 'local' 
          ? ref.read(localStorageProviderProvider)
          : registry[widget.providerId];
          
      if (provider != null) {
        final info = await provider.getDiskSpaceInfo(widget.path);
        if (mounted) {
          setState(() {
            _info = info;
            _lastPath = widget.path;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    if (i == 0) return '${size.toInt()} ${suffixes[i]}';
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: SizedBox(
          width: 12, 
          height: 12, 
          child: CircularProgressIndicator(strokeWidth: 2)
        ),
      );
    }

    if (_info == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final percent = _info!.totalBytes > 0 ? (_info!.usedBytes / _info!.totalBytes).clamp(0.0, 1.0) : 0.0;
    
    Color progressColor = theme.colorScheme.primary;
    if (percent > 0.9) {
      progressColor = theme.colorScheme.error;
    } else if (percent > 0.75) {
      progressColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Tooltip(
        message: 'Kullanılan: ${_formatBytes(_info!.usedBytes)}\nToplam: ${_formatBytes(_info!.totalBytes)}',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: percent,
                  backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${_formatBytes(_info!.totalBytes)} / ${_formatBytes(_info!.freeBytes)} boş',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9.5,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
