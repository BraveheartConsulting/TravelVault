import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Thin wrapper around [LocalAuthentication] that turns the platform's
/// exception-y API into simple booleans the lock flow can reason about.
///
/// Device passcode is allowed as a fallback (`biometricOnly: false`) so the
/// vault is still gated on devices without enrolled biometrics.
class BiometricGate {
  BiometricGate({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// Whether the device can perform any auth (biometric or passcode).
  Future<bool> isSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Prompts the user to authenticate. Returns true only on a confirmed
  /// success; any failure, cancellation, or platform error returns false.
  Future<bool> authenticate({
    String reason = 'Unlock your travel vault',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
