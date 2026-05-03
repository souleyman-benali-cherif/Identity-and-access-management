import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/password_utils.dart';

class PasswordResetFormScreen extends ConsumerStatefulWidget {
  final String personId;
  const PasswordResetFormScreen({super.key, required this.personId});

  @override
  ConsumerState<PasswordResetFormScreen> createState() => _PasswordResetFormScreenState();
}

class _PasswordResetFormScreenState extends ConsumerState<PasswordResetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final person = await ref.read(identityServiceProvider).getPersonById(widget.personId);
    if (person == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account not found.')));
      context.go(AppRoutes.login);
      return;
    }

    final authService = ref.read(authServiceProvider);
    final policy = await authService.getPasswordPolicy();

    // The token was already validated in the previous screen, so we can directly change the password.
    final error = await authService.changePassword(
      personId: widget.personId,
      newPlain: _newController.text,
      person: person,
      policy: policy,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // Success! Invalidate all existing sessions for security.
    await authService.invalidateAllSessions(widget.personId);

    // Show success dialog
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Success')]),
        content: const Text('Your password has been reset successfully. All active sessions have been signed out.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(AppRoutes.login);
            },
            child: const Text('Return to Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthIndicator() {
    final text = _newController.text;
    if (text.isEmpty) return const SizedBox.shrink();

    final strength = PasswordUtils.checkStrength(text);
    Color color;
    String label;
    
    switch (strength) {
      case PasswordStrength.weak:
        color = Colors.red;
        label = 'Weak';
        break;
      case PasswordStrength.medium:
        color = Colors.orange;
        label = 'Medium';
        break;
      case PasswordStrength.strong:
        color = Colors.green;
        label = 'Strong';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create New Password'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.vpn_key, size: 64, color: Colors.indigoAccent),
                    const SizedBox(height: 24),
                    const Text(
                      'Please enter your new password.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    TextFormField(
                      controller: _newController,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      obscureText: _obscureNew,
                      onChanged: (_) => setState(() {}),
                      validator: (v) => Validators.required(v, fieldLabel: 'New password'),
                    ),
                    _buildStrengthIndicator(),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _confirmController,
                      decoration: InputDecoration(
                        labelText: 'Confirm new password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      obscureText: _obscureConfirm,
                      validator: (v) => Validators.confirmPassword(v, _newController.text),
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Reset Password'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
