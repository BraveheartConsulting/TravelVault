import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biometric_gate.dart';

/// Whether the vault is currently accessible.
enum VaultLockState {
  /// Gated — the lock screen is shown, no vault data is reachable.
  locked,

  /// An authentication prompt is in flight.
  unlocking,

  /// Authenticated — vault data is reachable for this foreground session.
  unlocked,
}

final biometricGateProvider = Provider<BiometricGate>((_) => BiometricGate());

final lockControllerProvider = NotifierProvider<LockController, VaultLockState>(
  LockController.new,
);

/// Owns the app's lock state. The app starts [VaultLockState.locked]; it must be
/// re-locked whenever the app is backgrounded so a glance at the app switcher
/// never exposes the vault.
class LockController extends Notifier<VaultLockState> {
  @override
  VaultLockState build() => VaultLockState.locked;

  /// Prompts for biometric / passcode auth. Returns true on success.
  Future<bool> unlock() async {
    if (state == VaultLockState.unlocking) return false;
    state = VaultLockState.unlocking;

    final gate = ref.read(biometricGateProvider);
    final success = await gate.authenticate();

    state = success ? VaultLockState.unlocked : VaultLockState.locked;
    return success;
  }

  /// Re-locks the vault. Called on app launch and on resume from background.
  void lock() => state = VaultLockState.locked;
}
