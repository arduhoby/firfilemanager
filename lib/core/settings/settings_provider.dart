import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../theme/app_theme.dart';

part 'settings_provider.g.dart';

/// Keys for persisting settings
const _kThemeModeKey = 'settings_theme_mode';
const _kLocaleKey = 'settings_locale';
const _kSinglePanelModeKey = 'settings_single_panel_mode';

/// Secure storage instance for settings
const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

/// Manages app-level settings: theme mode and locale preference.
///
/// Settings are persisted in [FlutterSecureStorage] so they survive app restarts.
@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  @override
  SettingsState build() {
    unawaited(_loadSettings());
    return const SettingsState();
  }

  Future<void> _loadSettings() async {
    try {
      final themeModeStr = await _secureStorage.read(key: _kThemeModeKey);
      final localeStr = await _secureStorage.read(key: _kLocaleKey);
      final singlePanelStr = await _secureStorage.read(
        key: _kSinglePanelModeKey,
      );

      final themeMode = switch (themeModeStr) {
        'light' => AppThemeMode.light,
        'dark' => AppThemeMode.dark,
        _ => AppThemeMode.system,
      };

      final locale = switch (localeStr) {
        'tr' => const Locale('tr'),
        'en' => const Locale('en'),
        _ => null, // null = follow system
      };

      state = state.copyWith(
        themeMode: themeMode,
        locale: locale,
        singlePanelMode: singlePanelStr == 'true',
        loaded: true,
      );
    } catch (_) {
      state = state.copyWith(loaded: true);
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _secureStorage.write(key: _kThemeModeKey, value: mode.name);
  }

  Future<void> setSinglePanelMode(bool isSingle) async {
    state = state.copyWith(singlePanelMode: isSingle);
    await _secureStorage.write(
      key: _kSinglePanelModeKey,
      value: isSingle.toString(),
    );
  }

  Future<void> setLocale(Locale? locale) async {
    state = state.copyWith(locale: locale);
    if (locale != null) {
      await _secureStorage.write(key: _kLocaleKey, value: locale.languageCode);
    } else {
      await _secureStorage.delete(key: _kLocaleKey);
    }
  }
}

/// Immutable state for [Settings]
class SettingsState {
  const SettingsState({
    this.themeMode = AppThemeMode.system,
    this.locale,
    this.singlePanelMode = false,
    this.loaded = false,
  });

  final AppThemeMode themeMode;
  final Locale? locale;
  final bool singlePanelMode;
  final bool loaded;

  /// Convert [AppThemeMode] to Flutter's [ThemeMode]
  ThemeMode get flutterThemeMode => switch (themeMode) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };

  SettingsState copyWith({
    AppThemeMode? themeMode,
    Locale? locale,
    bool? singlePanelMode,
    bool? loaded,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      singlePanelMode: singlePanelMode ?? this.singlePanelMode,
      loaded: loaded ?? this.loaded,
    );
  }
}
