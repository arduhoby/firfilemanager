// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$archiveServiceHash() => r'e7842c6cee42203e1928d72c33b3dded66767396';

/// Service for compressing and extracting archives.
///
/// Supports:
/// - ZIP (create + extract)
/// - TAR (create + extract)
/// - TAR.GZ (create + extract)
///
/// Copied from [ArchiveService].
@ProviderFor(ArchiveService)
final archiveServiceProvider = NotifierProvider<ArchiveService, void>.internal(
  ArchiveService.new,
  name: r'archiveServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$archiveServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ArchiveService = Notifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
