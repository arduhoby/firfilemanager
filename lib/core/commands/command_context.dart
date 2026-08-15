import '../storage/models/file_entry.dart';

enum CommandCapability {
  read,
  write,
  rename,
  delete,
  archive,
  share,
  localPath,
  mountedPath,
  terminal,
}

class CommandContext {
  const CommandContext({
    required this.sourcePanelId,
    required this.providerId,
    required this.currentPath,
    this.clickedEntry,
    this.selectedEntries = const <FileEntry>[],
    this.targetPanelIds = const <String>[],
    this.capabilities = const <CommandCapability>{},
    this.showHidden = false,
    this.hasClipboardEntries = false,
  });

  final String sourcePanelId;
  final String providerId;
  final String currentPath;
  final FileEntry? clickedEntry;
  final List<FileEntry> selectedEntries;
  final List<String> targetPanelIds;
  final Set<CommandCapability> capabilities;
  final bool showHidden;
  final bool hasClipboardEntries;

  List<FileEntry> get effectiveEntries {
    if (selectedEntries.isNotEmpty) {
      return List<FileEntry>.unmodifiable(selectedEntries);
    }
    final entry = clickedEntry;
    return entry == null ? const <FileEntry>[] : <FileEntry>[entry];
  }

  bool supports(CommandCapability capability) =>
      capabilities.contains(capability);
}
