import 'package:flutter/material.dart';
import '../projects/projects_screen.dart';
import 'dashboard_screen.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../models/task.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  User? _currentUser;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProjectsScreen(),
    const EnhancedTasksTab(),
  ];

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Confirm Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  void _showSearchDialog() {
    showDialog(context: context, builder: (context) => const SearchDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text(
          'ACP Project',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 24),
            onPressed: _showSearchDialog,
            tooltip: 'Search',
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_rounded, size: 24),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(color: Colors.white, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Notifications coming soon'),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.deepPurple,
            unselectedItemColor: Colors.grey.shade600,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_outlined),
                activeIcon: Icon(Icons.folder),
                label: 'Projects',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.task_outlined),
                activeIcon: Icon(Icons.task),
                label: 'Tasks',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final isAdmin = _currentUser?.hasRole('admin') ?? false;
    final isManager = _currentUser?.hasRole('manager') ?? false;

    return Drawer(
      child: Column(
        children: [
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade400,
                  Colors.deepPurple.shade700,
                  Colors.deepPurple.shade900,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text(
                        _currentUser?.name[0].toUpperCase() ?? 'U',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentUser?.name ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUser?.email ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_currentUser?.roles != null)
                      Wrap(
                        spacing: 6,
                        children: _currentUser!.roles.map((role) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Main Navigation
                _buildDrawerItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  isSelected: _currentIndex == 0,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 0);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.folder_rounded,
                  title: 'Projects',
                  isSelected: _currentIndex == 1,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 1);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.task_rounded,
                  title: 'Tasks',
                  isSelected: _currentIndex == 2,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 2);
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(thickness: 1),
                ),

                // Admin Section
                if (isAdmin) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'ADMIN PANEL',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_rounded,
                    title: 'User Management',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/admin/users');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.health_and_safety_rounded,
                    title: 'System Health',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/admin/health');
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(thickness: 1),
                  ),
                ],

                // Manager Section
                if (isManager) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'MANAGER',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.add_circle_rounded,
                    title: 'Create Project',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/create-project');
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(thickness: 1),
                  ),
                ],

                // Other Options
                _buildDrawerItem(
                  icon: Icons.person_rounded,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Profile screen coming soon'),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Settings screen coming soon'),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Logout Section
          Container(
            margin: const EdgeInsets.all(16),
            child: Material(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _handleLogout,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.red.shade700,
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? Colors.deepPurple.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.deepPurple
                        : Colors.grey.shade800,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Enhanced Tasks Tab with Search functionality
class EnhancedTasksTab extends StatefulWidget {
  const EnhancedTasksTab({super.key});

  @override
  State<EnhancedTasksTab> createState() => _EnhancedTasksTabState();
}

class _EnhancedTasksTabState extends State<EnhancedTasksTab> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tasks = await _apiService.getTasks();
      if (mounted) {
        setState(() {
          _allTasks = tasks;
          _filteredTasks = tasks;
          _isLoading = false;
        });
        _applyFilters();
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

  void _applyFilters() {
    List<Task> filtered = _allTasks;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (task) =>
                task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                task.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Apply status filter
    if (_selectedFilter != 'all') {
      filtered = filtered
          .where((task) => task.status == _selectedFilter)
          .toList();
    }

    setState(() {
      _filteredTasks = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFilters();
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

  Color _getStatusColor(String status) {
    switch (status) {
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
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey.shade600,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', 'pending'),
                      const SizedBox(width: 8),
                      _buildFilterChip('In Progress', 'in-progress'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Completed', 'completed'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tasks List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorState()
                : _filteredTasks.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = _filteredTasks[index];
                        return _buildTaskCard(task);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.deepPurple,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => _onFilterChanged(value),
      selectedColor: Colors.deepPurple,
      backgroundColor: Colors.deepPurple.withOpacity(0.1),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected
            ? Colors.deepPurple
            : Colors.deepPurple.withOpacity(0.3),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).pushNamed(
            '/task-detail',
            arguments: {'projectId': task.projectId, 'taskId': task.id},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.statusDisplay,
                      style: TextStyle(
                        color: _getStatusColor(task.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (task.dueDate != null) ...[
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.dueDate!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTasks,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'all'
                  ? 'No tasks found'
                  : 'No tasks available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'all'
                  ? 'Try adjusting your search or filter criteria'
                  : 'Tasks will appear here once created',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (_searchQuery.isNotEmpty || _selectedFilter != 'all') ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                  _onFilterChanged('all');
                },
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Search Dialog Widget
class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final _searchController = TextEditingController();
  final _apiService = ApiService();

  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  String _searchType = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      List<dynamic> results = [];

      if (_searchType == 'all' || _searchType == 'projects') {
        final projects = await _apiService.getProjects();
        final filteredProjects = projects
            .where(
              (project) =>
                  project.name.toLowerCase().contains(query.toLowerCase()) ||
                  project.description.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
        results.addAll(
          filteredProjects.map((p) => {'type': 'project', 'data': p}),
        );
      }

      if (_searchType == 'all' || _searchType == 'tasks') {
        final tasks = await _apiService.getTasks();
        final filteredTasks = tasks
            .where(
              (task) =>
                  task.title.toLowerCase().contains(query.toLowerCase()) ||
                  task.description.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
        results.addAll(filteredTasks.map((t) => {'type': 'task', 'data': t}));
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Search',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _performSearch,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search projects, tasks...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Search Type Chips
            Row(
              children: [
                _buildSearchTypeChip('All', 'all'),
                const SizedBox(width: 8),
                _buildSearchTypeChip('Projects', 'projects'),
                const SizedBox(width: 8),
                _buildSearchTypeChip('Tasks', 'tasks'),
              ],
            ),
            const SizedBox(height: 16),

            // Search Results
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Start typing to search'
                                : 'No results found',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return _buildSearchResultItem(item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTypeChip(String label, String value) {
    final isSelected = _searchType == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.deepPurple,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _searchType = value;
        });
        _performSearch(_searchController.text);
      },
      selectedColor: Colors.deepPurple,
      backgroundColor: Colors.deepPurple.withOpacity(0.1),
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> item) {
    final type = item['type'];
    final data = item['data'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: type == 'project' ? Colors.purple : Colors.blue,
          child: Icon(
            type == 'project' ? Icons.folder : Icons.task,
            color: Colors.white,
          ),
        ),
        title: Text(
          type == 'project' ? data.name : data.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          data.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {
          Navigator.pop(context);
          if (type == 'project') {
            Navigator.pushNamed(context, '/project-detail', arguments: data.id);
          } else {
            Navigator.pushNamed(
              context,
              '/task-detail',
              arguments: {'projectId': data.projectId, 'taskId': data.id},
            );
          }
        },
      ),
    );
  }
}
