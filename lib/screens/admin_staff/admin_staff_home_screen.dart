import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/person_model.dart';
import '../../../core/constants/app_constants.dart';

class AdminStaffHomeScreen extends ConsumerStatefulWidget {
  const AdminStaffHomeScreen({super.key});

  @override
  ConsumerState<AdminStaffHomeScreen> createState() =>
      _AdminStaffHomeScreenState();
}

class _AdminStaffHomeScreenState extends ConsumerState<AdminStaffHomeScreen> {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();

  List<PersonModel> _searchResults = [];
  bool _isSearching = false;
  Map<String, int> _stats = {};

  String _statusFilter = 'All';
  String _typeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadStats();
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final stats = await ref.read(identityServiceProvider).getDashboardStats();
    if (mounted) setState(() => _stats = stats);
  }

  Future<void> _performSearch() async {
    setState(() => _isSearching = true);
    final results = await ref.read(identityServiceProvider).searchPersons(
          _searchController.text.trim(),
          statusFilter: _statusFilter,
          typeCategory: _typeFilter,
        );
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            childAspectRatio: 2.5,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatCard(
                  title: 'Total Users',
                  value: _stats['total']?.toString() ?? '...',
                  icon: Icons.people,
                  color: Colors.blue),
              _StatCard(
                  title: 'Active',
                  value: _stats['active']?.toString() ?? '...',
                  icon: Icons.check_circle,
                  color: AppTheme.success),
              _StatCard(
                  title: 'Pending',
                  value: _stats['pending']?.toString() ?? '...',
                  icon: Icons.hourglass_empty,
                  color: AppTheme.statusPending),
              _StatCard(
                  title: 'Locked/Suspended',
                  value: _stats['suspended']?.toString() ?? '...',
                  icon: Icons.lock,
                  color: AppTheme.warning),
            ],
          ),
          const SizedBox(height: 32),
          const Text('User Distribution',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _DistributionCard(
                      title: 'Students',
                      count: _stats['students'] ?? 0,
                      icon: Icons.school)),
              const SizedBox(width: 16),
              Expanded(
                  child: _DistributionCard(
                      title: 'Faculty',
                      count: _stats['faculty'] ?? 0,
                      icon: Icons.work)),
              const SizedBox(width: 16),
              Expanded(
                  child: _DistributionCard(
                      title: 'Staff/Admin',
                      count: _stats['staff'] ?? 0,
                      icon: Icons.admin_panel_settings)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagementTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('User Directory',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => context
                    .push(AppRoutes.editUser.replaceAll(':id', 'new'))
                    .then((_) {
                  _loadStats();
                  _performSearch();
                }),
                icon: const Icon(Icons.person_add),
                label: const Text('Create User'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search and Filters
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, ID, or email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch();
                      },
                    ),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    'All',
                    ...[
                      AppConstants.statusPending,
                      AppConstants.statusActive,
                      AppConstants.statusSuspended,
                      AppConstants.statusInactive,
                      AppConstants.statusArchived
                    ]
                  ]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _statusFilter = v!);
                    _performSearch();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _typeFilter,
                  decoration: const InputDecoration(labelText: 'Role Category'),
                  items: [
                    'All',
                    'Student',
                    'Faculty',
                    'Staff',
                    'Contractor',
                    'Alumni'
                  ]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _typeFilter = v!);
                    _performSearch();
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _performSearch,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 24)),
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Results Table
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? const Center(
                        child: Text('No users found matching your criteria.'))
                    : Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListView.separated(
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppTheme.accent.withValues(alpha: 0.2),
                                child: Text(
                                    user.firstName[0] + user.lastName[0],
                                    style: const TextStyle(
                                        color: AppTheme.accent)),
                              ),
                              title: Text(user.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  '${user.uniqueId} • ${user.userType} • ${user.personalEmail}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text(user.status),
                                    backgroundColor:
                                        AppTheme.statusColor(user.status)
                                            .withValues(alpha: 0.1),
                                    labelStyle: TextStyle(
                                        color:
                                            AppTheme.statusColor(user.status),
                                        fontSize: 12),
                                    side: BorderSide.none,
                                    padding: EdgeInsets.zero,
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                              onTap: () => context
                                  .push(AppRoutes.userProfile
                                      .replaceAll(':id', user.uniqueId))
                                  .then((_) {
                                _loadStats();
                                _performSearch();
                              }),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Staff Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (idx) =>
                setState(() => _selectedIndex = idx),
            labelType: NavigationRailLabelType.all,
            backgroundColor: Theme.of(context).colorScheme.surface,
            destinations: const [
              NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard')),
              NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Directory')),
              NavigationRailDestination(
                  icon: Icon(Icons.security),
                  selectedIcon: Icon(Icons.security),
                  label: Text('My Security')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildDashboardTab(),
                _buildUserManagementTab(),
                Center(
                  child: ElevatedButton(
                    onPressed: () => context.push(AppRoutes.changePassword),
                    child: const Text('Change My Password'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const _DistributionCard(
      {required this.title, required this.count, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Text(count.toString(),
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
