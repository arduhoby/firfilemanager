import 'dart:io';
import 'package:archive/archive.dart';

void main() {
  final bytes = File('pwd_test.zip').readAsBytesSync();
  try {
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);
    print('Success. Files: ${archive.length}');
    for (var f in archive) {
      print(f.name);
    }
  } catch (e) {
    print('Error: $e');
  }
}
