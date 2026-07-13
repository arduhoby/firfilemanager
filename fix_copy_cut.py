import re

with open('lib/features/shell_adaptive/file_operations_actions.dart', 'r') as f:
    content = f.read()

content = content.replace(
    "ref.read(fileClipboardProvider.notifier).copy(paths, side);",
    "ref.read(fileClipboardProvider.notifier).copy(paths, side, panelState.activeTab.providerId);"
)
content = content.replace(
    "ref.read(fileClipboardProvider.notifier).cut(paths, side);",
    "ref.read(fileClipboardProvider.notifier).cut(paths, side, panelState.activeTab.providerId);"
)

with open('lib/features/shell_adaptive/file_operations_actions.dart', 'w') as f:
    f.write(content)
