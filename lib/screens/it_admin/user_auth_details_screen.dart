import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/auth_credentials_model.dart';
import '../../../models/mfa_methods_model.dart';
import '../../../models/login_attempt_model.dart';
import '../../../core/theme/app_theme.dart';

class UserAuthDetailsScreen extends ConsumerStatefulWidget {
  final String personId;
  const UserAuthDetailsScreen({super.key, required this.personId});

  @override
  ConsumerState<UserAuthDetailsScreen> createState() =>
      _UserAuthDetailsScreenState();
}

class _UserAuthDetailsScreenState extends ConsumerState<UserAuthDetailsScreen> {
  bool _isLoading = true;
  AuthCredentialsModel? _creds;
  MfaMethodsModel? _mfa;
  List<LoginAttemptModel> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authService = ref.read(authServiceProvider);
    final auditService = ref.read(auditServiceProvider);

    final creds = await authService.getCredentials(widget.personId);
    if (creds == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Credentials not found')));
        context.pop();
      }
      return;
    }

    final mfa = await authService.getMfaMethods(widget.personId);
    final logs = await auditService.getLoginAttempts(widget.personId);

    if (mounted) {
      setState(() {
        _creds = creds;
        _mfa = mfa;
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  Future<void> _unlockAccount() async {
    setState(() => _isLoading = true);
    await ref.read(authServiceProvider).unlockAccount(widget.personId);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Account unlocked.')));
    }
  }

  Future<void> _forcePasswordReset() async {
    setState(() => _isLoading = true);
    await ref.read(authServiceProvider).forcePasswordReset(widget.personId);
    await ref.read(authServiceProvider).invalidateAllSessions(widget.personId);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password reset forced. Active sessions terminated.')));
    }
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 140,
              child: Text(label,
                  style: const TextStyle(color: AppTheme.textSecondary))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: valueColor))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _creds == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final c = _creds!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Auth Details: ${widget.personId}'),
        actions: [
          if (c.accountLocked)
            ElevatedButton.icon(
              onPressed: _unlockAccount,
              icon: const Icon(Icons.lock_open),
              label: const Text('Unlock Account'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _forcePasswordReset,
            icon: const Icon(Icons.password),
            label: const Text('Force Reset'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Credentials & MFA
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.security,
                                  color: AppTheme.accent),
                              const SizedBox(width: 8),
                              const Text('Credential Status',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Chip(
                                label: Text(c.authLevel),
                                backgroundColor:
                                    AppTheme.authLevelColor(c.authLevel)
                                        .withValues(alpha: 0.1),
                                labelStyle: TextStyle(
                                    color: AppTheme.authLevelColor(c.authLevel),
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          _buildInfoRow(
                              'Account Locked', c.accountLocked ? 'YES' : 'NO',
                              valueColor:
                                  c.accountLocked ? Colors.red : Colors.green),
                          if (c.lockedUntil != null)
                            _buildInfoRow(
                                'Locked Until',
                                DateFormat('yyyy-MM-dd HH:mm').format(
                                    DateTime.parse(c.lockedUntil!).toLocal())),
                          _buildInfoRow(
                              'Failed Attempts', c.failedAttempts.toString()),
                          _buildInfoRow(
                              'Must Reset PW', c.isFirstLogin ? 'YES' : 'NO',
                              valueColor:
                                  c.isFirstLogin ? Colors.orange : null),
                          _buildInfoRow('Cost Factor', c.costFactor.toString()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.verified_user, color: AppTheme.accent),
                              SizedBox(width: 8),
                              Text('MFA Configuration',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 32),
                          _buildInfoRow('OTP Enabled',
                              _mfa?.otpEnabled == true ? 'YES' : 'NO',
                              valueColor: _mfa?.otpEnabled == true
                                  ? Colors.green
                                  : Colors.grey),
                          _buildInfoRow('TOTP Configured',
                              _mfa?.totpEnabled == true ? 'YES' : 'NO',
                              valueColor: _mfa?.totpEnabled == true
                                  ? Colors.green
                                  : Colors.grey),
                          if (_mfa?.totpEnabled == true)
                            _buildInfoRow('Backup Codes Left',
                                _mfa!.remainingBackupCodes.toString()),
                          _buildInfoRow(
                              'Security Qs',
                              _mfa?.securityQuestionsEnabled == true
                                  ? 'YES'
                                  : 'NO',
                              valueColor: _mfa?.securityQuestionsEnabled == true
                                  ? Colors.green
                                  : Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right Column: Audit Logs
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history, color: AppTheme.accent),
                          SizedBox(width: 8),
                          Text('Login History',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 32),
                      if (_logs.isEmpty)
                        const Text('No login attempts recorded.')
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _logs.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            final dt = DateTime.parse(log.timestamp).toLocal();
                            return ListTile(
                              leading: Icon(
                                log.success ? Icons.check_circle : Icons.error,
                                color: log.success ? Colors.green : Colors.red,
                              ),
                              title: Text(
                                  DateFormat('yyyy-MM-dd HH:mm:ss').format(dt)),
                              subtitle: Text(log.success
                                  ? 'Successful Login (MFA: ${log.mfaUsed})'
                                  : 'Failed: ${log.failureReason}'),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
