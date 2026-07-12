import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/sync_provider.dart';
import '../models/vessel.dart';
import '../models/adjustment.dart';
import '../models/inventory_item.dart';
import '../services/db_service.dart';

class SyncScreen extends StatefulWidget {
  final Vessel vessel;
  const SyncScreen({super.key, required this.vessel});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncProvider>().loadVesselWorkspace(widget.vessel.id);
    });
  }

  Future<void> _handleSync(BuildContext context, SyncProvider sync) async {
    print('DEBUG SCREEN: Tombol sinkronisasi diklik untuk Vessel ID: ${widget.vessel.id}. Memulai sinkronisasi...');
    final allSuccess = await sync.syncVesselAdjustments(widget.vessel.id);
    print('DEBUG SCREEN: Hasil sinkronisasi allSuccess = $allSuccess');
    
    if (mounted) {
      if (allSuccess) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text('Sinkronisasi Sukses'),
              ],
            ),
            content: const Text('Seluruh usulan stock opname berhasil dikirim ke server dan data lokal telah diperbarui.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // return to vessel list or inventory
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sync.errorMessage ?? 'Beberapa usulan gagal disinkronkan. Silakan periksa pesan error.'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    final isOnline = context.watch<ConnectivityProvider>().isOnline;

    final pendingEdits = sync.adjustments.where((adj) => adj.isExisting).length;
    final pendingNew = sync.adjustments.where((adj) => !adj.isExisting).length;
    final totalPending = sync.adjustments.length;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('Tinjau & Sinkronisasi'),
          ),
          body: Column(
            children: [
              // Connection Indicator Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: isOnline ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      size: 16,
                      color: isOnline ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnline 
                          ? 'Koneksi tersedia: Siap melakukan sinkronisasi' 
                          : 'Koneksi terputus: Sinkronisasi dinonaktifkan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isOnline ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Pending list
              Expanded(
                child: totalPending == 0
                    ? _buildAllSyncedState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sync.adjustments.length,
                        itemBuilder: (context, index) {
                          final adj = sync.adjustments[index];
                          return _buildAdjustmentReviewCard(context, adj, sync);
                        },
                      ),
              ),
              
              // Bottom Action Bar
              if (totalPending > 0)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
                    ],
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Summary info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ringkasan Penyesuaian',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569)),
                          ),
                          Text(
                            '$pendingEdits Edit, $pendingNew Baru ($totalPending total)',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0D47A1)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Sync Button (Green CTA)
                      ElevatedButton(
                        onPressed: () => _handleSync(context, sync),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32), // Green CTA
                          disabledBackgroundColor: const Color(0xFFE2E8F0),
                          disabledForegroundColor: const Color(0xFF94A3B8),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload_rounded),
                            const SizedBox(width: 8),
                            Text(isOnline ? 'Kirim Hasil Stock Opname' : 'Kirim Hasil Stock Opname (Koneksi Terputus?)'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // Loader Overlay while syncing
        if (sync.isSyncing)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32))),
                        SizedBox(height: 16),
                        Text(
                          'Sedang Mengirim Data...',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Jangan tutup aplikasi ini.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAllSyncedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_done_rounded, size: 72, color: Color(0xFF2E7D32)),
          const SizedBox(height: 16),
          const Text(
            'Semua Data Sinkron!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tidak ada perubahan lokal yang perlu dikirim.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentReviewCard(BuildContext context, Adjustment adj, SyncProvider sync) {
    // Label type
    final isNew = !adj.isExisting;
    final typeText = isNew ? 'ITEM BARU' : 'EDIT STOK';
    final typeColor = isNew ? const Color(0xFF0D47A1) : const Color(0xFF2E7D32);
    final typeBg = isNew ? const Color(0xFFE3F2FD) : const Color(0xFFE8F5E9);

    final titleText = isNew ? adj.partName : 'Barang ID: ${adj.inventoryId}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Type and Delete Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    typeText,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC62828), size: 20),
                  onPressed: () => _confirmDelete(context, adj, sync),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Name/Identifier
            if (isNew) ...[
              Text(
                titleText,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              if (adj.partNumber != null && adj.partNumber!.isNotEmpty)
                Text('PN: ${adj.partNumber}', style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'monospace')),
            ] else ...[
              // We display the details from the DB inventory
              FutureBuilder<List<InventoryItem>>(
                future: DBService().getInventory(adj.vesselId),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final match = snapshot.data!.where((item) => item.id == adj.inventoryId);
                    if (match.isNotEmpty) {
                      final item = match.first;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.partName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text('PN: ${item.partNumber ?? "-"}', style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'monospace')),
                        ],
                      );
                    }
                  }
                  return Text(
                    titleText,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  );
                },
              ),
            ],
            const Divider(height: 16, color: Color(0xFFF1F5F9)),

            // Quantities
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jumlah Fisik Counted', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text(
                      '${adj.physicalQty.toStringAsRegExp()} ${adj.satuan}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Perubahan (Delta)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text(
                      isNew ? 'New Item' : '${adj.qtyChange >= 0 ? '+' : ''}${adj.qtyChange.toStringAsRegExp()} ${adj.satuan}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isNew ? const Color(0xFF0D47A1) : (adj.qtyChange >= 0 ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Remarks/Keterangan
            if (adj.keterangan.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan: ${adj.keterangan}',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ],

            // Error display if failed previously
            if (adj.syncError != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFEF9A9A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gagal Sync: ${adj.syncError}',
                        style: const TextStyle(color: Color(0xFFC62828), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Adjustment adj, SyncProvider sync) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Penyesuaian'),
        content: const Text('Apakah Anda yakin ingin membatalkan perubahan data stock opname ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              sync.deleteAdjustment(adj.id!, widget.vessel.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)), // Red CTA for delete
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// Extension replication for safety inside this file
extension on double {
  String toStringAsRegExp() {
    return this.toString().replaceAll(RegExp(r'\.0$'), '');
  }
}
