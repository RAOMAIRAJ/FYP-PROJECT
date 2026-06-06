import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'qanoon_buddy.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cases(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            case_number TEXT,
            title TEXT,
            court_name TEXT,
            judge_name TEXT,
            status TEXT,
            next_hearing_date TEXT,
            notes TEXT,
            created_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE wallet_docs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            type TEXT,
            doc_number TEXT,
            expiry_date TEXT,
            notes TEXT,
            file_path_mock TEXT,
            created_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE vehicles(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plate_number TEXT,
            maker TEXT,
            model TEXT,
            token_expiry TEXT,
            insurance_expiry TEXT,
            reg_date TEXT,
            created_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE expenses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            category TEXT,
            amount REAL,
            date TEXT,
            notes TEXT,
            created_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE complaints(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_name TEXT,
            user_email TEXT,
            category TEXT,
            reported_lawyer TEXT,
            description TEXT,
            date TEXT,
            status TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE tickets(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_name TEXT,
            type TEXT,
            subject TEXT,
            message TEXT,
            date TEXT,
            status TEXT,
            replies TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS wallet_docs(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT,
              type TEXT,
              doc_number TEXT,
              expiry_date TEXT,
              notes TEXT,
              file_path_mock TEXT,
              created_at TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS vehicles(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              plate_number TEXT,
              maker TEXT,
              model TEXT,
              token_expiry TEXT,
              insurance_expiry TEXT,
              reg_date TEXT,
              created_at TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS expenses(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT,
              category TEXT,
              amount REAL,
              date TEXT,
              notes TEXT,
              created_at TEXT
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS complaints(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_name TEXT,
              user_email TEXT,
              category TEXT,
              reported_lawyer TEXT,
              description TEXT,
              date TEXT,
              status TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS tickets(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_name TEXT,
              type TEXT,
              subject TEXT,
              message TEXT,
              date TEXT,
              status TEXT,
              replies TEXT
            )
          ''');
        }
      },
    );
  }

  // Insert case
  static Future<int> insertCase(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('cases', row);
  }

  // Get all cases
  static Future<List<Map<String, dynamic>>> getCases() async {
    final db = await database;
    return await db.query('cases', orderBy: 'next_hearing_date ASC');
  }

  // Update case
  static Future<int> updateCase(Map<String, dynamic> row) async {
    final db = await database;
    final Map<String, dynamic> data = Map.from(row);
    final id = data.remove('id');
    return await db.update('cases', data, where: 'id = ?', whereArgs: [id]);
  }

  // Delete case
  static Future<int> deleteCase(int id) async {
    final db = await database;
    return await db.delete('cases', where: 'id = ?', whereArgs: [id]);
  }

  // Wallet Docs
  static Future<int> insertWalletDoc(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('wallet_docs', row);
  }

  static Future<List<Map<String, dynamic>>> getWalletDocs() async {
    final db = await database;
    return await db.query('wallet_docs', orderBy: 'expiry_date ASC');
  }

  static Future<int> updateWalletDoc(Map<String, dynamic> row) async {
    final db = await database;
    final Map<String, dynamic> data = Map.from(row);
    final id = data.remove('id');
    return await db.update('wallet_docs', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteWalletDoc(int id) async {
    final db = await database;
    return await db.delete('wallet_docs', where: 'id = ?', whereArgs: [id]);
  }

  // Vehicles
  static Future<int> insertVehicle(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('vehicles', row);
  }

  static Future<List<Map<String, dynamic>>> getVehicles() async {
    final db = await database;
    return await db.query('vehicles', orderBy: 'plate_number ASC');
  }

  static Future<int> updateVehicle(Map<String, dynamic> row) async {
    final db = await database;
    final Map<String, dynamic> data = Map.from(row);
    final id = data.remove('id');
    return await db.update('vehicles', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteVehicle(int id) async {
    final db = await database;
    return await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  // Expenses
  static Future<int> insertExpense(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('expenses', row);
  }

  static Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await database;
    return await db.query('expenses', orderBy: 'date DESC');
  }

  static Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // --- Complaints ---
  static Future<int> insertComplaint(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('complaints', row);
  }

  static Future<List<Map<String, dynamic>>> getComplaints() async {
    final db = await database;
    return await db.query('complaints', orderBy: 'id DESC');
  }

  static Future<int> updateComplaintStatus(int id, String status) async {
    final db = await database;
    return await db.update('complaints', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  // --- Support Tickets ---
  static Future<int> insertTicket(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('tickets', row);
  }

  static Future<List<Map<String, dynamic>>> getTickets() async {
    final db = await database;
    return await db.query('tickets', orderBy: 'id DESC');
  }

  static Future<int> updateTicketStatusAndReplies(int id, String status, String repliesJson) async {
    final db = await database;
    return await db.update('tickets', {'status': status, 'replies': repliesJson}, where: 'id = ?', whereArgs: [id]);
  }
}
