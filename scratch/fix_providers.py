import re
import os

files = [
    'lib/core/storage/providers/cloud/dropbox_provider.dart',
    'lib/core/storage/providers/cloud/onedrive_provider.dart',
    'lib/core/storage/providers/cloud/nextcloud_provider.dart'
]

missing_methods = """
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
"""

def fix_file(path):
    with open(path, 'r') as f:
        content = f.read()

    # Fix method signatures
    content = re.sub(r'Future<List<FileEntry>> list\(String path\)', r'Future<List<FileEntry>> list(String path, [ListOptions? options])', content)
    content = re.sub(r'Stream<TransferProgress> read\(String path, \{dio\.CancelToken\? cancelToken\}\)', r'Stream<TransferProgress> read(String path, {dio.CancelToken? cancelToken})', content)
    content = re.sub(r'Stream<TransferProgress> write\(String path, Stream<List<int>> data, int size, \{dio\.CancelToken\? cancelToken\}\)', r'Stream<TransferProgress> write(String path, Stream<List<int>> data, {dio.CancelToken? cancelToken})', content)
    content = re.sub(r'Stream<TransferProgress> copy\(FileEntry source, String destination, \{dio\.CancelToken\? cancelToken\}\)', r'Stream<TransferProgress> copy(String sourcePath, StorageProvider destProvider, String destPath, {CopyOptions options = const CopyOptions(), dio.CancelToken? cancelToken})', content)
    content = re.sub(r'Future<List<FileEntry>> search\(String query, \{String path = \'\/\'\}\)', r'Future<List<FileEntry>> search(String path, String query, {bool recursive = false})', content)

    # Insert missing methods at the end before the last closing brace
    content = content.rstrip()
    if content.endswith('}'):
        content = content[:-1] + missing_methods + '}\n'
    
    with open(path, 'w') as f:
        f.write(content)
    print(f"Fixed {path}")

for file in files:
    if os.path.exists(file):
        fix_file(file)
    else:
        print(f"File not found: {file}")
