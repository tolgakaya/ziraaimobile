class PlantTreatment {
  final String? name;
  final String? type;
  final String? description;
  final String? applicationMethod;
  final List<String>? products;
  final String? frequency;
  final String? duration;
  final String? priority;
  final List<String>? precautions;
  final String? instructions;

  PlantTreatment({
    this.name,
    this.type,
    this.description,
    this.applicationMethod,
    this.products,
    this.frequency,
    this.duration,
    this.priority,
    this.precautions,
    this.instructions,
  });

  factory PlantTreatment.fromJson(Map<String, dynamic> json) {
    return PlantTreatment(
      name: json['name'] as String?,
      type: json['type'] as String?,
      description: json['description'] ?? json['instructions'] as String?,
      applicationMethod: json['applicationMethod'] as String?,
      products: (json['products'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      frequency: json['frequency'] as String?,
      duration: json['duration'] as String?,
      priority: json['priority'] as String?,
      precautions: (json['precautions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      instructions: json['instructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'description': description,
      'applicationMethod': applicationMethod,
      'products': products,
      'frequency': frequency,
      'duration': duration,
      'priority': priority,
      'precautions': precautions,
      'instructions': instructions,
    };
  }
}