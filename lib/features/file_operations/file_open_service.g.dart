// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_open_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fileOpenServiceHash() => r'0a55eb1e717f0a58420bf033550832e6339c1586';

/// Service for opening files with the system default application.
///
/// Uses platform-specific commands:
/// - macOS: `open`
/// - Windows: `start`
/// - Linux: `xdg-open`
///
/// Copied from [FileOpenService].
@ProviderFor(FileOpenService)
final fileOpenServiceProvider =
    NotifierProvider<FileOpenService, void>.internal(
      FileOpenService.new,
      name: r'fileOpenServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$fileOpenServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FileOpenService = Notifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
