// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_scanner.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$networkScannerHash() => r'6c3fa59e929362d7e3498135886d5a5520f6ecf5';

/// Scans the local network for FTP/SFTP/WebDAV services.
///
/// Uses two approaches:
/// 1. Port scanning on common ports (21, 22, 8080, 443) for local IP range
/// 2. mDNS/Bonjour discovery (via bonsoir package — Sprint 4)
///
/// Copied from [NetworkScanner].
@ProviderFor(NetworkScanner)
final networkScannerProvider =
    NotifierProvider<NetworkScanner, List<DiscoveredService>>.internal(
      NetworkScanner.new,
      name: r'networkScannerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$networkScannerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NetworkScanner = Notifier<List<DiscoveredService>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
