with open('lib/features/shell_adaptive/dual_pane_shell.dart', 'r') as f:
    content = f.read()

import_statement = "import '../../core/settings/settings_provider.dart';\n"
if "import '../../core/settings/settings_provider.dart';" not in content:
    content = content.replace(
        "import 'package:flutter_riverpod/flutter_riverpod.dart';",
        "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" + import_statement
    )

new_build = """  @override
  Widget build(BuildContext context) {
    final ratio = ref.watch(panelSplitRatioProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    if (settings.singlePanelMode) {
      final activeSide = ref.watch(activePanelProvider);
      return activeSide == PanelSide.a
          ? const FilePanel(side: PanelSide.a)
          : const FilePanel(side: PanelSide.b);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - _kDividerWidth;
        final leftWidth = available * ratio;
        final rightWidth = available * (1 - ratio);"""

start_idx = content.find("  @override\n  Widget build(BuildContext context) {\n    final ratio = ref.watch(panelSplitRatioProvider);\n    final theme = Theme.of(context);\n    final isDark = theme.brightness == Brightness.dark;\n\n    return LayoutBuilder(")
end_idx = content.find("        final rightWidth = available * (1 - ratio);", start_idx) + len("        final rightWidth = available * (1 - ratio);")

if start_idx != -1 and end_idx != -1:
    content = content[:start_idx] + new_build + content[end_idx:]
    with open('lib/features/shell_adaptive/dual_pane_shell.dart', 'w') as f:
        f.write(content)
    print("Fixed _ResizablePanels!")
else:
    print("Not found")

