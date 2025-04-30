import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseServices {

 static Future<Database> _openDatabase() async {
  final database_path = await getDatabasesPath();
  final database_file = join(database_path, "users.db");

  final db = await openDatabase(database_file,version: 1,onCreate: createDatabase,);
  await db.execute("PRAGMA foreign_keys = ON");

  return db;
}

  static Future<void> createDatabase(Database db, int version) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS users (userID INTEGER PRIMARY KEY AUTOINCREMENT,userName TEXT,email TEXT,mobileNo INTEGER,password TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS friends (connectionid INTEGER PRIMARY KEY AUTOINCREMENT,userID INTEGER,friendID INTEGER,UNIQUE(userID, friendID),FOREIGN KEY(userID) REFERENCES users(userID),FOREIGN KEY(friendID) REFERENCES users(userID))''');
    await db.execute('''CREATE TABLE IF NOT EXISTS matches (matchID INTEGER PRIMARY KEY AUTOINCREMENT,userID INTEGER,movieID TEXT,matched_at TEXT,FOREIGN KEY(userID) REFERENCES users(userID))''');
  }

  //user functions 
  static Future<int> addUserDetails(String name, String email, int mobileNo, String password) async {
    final db = await _openDatabase();

    Map<String, dynamic> userRecord = {
      'userName': name,
      'email' : email,
      'mobileNo' : mobileNo,
      'password' : password
    };
    return await db.insert('users', userRecord);
  }

  static Future<Map<String, dynamic>?> retrieveSingleRecord(int uID)async {
    final db = await _openDatabase();
    List<Map<String,dynamic>> result = await db.query('users', where : 'userID =?', whereArgs: [uID],limit: 1);

    return result.isNotEmpty ? result.first : null;
  }

  static Future<int> updateStudentRecord(int uID, Map<String,dynamic> record) async{
    final db = await _openDatabase();
    return await db.update('users', record, where: 'userID=?',whereArgs: [uID]);
  }
  
  static Future<List<Map<String, dynamic>>> getAllStudentRecords() async {
    final db = await _openDatabase();
    return await db.query('users');
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {//gets user name from input on login screen
    final db = await _openDatabase();
    final result = await db.query('users',where: 'userName = ?',whereArgs: [username],
  );

    return result.isNotEmpty ? result.first : null;
  }

//functions for friends   
 static Future<void> addFriend(int userID, int friendID) async {
  final db = await _openDatabase();

      await db.insert('friends', {
      'userID': userID,
      'friendID': friendID,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.insert('friends', {
      'userID': friendID,
      'friendID': userID,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
}


static Future<List<Map<String, dynamic>>> getFriends(int userID) async {
  final db = await _openDatabase();
  return await db.rawQuery('''
    SELECT DISTINCT users.* FROM users
    INNER JOIN friends ON users.userID = friends.friendID
    WHERE friends.userID = ?
  ''', [userID]);
}


  static Future<void> deleteFriend(int uID, int friendID) async {
    final db = await _openDatabase();
    await db.delete(
      'friends',
      where: 'userID = ? AND friendID = ?',
      whereArgs: [uID, friendID],
    );
  }

  static Future<Map<String, dynamic>?> searchUserByUsername(String username, int currentUserId) async { //for the find friend page 
  final db = await _openDatabase();
  final result = await db.query(
    'users',
    where: 'userName = ? AND userID != ?',
    whereArgs: [username, currentUserId],
    limit: 1,
  );

  return result.isNotEmpty ? result.first : null;
  }

  static Future<bool> CheckIfAlreadyFreinds(int userID, int otherUserID) async {
    final db = await _openDatabase();

     final result = await db.query(
    'friends',
    where: 'userID = ? AND friendID = ?',
    whereArgs: [userID, otherUserID],
    limit: 1,
  );

  return result.isNotEmpty;
  }


  static Future<List<Map<String, dynamic>>> displayMatches() async {
    final db = await _openDatabase();
    return await db.query('matches');
  }

static Future<void> saveMatch(String movie,int user,String time) async {
  final db = await _openDatabase();
      Map<String, dynamic> match_details = {
      'movieID': movie,
      'userID':user,
      'matched_at' : time,
    };
    await db.insert('matches', match_details);

}

}

