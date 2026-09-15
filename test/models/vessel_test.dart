import 'package:flutter_test/flutter_test.dart';
import 'package:stock_opname_app/models/vessel.dart';

void main() {
  group('Vessel Model Tests', () {
    test('fromJson creates Vessel correctly with integer id', () {
      final json = {
        'id': 101,
        'vessel_name': 'KM Sumber Berkah',
        'vessel_type': 'Cargo',
        'downloaded_at': '2026-09-15T08:00:00.000Z',
      };

      final vessel = Vessel.fromJson(json);

      expect(vessel.id, 101);
      expect(vessel.vesselName, 'KM Sumber Berkah');
      expect(vessel.vesselType, 'Cargo');
      expect(vessel.downloadedAt, DateTime.parse('2026-09-15T08:00:00.000Z'));
      print('  ✓ [SUCCESS] Parsed Vessel: "${vessel.vesselName}" (Type: ${vessel.vesselType})');
    });

    test('fromJson handles string id and null downloaded_at', () {
      final json = {
        'id': '202',
        'vessel_name': 'KM Samudera',
        'vessel_type': 'Tugboat',
        'downloaded_at': null,
      };

      final vessel = Vessel.fromJson(json);

      expect(vessel.id, 202);
      expect(vessel.vesselName, 'KM Samudera');
      expect(vessel.vesselType, 'Tugboat');
      expect(vessel.downloadedAt, isNull);
      print('  ✓ [SUCCESS] Handled string ID conversion: ${vessel.id} for "${vessel.vesselName}"');
    });

    test('toJson serializes Vessel properly', () {
      final vessel = Vessel(
        id: 303,
        vesselName: 'KM Nusantara',
        vesselType: 'Tanker',
        downloadedAt: DateTime.parse('2026-09-15T12:00:00.000Z'),
      );

      final map = vessel.toJson();

      expect(map['id'], 303);
      expect(map['vessel_name'], 'KM Nusantara');
      expect(map['vessel_type'], 'Tanker');
      expect(map['downloaded_at'], '2026-09-15T12:00:00.000Z');
      print('  ✓ [SUCCESS] Serialized Vessel to Map JSON: $map');
    });
  });
}
