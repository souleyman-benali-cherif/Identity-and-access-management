import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/identity_service.dart';
import '../../../models/person_model.dart';

class ChangeStatusScreen extends ConsumerStatefulWidget {
  final String personId;
  const ChangeStatusScreen({super.key, required this.personId});

  @override
  ConsumerState<ChangeStatusScreen> createState() => _ChangeStatusScreenState();
}

class _ChangeStatusScreenState extends ConsumerState<ChangeStatusScreen> {
  bool _isLoading = true;
  PersonModel? _person;
  String? _newStatus;
  List<String> _allowedTransitions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final idService = ref.read(identityServiceProvider);
    final person = await idService.getPersonById(widget.personId);

    if (person == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('User not found')));
        context.pop();
      }
      return;
    }

    final transitions = IdentityService.getAllowedTransitions(person.status);

    if (mounted) {
      setState(() {
        _person = person;
        _allowedTransitions = transitions;
        if (transitions.isNotEmpty) {
          _newStatus = transitions.first;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_newStatus == null) return;

    setState(() => _isLoading = true);

    final idService = ref.read(identityServiceProvider);
    final authState = ref.read(authProvider);

    // Enforce 5-year Archive rule
    if (_newStatus == AppConstants.statusArchived) {
      final eligibilityError =
          await idService.checkArchiveEligibility(widget.personId);
      if (eligibilityError != null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(eligibilityError)));
        }
        return;
      }
    }

    try {
      await idService.changeStatus(
        personId: widget.personId,
        oldStatus: _person!.status,
        newStatus: _newStatus!,
        changedBy: authState.personId!,
      );

      // If suspended or archived or inactive, lock the account and invalidate sessions
      if (_newStatus == AppConstants.statusSuspended ||
          _newStatus == AppConstants.statusInactive ||
          _newStatus == AppConstants.statusArchived) {
        final authService = ref.read(authServiceProvider);
        final creds = await authService.getCredentials(widget.personId);
        if (creds != null) {
          await authService
              .updateCredentials(creds.copyWith(accountLocked: true));
        }
        await authService.invalidateAllSessions(widget.personId);
      }

      // If active, unlock the account
      if (_newStatus == AppConstants.statusActive) {
        final authService = ref.read(authServiceProvider);
        await authService.unlockAccount(widget.personId);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Status updated successfully.')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Change User Status')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.swap_horiz,
                      size: 64, color: Colors.indigoAccent),
                  const SizedBox(height: 24),
                  Text('Update status for ${_person!.fullName}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('ID: ${_person!.uniqueId}',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Current Status: '),
                      Chip(label: Text(_person!.status)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_allowedTransitions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text(
                          'This account has reached its final state and cannot transition to any other status.',
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center),
                    )
                  else ...[
                    DropdownButtonFormField<String>(
                      initialValue: _newStatus,
                      decoration:
                          const InputDecoration(labelText: 'New Status'),
                      items: _allowedTransitions
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _newStatus = v),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                        'Note: Transitioning to Suspended, Inactive, or Archived will immediately lock the user account and invalidate all active sessions.',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Confirm Change'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
