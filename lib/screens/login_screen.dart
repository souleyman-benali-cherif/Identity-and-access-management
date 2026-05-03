import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../services/demo_reset_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isResettingDemoData = false;
  LoginResult? _pendingResult;

  @override
  void initState() {
    super.initState();
    _identifierController.addListener(_onInputChanged);
    _passwordController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    ref.read(authProvider.notifier).clearError();
  }

  @override
  void dispose() {
    _identifierController.removeListener(_onInputChanged);
    _passwordController.removeListener(_onInputChanged);
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleNavigation(LoginResult result) async {
    if (!mounted) return;
    switch (result) {
      case LoginResult.firstLogin:
        context.go(AppRoutes.forcedChange);
        break;
      case LoginResult.proceedToOtp:
        context.go(AppRoutes.otpVerification);
        break;
      case LoginResult.proceedToHome:
        await ref.read(authProvider.notifier).finalizeLogin();
        if (!mounted) return;
        final authState = ref.read(authProvider);
        final person = authState.currentPerson;
        if (person != null) {
          context.go(homeRouteForType(person.userType));
        }
        break;
      case LoginResult.locked:
      case LoginResult.failed:
        // Error shown via authState.errorMessage
        break;
    }
  }

  Future<void> _submit() async {
    debugPrint('[LoginScreen] _submit called');
    if (!_formKey.currentState!.validate()) {
      debugPrint('[LoginScreen] Form validation failed');
      return;
    }

    debugPrint('[LoginScreen] Form validated, calling login');

    FocusScope.of(context).unfocus();

    debugPrint('[LoginScreen] Before authProvider.login call');
    final result = await ref.read(authProvider.notifier).login(
          _identifierController.text.trim(),
          _passwordController.text,
        );
    debugPrint('[LoginScreen] authProvider.login returned: $result');

    if (!mounted) {
      debugPrint(
          '[LoginScreen] Widget not mounted, storing result for listener');
      _pendingResult = result;
      return;
    }

    _handleNavigation(result);
  }

  Future<void> _resetDemoData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset Demo Database?'),
          content: const Text(
            'This will delete all current data and recreate only:\n\n'
            'STF202400001 / Admin@1234\n'
            'STF202400002 / Staff@1234',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isResettingDemoData = true);

    try {
      await ref.read(authProvider.notifier).logout();
      await DemoResetService().resetAndReseedDefaults();

      if (!mounted) return;
      _identifierController.clear();
      _passwordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Database reset complete. Default admin/staff accounts are ready.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isResettingDemoData = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen for state changes to handle deferred navigation
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (_pendingResult != null) {
        debugPrint(
            '[LoginScreen] Listener triggered with pending result: $_pendingResult');
        _handleNavigation(_pendingResult!);
        _pendingResult = null;
      }
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.shield_rounded,
                      size: 64, color: Colors.indigoAccent),
                  const SizedBox(height: 16),
                  Text(
                    'University IAM System',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'University of Batna 2',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 48),
                  if (authState.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Theme.of(context).colorScheme.error),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  TextFormField(
                    controller: _identifierController,
                    decoration: const InputDecoration(
                      labelText: 'Username or Email',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    enabled: !authState.isLoading,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Please enter your username or email'
                        : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    enabled: !authState.isLoading,
                    validator: (v) => v == null || v.isEmpty
                        ? 'Please enter your password'
                        : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(value: false, onChanged: (v) {}),
                          const Text('Remember me'),
                        ],
                      ),
                      TextButton(
                        onPressed: authState.isLoading
                            ? null
                            : () => context.push(AppRoutes.forgotPassword),
                        child: const Text('Forgot your password?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authState.isLoading || _isResettingDemoData
                          ? null
                          : _submit,
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Login', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: authState.isLoading || _isResettingDemoData
                        ? null
                        : _resetDemoData,
                    icon: _isResettingDemoData
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cleaning_services_outlined),
                    label: const Text('Reset Demo Database'),
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
