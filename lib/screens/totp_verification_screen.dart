import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/router/app_router.dart';

class TotpVerificationScreen extends ConsumerStatefulWidget {
  const TotpVerificationScreen({super.key});

  @override
  ConsumerState<TotpVerificationScreen> createState() =>
      _TotpVerificationScreenState();
}

class _TotpVerificationScreenState
    extends ConsumerState<TotpVerificationScreen> {
  final _codeController = TextEditingController();
  final _backupController = TextEditingController();

  bool _useBackup = false;
  bool _isLoading = true;
  int _secondsToRefresh = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadSecret();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _backupController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSecret() async {
    final personId = ref.read(authProvider).personId;
    if (personId == null) {
      if (mounted) context.go(AppRoutes.login);
      return;
    }

    final authService = ref.read(authServiceProvider);
    final mfa = await authService.getMfaMethods(personId);

    if (!mounted) return;

    if (mfa == null || mfa.totpSecret == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('TOTP is not configured for this account.')),
      );
      context.go(AppRoutes.mfaSetup);
      return;
    }

    setState(() {
      _isLoading = false;
    });

    _updateRefreshCountdown();
    _startRefreshTimer();
  }

  void _updateRefreshCountdown() {
    final now = DateTime.now();
    final secondsPassed = now.second % 30;
    setState(() {
      _secondsToRefresh = 30 - secondsPassed;
    });
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final secondsPassed = now.second % 30;
      setState(() {
        _secondsToRefresh = 30 - secondsPassed;
      });
    });
  }

  Future<void> _verifyTotp() async {
    final code = _codeController.text.replaceAll(' ', '').trim();
    if (code.length != 6 || int.tryParse(code) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter a valid 6-digit authenticator code.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await ref.read(authProvider.notifier).verifyTotp(code);
    _handleResult(result);
  }

  Future<void> _verifyBackup() async {
    final code = _backupController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    final result =
        await ref.read(authProvider.notifier).useTotpBackupCode(code);
    _handleResult(result);
  }

  void _handleResult(TotpResult result) async {
    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case TotpResult.failed:
        // Error shown via authState
        break;
      case TotpResult.sessionExpired:
        context.go(AppRoutes.login);
        break;
      case TotpResult.notConfigured:
        context.go(AppRoutes.login);
        break;
      case TotpResult.proceedToSecQuestion:
        context.go(AppRoutes.securityQuestion);
        break;
      case TotpResult.proceedToHome:
        await ref.read(authProvider.notifier).finalizeLogin();
        if (!mounted) return;
        final person = ref.read(authProvider).currentPerson;
        if (person != null) {
          context.go(homeRouteForType(person.userType));
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Authenticator Verification'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.security,
                    size: 64, color: Colors.indigoAccent),
                const SizedBox(height: 24),
                if (authState.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    color: Colors.red.withValues(alpha: 0.1),
                    child: Text(authState.errorMessage!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (!_useBackup) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                            'Open Google Authenticator and enter the current 6-digit code.'),
                        const SizedBox(height: 8),
                        Text(
                          'Next code in: $_secondsToRefresh seconds',
                          style: TextStyle(
                              color: _secondsToRefresh <= 10
                                  ? Colors.red
                                  : Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Enter 6-digit code',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(letterSpacing: 8, fontSize: 24),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyTotp,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Verify Code'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _useBackup = true),
                    child: const Text('Use backup code instead'),
                  ),
                ] else ...[
                  // Backup Code Flow
                  const Text(
                    'Enter one of your 8-character alphanumeric backup codes.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _backupController,
                    decoration: const InputDecoration(
                      labelText: 'Backup code',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 8,
                    textAlign: TextAlign.center,
                    style: const TextStyle(letterSpacing: 4, fontSize: 20),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyBackup,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Use this backup code'),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => setState(() => _useBackup = false),
                    child: const Text('Back to authenticator code'),
                  ),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    context.go(AppRoutes.login);
                  },
                  child: const Text('Cancel and return to login',
                      style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
