import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widgets/login_screen.dart';
import 'widgets/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/NotificationServices.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'Theme/themeData.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Store latest action to be handled when app is in foreground
ReceivedAction? pendingAction;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationServices.initialize();
  final prefs = await SharedPreferences.getInstance();
  final bool loggedIn = prefs.getBool('isLoggedIn') ?? false;

  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  await NotificationServices.requestPermission();


  // Register top-level/global listeners
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: onActionReceivedMethod, // <-- FIXED
    onNotificationCreatedMethod: handleNotificationCreated,
    onNotificationDisplayedMethod: handleNotificationDisplayed,
    onDismissActionReceivedMethod: handleDismissAction,
  );

  runApp(filmSwiper(
    isLoggedIn: loggedIn,
    navigatorKey: navigatorKey,
  ));
}

// ------------------------------
// Top-level background-safe methods
// ------------------------------

Future<void> onActionReceivedMethod(ReceivedAction action) async {
  print('[Top-Level] Notification action received: ${action.buttonKeyPressed}');
  pendingAction = action;

  // Optional: Handle immediately if app is in foreground
  if (navigatorKey.currentState != null) {
    await NotificationServices.handleNotificationAction(action, navigatorKey);
  }
}

Future<void> handleNotificationCreated(ReceivedNotification notification) async {
  print('Notification created: ${notification.title}');
}

Future<void> handleNotificationDisplayed(ReceivedNotification notification) async {
  print('Notification displayed: ${notification.title}');
}

Future<void> handleDismissAction(ReceivedAction action) async {
  print('Notification dismissed: ${action.payload}');
}

// ------------------------------
// Main App
// ------------------------------

class filmSwiper extends StatefulWidget {
  final bool isLoggedIn;
  final GlobalKey<NavigatorState> navigatorKey;

  const filmSwiper({
    super.key,
    required this.isLoggedIn,
    required this.navigatorKey,
  });

  @override
  State<filmSwiper> createState() => _filmSwiperState();
}

class _filmSwiperState extends State<filmSwiper> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPendingAction();
  }

  void _checkPendingAction() {
    if (pendingAction != null) {
      NotificationServices.handleNotificationAction(pendingAction!, widget.navigatorKey);
      pendingAction = null; // Clear after handling
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: widget.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: FlicksTheme.redBackgroundTheme(),
      home: widget.isLoggedIn
          ? HomeScreen(navigatorKey: widget.navigatorKey)
          : LoginScreen(),
    );
  }
}
