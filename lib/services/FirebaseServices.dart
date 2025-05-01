import 'package:cloud_firestore/cloud_firestore.dart';
import 'NotificationServices.dart';
import 'DatabaseServices.dart';


Future <void> swipeRequest({required String fromuserID,required String toUserID, required String sessionID,}) async {
  final request = {
    'sessionsID': sessionID,
    'fromuserID': fromuserID,
    'toUserID': toUserID,
    'sentAt':FieldValue.serverTimestamp(),
    'status':'pending',
  };

  await FirebaseFirestore.instance.collection('swipeRequest').add(request);
  
}

Future<String> createSession(String userA, String userB, List<String> movieIds) async {
  final session = {
    'userA': userA,
    'userB': userB,
    'movies': movieIds,
    'swipes': {},
    'matches': [],
    'createdAt': FieldValue.serverTimestamp(),
  };

  final docRef = await FirebaseFirestore.instance.collection('sessions').add(session);
  String sessionID = docRef.id;

  NotificationServices.sendSessionInvitation(sessionID, userB);

  return sessionID;

}


Future<void> storeSwipe({required String sessionID,required String userID,required String movieID,required bool liked,}) async {

  try {
    final swipeRef = FirebaseFirestore.instance
      .collection('sessions')
      .doc(sessionID)
      .collection('swipes')
      .doc(userID);

    await swipeRef.set({movieID: liked}, SetOptions(merge: true));
  } catch (e) {
    print("Failed to store the swipe: $e");
  }
}

Future<void> movieMatch({
  required String sessionID,
  required String currentUserID,
  required String otherUserID, // Make otherUserID a required parameter
  required String movieID,
  required bool liked,
}) async {
  if (!liked) return; 

  try {
    // Fetch session data
    final sessionDoc = await FirebaseFirestore.instance.collection('sessions').doc(sessionID).get();
    final sessionData = sessionDoc.data();
    if (sessionData == null) return;

    // Fetch the other user's swipe data
    final otherUserSwipeRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionID)
        .collection('swipes')
        .doc(otherUserID);

    final otherUserSwipe = await otherUserSwipeRef.get();
    final otherSwipes = otherUserSwipe.data();

    // If the other user liked the same movie, it's a match
    if (otherSwipes != null && otherSwipes[movieID] == true) {
      final sessionRef = FirebaseFirestore.instance.collection('sessions').doc(sessionID);

      // Update session with the matched movie ID
      await sessionRef.update({
        'matches': FieldValue.arrayUnion([movieID])
      });

      String timestamp = DateTime.now().toIso8601String();

      // Save the match for both users (currentUser and the other user)
      await DatabaseServices.saveMatch(movieID, currentUserID, timestamp);
      await DatabaseServices.saveMatch(movieID, otherUserID, timestamp);

      // Send a notification to the other user
      NotificationServices.sendMatchNotification(
        sessionID, otherUserID, movieID, currentUserID,
      );
    }
  } catch (e) {
    print("Error checking for movie match: $e");
  }
}



  Future<Map<String, dynamic>?> getSessionById(String sessionId) async {
  try {
    final sessionDoc = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .get();

    if (sessionDoc.exists) {
      return sessionDoc.data();
    } else {
      print("Session not found: $sessionId");
      return null;
    }
  } catch (e) {
    print("Error fetching session: $e");
    return null;
  }
}
