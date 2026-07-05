import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/sync_provider.dart';
import '../models/vessel.dart';
import 'inventory_screen.dart';
import 'sync_screen.dart';

class VesselListScreen extends StatefulWidget {
  const VesselListScreen({super.key});

  @override
  State<VesselListScreen> createState() => _VesselListScreenState();
}

class _VesselListScreenState extends State<VesselListScreen> {
  ConnectivityProvider? _connectivityProvider;
  final _vesselSearchController = TextEditingController();
  String _vesselSearchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connectivity = context.read<ConnectivityProvider>();
      final sync = context.read<SyncProvider>();
      
      // Initial load
      sync.loadVessels(connectivity.isOnline).then((_) {
        if (!mounted) return;
        if (sync.errorMessage != null &&
            (sync.errorMessage!.toLowerCase().contains('unauthorized') ||
                sync.errorMessage!.contains('401'))) {
          context.read<AuthProvider>().logout();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesi masuk telah berakhir. Silakan login kembali.'),
              backgroundColor: Color(0xFFC62828),
            ),
          );
        }
      });

      // Listen to connectivity changes to reload vessel list
      _connectivityProvider = connectivity;
      connectivity.addListener(_onConnectivityChanged);
    });
  }

  void _onConnectivityChanged() {
    if (_connectivityProvider == null || !mounted) return;
    final sync = context.read<SyncProvider>();
    sync.loadVessels(_connectivityProvider!.isOnline).then((_) {
      if (!mounted) return;
      if (sync.errorMessage != null &&
          (sync.errorMessage!.toLowerCase().contains('unauthorized') ||
              sync.errorMessage!.contains('401'))) {
        context.read<AuthProvider>().logout();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi masuk telah berakhir. Silakan login kembali.'),
            backgroundColor: Color(0xFFC62828),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _connectivityProvider?.removeListener(_onConnectivityChanged);
    _vesselSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    final auth = context.watch<AuthProvider>();
    final sync = context.watch<SyncProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Daftar Kapal'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Real-time Connection Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: isOnline ? const Color(0xFFE8F5E9) : const Color(0xFFECEFF1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  size: 16,
                  color: isOnline ? const Color(0xFF2E7D32) : const Color(0xFF546E7A),
                ),
                const SizedBox(width: 8),
                Text(
                  isOnline 
                      ? 'Terhubung ke internet' 
                      : 'Mode Offline: Menampilkan data kapal terunduh saja',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOnline ? const Color(0xFF2E7D32) : const Color(0xFF455A64),
                  ),
                ),
              ],
            ),
          ),
          
          // User Welcome Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D47A1).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.fullName ?? 'Petugas Stock Opname',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Role: ${(auth.role ?? 'petugas').toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Vessel Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _vesselSearchController,
              decoration: InputDecoration(
                hintText: 'Cari Nama Kapal / Jenis...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _vesselSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() {
                            _vesselSearchController.clear();
                            _vesselSearchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) {
                setState(() {
                  _vesselSearchQuery = val;
                });
              },
            ),
          ),

          // Main Vessel List Content
          Expanded(
            child: sync.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => sync.loadVessels(isOnline),
                    child: sync.vessels.isEmpty
                        ? _buildEmptyState(isOnline, sync.errorMessage)
                        : () {
                            final filteredVessels = sync.vessels.where((v) {
                              final q = _vesselSearchQuery.toLowerCase();
                              return v.vesselName.toLowerCase().contains(q) ||
                                  v.vesselType.toLowerCase().contains(q);
                            }).toList();

                            if (filteredVessels.isEmpty) {
                              return const Center(
                                child: Text(
                                  'Kapal tidak ditemukan',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredVessels.length,
                              itemBuilder: (context, index) {
                                final vessel = filteredVessels[index];
                                return _buildVesselCard(context, vessel, isOnline, sync);
                              },
                            );
                          }(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isOnline, String? errorMessage) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Icon(
          errorMessage != null ? Icons.error_outline_rounded : Icons.directions_boat_filled_outlined,
          size: 80,
          color: errorMessage != null ? const Color(0xFFC62828) : const Color(0xFFCBD5E1),
        ),
        const SizedBox(height: 16),
        Text(
          errorMessage != null ? 'Gagal Memuat Data' : 'Tidak Ada Kapal Tersedia',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: errorMessage != null ? const Color(0xFFC62828) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            errorMessage ?? (isOnline
                ? 'Tarik layar ke bawah untuk memuat ulang.'
                : 'Aktifkan koneksi internet untuk mengunduh daftar kapal.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }

  Widget _buildVesselCard(BuildContext context, Vessel vessel, bool isOnline, SyncProvider syncProvider) {
    final isDownloaded = vessel.downloadedAt != null;
    // Read from in-memory provider state — no DB query on every rebuild
    final pendingCount = syncProvider.getPendingCount(vessel.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.directions_boat_rounded, color: Color(0xFF0D47A1)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vessel.vesselName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vessel.vesselType,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (pendingCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF6C00),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$pendingCount Pending',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Download status text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDownloaded ? 'Tersedia Offline' : 'Belum Terunduh',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDownloaded ? const Color(0xFF2E7D32) : const Color(0xFF64748B),
                      ),
                    ),
                    if (isDownloaded)
                      Text(
                        'Unduh: ${DateFormat('dd/MM/yy HH:mm').format(vessel.downloadedAt!)}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                  ],
                ),
                
                // Buttons based on status & network (Blue / Green CTAs)
                Row(
                  children: [
                    if (isDownloaded) ...[
                      // View Workspace Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InventoryScreen(vessel: vessel),
                            ),
                          ).then((_) {
                            // Trigger state refresh of this list when returning
                            setState(() {});
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: const Text('Buka'),
                      ),
                      const SizedBox(width: 8),
                      
                      // Sync Button (Only if online)
                      if (isOnline)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SyncScreen(vessel: vessel),
                              ),
                            ).then((_) {
                              setState(() {});
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pendingCount > 0
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF0D47A1),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          child: const Icon(
                            Icons.sync_rounded,
                            size: 18,
                          ),
                        ),
                    ] else ...[
                      // Download Button (Disabled in Offline Mode)
                      ElevatedButton.icon(
                        onPressed: isOnline 
                            ? () => _downloadVessel(context, vessel, syncProvider)
                            : null,
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Unduh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadVessel(BuildContext context, Vessel vessel, SyncProvider sync) async {
    // Step 1: Confirm download
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unduh Data Kapal'),
        content: Text(
          'Unduh data inventory untuk ${vessel.vesselName}?\n\n'
          'Data ini digunakan untuk stock opname secara offline.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Unduh'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Step 2: Show non-dismissable loading dialog to prevent accidental touches (ANR trigger)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AnimatedBuilder(
          animation: sync,
          builder: (context, _) {
            final progress = sync.downloadProgress;
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    progress.isNotEmpty ? progress : 'Mengunduh data ${vessel.vesselName}...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Debug: prg="$progress", load=${sync.isLoading}, err=${sync.errorMessage ?? "none"}',
                    style: const TextStyle(fontSize: 10, color: Colors.purple, fontFamily: 'monospace'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mohon tunggu, jangan tutup aplikasi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    // Step 3: Run download
    await sync.downloadVesselData(vessel);

    // Step 4: Close loading dialog safely with a tiny delay to ensure transition completes
    await Future.delayed(const Duration(milliseconds: 300));
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // Step 5: Show result
    if (!context.mounted) return;
    if (sync.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sync.errorMessage!),
          backgroundColor: const Color(0xFFC62828),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Data ${vessel.vesselName} berhasil diunduh!'),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
