class Adjustment {
  final int? id; // local auto-increment PK
  final int vesselId;
  final int? inventoryId; // null for newly created items
  final bool isExisting;  // true for existing item, false for new item
  final double qtyChange;
  final double physicalQty; // user-entered count
  final double hargaSatuan;
  final String keterangan;
  
  // For new items only (isExisting == false)
  final String partName;
  final String? partNumber;
  final String satuan;
  final int mainComponentId;
  final int? subComponentId;
  final String? newMainComponent; // For creating new component offline
  final String? newSubComponent;

  final bool isSynced;
  final String? syncError;
  final DateTime createdAt;

  Adjustment({
    this.id,
    required this.vesselId,
    this.inventoryId,
    required this.isExisting,
    required this.qtyChange,
    required this.physicalQty,
    required this.hargaSatuan,
    required this.keterangan,
    this.partName = '',
    this.partNumber,
    this.satuan = 'PCS',
    this.mainComponentId = 0,
    this.subComponentId,
    this.newMainComponent,
    this.newSubComponent,
    this.isSynced = false,
    this.syncError,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory Adjustment.fromMap(Map<String, dynamic> map) {
    return Adjustment(
      id: map['id'],
      vesselId: map['vessel_id'],
      inventoryId: map['inventory_id'],
      isExisting: map['is_existing'] == 1,
      qtyChange: double.parse(map['qty_change'].toString()),
      physicalQty: double.parse(map['physical_qty'].toString()),
      hargaSatuan: double.parse(map['harga_satuan'].toString()),
      keterangan: map['keterangan'] ?? '',
      partName: map['part_name'] ?? '',
      partNumber: map['part_number'],
      satuan: map['satuan'] ?? 'PCS',
      mainComponentId: map['main_component_id'] ?? 0,
      subComponentId: map['sub_component_id'],
      newMainComponent: map['new_main_component'],
      newSubComponent: map['new_sub_component'],
      isSynced: map['is_synced'] == 1,
      syncError: map['sync_error'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString()) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vessel_id': vesselId,
      'inventory_id': inventoryId,
      'is_existing': isExisting ? 1 : 0,
      'qty_change': qtyChange,
      'physical_qty': physicalQty,
      'harga_satuan': hargaSatuan,
      'keterangan': keterangan,
      'part_name': partName,
      'part_number': partNumber,
      'satuan': satuan,
      'main_component_id': mainComponentId,
      'sub_component_id': subComponentId,
      'new_main_component': newMainComponent,
      'new_sub_component': newSubComponent,
      'is_synced': isSynced ? 1 : 0,
      'sync_error': syncError,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // To send to API /submit_adjustment.php
  Map<String, dynamic> toApiJson() {
    final Map<String, dynamic> data = {
      'vessel_id': vesselId,
      'is_existing': isExisting ? 1 : 0,
      'qty_change': qtyChange,
      'harga_satuan': hargaSatuan,
      'keterangan': keterangan,
    };

    if (isExisting) {
      data['inventory_id'] = inventoryId;
    } else {
      data['part_name'] = partName;
      data['part_number'] = partNumber ?? '';
      data['satuan'] = satuan;
      data['main_component_id'] = mainComponentId;
      if (subComponentId != null) {
        data['sub_component_id'] = subComponentId;
      }
    }

    return data;
  }
}
