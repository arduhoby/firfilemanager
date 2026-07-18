import 'package:webdav_client/webdav_client.dart';

void main() async {
  final url1 = 'https://nextcloud.firdub.com:443/remote.php/webdav';
  final url2 = 'https://nextcloud.firdub.com/remote.php/webdav';
  
  print('Testing URL 1: $url1');
  try {
    final client = newClient(url1, user: 'test', password: 'testpassword');
    await client.readDir('/');
    print('URL 1 Success');
  } catch (e, stack) {
    print('URL 1 Failed: $e');
    print(stack);
  }

  print('\nTesting URL 2: $url2');
  try {
    final client = newClient(url2, user: 'test', password: 'testpassword');
    await client.readDir('/');
    print('URL 2 Success');
  } catch (e, stack) {
    print('URL 2 Failed: $e');
    print(stack);
  }
}
