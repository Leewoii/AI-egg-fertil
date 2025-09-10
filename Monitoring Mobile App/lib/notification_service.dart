import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async'; // For StreamSubscription
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:firebase_messaging/firebase_messaging.dart'; // For Firebase Cloud Messaging

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase authentication instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;

  // Initialize notifications and Firebase Messaging
  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Define notification channel
    const AndroidNotificationChannel androidNotificationChannel =
        AndroidNotificationChannel(
      'channel_id', // Channel ID
      'Notifications', // Channel name
      description: 'This channel is used for showing notifications.',
      importance: Importance.high,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);

    await requestNotificationPermission();

    // Request permissions for FCM
    await _firebaseMessaging.requestPermission();

    // Initialize FCM token and listen for token refresh
    initializeFcm();
  }

  // Request notification permission from the user
  Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      // Ask for permission if not granted
      final result = await Permission.notification.request();
      if (result.isDenied) {
        // Show a message to prompt enabling notifications
        showNotification(
          "Permission Required",
          "Notification permission is needed for the notification feature. Please enable it in settings.",
        );
      }
    }
  }

  // Show notification
  Future<void> showNotification(String title, String body, {int id = 0}) async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'channel_id', // Channel ID
    'Notifications', // Channel Name
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidNotificationDetails);

  await _flutterLocalNotificationsPlugin.show(
    id, // Use unique ID for each notification
    title, // Notification title
    body, // Notification body
    platformChannelSpecifics,
  );
}


  Future<void> initializeFcm() async {
    // Get the FCM token for the device
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      print("FCM Token: $token");
      // You can save this token to Firebase Firestore or your backend for further use
    }

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print("FCM Token refreshed: $newToken");
      // Update token in Firestore or your backend
    });

    // Listen for messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Received message in foreground: ${message.notification?.title}");
      showNotification(message.notification?.title ?? 'Notification', message.notification?.body ?? '');
    });

    // Handle message when the app is opened from a background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Opened app from notification: ${message.notification?.title}");
      // You can navigate to a specific screen based on the message data
    });

    // Handle background notifications when the app is terminated or in the background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Background handler function
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Received background message: ${message.notification?.title}");

    // Initialize local notification plugin in the background handler
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'channel_id', // Channel ID
      'Notifications', // Channel Name
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      message.notification?.title ?? 'Background Notification', // Title
      message.notification?.body ?? 'You have received a background notification.', // Body
      platformChannelSpecifics,
    );
  }

  // Subscribe to notifications for a specific user (via email)
  Future<void> subscribeToUserNotifications(String email) async {
    await _firebaseMessaging.subscribeToTopic(email);
  }

  // Unsubscribe from notifications for a specific user
  Future<void> unsubscribeFromUserNotifications(String email) async {
    await _firebaseMessaging.unsubscribeFromTopic(email);
  }

  // Start monitoring for changes in incubator data from Firestore
  void startMonitoring() {
  // Cancel any existing subscription
  _firestoreSubscription?.cancel();

  // Fetch the logged-in user's email
  String? loggedInUserEmail = _auth.currentUser?.email;

  if (loggedInUserEmail != null) {
    _firestoreSubscription = _firestore.collection('Detection').snapshots().listen(
      (snapshot) {
        for (var doc in snapshot.docs) {
          try {
            Map<String, dynamic> data = doc.data();

            // Safely retrieve incubator information
            String incubatorName = data['incubatorName'] ?? 'Incubator'; // Use incubatorName directly
            String incubatorOwnerEmail = data['access'] ?? ''; // Owner's email address

            // Check if the logged-in user matches the access email
            if (loggedInUserEmail == incubatorOwnerEmail) {
              // Fetching temperature, humidity, and tray data
              double trayTemperature = data['Tray_Temperature']?.toDouble() ?? 0;
              double trayHumidity = data['Tray_Humidity']?.toDouble() ?? 0;
              double hatcheryTemperature = data['Hatchery_Temperature']?.toDouble() ?? 0;
              double hatcheryHumidity = data['Hatchery_Humidity']?.toDouble() ?? 0;
              int daysLeft = data['daysLeft']?.toInt() ?? 0;
              bool Hatchery_Status = data['Hatchery_Status']?.toBool() ?? 0;

              // Use daysLeft for a notification when the hatch is close
              if (daysLeft <= 3 && daysLeft > 0) {
                showNotification(
                  "⏳ Days Left to Hatch!",
                  "$incubatorName: Only $daysLeft days left before your egg hatches.",
                  id: 2, // Unique ID for this notification
                );
              }

              // Fetch Tray_1 and Tray_2 (ensure they are maps)
              Map<String, dynamic> tray1 = data['Tray_1'] ?? {};
              Map<String, dynamic> tray2 = data['Tray_2'] ?? {};

              // Initialize a list for slots that are ready to hatch
              List<String> readySlots = [];

              // Check Tray_1 slots (slot_1 to slot_56)
              for (int i = 1; i <= 56; i++) {
                String slotKey = 'slot_$i';
                if (tray1[slotKey] != null && tray1[slotKey]['daysLeft'] == 0) {
                  readySlots.add('Tray 1 - Slot $i');
                }
              }

              // Check Tray_2 slots (slot_1 to slot_56)
              for (int i = 1; i <= 56; i++) {
                String slotKey = 'slot_$i';
                if (tray2[slotKey] != null && tray2[slotKey]['daysLeft'] == 0) {
                  readySlots.add('Tray 2 - Slot $i');
                }
              }

              // If multiple slots are ready, create a consolidated notification
              if (readySlots.isNotEmpty) {
                String readySlotsMessage = readySlots.join(', ');

                // Create the notification for eggs that are ready to hatch
                showNotification(
                  "🕰️ Eggs Ready to Hatch!",
                  "$incubatorName: The following eggs are ready to hatch: $readySlotsMessage.",
                  id: 1, // Use a static ID for the ready-to-hatch notification
                );
              }

              // Define a list of other notifications to trigger
              List<Map<String, String>> notifications = [];

              // Tray Temperature Notifications
              if (trayTemperature < 35.0) {
                notifications.add({
                  "title": "🌡️ Tray Temperature Alert!",
                  "body": "$incubatorName: Tray temperature is too low at $trayTemperature°C.",
                });
              } else if (trayTemperature > 40.0) {
                notifications.add({
                  "title": "🌡️ Tray Temperature Alert!",
                  "body": "$incubatorName: Tray temperature is too high at $trayTemperature°C.",
                });
              }

              // Tray Humidity Notifications
              if (trayHumidity < 50.0) {
                notifications.add({
                  "title": "💧 Tray Humidity Alert!",
                  "body": "$incubatorName: Tray humidity is too low at $trayHumidity%.",
                });
              } else if (trayHumidity > 100.0) {
                notifications.add({
                  "title": "💧 Tray Humidity Alert!",
                  "body": "$incubatorName: Tray humidity is too high at $trayHumidity%.",
                });
              }

              // Hatchery Temperature Notifications
              if (hatcheryTemperature < 35.0) {
                notifications.add({
                  "title": "🌡️ Hatchery Temperature Alert!",
                  "body": "$incubatorName: Hatchery temperature is too low at $hatcheryTemperature°C.",
                });
              } else if (hatcheryTemperature > 40.0) {
                notifications.add({
                  "title": "🌡️ Hatchery Temperature Alert!",
                  "body": "$incubatorName: Hatchery temperature is too high at $hatcheryTemperature°C.",
                });
              }

              // Hatchery Humidity Notifications
              if (hatcheryHumidity < 50.0) {
                notifications.add({
                  "title": "💧 Hatchery Humidity Alert!",
                  "body": "$incubatorName: Hatchery humidity is too low at $hatcheryHumidity%.",
                });
              } else if (hatcheryHumidity > 100.0) {
                notifications.add({
                  "title": "💧 Hatchery Humidity Alert!",
                  "body": "$incubatorName: Hatchery humidity is too high at $hatcheryHumidity%.",
                });
              }

              if (Hatchery_Status) {
                notifications.add({
                  "title": "🐤 Chicks Alert!",
                  "body": "$incubatorName: Chicks are hatched!",
                });
              }
              // Show all notifications with unique IDs
              for (int i = 0; i < notifications.length; i++) {
                showNotification(
                  notifications[i]["title"]!,
                  notifications[i]["body"]!,
                  id: i, // Pass the unique id for each notification
                );
              }
            }
          } catch (e) {
            print('Error processing document data: $e');
          }
        }
      },
    );
  }
}
}