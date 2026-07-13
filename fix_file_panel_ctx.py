with open('lib/features/shell_adaptive/file_panel.dart', 'r') as f:
    content = f.read()

# Add copyBgPath
content = content.replace(
    "          PopupMenuItem(value: 'revealBg', child: Row(children: [const Icon(Icons.search, size: 18), const SizedBox(width: 8), Text(l10n.actionRevealInFinder)])),",
    "          PopupMenuItem(value: 'revealBg', child: Row(children: [const Icon(Icons.search, size: 18), const SizedBox(width: 8), Text(l10n.actionRevealInFinder)])),\n          PopupMenuItem(value: 'copyBgPath', child: Row(children: [const Icon(Icons.copy_all, size: 18), const SizedBox(width: 8), const Text('Copy Path')])),",
    1
)

# Handle copyBgPath
content = content.replace(
    "             ref.read(fileOpenServiceProvider.notifier).revealInFileManager(_panelState.currentPath);",
    "             ref.read(fileOpenServiceProvider.notifier).revealInFileManager(_panelState.currentPath);\n          case 'copyBgPath':\n             Clipboard.setData(ClipboardData(text: _panelState.currentPath));\n             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Path copied to clipboard')));",
    1
)

# Add copyPath
content = content.replace(
    "          PopupMenuItem(value: 'reveal', child: Row(children: [const Icon(Icons.search, size: 18), const SizedBox(width: 8), Text(l10n.actionRevealInFinder)])),",
    "          PopupMenuItem(value: 'reveal', child: Row(children: [const Icon(Icons.search, size: 18), const SizedBox(width: 8), Text(l10n.actionRevealInFinder)])),\n          PopupMenuItem(value: 'copyPath', child: Row(children: [const Icon(Icons.copy_all, size: 18), const SizedBox(width: 8), const Text('Copy Path')])),",
    1
)

# Handle copyPath
content = content.replace(
    "          actions.revealInFileManager(context, entry);",
    "          actions.revealInFileManager(context, entry);\n        case 'copyPath':\n          Clipboard.setData(ClipboardData(text: entry.path));\n          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Path copied to clipboard')));",
    1
)

with open('lib/features/shell_adaptive/file_panel.dart', 'w') as f:
    f.write(content)

print("Added copyPath to file_panel.dart")
