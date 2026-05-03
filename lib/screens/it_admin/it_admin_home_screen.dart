import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/password_policy_model.dart';
import '../../../models/login_attempt_model.dart';
import '../../../models/auth_credentials_model.dart';

class ItAdminHomeScreen extends ConsumerStatefulWidget {
  const ItAdminHomeScreen({super.key});

  @override
  ConsumerState<ItAdminHomeScreen> createState() => _ItAdminHomeScreenState();
}

class _ItAdminHomeScreenState extends ConsumerState<ItAdminHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IT Admin Portal (Security & Auth)'),
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
                  icon: Icon(Icons.security),
                  selectedIcon: Icon(Icons.security),
                  label: Text('Policy')),
              NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Auth Directory')),
              NavigationRailDestination(
                  icon: Icon(Icons.list_alt),
                  selectedIcon: Icon(Icons.list_alt),
                  label: Text('Audit Logs')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                _PolicyTab(),
                _AuthDirectoryTab(),
                _AuditLogTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyTab extends ConsumerStatefulWidget {
  const _PolicyTab();

  @override
  ConsumerState<_PolicyTab> createState() => _PolicyTabState();
}

class _PolicyTabState extends ConsumerState<_PolicyTab> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  final _minLenCtrl = TextEditingController();
  final _maxLenCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  final _histCtrl = TextEditingController();
  final _attemptsCtrl = TextEditingController();
  final _lockCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPolicy();
  }

  Future<void> _loadPolicy() async {
    final policy = await ref.read(authServiceProvider).getPasswordPolicy();
    _minLenCtrl.text = policy.minLength.toString();
    _maxLenCtrl.text = policy.maxLength.toString();
    _catCtrl.text = policy.minCategories.toString();
    _histCtrl.text = policy.historyCount.toString();
    _attemptsCtrl.text = policy.maxFailedAttempts.toString();
    _lockCtrl.text = policy.lockoutDurationMinutes.toString();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _savePolicy() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final policy = PasswordPolicyModel(
      minLength: int.parse(_minLenCtrl.text),
      maxLength: int.parse(_maxLenCtrl.text),
      minCategories: int.parse(_catCtrl.text),
      historyCount: int.parse(_histCtrl.text),
      maxFailedAttempts: int.parse(_attemptsCtrl.text),
      lockoutDurationMinutes: int.parse(_lockCtrl.text),
    );

    await ref.read(authServiceProvider).savePasswordPolicy(policy);
    ref.invalidate(passwordPolicyProvider); // Refresh provider cache

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password Policy updated successfully.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Global Password Policy',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                      'These rules apply globally to all users when changing passwords or recovering accounts.',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 32),
                  const Text('Password Complexity',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                          child: TextFormField(
                              controller: _minLenCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Min Length'),
                              keyboardType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: TextFormField(
                              controller: _maxLenCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Max Length'),
                              keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _catCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Min Character Categories (1-4)'),
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 32),
                  const Text('Security Restrictions',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  TextFormField(
                      controller: _histCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Password History Memory (Count)'),
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: TextFormField(
                              controller: _attemptsCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Max Failed Login Attempts'),
                              keyboardType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: TextFormField(
                              controller: _lockCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Lockout Duration (Minutes)'),
                              keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _savePolicy,
                    child: const Text('Save Policy Configuration'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthDirectoryTab extends ConsumerStatefulWidget {
  const _AuthDirectoryTab();

  @override
  ConsumerState<_AuthDirectoryTab> createState() => _AuthDirectoryTabState();
}

class _AuthDirectoryTabState extends ConsumerState<_AuthDirectoryTab> {
  List<AuthCredentialsModel> _creds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await ref.read(authServiceProvider).getAllCredentials();
    if (mounted) {
      setState(() {
        _creds = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              const Text('Authentication Directory',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _creds.length,
            itemBuilder: (context, index) {
              final c = _creds[index];
              return ListTile(
                leading: Icon(Icons.security,
                    color: AppTheme.authLevelColor(c.authLevel)),
                title: Text(c.personId,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    'Auth Level: ${c.authLevel} | Failed Attempts: ${c.failedAttempts}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (c.accountLocked)
                      const Chip(
                          label: Text('LOCKED'), backgroundColor: Colors.red),
                    if (c.isFirstLogin)
                      const Chip(
                          label: Text('Must Reset PW'),
                          backgroundColor: Colors.orange),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => context
                    .push(
                        AppRoutes.userAuthDetails.replaceAll(':id', c.personId))
                    .then((_) => _loadData()),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AuditLogTab extends ConsumerStatefulWidget {
  const _AuditLogTab();

  @override
  ConsumerState<_AuditLogTab> createState() => _AuditLogTabState();
}

class _AuditLogTabState extends ConsumerState<_AuditLogTab> {
  List<LoginAttemptModel> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list =
        await ref.read(auditServiceProvider).getAllRecentAttempts(limit: 100);
    if (mounted) {
      setState(() {
        _logs = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              const Text('Recent Auth Audit Logs',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = _logs[index];
              final dt = DateTime.parse(log.timestamp).toLocal();
              return ListTile(
                leading: Icon(
                  log.success ? Icons.check_circle : Icons.error,
                  color: log.success ? Colors.green : Colors.red,
                ),
                title: Text(log.personId,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(dt)),
                trailing: log.success
                    ? const Text('SUCCESS',
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold))
                    : Text(log.failureReason ?? 'FAILED',
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
      ],
    );
  }
}
