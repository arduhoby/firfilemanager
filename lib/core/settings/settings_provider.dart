import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

part 'settings_provider.g.dart';

/// Keys for persisting settings
const _kThemeModeKey = 'settings_theme_mode';
const _kLocaleKey = 'settings_locale';
const _kSinglePanelModeKey = 'settings_single_panel_mode';
const _kBackgroundImagePathKey = 'settings_background_image_path';
const _kBackgroundOpacityKey = 'settings_background_opacity';

const _kFolderColorsKey = 'settings_folder_colors_map';
const _kPlayAnimationSoundsKey = 'settings_play_animation_sounds';

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

      final prefs = await SharedPreferences.getInstance();
      final bgPath = prefs.getString(_kBackgroundImagePathKey);
      final bgOpacity = prefs.getDouble(_kBackgroundOpacityKey) ?? 0.15;
      final playAnimationSounds = prefs.getBool(_kPlayAnimationSoundsKey) ?? true;
      
      // Load custom folder colors
      final colorsList = prefs.getStringList(_kFolderColorsKey) ?? [];
      final folderColors = <String, int>{};
      for (final item in colorsList) {
        final parts = item.split('::');
        if (parts.length == 2) {
          final colorVal = int.tryParse(parts[1]);
          if (colorVal != null) {
            folderColors[parts[0]] = colorVal;
          }
        }
      }

      state = state.copyWith(
        themeMode: themeMode,
        locale: locale,
        singlePanelMode: singlePanelStr == 'true',
        backgroundImagePath: bgPath,
        backgroundOpacity: bgOpacity,
        folderColors: folderColors,
        playAnimationSounds: playAnimationSounds,
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

  Future<void> setBackgroundImagePath(String? path) async {
    state = state.copyWith(backgroundImagePath: path, clearBackgroundPath: path == null);
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_kBackgroundImagePathKey, path);
    } else {
      await prefs.remove(_kBackgroundImagePathKey);
    }
  }

  Future<void> setBackgroundOpacity(double opacity) async {
    state = state.copyWith(backgroundOpacity: opacity);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kBackgroundOpacityKey, opacity);
  }

  Future<void> setFolderColor(String folderPath, Color? color) async {
    final updatedColors = Map<String, int>.from(state.folderColors);
    if (color == null) {
      updatedColors.remove(folderPath);
    } else {
      updatedColors[folderPath] = color.value;
    }
    state = state.copyWith(folderColors: updatedColors);

    final prefs = await SharedPreferences.getInstance();
    final colorsList = updatedColors.entries.map((e) => '${e.key}::${e.value}').toList();
    await prefs.setStringList(_kFolderColorsKey, colorsList);
  }
  Future<void> setPlayAnimationSounds(bool playSounds) async {
    state = state.copyWith(playAnimationSounds: playSounds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPlayAnimationSoundsKey, playSounds);
  }
}

/// Immutable state for [Settings]
class SettingsState {
  const SettingsState({
    this.themeMode = AppThemeMode.system,
    this.locale,
    this.singlePanelMode = false,
    this.loaded = false,
    this.backgroundImagePath,
    this.backgroundOpacity = 0.15,
    this.folderColors = const {},
    this.playAnimationSounds = true,
  });

  final AppThemeMode themeMode;
  final Locale? locale;
  final bool singlePanelMode;
  final bool loaded;
  final String? backgroundImagePath;
  final double backgroundOpacity;
  final Map<String, int> folderColors;
  final bool playAnimationSounds;

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
    String? backgroundImagePath,
    bool clearBackgroundPath = false,
    double? backgroundOpacity,
    Map<String, int>? folderColors,
    bool? playAnimationSounds,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      singlePanelMode: singlePanelMode ?? this.singlePanelMode,
      loaded: loaded ?? this.loaded,
      backgroundImagePath: clearBackgroundPath ? null : (backgroundImagePath ?? this.backgroundImagePath),
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      folderColors: folderColors ?? this.folderColors,
      playAnimationSounds: playAnimationSounds ?? this.playAnimationSounds,
    );
  }
}
