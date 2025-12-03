import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final String projectId;
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.projectId,
    required this.taskId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _apiService = ApiService();
  Map<String, dynamic>? _taskData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final taskData = await _apiService.getTask(
        widget.projectId,
        widget.taskId,
      );
      if (mounted) {
        setState(() {
          _taskData = taskData;
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

  Future<void> _updateTaskStatus(String newStatus) async {
    try {
      await _apiService.updateTask(
        widget.projectId,
        widget.taskId,
        status: newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Task status updated')));
        _loadTask();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteTask(widget.projectId, widget.taskId);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in-progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTask),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.pushNamed(
                  context,
                  '/edit-task',
                  arguments: {
                    'projectId': widget.projectId,
                    'taskId': widget.taskId,
                  },
                ).then((_) => _loadTask());
              } else if (value == 'delete') {
                _deleteTask();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit Task'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Task', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
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
                    onPressed: _loadTask,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadTask,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Title
                    Text(
                      _taskData!['title'] ?? 'Untitled Task',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Status and Priority Chips
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          avatar: Icon(
                            Icons.circle,
                            size: 12,
                            color: _getStatusColor(_taskData!['status'] ?? ''),
                          ),
                          label: Text(
                            (_taskData!['status'] as String?)
                                    ?.replaceAll('-', ' ')
                                    .toUpperCase() ??
                                'PENDING',
                          ),
                          backgroundColor: _getStatusColor(
                            _taskData!['status'] ?? '',
                          ).withOpacity(0.2),
                        ),
                        Chip(
                          avatar: Icon(
                            Icons.flag,
                            size: 16,
                            color: _getPriorityColor(
                              _taskData!['priority'] ?? '',
                            ),
                          ),
                          label: Text(
                            '${(_taskData!['priority'] as String?)?.toUpperCase() ?? 'MEDIUM'} PRIORITY',
                          ),
                          backgroundColor: _getPriorityColor(
                            _taskData!['priority'] ?? '',
                          ).withOpacity(0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description Section
                    _buildSection(
                      title: 'Description',
                      icon: Icons.description,
                      child: Text(
                        _taskData!['description'] ?? 'No description',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Details Section
                    _buildSection(
                      title: 'Details',
                      icon: Icons.info_outline,
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Assigned To',
                            _taskData!['assigned_to_name'] ?? 'Unassigned',
                            Icons.person,
                          ),
                          const Divider(),
                          _buildDetailRow(
                            'Created By',
                            _taskData!['created_by_name'] ?? 'Unknown',
                            Icons.person_outline,
                          ),
                          const Divider(),
                          _buildDetailRow(
                            'Due Date',
                            _taskData!['due_date'] ?? 'Not set',
                            Icons.calendar_today,
                          ),
                          const Divider(),
                          _buildDetailRow(
                            'Project',
                            _taskData!['project_name'] ?? 'Unknown',
                            Icons.folder,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Status Update Section
                    Text(
                      'Update Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusButton('pending'),
                        _buildStatusButton('in-progress'),
                        _buildStatusButton('completed'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String status) {
    final isCurrentStatus = _taskData!['status'] == status;
    return ElevatedButton.icon(
      onPressed: isCurrentStatus ? null : () => _updateTaskStatus(status),
      icon: Icon(
        isCurrentStatus ? Icons.check_circle : Icons.circle_outlined,
        size: 18,
      ),
      label: Text(status.replaceAll('-', ' ').toUpperCase()),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrentStatus
            ? _getStatusColor(status)
            : _getStatusColor(status).withOpacity(0.2),
        foregroundColor: isCurrentStatus ? Colors.white : Colors.black87,
      ),
    );
  }
}
