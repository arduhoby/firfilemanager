import re
with open('lib/features/file_operations/file_operations_state.dart', 'r') as f:
    content = f.read()

new_clipboard = """
/// Clipboard for copy/cut operations
@Riverpod(keepAlive: true)
class FileClipboard extends _$FileClipboard {
  @override
  ClipboardState? build() => null;

  void copy(List<String> paths, PanelSide side) {
    state = ClipboardState(
      sourcePaths: paths,
      sourceSide: side,
      operation: ClipboardOperation.copy,
    );
  }

  void cut(List<String> paths, PanelSide side) {
    state = ClipboardState(
      sourcePaths: paths,
      sourceSide: side,
      operation: ClipboardOperation.cut,
    );
  }

  void clear() {
    state = null;
  }
}
"""

content = re.sub(r'/// Clipboard for copy/cut operations.*?class FileClipboard extends _\$FileClipboard \{.*?\}', new_clipboard, content, flags=re.DOTALL)

with open('lib/features/file_operations/file_operations_state.dart', 'w') as f:
    f.write(content)
