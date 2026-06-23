import 'package:url_launcher/url_launcher.dart';

Future<void> openZohoForm() async {
  final Uri uri = Uri.parse('https://zfrmz.com/PG4973tMFG4i9XW4vEhT');
  if (!await launchUrl(uri, mode: LaunchMode.inAppWebView)) {
    throw Exception('Error');
  }
}