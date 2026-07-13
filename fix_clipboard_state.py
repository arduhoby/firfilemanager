with open('lib/features/file_operations/file_operations_state.dart', 'r') as f:
    content = f.read()

import re

# Add sourceProviderId to ClipboardState
new_clipboard_state = """class ClipboardState {
  const ClipboardState({
    required this.sourcePaths,
    required this.sourceSide,
    required this.sourceProviderId,
    required this.operation,
  });

  final List<String> sourcePaths;
  final PanelSide sourceSide;
  final String sourceProviderId;
  final ClipboardOperation operation;
}
"""

content = re.sub(r'class ClipboardState \{.*?\}', new_clipboard_state, content, flags=re.DOTALL)

# Also update the methods in FileClipboard
content = content.replace("void copy(List<String> paths, PanelSide side) {", "void copy(List<String> paths, PanelSide side, String providerId) {")
content = content.replace("void cut(List<String> paths, PanelSide side) {", "void cut(List<String> paths, PanelSide side, String providerId) {")
content = content.replace("sourceSide: side,", "sourceSide: side,\n      sourceProviderId: providerId,")

with open('lib/features/file_operations/file_operations_state.dart', 'w') as f:
    f.write(content)
