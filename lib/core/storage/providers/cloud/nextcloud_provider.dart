import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart' as dio;
import 'package:xml/xml.dart';

import '../../models/connection_profile.dart';
import '../../models/file_entry.dart';
import '../../models/transfer_progress.dart';
import '../../storage_provider.dart';

class NextcloudProvider implements StorageProvider {
  @override
  final ConnectionProfile profile;
  final String? clientId;
  final String? clientSecret;
  
  oauth2.Client? _client;

  NextcloudProvider(
    this.profile, {
    this.clientId,
    this.clientSecret,
  });

  String get _baseUrl {
    final host = profile.host ?? '';
    final scheme = profile.effectivePort == 443 ? 'https' : 'http';
    return '$scheme://$host';
  }

  String get _webdavUrl => '$_baseUrl/remote.php/webdav';

  @override
  Future<void> connect() async {
    if (clientId == null || clientId!.isEmpty) {
      throw Exception('Missing Client ID. Please configure API Keys in Settings.');
    }

    final authorizationEndpoint = Uri.parse('$_baseUrl/index.php/apps/oauth2/authorize');
    final tokenEndpoint = Uri.parse('$_baseUrl/index.php/apps/oauth2/api/v1/token');
    
    final grant = oauth2.AuthorizationCodeGrant(
      clientId!,
      authorizationEndpoint,
      tokenEndpoint,
      secret: clientSecret,
    );
    
    final redirectUrl = Uri.parse('http://localhost:3000/callback');
    final authUrl = grant.getAuthorizationUrl(redirectUrl);
    
    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl);
      // Wait for auth code...
    } else {
      throw Exception('Could not launch Nextcloud authorization URL.');
    }
  }

  @override
  Future<void> disconnect() async {
    _client?.close();
    _client = null;
  }

  @override
  bool get isConnected => _client != null;

  String _buildWebdavPath(String path) {
    if (path == '/' || path == '') return _webdavUrl;
    return '$_webdavUrl${path.startsWith('/') ? path : '/$path'}';
  }

  @override
  Future<List<FileEntry>> list(String path, [ListOptions? options]) async {
    if (!isConnected) throw Exception('Not connected to Nextcloud');
    
    final url = _buildWebdavPath(path);
    final response = await _client!.send(http.Request('PROPFIND', Uri.parse(url))
      ..headers['Depth'] = '1'
    );
    
    final body = await response.stream.bytesToString();
    if (response.statusCode >= 400) {
      throw Exception('Failed to list Nextcloud folder: $body');
    }
    
    return _parsePropfind(body, rootPath: path);
  }

  List<FileEntry> _parsePropfind(String xmlStr, {String? rootPath}) {
    final document = XmlDocument.parse(xmlStr);
    final responses = document.findAllElements('d:response');
    final entries = <FileEntry>[];
    
    for (var r in responses) {
      final href = r.findElements('d:href').firstOrNull?.innerText ?? '';
      
      // Skip the root folder itself if listing
      if (rootPath != null && href.endsWith('/')) {
        final decodedHref = Uri.decodeFull(href).replaceAll(r'\', '/');
        final decodedRoot = rootPath.endsWith('/') ? rootPath : '$rootPath/';
        if (decodedHref.endsWith(decodedRoot)) continue;
      }

      final props = r.findAllElements('d:prop').firstOrNull;
      if (props == null) continue;

      final getlastmodified = props.findElements('d:getlastmodified').firstOrNull?.innerText;
      final getcontentlength = props.findElements('d:getcontentlength').firstOrNull?.innerText;
      final resourcetype = props.findElements('d:resourcetype').firstOrNull;
      
      final isDir = resourcetype?.findElements('d:collection').isNotEmpty ?? false;
      final size = getcontentlength != null ? int.tryParse(getcontentlength) ?? 0 : 0;
      final modified = getlastmodified != null ? HttpDate.parse(getlastmodified) : DateTime.now();

      final decodedPath = Uri.decodeFull(href.replaceFirst('/remote.php/webdav', ''));
      
      entries.add(FileEntry(
        name: p.basename(decodedPath),
        path: decodedPath,
        isDirectory: isDir,
        size: isDir ? 0 : size,
        modified: modified,
        permissions: '',
      ));
    }
    
    return entries;
  }

  @override
  Future<void> delete(String path) async {
    if (!isConnected) throw Exception('Not connected to Nextcloud');
    
    final url = _buildWebdavPath(path);
    final response = await _client!.delete(Uri.parse(url));
    
    if (response.statusCode >= 400) {
      throw Exception('Failed to delete in Nextcloud: ${response.body}');
    }
  }

  @override
  Future<void> rename(String oldPath, String newName) async {
    if (!isConnected) throw Exception('Not connected to Nextcloud');
    
    final srcUrl = _buildWebdavPath(oldPath);
    final newPath = p.join(p.dirname(oldPath), newName).replaceAll(r'\', '/');
    final destUrl = _buildWebdavPath(newPath);
    
    final request = http.Request('MOVE', Uri.parse(srcUrl));
    request.headers['Destination'] = destUrl;
    final response = await _client!.send(request);
    
    if (response.statusCode >= 400) {
      throw Exception('Failed to rename in Nextcloud: ${response.reasonPhrase}');
    }
  }

  @override
  Future<void> makeDirectory(String path) async {
    if (!isConnected) throw Exception('Not connected to Nextcloud');
    
    final url = _buildWebdavPath(path);
    final request = http.Request('MKCOL', Uri.parse(url));
    final response = await _client!.send(request);
    
    if (response.statusCode >= 400) {
      throw Exception('Failed to create folder in Nextcloud: ${response.reasonPhrase}');
    }
  }

  @override
  Future<FileEntry> stat(String path) async {
    if (!isConnected) throw Exception('Not connected to Nextcloud');
    
    final url = _buildWebdavPath(path);
    final response = await _client!.send(http.Request('PROPFIND', Uri.parse(url))
      ..headers['Depth'] = '0'
    );
    
    final body = await response.stream.bytesToString();
    if (response.statusCode >= 400) {
      throw Exception('Failed to stat Nextcloud file: $body');
    }
    
    final entries = _parsePropfind(body);
    if (entries.isEmpty) throw Exception('File not found in Nextcloud');
    return entries.first;
  }

  @override
  Future<void> mkdir(String path) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> exists(String path) async {
    try {
      await stat(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  String basename(String path) => p.basename(path);

  @override
  String dirname(String path) => p.dirname(path);

  @override
  Stream<TransferProgress> read(String path, {CancelToken? cancelToken}) async* {
    if (!isConnected) throw Exception('Not connected to Nextcloud');
    throw UnimplementedError();
  }

  @override
  Stream<TransferProgress> write(String path, Stream<List<int>> data, {CancelToken? cancelToken}) async* {
    if (!isConnected) throw Exception('Not connected to Nextcloud');
    throw UnimplementedError();
  }

  @override
  Stream<TransferProgress> copy(String sourcePath, StorageProvider destProvider, String destPath, {CopyOptions options = const CopyOptions(), CancelToken? cancelToken}) async* {
    if (!isConnected) throw Exception('Not connected to Nextcloud');
    throw UnimplementedError();
  }

  @override
  Future<List<FileEntry>> search(String path, String query, {bool recursive = false}) async {
    if (!isConnected) throw Exception('Not connected to Nextcloud');
    
    // Nextcloud/WebDAV search uses specific WebDAV SEARCH extension or OCS API.
    // For simplicity, we can fallback to recursive PROPFIND or OCS.
    // We'll throw UnimplementedError for now as it's complex for WebDAV.
    throw UnimplementedError('Search not implemented for Nextcloud yet.');
  }

  @override
  String get displayName => profile.name;

  @override
  Stream<bool> get connectionStateChanges => const Stream.empty();

  @override
  Future<void> move(String sourcePath, String destPath) async {
    throw UnimplementedError('Move is not implemented yet');
  }

  @override
  Future<int?> getFreeSpace(String path) async => null;

  @override
  Future<String> get homePath async => '/';

  @override
  String normalizePath(String path) => path;

  @override
  String joinPath(String parent, String child) => '$parent/$child'.replaceAll('//', '/');

  @override
  bool supports(ProviderCapability capability) {
    return [
      ProviderCapability.list,
      ProviderCapability.read,
      ProviderCapability.write,
      ProviderCapability.delete,
      ProviderCapability.mkdir,
    ].contains(capability);
  }
}
