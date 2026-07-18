import 'package:http/http.dart' as http;

void main() async {
  final urls = [
    'https://nextcloud.firdub.com/',
    'https://nextcloud.firdub.com/status.php',
    'https://nextcloud.firdub.com/remote.php/webdav',
  ];

  for (final url in urls) {
    print('Testing HTTP GET on $url');
    try {
      final res = await http.get(Uri.parse(url));
      print('Status Code: ${res.statusCode}');
      print('Body Length: ${res.body.length}');
      if (res.body.length < 500) {
        print('Body: ${res.body}');
      } else {
        print('Body (first 100 chars): ${res.body.substring(0, 100)}');
      }
    } catch (e) {
      print('Failed: $e');
    }
    print('---');
  }
}
