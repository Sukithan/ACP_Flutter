import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _error;
  String _filterLevel = 'all';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logs = await _apiService.getSystemLogs();
      if (mounted) {
        setState(() {
          _logs = logs;
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

  List<Map<String, dynamic>> get _filteredLogs {
    if (_filterLevel == 'all') {
      return _logs;
    }
    return _logs
        .where(
          (log) =>
              log['level']?.toString().toLowerCase() ==
              _filterLevel.toLowerCase(),
        )
        .toList();
  }

  Color _getLevelColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      case 'debug':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getLevelIcon(String? level) {
    switch (level?.toLowerCase()) {
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      case 'debug':
        return Icons.bug_report;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Logs'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterLevel = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Logs')),
              const PopupMenuItem(value: 'error', child: Text('Errors')),
              const PopupMenuItem(value: 'warning', child: Text('Warnings')),
              const PopupMenuItem(value: 'info', child: Text('Info')),
              const PopupMenuItem(value: 'debug', child: Text('Debug')),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLogs),
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
                    onPressed: _loadLogs,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _filteredLogs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.article, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _filterLevel == 'all'
                        ? 'No logs found'
                        : 'No ${_filterLevel} logs found',
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Filter chip display
                if (_filterLevel != 'all')
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey.shade100,
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Chip(
                          label: Text('Filter: ${_filterLevel.toUpperCase()}'),
                          onDeleted: () {
                            setState(() {
                              _filterLevel = 'all';
                            });
                          },
                        ),
                        const Spacer(),
                        Text(
                          '${_filteredLogs.length} logs',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadLogs,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = _filteredLogs[index];
                        final level = log['level']?.toString();
                        final message = log['message']?.toString() ?? '';
                        final timestamp = log['timestamp']?.toString() ?? '';
                        final context = log['context'];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ExpansionTile(
                            leading: Icon(
                              _getLevelIcon(level),
                              color: _getLevelColor(level),
                            ),
                            title: Text(
                              message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(
                                        level?.toUpperCase() ?? 'LOG',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: _getLevelColor(level),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: EdgeInsets.zero,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        timestamp,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            children: [
                              if (context != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  color: Colors.grey.shade50,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Context:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        context.toString(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
