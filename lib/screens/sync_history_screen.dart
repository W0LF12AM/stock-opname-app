import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/connectivity_provider.dart';
import '../providers/sync_provider.dart';
import '../models/adjustment.dart';
import '../models/vessel.dart';
import 'sync_screen.dart';

class SyncHistoryScreen extends StatelessWidget {
  const SyncHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    final isOnline = context.watch<ConnectivityProvider>().isOnline;

    // Group pending adjustments by vesselId reactively from provider
    final Map<int, List<Adjustment>> pendingByVessel = {};
    for (final adj in sync.allPendingAdjustments) {
      pendingByVessel.putIfAbsent(adj.vesselId, () => []).add(adj);
    }

    // Map vessel details from provider
    final Map<int, Vessel> vesselMap = {
      for (final v in sync.vessels) v.id: v
    };

    final totalPending = sync.allPendingAdjustments.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Sinkronisasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => sync.loadAllPendingAdjustments(),
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => sync.loadAllPendingAdjustments(),
        child: pendingByVessel.isEmpty
            ? _buildEmptyState(context)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isOnline
                            ? const Color(0xFFA5D6A7)
                            : const Color(0xFFFFCC80),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOnline
                              ? Icons.cloud_upload_rounded
                              : Icons.cloud_off_rounded,
                          color: isOnline
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE65100),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$totalPending perubahan menunggu sinkronisasi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isOnline
                                      ? const Color(0xFF1B5E20)
                                      : const Color(0xFFBF360C),
                                ),
                              ),
                              Text(
                                isOnline
                                    ? 'Buka kapal untuk mensinkronkan'
                                    : 'Aktifkan koneksi internet untuk sync',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOnline
                                      ? const Color(0xFF388E3C)
                                      : const Color(0xFFE64A19),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Per-vessel pending cards
                  ...pendingByVessel.entries.map((entry) {
                    final vessel = vesselMap[entry.key];
                    final adjustments = entry.value;
                    return _buildVesselPendingCard(
                        context, vessel, adjustments, isOnline);
                  }),
                ],
              ),
      ),
    );
  }

  Widget _buildVesselPendingCard(
    BuildContext context,
    Vessel? vessel,
    List<Adjustment> adjustments,
    bool isOnline,
  ) {
    final vesselName = vessel?.vesselName ?? 'Kapal #${adjustments.first.vesselId}';
    final hasError = adjustments.any((a) => a.syncError != null);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_boat_rounded,
                    color: Color(0xFF0D47A1), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vesselName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (hasError)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDECEC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF9A9A)),
                    ),
                    child: const Text(
                      'Ada Gagal',
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFC62828),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${adjustments.length} perubahan pending',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),

            // List of pending item names
            ...adjustments.take(3).map((adj) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    adj.isExisting ? Icons.edit_rounded : Icons.add_circle_rounded,
                    size: 14,
                    color: adj.syncError != null
                        ? const Color(0xFFC62828)
                        : const Color(0xFF0D47A1),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      adj.partName,
                      style: TextStyle(
                        fontSize: 12,
                        color: adj.syncError != null
                            ? const Color(0xFFC62828)
                            : const Color(0xFF475569),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM HH:mm').format(adj.createdAt),
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            )),
            if (adjustments.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${adjustments.length - 3} lainnya...',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ),

            if (isOnline && vessel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final sync = context.read<SyncProvider>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SyncScreen(vessel: vessel),
                      ),
                    ).then((_) => sync.loadAllPendingAdjustments());
                  },
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: const Text('Sync Sekarang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        const Icon(Icons.check_circle_outline_rounded,
            size: 80, color: Color(0xFF81C784)),
        const SizedBox(height: 16),
        const Text(
          'Semua Tersinkron!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tidak ada perubahan yang menunggu sinkronisasi.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}
