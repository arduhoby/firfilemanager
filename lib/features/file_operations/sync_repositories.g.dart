// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_repositories.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$syncJobRepositoryHash() => r'17578677b9cf8b18308dceb56a90af77a06bac4a';

/// See also [SyncJobRepository].
@ProviderFor(SyncJobRepository)
final syncJobRepositoryProvider =
    NotifierProvider<SyncJobRepository, List<SyncJob>>.internal(
      SyncJobRepository.new,
      name: r'syncJobRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$syncJobRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SyncJobRepository = Notifier<List<SyncJob>>;
String _$syncHistoryRepositoryHash() =>
    r'ca09b9ea69d81be460d709aadc71421f2c3e58e2';

/// See also [SyncHistoryRepository].
@ProviderFor(SyncHistoryRepository)
final syncHistoryRepositoryProvider =
    NotifierProvider<SyncHistoryRepository, List<SyncRunReport>>.internal(
      SyncHistoryRepository.new,
      name: r'syncHistoryRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$syncHistoryRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SyncHistoryRepository = Notifier<List<SyncRunReport>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
