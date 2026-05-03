import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/contractor_model.dart';
import '../../models/mfa_methods_model.dart';

class ContractorHomeScreen extends ConsumerStatefulWidget {
  const ContractorHomeScreen({super.key});

  @override
  ConsumerState<ContractorHomeScreen> createState() => _ContractorHomeScreenState();
}

class _ContractorHomeScreenState extends ConsumerState<ContractorHomeScreen> {
  ContractorModel? _contractorData;
  MfaMethodsModel? _mfaMethods;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final person = ref.read(authProvider).currentPerson;
    if (person == null) return;
    
    final idService = ref.read(identityServiceProvider);
    final authService = ref.read(authServiceProvider);
    
    final contractor = await idService.getContractor(person.uniqueId);
    final mfa = await authService.getMfaMethods(person.uniqueId);
    
    if (mounted) {
      setState(() {
        _contractorData = contractor;
        _mfaMethods = mfa;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final person = ref.watch(authProvider).currentPerson;
    if (person == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Portal'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, ${person.firstName}', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 24),
                  
                  if (_contractorData?.expiresWithinSevenDays == true)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        border: Border.all(color: AppTheme.warning),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
                          const SizedBox(width: 16),
                          const Expanded(child: Text('Your access expires within 7 days. Please contact administration for renewal.', style: TextStyle(color: AppTheme.warning))),
                        ],
                      ),
                    ),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.handyman, color: AppTheme.accent),
                              const SizedBox(width: 8),
                              Text('Contract Details', style: Theme.of(context).textTheme.titleLarge),
                              const Spacer(),
                              Chip(
                                label: Text(person.status),
                                backgroundColor: AppTheme.statusColor(person.status).withValues(alpha: 0.1),
                                labelStyle: TextStyle(color: AppTheme.statusColor(person.status)),
                                side: BorderSide.none,
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          _buildInfoRow('Full Name', person.fullName),
                          _buildInfoRow('Contractor ID', person.uniqueId),
                          _buildInfoRow('Email', person.personalEmail),
                          if (_contractorData?.contractPurpose != null)
                            _buildInfoRow('Purpose', _contractorData!.contractPurpose!),
                          if (_contractorData?.accessExpiryDate != null)
                            _buildInfoRow('Access Expiry', _contractorData!.accessExpiryDate.substring(0, 10)),
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
                          Row(
                            children: [
                              const Icon(Icons.security, color: AppTheme.accent),
                              const SizedBox(width: 8),
                              Text('Security Settings', style: Theme.of(context).textTheme.titleLarge),
                            ],
                          ),
                          const Divider(height: 32),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Change Password'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push(AppRoutes.changePassword),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Two-Factor Authentication'),
                            subtitle: Text(
                              _mfaMethods?.otpEnabled == true || _mfaMethods?.totpEnabled == true
                                  ? 'MFA is enabled.'
                                  : 'Enable MFA.',
                            ),
                            trailing: _mfaMethods?.otpEnabled == true || _mfaMethods?.totpEnabled == true
                                ? const Icon(Icons.check_circle, color: AppTheme.success)
                                : const Icon(Icons.chevron_right),
                            onTap: () {
                              if (_mfaMethods?.otpEnabled != true && _mfaMethods?.totpEnabled != true) {
                                context.push(AppRoutes.mfaSetup).then((_) => _loadData());
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
