import re
import os

files = [
    'lib/core/storage/providers/cloud/dropbox_provider.dart',
    'lib/core/storage/providers/cloud/onedrive_provider.dart',
    'lib/core/storage/providers/cloud/nextcloud_provider.dart'
]

def fix_file(path):
    with open(path, 'r') as f:
        content = f.read()

    # Fix CancelToken prefix
    content = content.replace('dio.CancelToken', 'CancelToken')
    
    # Fix missing mkdir
    if 'Future<void> mkdir(String path) async' not in content:
        content = content.replace('  @override\n  Future<bool> exists(String path) async {', "  @override\n  Future<void> mkdir(String path) async {\n    throw UnimplementedError();\n  }\n\n  @override\n  Future<bool> exists(String path) async {")

    # Fix onedrive e.containsKey
    content = content.replace("final isDir = e.containsKey('folder');", "final isDir = (e as Map).containsKey('folder');")

    with open(path, 'w') as f:
        f.write(content)
    print(f"Fixed {path}")

for file in files:
    if os.path.exists(file):
        fix_file(file)
