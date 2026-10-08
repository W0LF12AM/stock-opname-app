import 'package:flutter_test/flutter_test.dart';
import 'package:stock_opname_app/models/vessel.dart';
import 'package:stock_opname_app/models/adjustment.dart';
import 'package:stock_opname_app/models/inventory_item.dart';
import 'package:stock_opname_app/services/pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfReportService Tests', () {
    final testVessel = Vessel(
      id: 1,
      vesselName: 'KM Samudera Sejahtera',
      vesselType: 'General Cargo',
      downloadedAt: DateTime.now(),
    );

    final testInventory = [
      InventoryItem(
        id: 101,
        vesselId: 1,
        partName: 'Main Engine Fuel Filter',
        partNumber: 'ME-FF-09',
        satuan: 'PCS',
        currentQty: 10.0,
        price: 350000.0,
        mainComponentId: 1,
        subComponentId: null,
        mainName: 'Main Engine',
        subName: null,
      ),
    ];

    test('generateAdjustmentReportBytes produces non-empty PDF bytes for pending draft', () async {
      final adjustments = [
        // Pengurangan stok item existing
        Adjustment(
          id: 1,
          vesselId: 1,
          inventoryId: 101,
          isExisting: true,
          qtyChange: -2.0,
          physicalQty: 8.0,
          hargaSatuan: 350000.0,
          keterangan: 'Pemakaian rutin overhaul ME Cylinder #3',
          satuan: 'PCS',
        ),
        // Item baru diregistrasi
        Adjustment(
          id: 2,
          vesselId: 1,
          isExisting: false,
          qtyChange: 5.0,
          physicalQty: 5.0,
          hargaSatuan: 125000.0,
          keterangan: 'Beli lokal di Pelabuhan Merak saat darurat',
          partName: 'Gasket Knalpot Aux Engine',
          partNumber: 'GK-AE-22',
          satuan: 'PCS',
          mainComponentId: 1,
        ),
      ];

      final pdfBytes = await PdfReportService().generateAdjustmentReportBytes(
        vessel: testVessel,
        adjustments: adjustments,
        inventoryItems: testInventory,
        reporterName: 'Budi Santoso',
        reporterRole: 'Masinis II (Crew)',
        isApproved: false,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      // Valid PDF documents start with '%PDF-'
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, equals('%PDF-'));
      print('  ✓ [SUCCESS] Generated valid Draft PDF bytes (${pdfBytes.length} bytes)');
    });

    test('generateAdjustmentReportBytes produces valid PDF bytes for approved status', () async {
      final adjustments = [
        Adjustment(
          id: 1,
          vesselId: 1,
          inventoryId: 101,
          isExisting: true,
          qtyChange: -1.0,
          physicalQty: 9.0,
          hargaSatuan: 350000.0,
          keterangan: 'Penggantian filter oli genset',
          satuan: 'PCS',
        ),
      ];

      final pdfBytes = await PdfReportService().generateAdjustmentReportBytes(
        vessel: testVessel,
        adjustments: adjustments,
        inventoryItems: testInventory,
        reporterName: 'Admin Kantor',
        reporterRole: 'Superintendent',
        isApproved: true,
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, equals('%PDF-'));
      print('  ✓ [SUCCESS] Generated valid Approved PDF bytes (${pdfBytes.length} bytes)');
    });

    test('generateAdjustmentReportBytes handles empty adjustment list gracefully', () async {
      final pdfBytes = await PdfReportService().generateAdjustmentReportBytes(
        vessel: testVessel,
        adjustments: [],
        inventoryItems: [],
        reporterName: 'Kru Kapal',
        reporterRole: 'Crew',
        isApproved: false,
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, equals('%PDF-'));
      print('  ✓ [SUCCESS] Empty adjustment list handled gracefully in PDF');
    });
  });
}
