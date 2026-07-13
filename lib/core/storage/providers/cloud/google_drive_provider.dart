import 'dart:async';
import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

import '../../storage_provider.dart';
import '../../models/connection_profile.dart';
import '../../models/file_entry.dart';
import '../../models/transfer_progress.dart';

class GoogleDriveProvider implements StorageProvider {
  final ConnectionProfile profile;
  final String? clientId;
  final String? clientSecret;

  AuthClient? _client;
  drive.DriveApi? _api;

  GoogleDriveProvider({
    required this.profile,
    this.clientId,
    this.clientSecret,
  });
  
  @override
  String get displayName => profile.name ?? 'Google Drive';

  @override
  bool get isConnected => _client != null && _api != null;
  
  @override
  Stream<bool> get connectionStateChanges => const Stream.empty();

  @override
  Future<void> connect() async {
    if (isConnected) return;

    final effectiveClientId = (clientId != null && clientId!.isNotEmpty)
        ? clientId!
        : '';

    final effectiveClientSecret = (clientSecret != null && clientSecret!.isNotEmpty)
        ? clientSecret!
        : '';

    if (effectiveClientId.isEmpty || effectiveClientSecret.isEmpty) {
      throw Exception('Google Drive Client ID and Client Secret are missing. Please configure them in the API Keys settings.');
    }

    try {
      final id = ClientId(effectiveClientId, effectiveClientSecret);
      final scopes = [drive.DriveApi.driveScope];

      _client = await clientViaUserConsent(id, scopes, (url) async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          throw Exception('Could not launch Google Sign In URL: $url');
        }
      });
      _api = drive.DriveApi(_client!);
    } catch (e, st) {
      print('Google Drive Connection Error: $e\n$st');
      throw StorageException('Failed to connect to Google Drive', cause: e);
    }
  }

  @override
  Future<void> disconnect() async {
    _client?.close();
    _client = null;
    _api = null;
  }
  
  String _resolveId(String path) {
    if (path == '/' || path.isEmpty) return 'root';
    return path;
  }

  @override
  Future<List<FileEntry>> list(String path, [ListOptions? options]) async {
    _checkConnection();
    final parentId = _resolveId(path);

    final fileList = await _api!.files.list(
      q: "'$parentId' in parents and trashed = false",
      $fields: 'files(id, name, mimeType, size, modifiedTime)',
    );

    final items = <FileEntry>[];
    for (final f in fileList.files ?? <drive.File>[]) {
      final isDir = f.mimeType == 'application/vnd.google-apps.folder';
      items.add(FileEntry(
        name: f.name ?? 'unknown',
        path: f.id ?? '', 
        isDirectory: isDir,
        size: f.size != null ? int.tryParse(f.size!) ?? 0 : 0,
        modified: f.modifiedTime ?? DateTime.now(),
        permissions: '',
      ));
    }
    return items;
  }

  @override
  Future<FileEntry> stat(String path) async {
    _checkConnection();
    final id = _resolveId(path);
    if (id == 'root') {
       return FileEntry(
        name: 'root',
        path: 'root',
        isDirectory: true,
        size: 0,
        modified: DateTime.now(),
        permissions: '',
      );
    }
    final f = await _api!.files.get(id, $fields: 'id, name, mimeType, size, modifiedTime') as drive.File;
    final isDir = f.mimeType == 'application/vnd.google-apps.folder';
    return FileEntry(
        name: f.name ?? 'unknown',
        path: f.id ?? '',
        isDirectory: isDir,
        size: f.size != null ? int.tryParse(f.size!) ?? 0 : 0,
        modified: f.modifiedTime ?? DateTime.now(),
        permissions: '',
      );
  }

  @override
  Stream<TransferProgress> read(
    String path, {
    CancelToken? cancelToken,
  }) async* {
    _checkConnection();
    final id = _resolveId(path);
    
    yield TransferProgress(
      operation: TransferOperation.read,
      state: TransferState.inProgress,
    );
    
    try {
      final media = await _api!.files.get(id, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final totalBytes = media.length ?? 0;
      var bytesTransferred = 0;
      
      await for (final chunk in media.stream) {
        if (cancelToken?.isCancelled ?? false) {
           yield TransferProgress(
            operation: TransferOperation.read,
            state: TransferState.cancelled,
          );
          return;
        }
        bytesTransferred += chunk.length;
        yield TransferProgress(
          operation: TransferOperation.read,
          state: TransferState.inProgress,
          bytesTransferred: bytesTransferred,
          totalBytes: totalBytes,
        );
      }
      
      yield TransferProgress(
        operation: TransferOperation.read,
        state: TransferState.completed,
        bytesTransferred: bytesTransferred,
        totalBytes: totalBytes,
      );
    } catch(e) {
      yield TransferProgress(
        operation: TransferOperation.read,
        state: TransferState.failed,
        error: e.toString(),
      );
    }
  }

  @override
  Stream<TransferProgress> write(
    String path,
    Stream<List<int>> data, {
    CancelToken? cancelToken,
  }) async* {
    _checkConnection();
    // Complex to implement cleanly without parent ID.
    throw UnimplementedError('Write requires file metadata which is not provided by standard write(path, stream)');
  }

  @override
  Stream<TransferProgress> copy(
    String sourcePath,
    StorageProvider destProvider,
    String destPath, {
    CopyOptions options = const CopyOptions(),
    CancelToken? cancelToken,
  }) async* {
    _checkConnection();
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String path) async {
    _checkConnection();
    final id = _resolveId(path);
    await _api!.files.delete(id);
  }

  @override
  Future<void> rename(String oldPath, String newName) async {
    _checkConnection();
    final id = _resolveId(oldPath);
    final file = drive.File()..name = newName;
    await _api!.files.update(file, id);
  }
  
  @override
  Future<void> move(String sourcePath, String destPath) async {
    throw UnimplementedError();
  }

  @override
  Future<void> mkdir(String path) async {
    _checkConnection();
    throw UnimplementedError();
  }

  @override
  Future<bool> exists(String path) async {
    try {
      await stat(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int?> getFreeSpace(String path) async => null;
  
  @override
  Future<String> get homePath async => 'root';
  
  @override
  String normalizePath(String path) => path;
  
  @override
  String joinPath(String parent, String child) => child;
  
  @override
  String basename(String path) => path;
  
  @override
  String dirname(String path) => 'root';

  @override
  Future<List<FileEntry>> search(String path, String query, {bool recursive = false}) async {
    _checkConnection();
    final gQuery = "name contains '$query' and trashed = false";
    
    final fileList = await _api!.files.list(
      q: gQuery,
      $fields: 'files(id, name, mimeType, size, modifiedTime)',
    );

    final items = <FileEntry>[];
    for (final f in fileList.files ?? <drive.File>[]) {
      final isDir = f.mimeType == 'application/vnd.google-apps.folder';
      items.add(FileEntry(
        name: f.name ?? 'unknown',
        path: f.id ?? '', 
        isDirectory: isDir,
        size: f.size != null ? int.tryParse(f.size!) ?? 0 : 0,
        modified: f.modifiedTime ?? DateTime.now(),
        permissions: '',
      ));
    }
    return items;
  }
  
  @override
  bool supports(ProviderCapability capability) {
    switch (capability) {
      case ProviderCapability.read:
      case ProviderCapability.delete:
      case ProviderCapability.list:
      case ProviderCapability.search:
        return true;
      case ProviderCapability.write:
      case ProviderCapability.move:
      case ProviderCapability.mkdir:
      case ProviderCapability.streaming:
      case ProviderCapability.symlinks:
      case ProviderCapability.permissions:
      case ProviderCapability.freeSpace:
        return false;
    }
  }
  
  void _checkConnection() {
    if (!isConnected) {
      throw StorageException('Not connected to Google Drive');
    }
  }
}
