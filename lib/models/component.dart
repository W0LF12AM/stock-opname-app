class MainComponent {
  final int id;
  final int vesselId;
  final String componentName;

  MainComponent({
    required this.id,
    required this.vesselId,
    required this.componentName,
  });

  factory MainComponent.fromJson(Map<String, dynamic> json, int vesselId) {
    return MainComponent(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      vesselId: vesselId,
      componentName: json['component_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vessel_id': vesselId,
      'component_name': componentName,
    };
  }
}

class SubComponent {
  final int id;
  final int mainComponentId;
  final String subComponentName;

  SubComponent({
    required this.id,
    required this.mainComponentId,
    required this.subComponentName,
  });

  factory SubComponent.fromJson(Map<String, dynamic> json) {
    return SubComponent(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      mainComponentId: json['main_component_id'] is int
          ? json['main_component_id']
          : int.parse(json['main_component_id'].toString()),
      subComponentName: json['sub_component_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'main_component_id': mainComponentId,
      'sub_component_name': subComponentName,
    };
  }
}
