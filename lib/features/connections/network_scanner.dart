import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_scanner.g.dart';

/// Represents a discovered network service
class DiscoveredService {
  DiscoveredService({
    required this.name,
    required this.host,
    required this.port,
    required this.type,
  });

  final String name;
  final String host;
  final int port;
  final String type;

  @override
  String toString() => 'DiscoveredService(name: $name, host: $host, port: $port, type: $type)';
}

/// Scans the local network for FTP/SFTP/WebDAV services.
///
/// Uses two approaches:
/// 1. Port scanning on common ports (21, 22, 8080, 443) for local IP range
/// 2. mDNS/Bonjour discovery (via bonsoir package — Sprint 4)
@Riverpod(keepAlive: true)
class NetworkScanner extends _$NetworkScanner {
  @override
  List<DiscoveredService> build() {
    return [];
  }

  /// Scan the local network for services.
  ///
  /// Scans the local subnet for common ports:
  /// - 21: FTP
  /// - 22: SFTP/SSH
  /// - 443: WebDAV (HTTPS)
  /// - 8080: WebDAV (HTTP)
  Future<List<DiscoveredService>> scanNetwork() async {
    final results = <DiscoveredService>[];
    state = []; // Clear previous results

    // Get local IP address
    final localIp = await _getLocalIp();
    if (localIp == null) return results;

    // Extract subnet (e.g., 192.168.1)
    final parts = localIp.split('.');
    if (parts.length != 4) return results;
    final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

    // Common ports to scan
    const ports = [
      (21, 'FTP'),
      (22, 'SFTP'),
      (443, 'WebDAV'),
      (8080, 'WebDAV'),
      (445, 'SMB'),
    ];

    // Scan subnet (1-254) in parallel batches
    const batchSize = 50;
    for (var start = 1; start < 255; start += batchSize) {
      final end = (start + batchSize > 254) ? 254 : start + batchSize;
      final futures = <Future<List<DiscoveredService>>>[];

      for (var i = start; i <= end; i++) {
        final ip = '$subnet.$i';
        futures.add(_scanHost(ip, ports));
      }

      final batchResults = await Future.wait(futures);
      for (final batch in batchResults) {
        results.addAll(batch);
        if (results.isNotEmpty) {
          state = List.from(results); // Update state incrementally
        }
      }
    }

    state = results;
    return results;
  }

  /// Scan a single host for open ports
  Future<List<DiscoveredService>> _scanHost(String ip, List<(int, String)> ports) async {
    final found = <DiscoveredService>[];

    for (final (port, type) in ports) {
      try {
        final socket = await Socket.connect(
          ip,
          port,
          timeout: const Duration(milliseconds: 500),
        );
        socket.destroy();

        found.add(DiscoveredService(
          name: '$type at $ip',
          host: ip,
          port: port,
          type: type,
        ));
      } catch (_) {
        // Port not open or host unreachable
      }
    }

    return found;
  }

  /// Get the local IP address
  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          // Skip loopback
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Clear scan results
  void clear() {
    state = [];
  }
}