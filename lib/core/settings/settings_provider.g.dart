// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$settingsHash() => r'2cff3bae971158c947c83e648eb6d21131db567b';

/// Manages app-level settings: theme mode and locale preference.
///
/// Settings are persisted in [FlutterSecureStorage] so they survive app restarts.
///
/// Copied from [Settings].
@ProviderFor(Settings)
final settingsProvider = NotifierProvider<Settings, SettingsState>.internal(
  Settings.new,
  name: r'settingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$settingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Settings = Notifier<SettingsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
