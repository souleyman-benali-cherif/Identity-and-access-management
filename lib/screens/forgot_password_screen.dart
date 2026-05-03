import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/validators.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();

  bool _isLoading = false;
  bool _tokenSent = false;
  String? _personId;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _requestToken() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || Validators.email(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email.')));
      return;
    }

    setState(() => _isLoading = true);

    final person =
        await ref.read(identityServiceProvider).getPersonByEmail(email);

    if (!mounted) return;

    if (person == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No account found with that email.')));
      return;
    }

    final token =
        await ref.read(authServiceProvider).generateResetToken(person.uniqueId);

    final sent = await ref.read(emailJsServiceProvider).sendResetTokenEmail(
          toEmail: person.personalEmail,
          toName: '${person.firstName} ${person.lastName}',
          resetToken: token,
          appName: 'IAM project',
        );

    if (!sent) {
      await ref.read(authServiceProvider).deleteResetToken(token);
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send reset token email. Please try again.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = false;
      _tokenSent = true;
      _personId = person.uniqueId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset token sent to your email.')),
    );
  }

  Future<void> _verifyToken() async {
    final tokenText = _tokenController.text.trim();
    if (tokenText.isEmpty) return;

    setState(() => _isLoading = true);

    final tokenModel =
        await ref.read(authServiceProvider).getResetToken(tokenText);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (tokenModel == null || tokenModel.personId != _personId) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid reset token.')));
      return;
    }

    if (tokenModel.used) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token has already been used.')));
      return;
    }

    if (tokenModel.isExpired) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Token has expired.')));
      return;
    }

    // Token is valid! Mark as used and proceed to reset form
    await ref.read(authServiceProvider).markTokenUsed(tokenText);
    if (mounted) {
      context.push(AppRoutes.passwordReset, extra: _personId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
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
                const Icon(Icons.lock_reset,
                    size: 64, color: Colors.indigoAccent),
                const SizedBox(height: 24),
                if (!_tokenSent) ...[
                  const Text(
                    'Enter your personal email address. We will generate a secure reset token for you.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Personal Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _requestToken,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Request Reset Token'),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Expanded(
                                child: Text('Email Sent',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                            'Check your inbox and paste the reset token below.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                      'Enter the reset token below to verify your identity.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: 'Reset Token (UUID)',
                      prefixIcon: Icon(Icons.key),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyToken,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Verify Token'),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Back to login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
