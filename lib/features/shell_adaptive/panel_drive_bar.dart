import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/models/connection_profile.dart';
import '../../core/storage/storage_provider_service.dart';
import '../connections/connection_repository.dart';
import '../file_operations/file_operations_state.dart';
import 'panel_controller.dart';

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
              color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.75) : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
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
    );
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
