import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/receipt.dart';
import 'database_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap
    // Navigate to the specific receipt or section
  }

  Future<bool> requestPermissions() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  // Schedule warranty expiry notification
  Future<void> scheduleWarrantyNotification(Receipt receipt) async {
    if (receipt.warrantyExpiry == null) return;

    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled =
        prefs.getBool('warranty_notifications') ?? true;
    if (!notificationsEnabled) return;

    // Schedule notification 14 days before expiry
    final notifyDate = receipt.warrantyExpiry!.subtract(
      const Duration(days: 14),
    );
    if (notifyDate.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      receipt.id.hashCode,
      'Warranty Expiring Soon',
      '${receipt.itemName} warranty expires in 14 days. Check your device for issues before it\'s too late!',
      tz.TZDateTime.from(notifyDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'warranty_channel',
          'Warranty Alerts',
          channelDescription: 'Notifications for expiring warranties',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(
            '${receipt.itemName} warranty expires in 14 days. Check your device for issues before it\'s too late!',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );

    // Also schedule 7 day reminder
    final sevenDayNotify = receipt.warrantyExpiry!.subtract(
      const Duration(days: 7),
    );
    if (sevenDayNotify.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        receipt.id.hashCode + 1,
        'Warranty Expires in 7 Days',
        '${receipt.itemName} warranty expires in 7 days!',
        tz.TZDateTime.from(sevenDayNotify, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'warranty_channel',
            'Warranty Alerts',
            channelDescription: 'Notifications for expiring warranties',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // Schedule return deadline notification
  Future<void> scheduleReturnNotification(Receipt receipt) async {
    if (receipt.returnDeadline == null) return;

    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('return_notifications') ?? true;
    if (!notificationsEnabled) return;

    // Schedule notification 3 days before deadline
    final notifyDate = receipt.returnDeadline!.subtract(
      const Duration(days: 3),
    );
    if (notifyDate.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      receipt.id.hashCode + 100,
      'Return Window Closing Soon',
      'Only 3 days left to return ${receipt.itemName}! Don\'t miss the return window.',
      tz.TZDateTime.from(notifyDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'return_channel',
          'Return Window Alerts',
          channelDescription: 'Notifications for closing return windows',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(
            'Only 3 days left to return ${receipt.itemName}! Don\'t miss the return window.',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Also schedule 1 day reminder
    final oneDayNotify = receipt.returnDeadline!.subtract(
      const Duration(days: 1),
    );
    if (oneDayNotify.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        receipt.id.hashCode + 101,
        'Last Day to Return',
        'Tomorrow is the last day to return ${receipt.itemName}!',
        tz.TZDateTime.from(oneDayNotify, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'return_channel',
            'Return Window Alerts',
            channelDescription: 'Notifications for closing return windows',
            importance: Importance.max,
            priority: Priority.max,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // Cancel all notifications for a receipt
  Future<void> cancelReceiptNotifications(String receiptId) async {
    await _notifications.cancel(receiptId.hashCode);
    await _notifications.cancel(receiptId.hashCode + 1);
    await _notifications.cancel(receiptId.hashCode + 100);
    await _notifications.cancel(receiptId.hashCode + 101);
  }

  // Reschedule all notifications (call on app start)
  Future<void> rescheduleAllNotifications() async {
    final db = DatabaseService();
    final receipts = await db.getAllReceipts();

    await _notifications.cancelAll();

    for (final receipt in receipts) {
      await scheduleWarrantyNotification(receipt);
      await scheduleReturnNotification(receipt);
    }
  }

  // Show immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'general_channel',
          'General',
          channelDescription: 'General notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }
}
