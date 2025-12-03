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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'active',
      createdBy: json['created_by'] ?? 0,
      assignedManager: json['assigned_manager'] ?? 0,
    );
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
