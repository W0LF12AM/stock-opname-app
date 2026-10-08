import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/vessel.dart';
import '../models/adjustment.dart';
import '../models/inventory_item.dart';

class PdfReportService {
  static final PdfReportService _instance = PdfReportService._internal();
  factory PdfReportService() => _instance;
  PdfReportService._internal();

  /// Menghasilkan dokumen PDF dalam bentuk byte data (Uint8List)
  Future<Uint8List> generateAdjustmentReportBytes({
    required Vessel vessel,
    required List<Adjustment> adjustments,
    List<InventoryItem> inventoryItems = const [],
    String reporterName = 'Kru Kapal',
    String reporterRole = 'Crew',
    bool isApproved = false,
  }) async {
    final pdf = pw.Document();

    // Map untuk mempermudah pencarian nama sparepart existing
    final Map<int, InventoryItem> itemMap = {
      for (final item in inventoryItems) item.id: item,
    };

    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');
    final formattedDate = dateFormatter.format(DateTime.now());

    // Hitung ringkasan
    final reductionCount = adjustments.where((a) => a.isExisting).length;
    final newCount = adjustments.where((a) => !a.isExisting).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ==========================================
            // HEADER DOKUMEN & KOP LAPORAN
            // ==========================================
            _buildDocumentHeader(
              vessel: vessel,
              formattedDate: formattedDate,
              isApproved: isApproved,
            ),
            pw.SizedBox(height: 14),

            // ==========================================
            // INFORMASI METADATA & STATUS BADGE
            // ==========================================
            _buildMetadataSection(
              vessel: vessel,
              reporterName: reporterName,
              reporterRole: reporterRole,
              reductionCount: reductionCount,
              newCount: newCount,
              isApproved: isApproved,
            ),
            pw.SizedBox(height: 18),

            // ==========================================
            // TABEL DATA ADJUSTMENT
            // ==========================================
            pw.Text(
              'RINCIAN PENYESUAIAN STOK & ITEM BARU',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#0D47A1'),
              ),
            ),
            pw.SizedBox(height: 8),
            _buildAdjustmentsTable(adjustments, itemMap),
            pw.SizedBox(height: 24),

            // ==========================================
            // LEMBAR PENGESAHAN (TANDA TANGAN)
            // ==========================================
            _buildSignatureSection(
              reporterName: reporterName,
              reporterRole: reporterRole,
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Aplikasi Stock Opname Kapal - Dokumen Resmi Onboard',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Menampilkan dialog preview & print langsung di aplikasi
  Future<void> previewReport(
    BuildContext context, {
    required Vessel vessel,
    required List<Adjustment> adjustments,
    List<InventoryItem> inventoryItems = const [],
    String reporterName = 'Kru Kapal',
    String reporterRole = 'Crew',
    bool isApproved = false,
  }) async {
    final pdfBytes = await generateAdjustmentReportBytes(
      vessel: vessel,
      adjustments: adjustments,
      inventoryItems: inventoryItems,
      reporterName: reporterName,
      reporterRole: reporterRole,
      isApproved: isApproved,
    );

    final filename = 'Berita_Acara_Stok_${vessel.vesselName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

    await Printing.layoutPdf(
      name: filename,
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  /// Bagikan file PDF melalui aplikasi lain (WhatsApp, Email, Drive)
  Future<void> shareReport({
    required Vessel vessel,
    required List<Adjustment> adjustments,
    List<InventoryItem> inventoryItems = const [],
    String reporterName = 'Kru Kapal',
    String reporterRole = 'Crew',
    bool isApproved = false,
  }) async {
    final pdfBytes = await generateAdjustmentReportBytes(
      vessel: vessel,
      adjustments: adjustments,
      inventoryItems: inventoryItems,
      reporterName: reporterName,
      reporterRole: reporterRole,
      isApproved: isApproved,
    );

    final filename = 'Berita_Acara_Stok_${vessel.vesselName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename,
    );
  }

  // =========================================================================
  // HELPER WIDGETS BUILDER
  // =========================================================================

  pw.Widget _buildDocumentHeader({
    required Vessel vessel,
    required String formattedDate,
    required bool isApproved,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromHex('#0D47A1'), width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BERITA ACARA PENYESUAIAN STOK',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#0D47A1'),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'LOGISTIK & INVENTARIS SPAREPART KAPAL',
                style: const pw.TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'TANGGAL CETAK',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                formattedDate,
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMetadataSection({
    required Vessel vessel,
    required String reporterName,
    required String reporterRole,
    required int reductionCount,
    required int newCount,
    required bool isApproved,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 1),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Info Kapal & Pelapor
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildMetaRow('Nama Kapal', '${vessel.vesselName} (${vessel.vesselType})'),
                pw.SizedBox(height: 4),
                _buildMetaRow('Pelapor / Petugas', '$reporterName ($reporterRole)'),
                pw.SizedBox(height: 4),
                _buildMetaRow('Ringkasan Usulan', '$reductionCount Pengurangan Stok, $newCount Item Baru'),
              ],
            ),
          ),
          pw.SizedBox(width: 12),

          // Status Badge Resmi (Icon Vektor & Warna, Tanpa Emoji)
          pw.Expanded(
            flex: 5,
            child: pw.Align(
              alignment: pw.Alignment.topRight,
              child: _buildStatusBadge(isApproved: isApproved),
            ),
          ),
        ],
      ),
    );
  }

  /// Badge Status dengan Icon Vektor dan Warna resmi (Tanpa Emoji)
  pw.Widget _buildStatusBadge({required bool isApproved}) {
    final bgColor = isApproved ? PdfColor.fromHex('#E8F5E9') : PdfColor.fromHex('#FFF3E0');
    final borderColor = isApproved ? PdfColor.fromHex('#81C784') : PdfColor.fromHex('#FFB74D');
    final textColor = isApproved ? PdfColor.fromHex('#1B5E20') : PdfColor.fromHex('#E65100');
    final iconColor = textColor;
    final statusText = isApproved ? 'DISETUJUI (RESMI)' : 'MENUNGGU APPROVAL';
    final subtitleText = isApproved ? 'Telah diverifikasi Admin' : 'Usulan Draft Kru Kapal';

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: borderColor, width: 1.2),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Icon Vektor Resmi (Container Lingkaran + Simbol Vektor)
          pw.Container(
            width: 18,
            height: 18,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: iconColor, width: 1.5),
            ),
            child: pw.Center(
              child: isApproved
                  ? pw.CustomPaint(
                      size: const PdfPoint(10, 10),
                      painter: (PdfGraphics canvas, PdfPoint size) {
                        canvas.setColor(iconColor);
                        canvas.setLineWidth(1.6);
                        canvas.moveTo(1, 5);
                        canvas.lineTo(4, 2);
                        canvas.lineTo(9, 8);
                        canvas.strokePath();
                      },
                    )
                  : pw.CustomPaint(
                      size: const PdfPoint(10, 10),
                      painter: (PdfGraphics canvas, PdfPoint size) {
                        canvas.setColor(iconColor);
                        canvas.setLineWidth(1.4);
                        canvas.moveTo(5, 5);
                        canvas.lineTo(5, 8.5); // jarum vertikal
                        canvas.moveTo(5, 5);
                        canvas.lineTo(8.5, 5); // jarum horizontal
                        canvas.strokePath();
                      },
                    ),
            ),
          ),
          pw.SizedBox(width: 8),

          // Teks Status
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                statusText,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: textColor,
                ),
              ),
              pw.Text(
                subtitleText,
                style: pw.TextStyle(
                  fontSize: 7.5,
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMetaRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 95,
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
          ),
        ),
        pw.Text(': ', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildAdjustmentsTable(
    List<Adjustment> adjustments,
    Map<int, InventoryItem> itemMap,
  ) {
    if (adjustments.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Center(
          child: pw.Text(
            'Tidak ada usulan penyesuaian stok yang tercatat.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
      );
    }

    final headers = [
      'No',
      'Nama Sparepart & Part Number',
      'Tipe',
      'Sistem',
      'Fisik',
      'Selisih',
      'Keterangan / Alasan Pemakaian',
    ];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#0D47A1'),
      ),
      headerAlignment: pw.Alignment.centerLeft,
      cellStyle: const pw.TextStyle(fontSize: 7.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      columnWidths: {
        0: const pw.FixedColumnWidth(22),  // No
        1: const pw.FlexColumnWidth(3.2), // Nama & PN
        2: const pw.FixedColumnWidth(65),  // Tipe
        3: const pw.FixedColumnWidth(42),  // Sistem
        4: const pw.FixedColumnWidth(42),  // Fisik
        5: const pw.FixedColumnWidth(48),  // Selisih
        6: const pw.FlexColumnWidth(3.0), // Remarks
      },
      data: adjustments.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final adj = entry.value;

        String partName = '';
        String partNumber = '';
        String satuan = adj.satuan;
        double systemQty = 0.0;

        if (adj.isExisting) {
          final item = itemMap[adj.inventoryId];
          partName = item?.partName ?? 'Item ID: ${adj.inventoryId}';
          partNumber = item?.partNumber ?? adj.partNumber ?? '-';
          satuan = item?.satuan ?? adj.satuan;
          systemQty = adj.physicalQty - adj.qtyChange;
        } else {
          partName = adj.partName;
          partNumber = adj.partNumber ?? '-';
          systemQty = 0.0;
        }

        final deltaStr = adj.isExisting
            ? '${adj.qtyChange >= 0 ? '+' : ''}${adj.qtyChange.toStringAsFixed(1)} $satuan'
            : '+${adj.physicalQty.toStringAsFixed(1)} $satuan (Baru)';

        final typeStr = adj.isExisting ? 'Pengurangan' : 'Item Baru';

        return [
          '$index',
          '$partName\nPN: $partNumber',
          typeStr,
          adj.isExisting ? '${systemQty.toStringAsFixed(1)} $satuan' : '-',
          '${adj.physicalQty.toStringAsFixed(1)} $satuan',
          deltaStr,
          adj.keterangan.isNotEmpty ? adj.keterangan : '-',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildSignatureSection({
    required String reporterName,
    required String reporterRole,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildSignatureBox(
            title: 'Dibuat Oleh:',
            role: reporterRole,
            name: reporterName,
          ),
          _buildSignatureBox(
            title: 'Diketahui Oleh:',
            role: 'Chief Engineer / Nakhoda',
            name: '( .................................... )',
          ),
          _buildSignatureBox(
            title: 'Disetujui Oleh:',
            role: 'Superintendent / Admin Darat',
            name: '( .................................... )',
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignatureBox({
    required String title,
    required String role,
    required String name,
  }) {
    return pw.Container(
      width: 155,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.Text(
            role,
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 38), // Ruang tanda tangan fisik
          pw.Text(
            name,
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
}
