class Vessel {
  final int id;
  final String vesselName;
  final String vesselType;
  final DateTime? downloadedAt; // local-only metadata

  Vessel({
    required this.id,
    required this.vesselName,
    required this.vesselType,
    this.downloadedAt,
  });

  factory Vessel.fromJson(Map<String, dynamic> json) {
    return Vessel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      vesselName: json['vessel_name'] ?? '',
      vesselType: json['vessel_type'] ?? '',
      downloadedAt: json['downloaded_at'] != null
          ? DateTime.tryParse(json['downloaded_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vessel_name': vesselName,
      'vessel_type': vesselType,
      'downloaded_at': downloadedAt?.toIso8601String(),
    };
  }
}
