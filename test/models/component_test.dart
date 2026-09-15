import 'package:flutter_test/flutter_test.dart';
import 'package:stock_opname_app/models/component.dart';

void main() {
  group('Component Model Tests', () {
    test('MainComponent.fromJson and toJson work correctly', () {
      final json = {
        'id': 12,
        'component_name': 'Main Propulsion Engine',
      };

      final mainComp = MainComponent.fromJson(json, 9);

      expect(mainComp.id, 12);
      expect(mainComp.vesselId, 9);
      expect(mainComp.componentName, 'Main Propulsion Engine');

      final map = mainComp.toJson();
      expect(map['id'], 12);
      expect(map['vessel_id'], 9);
      expect(map['component_name'], 'Main Propulsion Engine');
      print('  ✓ [SUCCESS] MainComponent parsed & serialized: "${mainComp.componentName}"');
    });

    test('MainComponent handles string ID from API', () {
      final json = {
        'id': '15',
        'component_name': 'Deck Machinery',
      };

      final mainComp = MainComponent.fromJson(json, 4);

      expect(mainComp.id, 15);
      expect(mainComp.vesselId, 4);
      expect(mainComp.componentName, 'Deck Machinery');
      print('  ✓ [SUCCESS] Handled string ID for MainComponent: ${mainComp.id}');
    });

    test('SubComponent.fromJson and toJson work correctly', () {
      final json = {
        'id': 101,
        'main_component_id': 12,
        'sub_component_name': 'Turbocharger',
      };

      final subComp = SubComponent.fromJson(json);

      expect(subComp.id, 101);
      expect(subComp.mainComponentId, 12);
      expect(subComp.subComponentName, 'Turbocharger');

      final map = subComp.toJson();
      expect(map['id'], 101);
      expect(map['main_component_id'], 12);
      expect(map['sub_component_name'], 'Turbocharger');
      print('  ✓ [SUCCESS] SubComponent parsed & serialized: "${subComp.subComponentName}"');
    });

    test('SubComponent handles string IDs from API', () {
      final json = {
        'id': '205',
        'main_component_id': '15',
        'sub_component_name': 'Windlass Motor',
      };

      final subComp = SubComponent.fromJson(json);

      expect(subComp.id, 205);
      expect(subComp.mainComponentId, 15);
      expect(subComp.subComponentName, 'Windlass Motor');
      print('  ✓ [SUCCESS] Handled string IDs for SubComponent: ${subComp.id}');
    });
  });
}
