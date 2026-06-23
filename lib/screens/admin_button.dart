import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminButton extends StatelessWidget {
  const AdminButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => launchUrl(
        Uri.parse('https://levandan123321--bookings-admin-dashboard.retool.app'),
        mode: LaunchMode.externalApplication,
      ),
      icon: const Icon(Icons.dashboard),
      label: const Text('Dashboard Admin'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}