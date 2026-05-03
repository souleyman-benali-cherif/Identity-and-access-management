import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/router/app_router.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _codeController = TextEditingController();

  String? _errorMsg;
  bool _isLoading = true;

  // Expiry timer (5 mins)
  Timer? _expiryTimer;
  int _secondsToExpiry = 300;

  // Resend cooldown timer (60 secs)
  Timer? _cooldownTimer;
  int _secondsToResend = 0;

  @override
  void initState() {
    super.initState();
    _requestNewOtp();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _expiryTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestNewOtp() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final result = await ref.read(authProvider.notifier).requestOtp();

    if (!mounted) return;

    if (result.error != null) {
      setState(() {
        _isLoading = false;
        _errorMsg = result.error;
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _secondsToExpiry = 300;
      _secondsToResend = 60;
    });

    _startExpiryTimer();
    _startCooldownTimer();
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsToExpiry > 0) {
        setState(() => _secondsToExpiry--);
      } else {
        timer.cancel();
      }
    });
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsToResend > 0) {
        setState(() => _secondsToResend--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    final result = await ref.read(authProvider.notifier).verifyOtp(code);

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case OtpResult.failed:
        // Error shown via authState
        break;
      case OtpResult.sessionExpired:
        context.go(AppRoutes.login);
        break;
      case OtpResult.proceedToTotp:
        final authState = ref.read(authProvider);
        final personId = authState.personId;
        if (personId == null) {
          if (!mounted) return;
          context.go(AppRoutes.login);
          break;
        }

        final mfa = await ref.read(authServiceProvider).getMfaMethods(personId);
        final nextRoute = (mfa == null || mfa.totpSecret == null)
            ? AppRoutes.mfaSetup
            : AppRoutes.totpVerification;

        if (!mounted) return;
        context.go(nextRoute);
        break;
      case OtpResult.proceedToHome:
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
        title: const Text('Two-Factor Verification'),
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
                const Icon(Icons.mark_email_unread_outlined,
                    size: 64, color: Colors.indigoAccent),
                const SizedBox(height: 24),
                if (_errorMsg != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    color: Colors.red.withValues(alpha: 0.1),
                    child: Text(_errorMsg!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                if (authState.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    color: Colors.red.withValues(alpha: 0.1),
                    child: Text(authState.errorMessage!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                if (!_isLoading) ...[
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
                            'A verification code was sent to your email.'),
                        const SizedBox(height: 8),
                        Text('Expires in: ${_formatTime(_secondsToExpiry)}',
                            style: TextStyle(
                                color: _secondsToExpiry < 60
                                    ? Colors.red
                                    : Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Enter 8-digit code',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    textAlign: TextAlign.center,
                    style: const TextStyle(letterSpacing: 8, fontSize: 24),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed:
                        _isLoading || _secondsToExpiry == 0 ? null : _verify,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Verify'),
                  ),
                ] else if (_isLoading) ...[
                  const Center(child: CircularProgressIndicator()),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _secondsToResend > 0 || _isLoading
                          ? null
                          : _requestNewOtp,
                      child: Text(_secondsToResend > 0
                          ? 'Resend code in ${_secondsToResend}s'
                          : 'Resend code'),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    context.go(AppRoutes.login);
                  },
                  child: const Text('Back to login',
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
