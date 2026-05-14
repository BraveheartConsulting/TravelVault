import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/security/lock_controller.dart';
import 'router.dart';
import 'theme.dart';

/// Root widget. Watches the app lifecycle and re-locks the vault whenever the
/// app leaves the foreground, so the vault is never visible in the app
/// switcher or after a return from background.
class TravelVaultApp extends ConsumerStatefulWidget {
  const TravelVaultApp({super.key});

  @override
  ConsumerState<TravelVaultApp> createState() => _TravelVaultAppState();
}

class _TravelVaultAppState extends ConsumerState<TravelVaultApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      ref.read(lockControllerProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'TravelVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
