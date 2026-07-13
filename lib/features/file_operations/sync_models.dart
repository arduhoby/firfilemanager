import '../../core/storage/models/file_entry.dart';
import '../../core/storage/storage_provider.dart';

enum SyncStatus {
  missing,
  modified,
  identical,
}

class SyncItem {
  final FileEntry sourceEntry;
  final String relativePath;
  final int depth;
  final SyncStatus status;
  bool isSelected;

  SyncItem({
    required this.sourceEntry,
    required this.relativePath,
    required this.depth,
    required this.status,
    required this.isSelected,
  });
}
