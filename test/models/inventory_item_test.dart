import 'package:flutter_test/flutter_test.dart';
import 'package:stock_opname_app/models/inventory_item.dart';

void main() {
  group('InventoryItem Model Tests', () {
    test('fromJson creates item correctly with full properties', () {
      final json = {
        'id': 1,
        'part_name': 'Fuel Filter Element',
        'part_number': 'FF-9021',
        'satuan': 'PCS',
        'current_qty': 15.5,
        'price': 250000.0,
        'main_component_id': 10,
        'sub_component_id': 20,
        'main_name': 'Main Engine',
        'sub_name': 'Fuel System',
      };

      final item = InventoryItem.fromJson(json, 42);

      expect(item.id, 1);
      expect(item.vesselId, 42);
      expect(item.partName, 'Fuel Filter Element');
      expect(item.partNumber, 'FF-9021');
      expect(item.satuan, 'PCS');
      expect(item.currentQty, 15.5);
      expect(item.price, 250000.0);
      expect(item.mainComponentId, 10);
      expect(item.subComponentId, 20);
      expect(item.mainName, 'Main Engine');
      expect(item.subName, 'Fuel System');
      print('  ✓ [SUCCESS] Parsed InventoryItem: "${item.partName}" (Qty: ${item.currentQty}, Price: Rp ${item.price})');
    });

    test('fromJson handles string numbers and nullable sub-components', () {
      final json = {
        'id': '99',
        'part_name': 'O-Ring',
        'part_number': null,
        'satuan': null,
        'current_qty': '10',
        'price': '75000',
        'main_component_id': '5',
        'sub_component_id': null,
        'main_name': 'Auxiliary Engine',
        'sub_name': null,
      };

      final item = InventoryItem.fromJson(json, 1);

      expect(item.id, 99);
      expect(item.vesselId, 1);
      expect(item.partName, 'O-Ring');
      expect(item.partNumber, isNull);
      expect(item.satuan, 'PCS'); // default
      expect(item.currentQty, 10.0);
      expect(item.price, 75000.0);
      expect(item.mainComponentId, 5);
      expect(item.subComponentId, isNull);
      expect(item.mainName, 'Auxiliary Engine');
      expect(item.subName, isNull);
      print('  ✓ [SUCCESS] Handled string numbers & nulls for "${item.partName}"');
    });

    test('toJson serializes InventoryItem properly', () {
      final item = InventoryItem(
        id: 7,
        vesselId: 88,
        partName: 'Piston Ring',
        partNumber: 'PR-100',
        satuan: 'SET',
        currentQty: 4.0,
        price: 1200000.0,
        mainComponentId: 2,
        subComponentId: 5,
        mainName: 'Engine Block',
        subName: 'Cylinder',
      );

      final map = item.toJson();

      expect(map['id'], 7);
      expect(map['vessel_id'], 88);
      expect(map['part_name'], 'Piston Ring');
      expect(map['part_number'], 'PR-100');
      expect(map['satuan'], 'SET');
      expect(map['current_qty'], 4.0);
      expect(map['price'], 1200000.0);
      expect(map['main_component_id'], 2);
      expect(map['sub_component_id'], 5);
      expect(map['main_name'], 'Engine Block');
      expect(map['sub_name'], 'Cylinder');
      print('  ✓ [SUCCESS] Serialized InventoryItem to JSON: ${map['part_name']}');
    });
  });
}
