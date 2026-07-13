// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$connectionRepositoryHash() =>
    r'4f20ec2c15d3891aa7d9c39026cb54f0619648a5';

/// Repository for managing saved connection profiles.
///
/// Connection metadata (name, host, port, type) is stored in memory.
/// Credentials (passwords, private keys) are stored in [FlutterSecureStorage]
/// using the platform keychain/keystore.
///
/// Copied from [ConnectionRepository].
@ProviderFor(ConnectionRepository)
final connectionRepositoryProvider =
    NotifierProvider<ConnectionRepository, List<ConnectionProfile>>.internal(
      ConnectionRepository.new,
      name: r'connectionRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$connectionRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ConnectionRepository = Notifier<List<ConnectionProfile>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
