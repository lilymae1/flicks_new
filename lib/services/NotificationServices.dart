import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../widgets/new_swipe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/match_details.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/home_screen.dart';

class NotificationServices {
  // Initialize notifications
  static Future<void> initialize() async {
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'session_channel',
          channelName: 'Basic Notifications',
          channelDescription: 'Notification channel for basic notifications',
          defaultColor: Colors.teal,
          ledColor: Colors.white,
          playSound: true,
          enableLights: true,
          enableVibration: true,
          importance: NotificationImportance.Max,
        )
      ],
    );
  }

  // Request notification permission
  static Future<void> requestPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  // Send and store session invitation
  static Future<void> sendSessionInvitation(String sessionID, String toUserID) async {
    // Store the notification in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(toUserID)
        .collection('notifications')
        .add({
      'type': 'invitation',
      'sessionID': sessionID,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    // Optionally: Show local notification (for same device)
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'session_channel',
        title: 'Swipe Invitation!',
        body: 'You\'ve been invited to join a movie swipe session!',
        payload: {
          'sessionID': sessionID,
        },
        displayOnForeground: true,
        notificationLayout: NotificationLayout.Default,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'JOIN',
          label: 'Join Swipe',
        ),
      ],
    );
  }

  // Send match notification and store
  static Future<void> sendMatchNotification(String sessionId, String otherUserName, String movieId, String toUserID) async {
    // Store in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(toUserID)
        .collection('notifications')
        .add({
      'type': 'match',
      'sessionID': sessionId,
      'movieID': movieId,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'fromUser': otherUserName,
    });

    // Local notification
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(1000000000),
        channelKey: 'session_channel',
        title: 'You have a match!',
        body: '$otherUserName and you both liked the same movie!',
        payload: {
          'sessionID': sessionId,
          'movieID': movieId,
        },
        displayOnForeground: true,
        notificationLayout: NotificationLayout.Default,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'VIEW_MATCH',
          label: 'View Match',
        ),
      ],
    );
  }

  // Load and show any unread notifications from Firestore
  static Future<void> checkPendingNotifications(String userID) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userID)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .orderBy('timestamp')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final type = data['type'];

      if (type == 'invitation') {
        final sessionID = data['sessionID'];
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            channelKey: 'session_channel',
            title: 'Swipe Invitation!',
            body: 'You have a pending swipe invitation!',
            payload: {
              'sessionID': sessionID,
            },
            displayOnForeground: true,
          ),
          actionButtons: [
            NotificationActionButton(
              key: 'JOIN',
              label: 'Join Swipe',
            ),
          ],
        );
      } else if (type == 'match') {
        final sessionID = data['sessionID'];
        final movieID = data['movieID'];
        final fromUser = data['fromUser'];
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            channelKey: 'session_channel',
            title: 'You have a match!',
            body: '$fromUser and you both liked the same movie!',
            payload: {
              'sessionID': sessionID,
              'movieID': movieID,
            },
            displayOnForeground: true,
          ),
          actionButtons: [
            NotificationActionButton(
              key: 'VIEW_MATCH',
              label: 'View Match',
            ),
          ],
        );
      }

      // Mark as read
      await doc.reference.update({'read': true});
    }
  }

  // Handle notification actions
 static Future<void> handleNotificationAction(
  ReceivedAction action,
  GlobalKey<NavigatorState> navigatorKey,
) async {
  String sessionId = action.payload?['sessionID'] ?? '';
  String movieId = action.payload?['movieID'] ?? '';

  if (action.buttonKeyPressed == 'VIEW_MATCH') {
    if (sessionId.isNotEmpty && movieId.isNotEmpty) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => MatchDetailsPage(sessionId: sessionId, movieId: movieId),
        ),
      );
    }
  }

  if (action.buttonKeyPressed == 'JOIN') {
    if (sessionId.isNotEmpty) {
      // Replace current route stack and open HomeScreen with correct tab
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            navigatorKey: navigatorKey,
            initialTabIndex: 2, // Tab index for "Start swiping"
            deepLinkSessionId: sessionId,
          ),
        ),
        (route) => false,
      );
    }
  }

  return Future.value();
}

}