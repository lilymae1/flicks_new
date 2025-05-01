import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // needed for in-memory testing
import 'package:flicks_new/services/DatabaseServices.dart'; // adjust to your path

void main() {
  // Initialize FFI for test environment
  sqfliteFfiInit();

  setUpAll(() {
    // Override sqflite with FFI (enables in-memory DB for tests)
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseServices tests', () {
    test('can insert and retrieve user', () async {
      final id = await DatabaseServices.addUserDetails(
        'TestUser',
        'test@example.com',
        1234567890,
        'securePassword',
      );

      final user = await DatabaseServices.retrieveSingleRecord(id);

      expect(user, isNotNull);
      expect(user!['userName'], 'TestUser');
      expect(user['email'], 'test@example.com');
    });

    test('can update user record', () async {
      final id = await DatabaseServices.addUserDetails(
        'AnotherUser',
        'user@example.com',
        9876543210,
        'initial',
      );

      final rows = await DatabaseServices.updateStudentRecord(id, {
        'email': 'updated@example.com',
        'password': 'newPass',
      });

      expect(rows, 1);

      final updated = await DatabaseServices.retrieveSingleRecord(id);
      expect(updated!['email'], 'updated@example.com');
    });

    test('can save and retrieve matches', () async {
      await DatabaseServices.saveMatch('MOV123', 1, '2024-04-29 12:00');
      final matches = await DatabaseServices.displayMatches();

      expect(matches.length, greaterThan(0));
      expect(matches.first['movieID'], 'MOV123');
    });
  });
}
