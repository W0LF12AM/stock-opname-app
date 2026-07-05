class InventoryItem {
  final int id;
  final int vesselId;
  final String partName;
  final String? partNumber;
  final String satuan;
  final double currentQty;
  final double price;
  final int mainComponentId;
  final int? subComponentId;
  final String mainName;
  final String? subName;

  InventoryItem({
    required this.id,
    required this.vesselId,
    required this.partName,
    this.partNumber,
    required this.satuan,
    required this.currentQty,
    required this.price,
    required this.mainComponentId,
    this.subComponentId,
    required this.mainName,
    this.subName,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json, int vesselId) {
    return InventoryItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      vesselId: vesselId,
      partName: json['part_name'] ?? '',
      partNumber: json['part_number'],
      satuan: json['satuan'] ?? 'PCS',
      currentQty: json['current_qty'] != null
          ? double.parse(json['current_qty'].toString())
          : 0.0,
      price: json['price'] != null
          ? double.parse(json['price'].toString())
          : 0.0,
      mainComponentId: json['main_component_id'] is int
          ? json['main_component_id']
          : int.parse(json['main_component_id'].toString()),
      subComponentId: json['sub_component_id'] != null
          ? (json['sub_component_id'] is int
              ? json['sub_component_id'] as int
              : int.tryParse(json['sub_component_id'].toString()))
          : null,
      mainName: json['main_name'] ?? '',
      subName: json['sub_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vessel_id': vesselId,
      'part_name': partName,
      'part_number': partNumber,
      'satuan': satuan,
      'current_qty': currentQty,
      'price': price,
      'main_component_id': mainComponentId,
      'sub_component_id': subComponentId,
      'main_name': mainName,
      'sub_name': subName,
    };
  }
}
