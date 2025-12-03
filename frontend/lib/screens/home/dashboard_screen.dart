import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  final _authService = AuthService();
  User? _currentUser;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _authService.getCurrentUser();
      final stats = await _apiService.getDashboardStats();

      if (mounted) {
        setState(() {
          _currentUser = user;
          _stats = stats;
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    // Determine which dashboard to show based on user role
    if (_currentUser?.hasRole('admin') ?? false) {
      return _buildAdminDashboard();
    } else if (_currentUser?.hasRole('manager') ?? false) {
      return _buildManagerDashboard();
    } else {
      return _buildEmployeeDashboard();
    }
  }

  Widget _buildAdminDashboard() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 16),
            Text(
              'Overview',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Overview stats grid
            _buildStatsGrid([
              _StatItem(
                icon: Icons.people,
                title: 'Users',
                value: '${_stats?['total_users'] ?? 0}',
                color: Colors.blue,
              ),
              _StatItem(
                icon: Icons.folder,
                title: 'Projects',
                value: '${_stats?['total_projects'] ?? 0}',
                color: Colors.purple,
              ),
              _StatItem(
                icon: Icons.task,
                title: 'Tasks',
                value: '${_stats?['total_tasks'] ?? 0}',
                color: Colors.orange,
              ),
              _StatItem(
                icon: Icons.check_circle,
                title: 'Done',
                value: '${_stats?['completed_tasks'] ?? 0}',
                color: Colors.green,
              ),
            ]),
            const SizedBox(height: 16),
            // System status section
            Text(
              'System Status',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStatusCards(),
            const SizedBox(height: 16),
            _buildQuickActionsAdmin(),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerDashboard() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 16),
            Text(
              'My Projects Overview',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildStatsGrid([
              _StatItem(
                icon: Icons.folder,
                title: 'My Projects',
                value: '${_stats?['my_projects'] ?? 0}',
                color: Colors.purple,
              ),
              _StatItem(
                icon: Icons.play_circle,
                title: 'Active Projects',
                value: '${_stats?['active_projects'] ?? 0}',
                color: Colors.green,
              ),
              _StatItem(
                icon: Icons.task,
                title: 'Total Tasks',
                value: '${_stats?['total_tasks'] ?? 0}',
                color: Colors.orange,
              ),
              _StatItem(
                icon: Icons.people,
                title: 'Team Members',
                value: '${_stats?['team_members'] ?? 0}',
                color: Colors.blue,
              ),
            ]),
            const SizedBox(height: 16),
            Text(
              'Task Progress',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTaskProgressCard(),
            const SizedBox(height: 16),
            _buildQuickActionsManager(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeDashboard() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 16),
            Text(
              'Tasks Overview',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildStatsGrid([
              _StatItem(
                icon: Icons.task,
                title: 'Tasks',
                value: '${_stats?['my_tasks'] ?? 0}',
                color: Colors.blue,
              ),
              _StatItem(
                icon: Icons.pending,
                title: 'Pending',
                value: '${_stats?['pending_tasks'] ?? 0}',
                color: Colors.orange,
              ),
              _StatItem(
                icon: Icons.play_arrow,
                title: 'In Progress',
                value: '${_stats?['in_progress_tasks'] ?? 0}',
                color: Colors.purple,
              ),
              _StatItem(
                icon: Icons.check_circle,
                title: 'Completed',
                value: '${_stats?['completed_tasks'] ?? 0}',
                color: Colors.green,
              ),
            ]),
            const SizedBox(height: 16),
            Text(
              'Task Priority Breakdown',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildPriorityBreakdown(),
            const SizedBox(height: 16),
            _buildQuickActionsEmployee(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white,
              child: Text(
                _currentUser?.name[0].toUpperCase() ?? 'U',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  Text(
                    _currentUser?.name ?? 'User',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: (_currentUser?.roles ?? []).map((role) {
                      return Chip(
                        label: Text(
                          role.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(List<_StatItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 2,
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 24, color: item.color),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    item.value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: item.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCards() {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: Card(
              color: Colors.green.shade50,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 24,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'System Healthy',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              color: Colors.blue.shade50,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud, color: Colors.blue.shade700, size: 24),
                    const SizedBox(height: 6),
                    Text(
                      'Services Up',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskProgressCard() {
    final total = _stats?['total_tasks'] ?? 1;
    final completed = _stats?['completed_tasks'] ?? 0;
    final inProgress = _stats?['in_progress_tasks'] ?? 0;
    final pending = _stats?['pending_tasks'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressItem('Completed', completed, total, Colors.green),
            const SizedBox(height: 12),
            _buildProgressItem('In Progress', inProgress, total, Colors.blue),
            const SizedBox(height: 12),
            _buildProgressItem('Pending', pending, total, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total * 100).toInt() : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('$value / $total ($percentage%)'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: total > 0 ? value / total : 0,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildPriorityBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPriorityItem(
              'High Priority',
              _stats?['high_priority_tasks'] ?? 0,
              Colors.red,
            ),
            const Divider(),
            _buildPriorityItem(
              'Medium Priority',
              _stats?['medium_priority_tasks'] ?? 0,
              Colors.orange,
            ),
            const Divider(),
            _buildPriorityItem(
              'Low Priority',
              _stats?['low_priority_tasks'] ?? 0,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsAdmin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.0,
          children: [
            _buildActionCard(
              'Manage Users',
              Icons.people_alt,
              Colors.blue,
              () => Navigator.pushNamed(context, '/admin/users'),
            ),
            _buildActionCard(
              'System Health',
              Icons.health_and_safety,
              Colors.green,
              () => Navigator.pushNamed(context, '/admin/health'),
            ),
            _buildActionCard(
              'View Logs',
              Icons.article,
              Colors.orange,
              () => Navigator.pushNamed(context, '/admin/logs'),
            ),
            _buildActionCard(
              'All Projects',
              Icons.folder,
              Colors.purple,
              () => Navigator.pushNamed(context, '/projects'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsManager() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.0,
          children: [
            _buildActionCard(
              'My Projects',
              Icons.folder,
              Colors.purple,
              () => Navigator.pushNamed(context, '/projects'),
            ),
            _buildActionCard(
              'Create Project',
              Icons.add_circle,
              Colors.green,
              () => Navigator.pushNamed(context, '/create-project'),
            ),
            _buildActionCard(
              'All Tasks',
              Icons.task,
              Colors.orange,
              () => Navigator.pushNamed(context, '/tasks'),
            ),
            _buildActionCard(
              'Team Members',
              Icons.people,
              Colors.blue,
              () => Navigator.pushNamed(context, '/team'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsEmployee() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.0,
          children: [
            _buildActionCard(
              'Tasks',
              Icons.task,
              Colors.blue,
              () => Navigator.pushNamed(context, '/tasks'),
            ),
            _buildActionCard(
              'Projects',
              Icons.folder,
              Colors.purple,
              () => Navigator.pushNamed(context, '/projects'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  _StatItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
}
