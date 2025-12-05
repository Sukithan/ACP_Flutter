import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import '../../models/task.dart';
import 'dart:developer';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _apiService = ApiService();
  final _webSocketService = WebSocketService();
  Map<String, dynamic>? _projectData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProject();
    _initializeProjectRealTimeUpdates();
  }

  Future<void> _initializeProjectRealTimeUpdates() async {
    try {
      await _webSocketService.initialize();

      // Subscribe to this specific project's task updates
      await _webSocketService.subscribeToProjectTaskUpdates(widget.projectId, (
        data,
      ) {
        log('Project task update received: $data');
        if (mounted) {
          _handleProjectTaskUpdate(data);
        }
      });

      // Subscribe to project updates
      await _webSocketService.subscribeToProjectUpdates((data) {
        log('Project update received: $data');
        if (mounted && data['project']?['id'] == widget.projectId) {
          _handleProjectUpdate(data);
        }
      });
    } catch (e) {
      log('Failed to initialize project real-time updates: $e');
    }
  }

  void _handleProjectTaskUpdate(dynamic data) {
    if (data == null || data['project_id'] != widget.projectId) return;

    // Reload project to get updated task list
    _loadProject();

    final action = data['action'] as String?;
    final taskTitle = data['task']?['title'] as String?;

    if (action != null && taskTitle != null) {
      _showTaskUpdateNotification(action, taskTitle);
    }
  }

  void _handleProjectUpdate(dynamic data) {
    if (data == null) return;

    final action = data['action'] as String?;
    final projectData = data['project'] as Map<String, dynamic>?;

    if (projectData != null && projectData['id'] == widget.projectId) {
      // Update project data
      setState(() {
        _projectData = {...?_projectData, ...projectData};
      });

      if (action != null) {
        _showProjectUpdateNotification(action);
      }
    }
  }

  void _showTaskUpdateNotification(String action, String taskTitle) {
    String message;
    switch (action) {
      case 'created':
        message = 'New task "$taskTitle" added to this project';
        break;
      case 'updated':
        message = 'Task "$taskTitle" was updated';
        break;
      case 'status_changed':
        message = 'Task "$taskTitle" status changed';
        break;
      case 'deleted':
        message = 'Task "$taskTitle" was deleted';
        break;
      default:
        message = 'Task "$taskTitle" was modified';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.task_alt, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showProjectUpdateNotification(String action) {
    String message;
    switch (action) {
      case 'updated':
        message = 'This project was updated';
        break;
      default:
        message = 'This project was modified';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.sync, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadProject() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final projectData = await _apiService.getProject(widget.projectId);
      if (mounted) {
        setState(() {
          _projectData = projectData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'on-hold':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProject),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProject,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProject,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Info Card
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _projectData!['name'] ?? 'Unknown Project',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _projectData!['description'] ?? '',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            Chip(
                              label: Text(
                                (_projectData!['status'] as String?)
                                        ?.replaceAll('-', ' ')
                                        .toUpperCase() ??
                                    'UNKNOWN',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: _getStatusColor(
                                _projectData!['status'] ?? '',
                              ).withOpacity(0.2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Tasks Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tasks',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed(
                                    '/create-task',
                                    arguments: widget.projectId,
                                  )
                                  .then((_) => _loadProject());
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Task'),
                          ),
                        ],
                      ),
                    ),
                    _projectData!['tasks'] == null ||
                            (_projectData!['tasks'] as List).isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.task_alt,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text('No tasks yet'),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: (_projectData!['tasks'] as List).length,
                            itemBuilder: (context, index) {
                              final taskData =
                                  (_projectData!['tasks'] as List)[index];
                              final task = Task.fromJson(taskData);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getPriorityColor(
                                      task.priority,
                                    ),
                                    child: Text(
                                      task.priority[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    task.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(task.description, maxLines: 1),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Chip(
                                            label: Text(
                                              task.statusDisplay,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          if (task.assignedToName != null) ...[
                                            const SizedBox(width: 8),
                                            Icon(Icons.person, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              task.assignedToName!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pushNamed(
                                      '/task-detail',
                                      arguments: {
                                        'projectId': widget.projectId,
                                        'taskId': task.id,
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
