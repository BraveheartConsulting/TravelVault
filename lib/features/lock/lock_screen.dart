import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/lock_controller.dart';

/// The gate shown whenever the vault is locked. No vault data is reachable
/// behind this screen until biometric / passcode auth succeeds.
class LockScreen extends ConsumerWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(lockControllerProvider);
    final isUnlocking = lockState == LockState.unlocking;
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text('TravelVault', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Your travel documents, secured on this device.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: isUnlocking
                    ? null
                    : () => ref.read(lockControllerProvider.notifier).unlock(),
                icon: isUnlocking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fingerprint),
                label: Text(isUnlocking ? 'Unlocking…' : 'Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
