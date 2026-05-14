import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/document.dart';
import 'expiry_schedule.dart';

/// Schedules on-device expiry alerts for documents. Local notifications only —
/// no push tokens, no server, no network. Consistent with the no-cloud promise.
class ExpiryNotifier {
  ExpiryNotifier({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const String _channelId = 'travelvault.expiry';
  static const String _channelName = 'Document expiry alerts';

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        // Permissions are requested explicitly via [requestPermissions].
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Asks the OS for permission to post notifications. Called the first time a
  /// document with an expiry date is saved.
  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Cancels every pending alert and reschedules from [documents]. Call on
  /// startup and after any change to the document set so pending alerts always
  /// reflect current data.
  Future<void> rescheduleAll(List<Document> documents) async {
    await init();
    await _plugin.cancelAll();
    for (final document in documents) {
      await _schedule(document);
    }
  }

  /// Replaces the pending alert for a single document.
  Future<void> scheduleForDocument(Document document) async {
    await init();
    await _plugin.cancel(notificationIdFor(document.id));
    await _schedule(document);
  }

  Future<void> cancelForDocument(String documentId) async {
    await init();
    await _plugin.cancel(notificationIdFor(documentId));
  }

  Future<void> _schedule(Document document) async {
    final alertAt = expiryAlertTime(document);
    if (alertAt == null) return;

    await _plugin.zonedSchedule(
      notificationIdFor(document.id),
      '${document.title} expires soon',
      'Your ${document.type.name} expires on '
          '${_formatDate(document.expiryDate!)}.',
      tz.TZDateTime.from(alertAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}
