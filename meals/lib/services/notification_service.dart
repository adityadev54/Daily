import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _mealRemindersKey = 'meal_reminders_enabled';
  static const String _expiryAlertsKey = 'expiry_alerts_enabled';
  static const String _lowStockAlertsKey = 'low_stock_alerts_enabled';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to specific screens based on payload
    debugPrint('Notification tapped: ${response.payload}');
  }

  // Permission handling
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // Settings persistence
  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? false;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  Future<bool> getMealRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_mealRemindersKey) ?? true;
  }

  Future<void> setMealRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mealRemindersKey, enabled);
  }

  Future<bool> getExpiryAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_expiryAlertsKey) ?? true;
  }

  Future<void> setExpiryAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_expiryAlertsKey, enabled);
  }

  Future<bool> getLowStockAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lowStockAlertsKey) ?? true;
  }

  Future<void> setLowStockAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lowStockAlertsKey, enabled);
  }

  // Notification channels
  Future<void> _createNotificationChannel(
    String channelId,
    String channelName,
    String channelDescription,
  ) async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
      ),
    );
  }

  // Schedule meal reminder
  Future<void> scheduleMealReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!await getNotificationsEnabled() || !await getMealRemindersEnabled()) {
      return;
    }

    await _createNotificationChannel(
      'meal_reminders',
      'Meal Reminders',
      'Reminders for meal preparation',
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _convertToTZDateTime(scheduledTime),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_reminders',
          'Meal Reminders',
          channelDescription: 'Reminders for meal preparation',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'meal_reminder_$id',
    );
  }

  // Show expiry alert
  Future<void> showExpiryAlert({
    required int id,
    required String itemName,
    required int daysUntilExpiry,
  }) async {
    if (!await getNotificationsEnabled() || !await getExpiryAlertsEnabled()) {
      return;
    }

    await _createNotificationChannel(
      'expiry_alerts',
      'Expiry Alerts',
      'Alerts for items about to expire',
    );

    final body = daysUntilExpiry == 0
        ? '$itemName expires today!'
        : daysUntilExpiry == 1
        ? '$itemName expires tomorrow'
        : '$itemName expires in $daysUntilExpiry days';

    await _notifications.show(
      id,
      'Item Expiring Soon',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry_alerts',
          'Expiry Alerts',
          channelDescription: 'Alerts for items about to expire',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'expiry_alert_$id',
    );
  }

  // Show low stock alert
  Future<void> showLowStockAlert({
    required int id,
    required String itemName,
  }) async {
    if (!await getNotificationsEnabled() || !await getLowStockAlertsEnabled()) {
      return;
    }

    await _createNotificationChannel(
      'low_stock_alerts',
      'Low Stock Alerts',
      'Alerts for low stock items',
    );

    await _notifications.show(
      id,
      'Low Stock',
      '$itemName is running low',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'low_stock_alerts',
          'Low Stock Alerts',
          channelDescription: 'Alerts for low stock items',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'low_stock_$id',
    );
  }

  // Show general notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!await getNotificationsEnabled()) return;

    await _createNotificationChannel(
      'general',
      'General',
      'General notifications',
    );

    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'general',
          'General',
          channelDescription: 'General notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
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

  // Cancel notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Helper to convert DateTime to TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    tz_data.initializeTimeZones();
    return tz.TZDateTime.from(dateTime, tz.local);
  }
}
