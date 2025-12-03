class Project {
  final String id;
  final String name;
  final String description;
  final String status;
  final int createdBy;
  final int assignedManager;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.createdBy,
    required this.assignedManager,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      createdBy: _parseInt(json['created_by']) ?? 0,
      assignedManager: _parseInt(json['assigned_manager']) ?? 0,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'created_by': createdBy,
      'assigned_manager': assignedManager,
    };
  }

  String get statusDisplay {
    return status[0].toUpperCase() + status.substring(1).replaceAll('-', ' ');
  }
}
