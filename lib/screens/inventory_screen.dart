import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';
import '../providers/connectivity_provider.dart';
import '../models/vessel.dart';
import '../models/inventory_item.dart';
import '../models/adjustment.dart';
import 'create_item_form.dart';
import 'sync_screen.dart';

class InventoryScreen extends StatefulWidget {
  final Vessel vessel;
  const InventoryScreen({super.key, required this.vessel});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  int? _selectedMainId;
  int? _selectedSubId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncProvider>().loadVesselWorkspace(widget.vessel.id);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();

    // Filter list in memory
    final blendedList = sync.getBlendedInventory();
    final filteredList = blendedList.where((item) {
      final matchesSearch = item.partName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.partNumber != null && item.partNumber!.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesMain = _selectedMainId == null || item.mainComponentId == _selectedMainId;
      final matchesSub = _selectedSubId == null || item.subComponentId == _selectedSubId;
      
      return matchesSearch && matchesMain && matchesSub;
    }).toList();

    // Get number of pending adjustments
    final pendingCount = sync.getPendingCount(widget.vessel.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.vessel.vesselName),
        actions: [
          // Refresh/Re-download data button
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Download Ulang Data',
            onPressed: () => _redownloadData(context, sync),
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.sync_rounded),
                if (pendingCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(
                      radius: 6,
                      backgroundColor: const Color(0xFFEF6C00),
                    ),
                  ),
              ],
            ),
            tooltip: 'Tinjau & Sinkronisasi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SyncScreen(vessel: widget.vessel),
                ),
              ).then((_) {
                sync.loadVesselWorkspace(widget.vessel.id);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            elevation: 1,
            color: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari Nama Barang / Part Number...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 8),
                
                // Component Dropdown Filters
                Row(
                  children: [
                    // Main Component Filter
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedMainId,
                        hint: const Text('Komponen Utama', style: TextStyle(fontSize: 12)),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Semua Komponen', style: TextStyle(fontSize: 12)),
                          ),
                          ...sync.mainComponents.map((main) {
                            return DropdownMenuItem<int>(
                              value: main.id,
                              child: Text(main.componentName, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedMainId = val;
                            _selectedSubId = null; // Reset sub when main changes
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Sub Component Filter
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedSubId,
                        hint: const Text('Sub Komponen', style: TextStyle(fontSize: 12)),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Semua Sub', style: TextStyle(fontSize: 12)),
                          ),
                          ...sync.subComponents
                              .where((sub) => _selectedMainId == null || sub.mainComponentId == _selectedMainId)
                              .map((sub) {
                            return DropdownMenuItem<int>(
                              value: sub.id,
                              child: Text(sub.subComponentName, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedSubId = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Workspace list
          Expanded(
            child: sync.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? _buildNoItemsState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          
                          // Check if this item is newly created (temp negative ID)
                          final isNewItem = item.id < 0;
                          // Check if this item has local adjustment
                          final localAdj = isNewItem 
                              ? sync.getAdjustmentForNewItem(item.id)
                              : sync.getAdjustmentForItem(item.id);

                          return _buildInventoryCard(context, item, isNewItem, localAdj, sync);
                        },
                      ),
          ),
        ],
      ),
      
      // Floating Action Button to create item (Green CTA style or Navy blue)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateItemForm(vesselId: widget.vessel.id),
            ),
          ).then((_) {
            sync.loadVesselWorkspace(widget.vessel.id);
          });
        },
        backgroundColor: const Color(0xFF0D47A1), // Blue primary CTA
        foregroundColor: Colors.white,
        tooltip: 'Tambah Item Baru',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildNoItemsState() {
    // Distinguish: truly empty (no inventory in DB) vs. filtered empty
    final sync = context.read<SyncProvider>();
    final isOnline = context.read<ConnectivityProvider>().isOnline;
    final isTrulyEmpty = sync.inventory.isEmpty && _searchQuery.isEmpty &&
        _selectedMainId == null && _selectedSubId == null;

    if (isTrulyEmpty) {
      // Inventory was downloaded but is empty — likely stale download before the fix
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isOnline ? Icons.cloud_download_outlined : Icons.inventory_2_outlined,
                size: 72,
                color: const Color(0xFF90A4AE),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tidak Ada Data Inventory',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isOnline
                    ? 'Data kosong. Tekan tombol refresh (↻) di atas untuk mengunduh ulang.'
                    : 'Data kosong. Sambungkan ke internet lalu tekan refresh (↻).',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              if (isOnline) ...[  
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _redownloadData(
                    context,
                    context.read<SyncProvider>(),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Download Ulang Sekarang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Filtered empty — user's search/filter returned nothing
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 64, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          const Text(
            'Barang Tidak Ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sesuaikan kata kunci atau filter pencarian Anda.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _redownloadData(BuildContext context, SyncProvider sync) async {
    final isOnline = context.read<ConnectivityProvider>().isOnline;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada koneksi internet untuk download ulang.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    // Show loading dialog
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
                    progress.isNotEmpty ? progress : 'Mengunduh ulang data ${widget.vessel.vesselName}...',
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

    await sync.downloadVesselData(widget.vessel);
    
    // Close loading dialog safely with a tiny delay to ensure transition completes
    await Future.delayed(const Duration(milliseconds: 300));
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // Reload workspace after re-download
    if (context.mounted) {
      await sync.loadVesselWorkspace(widget.vessel.id);
    }

    if (context.mounted && sync.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sync.errorMessage!),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    }
  }

  Widget _buildInventoryCard(
    BuildContext context, 
    InventoryItem item, 
    bool isNewItem, 
    Adjustment? adjustment, 
    SyncProvider sync
  ) {
    final hasAdjustment = adjustment != null;
    
    // Choose styling based on state
    Color cardBorderColor = Colors.transparent;
    Color badgeColor = const Color(0xFFF1F5F9);
    Color badgeTextColor = const Color(0xFF475569);
    String badgeText = '';

    if (isNewItem) {
      // Newly created offline item
      cardBorderColor = const Color(0xFF90CAF9); // Light Blue border
      badgeColor = const Color(0xFFE3F2FD);
      badgeTextColor = const Color(0xFF0D47A1);
      badgeText = 'NEW';
    } else if (hasAdjustment) {
      // Modified item
      cardBorderColor = const Color(0xFFA5D6A7); // Light Green border
      badgeColor = const Color(0xFFE8F5E9);
      badgeTextColor = const Color(0xFF2E7D32);
      badgeText = 'ADJUSTED';
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: cardBorderColor != Colors.transparent 
            ? BorderSide(color: cardBorderColor, width: 1.5)
            : const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openAdjustmentSheet(context, item, isNewItem, adjustment, sync),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Part Name and Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.partName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  if (badgeText.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 4),
              
              // Part Number
              Text(
                'PN: ${item.partNumber ?? "-"}',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              
              // Component Hierarchy Tag
              Text(
                '${item.mainName}${item.subName != null ? ' > ${item.subName}' : ''}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              
              // Bottom Row: Quantities and Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Price
                  Text(
                    'Harga: Rp ${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  
                  // Quantity details
                  Row(
                    children: [
                      if (hasAdjustment && !isNewItem) ...[
                        // Show original system qty crossed out or marked
                        // Wait, to calculate original system qty, we extract it.
                        // Since `item.currentQty` is ALREADY updated with `adjustment.physicalQty` in blended inventory,
                        // we need to calculate the system quantity by working backward:
                        // `systemQty = physicalQty - qtyChange`
                        Text(
                          'Sistem: ${(adjustment.physicalQty - adjustment.qtyChange).toStringAsRegExp()} ${item.satuan}  ➔  ',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      Text(
                        'Fisik: ${item.currentQty.toStringAsRegExp()} ${item.satuan}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: hasAdjustment ? const Color(0xFF2E7D32) : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Display remarks/notes if adjustment exists
              if (hasAdjustment && adjustment.keterangan.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notes_rounded, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          adjustment.keterangan,
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  // Bottom Sheet for Adjusting Items
  void _openAdjustmentSheet(
    BuildContext context, 
    InventoryItem item, 
    bool isNewItem, 
    Adjustment? adjustment, 
    SyncProvider sync
  ) {
    final physicalQtyController = TextEditingController();
    final keteranganController = TextEditingController();
    final priceController = TextEditingController();

    // Prefill fields
    final double initialSystemQty = isNewItem 
        ? 0.0 
        : (adjustment != null ? (adjustment.physicalQty - adjustment.qtyChange) : item.currentQty);
    
    physicalQtyController.text = (adjustment?.physicalQty ?? initialSystemQty).toStringAsRegExp();
    keteranganController.text = adjustment?.keterangan ?? '';
    priceController.text = (adjustment?.hargaSatuan ?? item.price).toStringAsFixed(0);

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            double currentCount = double.tryParse(physicalQtyController.text) ?? 0.0;
            double delta = currentCount - initialSystemQty;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Penyesuaian Stok',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Item info summary
                      Text(
                        item.partName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D47A1)),
                      ),
                      if (item.partNumber != null && item.partNumber!.isNotEmpty)
                        Text('Part Number: ${item.partNumber}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      Text(
                        'Komponen: ${item.mainName}${item.subName != null ? ' > ${item.subName}' : ''}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      const SizedBox(height: 16),

                      // Input: Physical Quantity Counted
                      TextFormField(
                        controller: physicalQtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Jumlah Fisik di Kapal',
                          suffixText: item.satuan,
                          helperText: isNewItem 
                              ? 'Item baru. Stok awal akan diatur.' 
                              : 'Stok Sistem: ${initialSystemQty.toStringAsRegExp()} ${item.satuan}',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Jumlah fisik wajib diisi';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Harus berupa angka valid';
                          }
                          if (double.parse(value) < 0) {
                            return 'Jumlah tidak boleh kurang dari 0';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          setSheetState(() {
                            currentCount = double.tryParse(val) ?? 0.0;
                            delta = currentCount - initialSystemQty;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Real-time calculated delta indicator (Only for existing items)
                      if (!isNewItem)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: delta == 0
                                ? const Color(0xFFF1F5F9)
                                : (delta > 0 ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Selisih Penyesuaian:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              Text(
                                '${delta >= 0 ? '+' : ''}${delta.toStringAsRegExp()} ${item.satuan}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: delta == 0
                                      ? const Color(0xFF475569)
                                      : (delta > 0 ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Input: Unit Price
                      TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga Satuan (Rupiah)',
                          prefixText: 'Rp ',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          if (double.tryParse(value) == null) return 'Harus berupa angka';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Input: Remarks / Keterangan (e.g. why changed)
                      TextFormField(
                        controller: keteranganController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan (Contoh: Barang Rusak/Hilang)',
                          hintText: 'Tulis alasan penyesuaian stok di sini...',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          // Revert/Delete Button if adjustment already existed
                          if (adjustment != null) ...[
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                sync.deleteAdjustment(adjustment.id!, widget.vessel.id).then((_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Penyesuaian stok dibatalkan')),
                                  );
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC62828), // Red context CTA
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Icon(Icons.delete_outline_rounded),
                            ),
                            const SizedBox(width: 12),
                          ],
                          
                          // Save Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (!formKey.currentState!.validate()) return;
                                
                                final double physical = double.parse(physicalQtyController.text);
                                final double price = double.tryParse(priceController.text) ?? item.price;
                                
                                final newAdj = Adjustment(
                                  id: adjustment?.id, // Keep local PK if editing
                                  vesselId: widget.vessel.id,
                                  inventoryId: isNewItem ? null : item.id,
                                  isExisting: !isNewItem,
                                  qtyChange: isNewItem ? physical : (physical - initialSystemQty),
                                  physicalQty: physical,
                                  hargaSatuan: price,
                                  keterangan: keteranganController.text,
                                  partName: isNewItem ? item.partName : '',
                                  partNumber: isNewItem ? item.partNumber : null,
                                  satuan: isNewItem ? item.satuan : 'PCS',
                                  mainComponentId: isNewItem ? item.mainComponentId : 0,
                                  subComponentId: isNewItem ? item.subComponentId : null,
                                );
                                
                                sync.saveAdjustment(newAdj).then((_) {
                                  if (context.mounted) {
                                    Navigator.pop(context); // Close the sheet only on success
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Penyesuaian berhasil disimpan lokal'),
                                        backgroundColor: Color(0xFF2E7D32), // Green CTA
                                      ),
                                    );
                                  }
                                }).catchError((error) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal menyimpan: $error'),
                                        backgroundColor: const Color(0xFFC62828), // Red error
                                      ),
                                    );
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32), // Green CTA for saving
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Simpan Penyesuaian'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Extension to clean decimal points in quantities
extension DoubleExtension on double {
  String toStringAsRegExp() {
    return this.toString().replaceAll(RegExp(r'\.0$'), '');
  }
}
