import 'package:awesome_notifications/awesome_notifications.dart';

Future<void> myOnActionReceivedMethod(ReceivedAction action) async {
  // For now just print
  print('Action received in background: ${action.buttonKeyPressed}');
}