import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/lock_controller.dart';

/// Placeholder settings screen. Profile management, export, and the Pro unlock
/// land here in later increments.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Lock now'),
            subtitle: const Text('Re-lock the vault immediately'),
            onTap: () => ref.read(lockControllerProvider.notifier).lock(),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Security'),
            subtitle: Text('Encrypted on-device · No cloud · No account'),
          ),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'TravelVault',
            applicationVersion: '0.1.0',
          ),
        ],
      ),
    );
  }
}
