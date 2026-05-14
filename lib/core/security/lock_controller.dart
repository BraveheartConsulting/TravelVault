import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biometric_gate.dart';

/// Whether the vault is currently accessible.
enum LockState {
  /// Gated — the lock screen is shown, no vault data is reachable.
  locked,

  /// An authentication prompt is in flight.
  unlocking,

  /// Authenticated — vault data is reachable for this foreground session.
  unlocked,
}

final biometricGateProvider = Provider<BiometricGate>((_) => BiometricGate());

final lockControllerProvider =
    NotifierProvider<LockController, LockState>(LockController.new);

/// Owns the app's lock state. The app starts [LockState.locked]; it must be
/// re-locked whenever the app is backgrounded so a glance at the app switcher
/// never exposes the vault.
class LockController extends Notifier<LockState> {
  @override
  LockState build() => LockState.locked;

  /// Prompts for biometric / passcode auth. Returns true on success.
  Future<bool> unlock() async {
    if (state == LockState.unlocking) return false;
    state = LockState.unlocking;

    final gate = ref.read(biometricGateProvider);
    final success = await gate.authenticate();

    state = success ? LockState.unlocked : LockState.locked;
    return success;
  }

  /// Re-locks the vault. Called on app launch and on resume from background.
  void lock() => state = LockState.locked;
}
