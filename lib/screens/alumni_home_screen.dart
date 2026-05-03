import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

class AlumniHomeScreen extends ConsumerWidget {
  const AlumniHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person = ref.watch(authProvider).currentPerson;
    if (person == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumni Portal (Read-Only)'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back, ${person.firstName}', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'As an alumni, you have read-only access to your academic history and records.',
              style: TextStyle(color: AppTheme.textSecondary),
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
                        const Icon(Icons.school, color: AppTheme.accent),
                        const SizedBox(width: 8),
                        Text('Alumni Record', style: Theme.of(context).textTheme.titleLarge),
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
                    _buildInfoRow('Alumni ID', person.uniqueId),
                    _buildInfoRow('Email', person.personalEmail),
                    _buildInfoRow('Graduation Year', person.graduationYear?.toString() ?? 'N/A'),
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
                        Text('Security', style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                    const Divider(height: 32),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Change Password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.changePassword),
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
