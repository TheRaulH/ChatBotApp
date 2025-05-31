import 'package:sqflite/sqflite.dart'; 

class SQLiteConfig {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = await getDatabasesPath(); 
    String dbPath = '$path/chat_app.db';

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE chat_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            question TEXT,
            answer TEXT,
            is_local BOOLEAN,
            timestamp INTEGER
          )
        ''');
      },
    );
  }
}
