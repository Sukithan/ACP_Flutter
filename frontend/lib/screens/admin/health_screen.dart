import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final _apiService = ApiService();
  Map<String, dynamic>? _healthData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHealth();
  }

  Future<void> _loadHealth() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final healthData = await _apiService.getSystemHealth();
      if (mounted) {
        setState(() {
          _healthData = healthData;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Health'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHealth),
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
                    onPressed: _loadHealth,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadHealth,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall Status Card
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'System Status',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _healthData?['status'] ?? 'Healthy',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Database Status
                    Text(
                      'Database',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: const Icon(Icons.storage, color: Colors.white),
                        ),
                        title: const Text('Database Connection'),
                        subtitle: Text(
                          _healthData?['database']?['status'] ?? 'Connected',
                        ),
                        trailing: Icon(Icons.check_circle, color: Colors.green),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Cache Status
                    Text(
                      'Cache',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: const Icon(
                            Icons.flash_on,
                            color: Colors.white,
                          ),
                        ),
                        title: const Text('Cache System'),
                        subtitle: Text(
                          _healthData?['cache']?['status'] ?? 'Active',
                        ),
                        trailing: Icon(Icons.check_circle, color: Colors.green),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Queue Status
                    Text(
                      'Queue',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: const Icon(Icons.queue, color: Colors.white),
                        ),
                        title: const Text('Queue System'),
                        subtitle: Text(
                          _healthData?['queue']?['status'] ?? 'Running',
                        ),
                        trailing: Icon(Icons.check_circle, color: Colors.green),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // System Info
                    Text(
                      'System Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              'PHP Version',
                              _healthData?['php_version'] ?? 'N/A',
                            ),
                            const Divider(),
                            _buildInfoRow(
                              'Laravel Version',
                              _healthData?['laravel_version'] ?? 'N/A',
                            ),
                            const Divider(),
                            _buildInfoRow(
                              'Environment',
                              _healthData?['environment'] ?? 'production',
                            ),
                            const Divider(),
                            _buildInfoRow(
                              'Uptime',
                              _healthData?['uptime'] ?? 'N/A',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
