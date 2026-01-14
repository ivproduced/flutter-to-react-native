// lib/services/database_service.dart
import 'package:flutter/foundation.dart'; // For kDebugMode and debugPrint
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/information_system.dart'; // Ensure this path is correct

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('information_systems.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // --- Using VERSION 4 as per previous discussions ---
    return await openDatabase(path, version: 4, onCreate: _createDB, onUpgrade: _onUpgradeDB);
  }

  Future _createDB(Database db, int version) async {
    if (kDebugMode) {
      print("DatabaseService: Creating new database table structure (version $version)");
    }
    // Ensure this calls the method that creates ALL current columns for the new version
    await _createInformationSystemsTableV4(db);
  }

  // Schema for Version 4 (includes customParameterBlockDefinitions)
  Future _createInformationSystemsTableV4(Database db) async {
    const idType = 'TEXT PRIMARY KEY NOT NULL';
    const textType = 'TEXT NOT NULL';
    const nullableTextType = 'TEXT';
    const textTypeDefaultEmptyJsonMap = "TEXT DEFAULT '{}' NOT NULL";
    const textTypeDefaultEmptyJsonList = "TEXT DEFAULT '[]' NOT NULL";
    const textTypeDefaultEmptyString = "TEXT DEFAULT '' NOT NULL";

    await db.execute('''
CREATE TABLE information_systems (
  id $idType,
  name $textType,
  description $textTypeDefaultEmptyString,
  atoStatus $textType,
  selectedBaselineId $nullableTextType,
  controlImplementations $textTypeDefaultEmptyJsonMap,
  notes $textTypeDefaultEmptyString,
  assessmentObjectiveResponses $textTypeDefaultEmptyJsonMap,
  systemParameterBlockValues $textTypeDefaultEmptyJsonMap,
  companyAgencyName $nullableTextType,
  customParameterBlockDefinitions $textTypeDefaultEmptyJsonList  -- Column for V4
)
''');
    if (kDebugMode) {
      print("DatabaseService: information_systems table V4 created.");
    }
  }

  Future _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print("DatabaseService: Upgrading database from version $oldVersion to $newVersion");
    }
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE information_systems ADD COLUMN assessmentObjectiveResponses TEXT DEFAULT '{}' NOT NULL");
        if (kDebugMode) {
          print("DatabaseService: V_OLD (<2) -> V2: Added assessmentObjectiveResponses column.");
        }
      } catch (e) {
        if (kDebugMode) {
          print("DatabaseService: Error adding assessmentObjectiveResponses (V<2->V2): $e");
        }
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute("ALTER TABLE information_systems ADD COLUMN systemParameterBlockValues TEXT DEFAULT '{}' NOT NULL");
        if (kDebugMode) {
          print("DatabaseService: V_OLD (<3) -> V3: Added systemParameterBlockValues column.");
        }
      } catch (e) {
        if (kDebugMode) {
          print("DatabaseService: Error adding systemParameterBlockValues (V<3->V3): $e");
        }
      }
      try {
        await db.execute("ALTER TABLE information_systems ADD COLUMN companyAgencyName TEXT");
        if (kDebugMode) {
          print("DatabaseService: V_OLD (<3) -> V3: Added companyAgencyName column.");
        }
      } catch (e) {
        if (kDebugMode) {
          print("DatabaseService: Error adding companyAgencyName (V<3->V3): $e");
        }
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute("ALTER TABLE information_systems ADD COLUMN customParameterBlockDefinitions TEXT DEFAULT '[]' NOT NULL");
        if (kDebugMode) {
          print("DatabaseService: V_OLD (<4) -> V4: Added customParameterBlockDefinitions column.");
        }
      } catch (e) {
        if (kDebugMode) {
          print("DatabaseService: Error adding customParameterBlockDefinitions column (V<4->V4): $e");
        }
      }
    }
  }

  // --- CRUD Methods ---
  Future<int> createInformationSystem(InformationSystem system) async {
    final db = await instance.database;
    if (kDebugMode) {
      debugPrint("DatabaseService.createInformationSystem: System BEFORE toMap (in db.insert): ID='${system.id}', Name='${system.name}'");
    }
    Map<String, dynamic> mapForDb;
    try {
      mapForDb = system.toMap();
      if (kDebugMode) {
        debugPrint("DatabaseService.createInformationSystem: system.toMap() SUCCEEDED. Map for DB keys: ${mapForDb.keys.toList()}");
      }
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint("DatabaseService.createInformationSystem: ERROR during system.toMap(): $e\nSTACK TRACE for toMap error:\n$s");
      }
      rethrow; 
    }
    return await db.insert('information_systems', mapForDb);
  }

  Future<InformationSystem?> getInformationSystemById(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'information_systems',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return InformationSystem.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<InformationSystem>> getAllInformationSystems() async {
    final db = await instance.database;
    // Ensure orderBy is safe and doesn't use unvalidated input if 'name' could be complex
    final result = await db.query('information_systems', orderBy: 'name COLLATE NOCASE ASC');
    return result.map((json) => InformationSystem.fromMap(json)).toList();
  }

  Future<int> updateInformationSystem(InformationSystem system) async {
    final db = await instance.database;
    return await db.update(
      'information_systems',
      system.toMap(),
      where: 'id = ?',
      whereArgs: [system.id],
    );
  }

  Future<int> deleteInformationSystem(String id) async {
    final db = await instance.database;
    return await db.delete(
      'information_systems',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    // Check if database is open before trying to close
    if (db.isOpen) {
      db.close();
      _database = null; // Clear the static instance so it can be re-initialized
       if (kDebugMode) {
        print("DatabaseService: Database closed.");
      }
    }
  }
}