import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/task.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _apiService = ApiService();
  Map<String, dynamic>? _projectData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProject();
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
void _logError(String message, dynamic error) {
  debugPrint('ProjectDetailScreen Error: $message');
  debugPrint('Error details: $error');
}