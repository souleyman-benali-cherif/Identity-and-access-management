import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/validators.dart';

class SecurityQuestionScreen extends ConsumerStatefulWidget {
  const SecurityQuestionScreen({super.key});

  @override
  ConsumerState<SecurityQuestionScreen> createState() =>
      _SecurityQuestionScreenState();
}

class _SecurityQuestionScreenState
    extends ConsumerState<SecurityQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ans1Controller = TextEditingController();
  final _ans2Controller = TextEditingController();

  bool _isLoading = true;
  String? _q1;
  String? _q2;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _ans1Controller.dispose();
    _ans2Controller.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final personId = ref.read(authProvider).personId;
    if (personId == null) {
      if (mounted) context.go(AppRoutes.login);
      return;
    }

    final authService = ref.read(authServiceProvider);
    final mfa = await authService.getMfaMethods(personId);

    if (!mounted) return;

    if (mfa == null || !mfa.securityQuestionsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Security questions are not configured for this account.')),
      );
      context.go(AppRoutes.login);
      return;
    }

    setState(() {
      _q1 = mfa.securityQuestion1;
      _q2 = mfa.securityQuestion2;
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result =
        await ref.read(authProvider.notifier).verifySecurityQuestions(
              _ans1Controller.text,
              _ans2Controller.text,
            );

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case SecQResult.failed:
        // Error shown via authState
        break;
      case SecQResult.sessionExpired:
        context.go(AppRoutes.login);
        break;
      case SecQResult.notConfigured:
        context.go(AppRoutes.login);
        break;
      case SecQResult.proceedToHome:
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
        title: const Text('Security Questions'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.help_outline,
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
                if (_isLoading && _q1 == null)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  const Text(
                    'Please answer your security questions to complete verification.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Question 1',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(_q1 ?? '',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _ans1Controller,
                          decoration: const InputDecoration(
                            labelText: 'Your answer',
                            border: OutlineInputBorder(),
                          ),
                          validator: Validators.securityAnswer,
                        ),
                        const SizedBox(height: 24),
                        Text('Question 2',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(_q2 ?? '',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _ans2Controller,
                          decoration: const InputDecoration(
                            labelText: 'Your answer',
                            border: OutlineInputBorder(),
                          ),
                          validator: Validators.securityAnswer,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Verify Answers'),
                        ),
                      ],
                    ),
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
