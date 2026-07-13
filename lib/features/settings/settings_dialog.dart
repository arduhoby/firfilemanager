import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Settings'), // TODO localization
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Theme Mode
            ListTile(
              title: const Text('Theme'),
              trailing: DropdownButton<AppThemeMode>(
                value: settings.themeMode,
                onChanged: (mode) {
                  if (mode != null) {
                    ref.read(settingsProvider.notifier).setThemeMode(mode);
                  }
                },
                items: AppThemeMode.values.map((mode) {
                  return DropdownMenuItem(
                    value: mode,
                    child: Text(mode.name),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            // Locale
            ListTile(
              title: const Text('Language'),
              trailing: DropdownButton<Locale?>(
                value: settings.locale,
                onChanged: (locale) {
                  ref.read(settingsProvider.notifier).setLocale(locale);
                },
                items: const [
                  DropdownMenuItem(value: null, child: Text('System')),
                  DropdownMenuItem(value: Locale('en'), child: Text('English')),
                  DropdownMenuItem(value: Locale('tr'), child: Text('Türkçe')),
                ],
              ),
            ),
            const Divider(),
            // Single Panel Mode
            SwitchListTile(
              title: const Text('Single Panel Mode'),
              subtitle: const Text('Use a single panel layout instead of dual panels.'),
              value: settings.singlePanelMode,
              onChanged: (val) {
                ref.read(settingsProvider.notifier).setSinglePanelMode(val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
      ],
    );
  }
}
