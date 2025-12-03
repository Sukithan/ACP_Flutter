class Task {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final int assignedTo;
  final String? assignedToName;
  final int createdBy;
  final String? dueDate;
  final String priority;
  final String status;

  Task({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.assignedTo,
    this.assignedToName,
    required this.createdBy,
    this.dueDate,
    required this.priority,
    required this.status,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      assignedTo: _parseInt(json['assigned_to']) ?? 0,
      assignedToName: json['assigned_to_name']?.toString(),
      createdBy: _parseInt(json['created_by']) ?? 0,
      dueDate: json['due_date']?.toString(),
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'pending',
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
      'project_id': projectId,
      'title': title,
      'description': description,
      'assigned_to': assignedTo,
      'assigned_to_name': assignedToName,
      'created_by': createdBy,
      'due_date': dueDate,
      'priority': priority,
      'status': status,
    };
  }

  String get statusDisplay {
    return status[0].toUpperCase() + status.substring(1).replaceAll('-', ' ');
  }

  String get priorityDisplay {
    return priority[0].toUpperCase() + priority.substring(1);
  }
}
