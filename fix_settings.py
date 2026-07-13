with open('lib/core/settings/settings_provider.dart', 'r') as f:
    content = f.read()

# Replace _kLocaleKey = 'settings_locale'; with:
# const _kLocaleKey = 'settings_locale';
# const _kSinglePanelModeKey = 'settings_single_panel_mode';
content = content.replace(
    "const _kLocaleKey = 'settings_locale';",
    "const _kLocaleKey = 'settings_locale';\nconst _kSinglePanelModeKey = 'settings_single_panel_mode';"
)

# In _loadSettings()
# final localeStr = await _secureStorage.read(key: _kLocaleKey);
# final singlePanelStr = await _secureStorage.read(key: _kSinglePanelModeKey);
content = content.replace(
    "final localeStr = await _secureStorage.read(key: _kLocaleKey);",
    "final localeStr = await _secureStorage.read(key: _kLocaleKey);\n      final singlePanelStr = await _secureStorage.read(key: _kSinglePanelModeKey);"
)

# state = state.copyWith(
#         themeMode: themeMode,
#         locale: locale,
#         singlePanelMode: singlePanelStr == 'true',
#         loaded: true,
#       );
content = content.replace(
    "locale: locale,\n        loaded: true,",
    "locale: locale,\n        singlePanelMode: singlePanelStr == 'true',\n        loaded: true,"
)

# In setLocale add setSinglePanelMode
content = content.replace(
    "  Future<void> setLocale(Locale? locale) async {",
    "  Future<void> setSinglePanelMode(bool isSingle) async {\n    state = state.copyWith(singlePanelMode: isSingle);\n    await _secureStorage.write(key: _kSinglePanelModeKey, value: isSingle.toString());\n  }\n\n  Future<void> setLocale(Locale? locale) async {"
)

# In SettingsState constructor
content = content.replace(
    "this.locale,\n    this.loaded = false,",
    "this.locale,\n    this.singlePanelMode = false,\n    this.loaded = false,"
)

# In SettingsState fields
content = content.replace(
    "final Locale? locale;\n  final bool loaded;",
    "final Locale? locale;\n  final bool singlePanelMode;\n  final bool loaded;"
)

# In SettingsState copyWith method
content = content.replace(
    "Locale? locale,\n    bool? loaded,",
    "Locale? locale,\n    bool? singlePanelMode,\n    bool? loaded,"
)
content = content.replace(
    "locale: locale ?? this.locale,\n      loaded: loaded ?? this.loaded,",
    "locale: locale ?? this.locale,\n      singlePanelMode: singlePanelMode ?? this.singlePanelMode,\n      loaded: loaded ?? this.loaded,"
)

with open('lib/core/settings/settings_provider.dart', 'w') as f:
    f.write(content)
