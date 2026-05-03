import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/password_utils.dart';
import '../../core/utils/validators.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final authState = ref.read(authProvider);
    final personId = authState.personId;
    final creds = authState.credentials;
    final person = authState.currentPerson;
    
    if (personId == null || creds == null || person == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session error. Please login again.')));
      return;
    }

    final isCurrentCorrect = await PasswordUtils.verifyPassword(_currentController.text, creds.hashedPassword);
    
    if (!isCurrentCorrect) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Current password is incorrect.')));
      return;
    }

    final authService = ref.read(authServiceProvider);
    final policy = await authService.getPasswordPolicy();

    final error = await authService.changePassword(
      personId: personId,
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

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully.')));
    context.pop();
  }

  Widget _buildStrengthIndicator() {
    final text = _newController.text;
    if (text.isEmpty) return const SizedBox.shrink();

    final strength = PasswordUtils.checkStrength(text);
    Color color;
    String label;
    
    switch (strength) {
      case PasswordStrength.weak: color = Colors.red; label = 'Weak'; break;
      case PasswordStrength.medium: color = Colors.orange; label = 'Medium'; break;
      case PasswordStrength.strong: color = Colors.green; label = 'Strong'; break;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
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
                  const Icon(Icons.password, size: 64, color: Colors.indigoAccent),
                  const SizedBox(height: 24),
                  
                  TextFormField(
                    controller: _currentController,
                    decoration: InputDecoration(
                      labelText: 'Current password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCurrent ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    obscureText: _obscureCurrent,
                    validator: (v) => Validators.required(v, fieldLabel: 'Current password'),
                  ),
                  const SizedBox(height: 16),
                  
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
                          : const Text('Update Password'),
                    ),
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
