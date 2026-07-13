with open('lib/features/connections/connections_sidebar.dart', 'r') as f:
    content = f.read()

import_statement = "import '../settings/settings_dialog.dart';\n"
content = content.replace(
    "import 'package:flutter_riverpod/flutter_riverpod.dart';",
    "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" + import_statement
)

footer_code = """  Widget _buildFooter(BuildContext context, gen.AppLocalizations l10n, ThemeData theme, bool collapsed) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0x22FFFFFF) : const Color(0x18000000),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SidebarTile(
            icon: Icons.key_outlined,
            name: 'Cloud API Keys',
            subtitle: 'OAuth credentials',
            color: theme.colorScheme.onSurfaceVariant,
            collapsed: collapsed,
            onTap: () => showDialog(
              context: context,
              builder: (_) => const ApiKeysDialog(),
            ),
          ),
          _SidebarTile(
            icon: Icons.settings_outlined,
            name: l10n.actionSettings ?? 'Settings',
            subtitle: 'App preferences',
            color: theme.colorScheme.onSurfaceVariant,
            collapsed: collapsed,
            onTap: () => showDialog(
              context: context,
              builder: (_) => const SettingsDialog(),
            ),
          ),
        ],
      ),
    );
  }"""

start = content.find("  Widget _buildFooter(")
end = content.find("  // ─── Actions", start)

if start != -1 and end != -1:
    content = content[:start] + footer_code + "\n\n" + content[end:]
    with open('lib/features/connections/connections_sidebar.dart', 'w') as f:
        f.write(content)
    print("Fixed!")
else:
    print("Not found")
