import 'package:flutter_test/flutter_test.dart';
import 'package:stock_opname_app/models/adjustment.dart';

void main() {
  group('Adjustment Model Tests', () {
    test('fromMap parses existing item adjustment correctly', () {
      final map = {
        'id': 1,
        'vessel_id': 10,
        'inventory_id': 55,
        'is_existing': 1,
        'qty_change': -2.0,
        'physical_qty': 8.0,
        'harga_satuan': 150000.0,
        'keterangan': 'Rusak saat bongkar muat',
        'part_name': 'Filter Oli',
        'part_number': 'FO-123',
        'satuan': 'PCS',
        'main_component_id': 3,
        'sub_component_id': 7,
        'new_main_component': null,
        'new_sub_component': null,
        'is_synced': 0,
        'sync_error': null,
        'created_at': '2026-09-15T08:30:00.000Z',
      };

      final adj = Adjustment.fromMap(map);

      expect(adj.id, 1);
      expect(adj.vesselId, 10);
      expect(adj.inventoryId, 55);
      expect(adj.isExisting, isTrue);
      expect(adj.qtyChange, -2.0);
      expect(adj.physicalQty, 8.0);
      expect(adj.hargaSatuan, 150000.0);
      expect(adj.keterangan, 'Rusak saat bongkar muat');
      expect(adj.isSynced, isFalse);
      expect(adj.createdAt, DateTime.parse('2026-09-15T08:30:00.000Z'));
      print('  ✓ [SUCCESS] Parsed SQLite Adjustment: "${adj.partName}", qtyChange=${adj.qtyChange}');
    });

    test('toMap serializes local sqlite columns properly', () {
      final now = DateTime.parse('2026-09-15T09:00:00.000Z');
      final adj = Adjustment(
        id: 5,
        vesselId: 10,
        inventoryId: null,
        isExisting: false,
        qtyChange: 5.0,
        physicalQty: 5.0,
        hargaSatuan: 50000.0,
        keterangan: 'Item baru ditemukan di gudang',
        partName: 'Baut M10',
        partNumber: 'BM-10',
        satuan: 'PCS',
        mainComponentId: 1,
        subComponentId: null,
        newMainComponent: 'Pipa Air',
        newSubComponent: null,
        isSynced: true,
        syncError: null,
        createdAt: now,
      );

      final map = adj.toMap();

      expect(map['id'], 5);
      expect(map['vessel_id'], 10);
      expect(map['inventory_id'], isNull);
      expect(map['is_existing'], 0);
      expect(map['qty_change'], 5.0);
      expect(map['physical_qty'], 5.0);
      expect(map['is_synced'], 1);
      expect(map['part_name'], 'Baut M10');
      expect(map['new_main_component'], 'Pipa Air');
      expect(map['created_at'], '2026-09-15T09:00:00.000Z');
      print('  ✓ [SUCCESS] Serialized SQLite Adjustment map with is_synced=1, is_existing=0');
    });

    test('toApiJson creates expected payload for existing items', () {
      final adj = Adjustment(
        vesselId: 2,
        inventoryId: 100,
        isExisting: true,
        qtyChange: 3.0,
        physicalQty: 10.0,
        hargaSatuan: 75000.0,
        keterangan: 'Penyesuaian stok opname',
      );

      final apiJson = adj.toApiJson();

      expect(apiJson['vessel_id'], 2);
      expect(apiJson['is_existing'], 1);
      expect(apiJson['inventory_id'], 100);
      expect(apiJson['qty_change'], 3.0);
      expect(apiJson['harga_satuan'], 75000.0);
      expect(apiJson['keterangan'], 'Penyesuaian stok opname');
      expect(apiJson.containsKey('part_name'), isFalse);
      print('  ✓ [SUCCESS] Generated API payload for existing item: $apiJson');
    });

    test('toApiJson creates expected payload for newly created items', () {
      final adj = Adjustment(
        vesselId: 2,
        inventoryId: null,
        isExisting: false,
        qtyChange: 4.0,
        physicalQty: 4.0,
        hargaSatuan: 200000.0,
        keterangan: 'Part baru',
        partName: 'Gasket Knalpot',
        partNumber: 'GK-99',
        satuan: 'SET',
        mainComponentId: 4,
        subComponentId: 8,
      );

      final apiJson = adj.toApiJson();

      expect(apiJson['vessel_id'], 2);
      expect(apiJson['is_existing'], 0);
      expect(apiJson['part_name'], 'Gasket Knalpot');
      expect(apiJson['part_number'], 'GK-99');
      expect(apiJson['satuan'], 'SET');
      expect(apiJson['main_component_id'], 4);
      expect(apiJson['sub_component_id'], 8);
      expect(apiJson.containsKey('inventory_id'), isFalse);
      print('  ✓ [SUCCESS] Generated API payload for new item: $apiJson');
    });
  });
}
