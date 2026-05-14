import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/security/lock_controller.dart';
import '../data/models/document.dart';
import '../data/models/trip.dart';
import '../data/models/trip_stop.dart';
import '../features/documents/document_detail_screen.dart';
import '../features/documents/document_edit_screen.dart';
import '../features/home/home_screen.dart';
import '../features/lock/lock_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/trips/trip_detail_screen.dart';
import '../features/trips/trip_edit_screen.dart';
import '../features/trips/trip_stop_edit_screen.dart';

/// App router. Redirects enforce the lock gate: while the vault is not
/// [LockState.unlocked], every route collapses to `/lock`.
final routerProvider = Provider<GoRouter>((ref) {
  // Bridges the Riverpod lock state to go_router's Listenable-based refresh.
  final refresh = ValueNotifier<LockState>(ref.read(lockControllerProvider));
  ref.onDispose(refresh.dispose);
  ref.listen<LockState>(
    lockControllerProvider,
    (_, next) => refresh.value = next,
  );

  return GoRouter(
    initialLocation: '/lock',
    refreshListenable: refresh,
    redirect: (context, state) {
      final unlocked = ref.read(lockControllerProvider) == LockState.unlocked;
      final atLock = state.matchedLocation == '/lock';

      if (!unlocked && !atLock) return '/lock';
      if (unlocked && atLock) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/lock', builder: (_, __) => const LockScreen()),
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      // `/documents/new` is listed before `/documents/:id` so it isn't
      // captured as an id.
      GoRoute(
        path: '/documents/new',
        builder: (_, __) => const DocumentEditScreen(),
      ),
      GoRoute(
        path: '/documents/:id/edit',
        builder: (_, state) =>
            DocumentEditScreen(existing: state.extra as Document?),
      ),
      GoRoute(
        path: '/documents/:id',
        builder: (_, state) =>
            DocumentDetailScreen(documentId: state.pathParameters['id']!),
      ),
      // `/trips/new` is listed before `/trips/:id` so it isn't captured as
      // an id.
      GoRoute(path: '/trips/new', builder: (_, __) => const TripEditScreen()),
      GoRoute(
        path: '/trips/:id/edit',
        builder: (_, state) => TripEditScreen(existing: state.extra as Trip?),
      ),
      GoRoute(
        path: '/trips/:id/stops/new',
        builder: (_, state) =>
            TripStopEditScreen(tripId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/trips/:id/stops/:stopId/edit',
        builder: (_, state) => TripStopEditScreen(
          tripId: state.pathParameters['id']!,
          existing: state.extra as TripStop?,
        ),
      ),
      GoRoute(
        path: '/trips/:id',
        builder: (_, state) =>
            TripDetailScreen(tripId: state.pathParameters['id']!),
      ),
    ],
  );
});
