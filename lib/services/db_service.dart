import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/vessel.dart';
import '../models/inventory_item.dart';
import '../models/component.dart';
import '../models/adjustment.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  static Database? _database;

  factory DBService() {
    return _instance;
  }

  DBService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'stock_opname_app.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Vessels table
    await db.execute('''
      CREATE TABLE vessels (
        id INTEGER PRIMARY KEY,
        vessel_name TEXT NOT NULL,
        vessel_type TEXT NOT NULL,
        downloaded_at TEXT
      )
    ''');

    // 2. Inventory table
    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY,
        vessel_id INTEGER NOT NULL,
        part_name TEXT NOT NULL,
        part_number TEXT,
        satuan TEXT NOT NULL,
        current_qty REAL NOT NULL,
        price REAL NOT NULL,
        main_component_id INTEGER NOT NULL,
        sub_component_id INTEGER,
        main_name TEXT NOT NULL,
        sub_name TEXT
      )
    ''');

    // 3. Main Components table
    await db.execute('''
      CREATE TABLE main_components (
        id INTEGER PRIMARY KEY,
        vessel_id INTEGER NOT NULL,
        component_name TEXT NOT NULL
      )
    ''');

    // 4. Sub Components table
    await db.execute('''
      CREATE TABLE sub_components (
        id INTEGER PRIMARY KEY,
        main_component_id INTEGER NOT NULL,
        sub_component_name TEXT NOT NULL
      )
    ''');

    // 5. Local Adjustments table
    await db.execute('''
      CREATE TABLE local_adjustments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vessel_id INTEGER NOT NULL,
        inventory_id INTEGER NULL,
        is_existing INTEGER NOT NULL,
        qty_change REAL NOT NULL,
        physical_qty REAL NOT NULL,
        harga_satuan REAL NOT NULL,
        keterangan TEXT NOT NULL,
        part_name TEXT NOT NULL,
        part_number TEXT NULL,
        satuan TEXT NOT NULL,
        main_component_id INTEGER NOT NULL,
        sub_component_id INTEGER NULL,
        new_main_component TEXT NULL,
        new_sub_component TEXT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        sync_error TEXT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE local_adjustments ADD COLUMN new_main_component TEXT NULL');
      await db.execute('ALTER TABLE local_adjustments ADD COLUMN new_sub_component TEXT NULL');
    }
  }

  // ==========================================
  // VESSEL SYNC / DOWNLOAD OPERATIONS
  // ==========================================

  Future<void> saveVesselData({
    required Vessel vessel,
    required List<InventoryItem> items,
    required List<MainComponent> mainComponents,
    required List<SubComponent> subComponents,
  }) async {
    final db = await database;

    // Use a Batch for all inserts to avoid blocking the UI thread
    // with hundreds of sequential await calls.
    await db.transaction((txn) async {
      final batch = txn.batch();

      // 1. Save vessel record (insert or replace)
      batch.insert(
        'vessels',
        {
          'id': vessel.id,
          'vessel_name': vessel.vesselName,
          'vessel_type': vessel.vesselType,
          'downloaded_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Clear old inventory for this vessel
      batch.delete(
        'inventory',
        where: 'vessel_id = ?',
        whereArgs: [vessel.id],
      );

      // 3. Queue all new inventory items
      for (final item in items) {
        batch.insert(
          'inventory',
          item.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 4. Clear old main components for this vessel
      batch.delete(
        'main_components',
        where: 'vessel_id = ?',
        whereArgs: [vessel.id],
      );

      // 5. Queue all new main components
      for (final main in mainComponents) {
        batch.insert(
          'main_components',
          main.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 6. Clear old sub components for this vessel's main components
      if (mainComponents.isNotEmpty) {
        final mainIds = mainComponents.map((m) => m.id).join(',');
        batch.rawDelete(
          'DELETE FROM sub_components WHERE main_component_id IN ($mainIds)',
        );
      }

      // 7. Queue all new sub components
      for (final sub in subComponents) {
        batch.insert(
          'sub_components',
          sub.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Execute all queued operations in a single DB call
      await batch.commit(noResult: true);
    });
  }

  Future<List<Vessel>> getCachedVessels() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('vessels', orderBy: 'vessel_name ASC');
    return List.generate(maps.length, (i) => Vessel.fromJson(maps[i]));
  }

  Future<Vessel?> getCachedVessel(int vesselId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vessels',
      where: 'id = ?',
      whereArgs: [vesselId],
    );
    if (maps.isEmpty) return null;
    return Vessel.fromJson(maps.first);
  }

  // ==========================================
  // INVENTORY & COMPONENT RETRIEVAL
  // ==========================================

  Future<List<InventoryItem>> getInventory(int vesselId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'inventory',
      where: 'vessel_id = ?',
      whereArgs: [vesselId],
      orderBy: 'part_name ASC',
    );
    return List.generate(maps.length, (i) => InventoryItem.fromJson(maps[i], vesselId));
  }

  Future<List<MainComponent>> getMainComponents(int vesselId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'main_components',
      where: 'vessel_id = ?',
      whereArgs: [vesselId],
      orderBy: 'component_name ASC',
    );
    return List.generate(maps.length, (i) => MainComponent.fromJson(maps[i], vesselId));
  }

  Future<List<SubComponent>> getSubComponents(int vesselId) async {
    final db = await database;
    // Query sub components joined with main components for this vessel
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.id, s.main_component_id, s.sub_component_name
      FROM sub_components s
      INNER JOIN main_components m ON s.main_component_id = m.id
      WHERE m.vessel_id = ?
      ORDER BY s.sub_component_name ASC
    ''', [vesselId]);
    return List.generate(maps.length, (i) => SubComponent.fromJson(maps[i]));
  }

  // ==========================================
  // ADJUSTMENT OPERATIONS (OFFLINE INPUTS)
  // ==========================================

  Future<void> saveAdjustment(Adjustment adj) async {
    final db = await database;

    if (adj.isExisting) {
      // Check if adjustment for this inventory item already exists
      final List<Map<String, dynamic>> existing = await db.query(
        'local_adjustments',
        where: 'vessel_id = ? AND inventory_id = ? AND is_synced = 0',
        whereArgs: [adj.vesselId, adj.inventoryId],
      );

      if (existing.isNotEmpty) {
        // Update existing adjustment
        final id = existing.first['id'] as int;
        await db.update(
          'local_adjustments',
          {
            'qty_change': adj.qtyChange,
            'physical_qty': adj.physicalQty,
            'harga_satuan': adj.hargaSatuan,
            'keterangan': adj.keterangan,
            'sync_error': null, // Reset sync error
            'created_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        return;
      }
    }

    // Insert new adjustment (either new item, or first adjustment for existing item)
    await db.insert(
      'local_adjustments',
      adj.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Adjustment>> getPendingAdjustments(int vesselId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'local_adjustments',
      where: 'vessel_id = ? AND is_synced = 0',
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (i) => Adjustment.fromMap(maps[i]));
  }

  Future<List<Adjustment>> getAllPendingAdjustments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'local_adjustments',
      where: 'is_synced = 0',
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (i) => Adjustment.fromMap(maps[i]));
  }

  Future<void> markAdjustmentSynced(int id) async {
    final db = await database;
    await db.update(
      'local_adjustments',
      {
        'is_synced': 1,
        'sync_error': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAdjustmentFailed(int id, String error) async {
    final db = await database;
    await db.update(
      'local_adjustments',
      {
        'sync_error': error,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearSyncedAdjustments(int vesselId) async {
    final db = await database;
    await db.delete(
      'local_adjustments',
      where: 'vessel_id = ? AND is_synced = 1',
    );
  }

  Future<void> deleteAdjustment(int id) async {
    final db = await database;
    await db.delete(
      'local_adjustments',
      where: 'id = ?',
      whereArgs: [id], // FIX: was missing, would have deleted ALL adjustments
    );
  }

  Future<void> resetVesselCache(int vesselId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('vessels', where: 'id = ?', whereArgs: [vesselId]);
      await txn.delete('inventory', where: 'vessel_id = ?', whereArgs: [vesselId]);
      await txn.delete('main_components', where: 'vessel_id = ?', whereArgs: [vesselId]);
      // Note: sub components could be left as orphans, but we can clean them up by matching main components
      await txn.rawDelete('''
        DELETE FROM sub_components 
        WHERE main_component_id NOT IN (SELECT id FROM main_components)
      ''');
      await txn.delete('local_adjustments', where: 'vessel_id = ?', whereArgs: [vesselId]);
    });
  }
}
