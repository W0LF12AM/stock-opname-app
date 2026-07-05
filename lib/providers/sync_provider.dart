import 'package:flutter/material.dart';
import '../models/vessel.dart';
import '../models/inventory_item.dart';
import '../models/component.dart';
import '../models/adjustment.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';

class SyncProvider extends ChangeNotifier {
  final APIService _api = APIService();
  final DBService _db = DBService();

  List<Vessel> _vessels = [];
  List<InventoryItem> _inventory = [];
  List<MainComponent> _mainComponents = [];
  List<SubComponent> _subComponents = [];
  List<Adjustment> _adjustments = [];
  List<Adjustment> _allPendingAdjustments = [];

  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;
  String _downloadProgress = '';

  List<Vessel> get vessels => _vessels;
  List<InventoryItem> get inventory => _inventory;
  List<MainComponent> get mainComponents => _mainComponents;
  List<SubComponent> get subComponents => _subComponents;
  List<Adjustment> get adjustments => _adjustments;
  List<Adjustment> get allPendingAdjustments => _allPendingAdjustments;

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  String get downloadProgress => _downloadProgress;

  SyncProvider() {
    loadAllPendingAdjustments();
  }

  Future<void> loadAllPendingAdjustments() async {
    try {
      _allPendingAdjustments = await _db.getAllPendingAdjustments();
      notifyListeners();
    } catch (_) {}
  }

  // Helper to count pending changes per vessel
  int getPendingCount(int vesselId) {
    return _allPendingAdjustments.where((adj) => adj.vesselId == vesselId && !adj.isSynced).length;
  }

  // ==========================================
  // VESSEL LIST METHODS
  // ==========================================

  Future<void> loadVessels(bool isOnline) async {
    if (_isLoading) return; // Guard: prevent concurrent calls causing SQLite deadlock
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Get locally cached vessels
      final cached = await _db.getCachedVessels();
      
      if (isOnline) {
        // 2. Fetch fresh vessels from API
        final apiVessels = await _api.fetchVessels();
        
        // Merge downloaded status (downloaded_at) from local to API list
        _vessels = apiVessels.map((apiV) {
          final match = cached.where((c) => c.id == apiV.id);
          if (match.isNotEmpty) {
            return Vessel(
              id: apiV.id,
              vesselName: apiV.vesselName,
              vesselType: apiV.vesselType,
              downloadedAt: match.first.downloadedAt,
            );
          }
          return apiV;
        }).toList();
      } else {
        // Offline: Show only cached vessels
        _vessels = cached;
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat daftar kapal: ${e.toString()}';
      // Fallback to cache
      _vessels = await _db.getCachedVessels();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> downloadVesselData(Vessel vessel) async {
    _isLoading = true;
    _errorMessage = null;
    _downloadProgress = 'Menghubungi server...';
    notifyListeners();

    try {
      // Step 1: Fetch inventory items
      _downloadProgress = 'Mengunduh data inventory (${vessel.vesselName})...';
      notifyListeners();
      final items = await _api.fetchInventory(vessel.id);

      // Step 2: Fetch components
      _downloadProgress = 'Mengunduh data komponen...';
      notifyListeners();
      final compData = await _api.fetchComponents(vessel.id);

      final List<dynamic> rawMains = compData['main_components'] ?? [];
      final List<dynamic> rawSubs = compData['sub_components'] ?? [];

      final mainComponents = rawMains.map((item) => MainComponent.fromJson(item, vessel.id)).toList();
      final subComponents = rawSubs.map((item) => SubComponent.fromJson(item)).toList();

      // Step 3: Save to local DB
      _downloadProgress = 'Menyimpan ${items.length} item ke penyimpanan lokal...';
      notifyListeners();
      await _db.saveVesselData(
        vessel: vessel,
        items: items,
        mainComponents: mainComponents,
        subComponents: subComponents,
      );

      // Step 4: Update _vessels list in memory
      _downloadProgress = 'Selesai!';
      notifyListeners();

      final updatedVessel = Vessel(
        id: vessel.id,
        vesselName: vessel.vesselName,
        vesselType: vessel.vesselType,
        downloadedAt: DateTime.now(),
      );
      final idx = _vessels.indexWhere((v) => v.id == vessel.id);
      if (idx != -1) {
        _vessels[idx] = updatedVessel;
      } else {
        _vessels.add(updatedVessel);
      }
    } catch (e) {
      _errorMessage = 'Gagal mengunduh data kapal: ${e.toString()}';
    } finally {
      _isLoading = false;
      _downloadProgress = '';
      notifyListeners();
    }
  }

  // ==========================================
  // WORKSPACE METHODS (INVENTORY STOCKTAKING)
  // ==========================================

  Future<void> loadVesselWorkspace(int vesselId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _inventory = await _db.getInventory(vesselId);
      _mainComponents = await _db.getMainComponents(vesselId);
      _subComponents = await _db.getSubComponents(vesselId);
      _adjustments = await _db.getPendingAdjustments(vesselId);
    } catch (e) {
      _errorMessage = 'Gagal memuat workspace: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveAdjustment(Adjustment adj) async {
    try {
      await _db.saveAdjustment(adj);
      // Reload adjustments & inventory workspace
      _adjustments = await _db.getPendingAdjustments(adj.vesselId);
      await loadAllPendingAdjustments();
    } catch (e) {
      _errorMessage = 'Gagal menyimpan penyesuaian: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAdjustment(int id, int vesselId) async {
    try {
      await _db.deleteAdjustment(id);
      _adjustments = await _db.getPendingAdjustments(vesselId);
      await loadAllPendingAdjustments();
    } catch (e) {
      _errorMessage = 'Gagal menghapus penyesuaian: ${e.toString()}';
      notifyListeners();
    }
  }

  // Blends original inventory items with local unsynced adjustments (edits & new items)
  List<InventoryItem> getBlendedInventory() {
    final List<InventoryItem> list = List.from(_inventory);

    for (final adj in _adjustments) {
      if (adj.isSynced) continue;

      if (adj.isExisting) {
        // Find existing item and update it in list (locally)
        final index = list.indexWhere((item) => item.id == adj.inventoryId);
        if (index != -1) {
          final original = list[index];
          list[index] = InventoryItem(
            id: original.id,
            vesselId: original.vesselId,
            partName: original.partName,
            partNumber: original.partNumber,
            satuan: original.satuan,
            currentQty: adj.physicalQty, // Show adjusted qty
            price: adj.hargaSatuan,
            mainComponentId: original.mainComponentId,
            subComponentId: original.subComponentId,
            mainName: original.mainName,
            subName: original.subName,
          );
        }
      } else {
        // Newly created item: find component names for local display
        final mainComp = _mainComponents.firstWhere(
          (m) => m.id == adj.mainComponentId,
          orElse: () => MainComponent(
            id: adj.mainComponentId,
            vesselId: adj.vesselId,
            componentName: adj.newMainComponent ?? 'Lainnya',
          ),
        );
        final subComp = _subComponents.firstWhere(
          (s) => s.id == adj.subComponentId,
          orElse: () => SubComponent(
            id: adj.subComponentId ?? 0,
            mainComponentId: adj.mainComponentId,
            subComponentName: adj.newSubComponent ?? '',
          ),
        );

        // Add to local display inventory
        list.add(InventoryItem(
          id: -(adj.id ?? 1), // Negative temporary ID to prevent conflicts
          vesselId: adj.vesselId,
          partName: adj.partName,
          partNumber: adj.partNumber,
          satuan: adj.satuan,
          currentQty: adj.physicalQty,
          price: adj.hargaSatuan,
          mainComponentId: adj.mainComponentId,
          subComponentId: adj.subComponentId,
          mainName: adj.newMainComponent ?? mainComp.componentName,
          subName: (adj.newSubComponent != null && adj.newSubComponent!.isNotEmpty)
              ? adj.newSubComponent
              : (subComp.subComponentName.isNotEmpty ? subComp.subComponentName : null),
        ));
      }
    }
    
    // Sort blended inventory by part name
    list.sort((a, b) => a.partName.toLowerCase().compareTo(b.partName.toLowerCase()));
    return list;
  }

  // Returns local adjustment for specific item, if any
  Adjustment? getAdjustmentForItem(int itemId) {
    final matches = _adjustments.where((adj) => adj.isExisting && adj.inventoryId == itemId);
    return matches.isNotEmpty ? matches.first : null;
  }

  // Returns local adjustment for newly created item by temporary negative ID
  Adjustment? getAdjustmentForNewItem(int tempId) {
    final localId = -tempId;
    final matches = _adjustments.where((adj) => !adj.isExisting && adj.id == localId);
    return matches.isNotEmpty ? matches.first : null;
  }

  // ==========================================
  // SYNCHRONIZATION LOOP
  // ==========================================

  Future<bool> syncVesselAdjustments(int vesselId) async {
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    bool allSuccess = true;

    try {
      // 1. Fetch pending adjustments
      final pending = await _db.getPendingAdjustments(vesselId);
      if (pending.isEmpty) {
        _isSyncing = false;
        notifyListeners();
        return true;
      }

      // 2. Submit sequentially
      for (final adj in pending) {
        try {
          await _api.submitAdjustment(adj);
          await _db.markAdjustmentSynced(adj.id!);
        } catch (e) {
          allSuccess = false;
          await _db.markAdjustmentFailed(adj.id!, e.toString());
        }
      }

      // 3. Clear successful syncs from local db (reduces space)
      await _db.clearSyncedAdjustments(vesselId);

      // 4. Reload adjustments from DB to show failures if any
      _adjustments = await _db.getPendingAdjustments(vesselId);

      // 5. If everything synced successfully, automatically download latest database state from server
      if (allSuccess) {
        final vessel = await _db.getCachedVessel(vesselId);
        if (vessel != null) {
          // Re-download latest inventory state
          final freshItems = await _api.fetchInventory(vesselId);
          final compData = await _api.fetchComponents(vesselId);

          final List<dynamic> rawMains = compData['main_components'] ?? [];
          final List<dynamic> rawSubs = compData['sub_components'] ?? [];

          final mainComponents = rawMains.map((item) => MainComponent.fromJson(item, vesselId)).toList();
          final subComponents = rawSubs.map((item) => SubComponent.fromJson(item)).toList();

          await _db.saveVesselData(
            vessel: vessel,
            items: freshItems,
            mainComponents: mainComponents,
            subComponents: subComponents,
          );
          
          // Reload workspace
          _inventory = freshItems;
          _mainComponents = mainComponents;
          _subComponents = subComponents;
        }
      }
    } catch (e) {
      _errorMessage = 'Gagal selama sinkronisasi: ${e.toString()}';
      allSuccess = false;
    } finally {
      _isSyncing = false;
      await loadAllPendingAdjustments();
    }

    return allSuccess;
  }
}
