import 'package:flutter/material.dart';
import '../../core/storage/storage_provider.dart';
import '../file_operations/sync_models.dart';
import '../../l10n/generated/app_localizations.dart' as gen;

class SyncPreviewDialog extends StatefulWidget {
  final String sourcePath;
  final String destPath;
  final List<SyncItem> items;

  const SyncPreviewDialog({
    super.key,
    required this.sourcePath,
    required this.destPath,
    required this.items,
  });

  @override
  State<SyncPreviewDialog> createState() => _SyncPreviewDialogState();
}

class SyncNode {
  final String path;
  final String name;
  final int depth;
  final bool isDirectory;
  SyncStatus status;
  SyncItem? item;
  bool isSelected;

  SyncNode({
    required this.path,
    required this.name,
    required this.depth,
    required this.isDirectory,
    required this.status,
    required this.isSelected,
    this.item,
  });
}

class _SyncPreviewDialogState extends State<SyncPreviewDialog> {
  late List<SyncItem> _items;
  late List<SyncNode> _nodes;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
    _buildTree();
  }

  void _buildTree() {
    final nodes = <SyncNode>[];
    final dirMap = <String, SyncNode>{};

    for (final item in _items) {
      final parts = item.relativePath.split('/');
      String currentPath = '';

      for (int i = 0; i < parts.length - 1; i++) {
        final part = parts[i];
        currentPath = currentPath.isEmpty ? part : '$currentPath/$part';

        if (!dirMap.containsKey(currentPath)) {
          final dirNode = SyncNode(
            path: currentPath,
            name: part,
            depth: i,
            isDirectory: true,
            status: SyncStatus.identical,
            isSelected: false,
          );
          dirMap[currentPath] = dirNode;
          nodes.add(dirNode);
        }
      }

      final fileNode = SyncNode(
        path: item.relativePath,
        name: parts.last,
        depth: parts.length - 1,
        isDirectory: false,
        status: item.status,
        isSelected: item.isSelected,
        item: item,
      );
      nodes.add(fileNode);
    }

    for (final dir in dirMap.values) {
      bool hasMissing = false;
      bool hasModified = false;
      bool hasSelected = false;

      for (final node in nodes) {
        if (!node.isDirectory && node.path.startsWith('${dir.path}/')) {
          if (node.status == SyncStatus.missing) hasMissing = true;
          if (node.status == SyncStatus.modified) hasModified = true;
          if (node.isSelected) hasSelected = true;
        }
      }

      if (hasMissing) {
        dir.status = SyncStatus.missing;
      } else if (hasModified) {
        dir.status = SyncStatus.modified;
      } else {
        dir.status = SyncStatus.identical;
      }
      dir.isSelected = hasSelected;
    }

    nodes.sort((a, b) => a.path.compareTo(b.path));
    _nodes = nodes;
  }

  int get _selectedCount => _items.where((i) => i.isSelected).length;

  Color _getColorForStatus(SyncStatus status) {
    switch (status) {
      case SyncStatus.missing:
        return Colors.red;
      case SyncStatus.modified:
        return Colors.blue.shade800; // Dark Blue
      case SyncStatus.identical:
        return Colors.green;
    }
  }

  IconData _getIconForStatus(SyncNode node) {
    if (node.isDirectory) {
      return node.isSelected ? Icons.folder : Icons.folder_outlined;
    }
    switch (node.status) {
      case SyncStatus.missing:
        return Icons.add_circle_outline;
      case SyncStatus.modified:
        return Icons.change_circle_outlined;
      case SyncStatus.identical:
        return Icons.check_circle_outline;
    }
  }

  String _getLabelForStatus(SyncStatus status) {
    switch (status) {
      case SyncStatus.missing:
        return 'Missing';
      case SyncStatus.modified:
        return 'Modified';
      case SyncStatus.identical:
        return 'Identical';
    }
  }

  void _toggleNode(SyncNode node, bool value) {
    setState(() {
      node.isSelected = value;
      if (node.item != null) {
        node.item!.isSelected = value;
      }

      if (node.isDirectory) {
        for (final child in _nodes) {
          if (child.path.startsWith('${node.path}/')) {
            child.isSelected = value;
            if (child.item != null) {
              child.item!.isSelected = value;
            }
          }
        }
      } else {
        // Automatically check parents if a child is checked
        if (value) {
          final parts = node.path.split('/');
          String currentPath = '';
          for (int i = 0; i < parts.length - 1; i++) {
            currentPath = currentPath.isEmpty ? parts[i] : '$currentPath/${parts[i]}';
            final parent = _nodes.firstWhere((n) => n.path == currentPath && n.isDirectory, orElse: () => node);
            if (parent != node) {
              parent.isSelected = true;
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.sync, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Sync Preview'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Source: ${widget.sourcePath}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Destination: ${widget.destPath}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$_selectedCount of ${_items.length} files selected to sync.', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _nodes.length,
                  itemBuilder: (context, index) {
                    final node = _nodes[index];
                    final color = _getColorForStatus(node.status);

                    return InkWell(
                      onTap: () => _toggleNode(node, !node.isSelected),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        child: Row(
                          children: [
                            SizedBox(width: node.depth * 24.0), // Tree indentation
                            Checkbox(
                              value: node.isSelected,
                              onChanged: (val) {
                                if (val != null) _toggleNode(node, val);
                              },
                              activeColor: color,
                            ),
                            Icon(_getIconForStatus(node), color: color, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                node.name,
                                style: TextStyle(
                                  color: color, 
                                  fontWeight: node.isDirectory || node.status != SyncStatus.identical 
                                      ? FontWeight.bold 
                                      : FontWeight.normal
                                ),
                              ),
                            ),
                            if (!node.isDirectory)
                              Text(
                                _getLabelForStatus(node.status),
                                style: TextStyle(color: color, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(gen.AppLocalizations.of(context)?.actionCancel ?? 'Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            final selected = _items.where((i) => i.isSelected).toList();
            Navigator.pop(context, selected);
          },
          icon: const Icon(Icons.copy, size: 18),
          label: Text('Start Sync ($_selectedCount)'),
        ),
      ],
    );
  }
}
