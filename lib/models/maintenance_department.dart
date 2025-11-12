// lib/models/maintenance_department.dart

class MaintenanceDepartment {
  int? id;
  String name;
  String? description;
  DateTime createdAt;

  MaintenanceDepartment({
    this.id,
    required this.name,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MaintenanceDepartment.fromMap(Map<String, dynamic> map) {
    return MaintenanceDepartment(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
