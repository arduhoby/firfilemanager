import 'package:flutter_secure_storage/flutter_secure_storage.dart';
void main() async {
  final storage = FlutterSecureStorage();
  print("Writing...");
  await storage.write(key: 'test', value: 'test').timeout(Duration(seconds: 2));
  print("Done!");
}
