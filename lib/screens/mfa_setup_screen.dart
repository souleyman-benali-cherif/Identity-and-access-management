import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/password_utils.dart';
import '../../core/utils/validators.dart';
import '../../models/mfa_methods_model.dart';
import '../../core/theme/app_theme.dart';

class MfaSetupScreen extends ConsumerStatefulWidget {
  const MfaSetupScreen({super.key});

  @override
  ConsumerState<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends ConsumerState<MfaSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ans1Controller = TextEditingController();
  final _ans2Controller = TextEditingController();
  
  String? _q1;
  String? _q2;
  String? _totpSecret;
  List<String> _backupCodes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _q1 = AppConstants.securityQuestions[0];
    _q2 = AppConstants.securityQuestions[1];
    _generateTotpData();
  }

  @override
  void dispose() {
    _ans1Controller.dispose();
    _ans2Controller.dispose();
    super.dispose();
  }

  void _generateTotpData() {
    final authService = ref.read(authServiceProvider);
    setState(() {
      _totpSecret = authService.generateTotpSecret();
      _backupCodes = authService.generateBackupCodes();
    });
  }

  Future<void> _submit() async {
    final authState = ref.read(authProvider);
    final authLevel = authState.authLevel;
    
    // For L4, security questions are required.
    if (authLevel == AppConstants.authLevelL4) {
      if (!_formKey.currentState!.validate()) return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final authService = ref.read(authServiceProvider);
      
      String? hash1;
      String? hash2;
      
      if (authLevel == AppConstants.authLevelL4) {
        hash1 = await PasswordUtils.hashPassword(_ans1Controller.text.trim().toLowerCase());
        hash2 = await PasswordUtils.hashPassword(_ans2Controller.text.trim().toLowerCase());
      }
      
      final methods = MfaMethodsModel(
        personId:                 authState.personId!,
        totpSecret:               authLevel == AppConstants.authLevelL4 || authLevel == AppConstants.authLevelL3 ? _totpSecret : null,
        totpBackupCodes:          authLevel == AppConstants.authLevelL4 || authLevel == AppConstants.authLevelL3 ? _backupCodes : const [],
        totpBackupCodesUsed:      authLevel == AppConstants.authLevelL4 || authLevel == AppConstants.authLevelL3 ? List.filled(10, false) : const [],
        securityQuestion1:        authLevel == AppConstants.authLevelL4 ? _q1 : null,
        securityAnswer1Hashed:    hash1,
        securityQuestion2:        authLevel == AppConstants.authLevelL4 ? _q2 : null,
        securityAnswer2Hashed:    hash2,
        otpEnabled:               true, // Everyone L2+ gets OTP
        totpEnabled:              authLevel == AppConstants.authLevelL4 || authLevel == AppConstants.authLevelL3,
        securityQuestionsEnabled: authLevel == AppConstants.authLevelL4,
      );
      
      await authService.saveMfaMethods(methods);
      await authService.recalculateAuthLevel(authState.personId!, authState.currentPerson!.userType);
      
      // Update state to complete login
      await ref.read(authProvider.notifier).finalizeLogin();
      
      if (mounted) {
        context.go(homeRouteForType(authState.currentPerson!.userType));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error saving MFA configuration.')));
      }
    }
  }

  Widget _buildTotpSection() {
    final authService = ref.read(authServiceProvider);
    final authState = ref.watch(authProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Authenticator App Setup', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Scan the QR code with your authenticator app (like Google Authenticator):'),
        const SizedBox(height: 12),
        // QR Code
        if (_totpSecret != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: QrImageView(
              data: authService.buildTotpProvisioningUri(
                secret: _totpSecret!,
                accountName: authState.personId ?? 'user',
                issuer: 'IAM Suite',
              ),
              version: QrVersions.auto,
              size: 200.0,
              gapless: false,
            ),
          ),
        const SizedBox(height: 24),
        const Text('Or enter this secret key into your authenticator app:'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
          child: SelectableText(_totpSecret ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 32),
        const Text('Backup Codes (Save these in a secure place!):'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(8)),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _backupCodes.map((c) => Text(c, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))).toList(),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSecurityQuestionsSection() {
    final qs = AppConstants.securityQuestions;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Security Questions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _q1,
            decoration: const InputDecoration(labelText: 'Question 1'),
            items: qs.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
            onChanged: (v) => setState(() => _q1 = v),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ans1Controller,
            decoration: const InputDecoration(labelText: 'Answer 1'),
            validator: Validators.securityAnswer,
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _q2,
            decoration: const InputDecoration(labelText: 'Question 2'),
            items: qs.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
            onChanged: (v) => setState(() => _q2 = v),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ans2Controller,
            decoration: const InputDecoration(labelText: 'Answer 2'),
            validator: Validators.securityAnswer,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authLevel = authState.authLevel ?? AppConstants.authLevelL2;

    final requiresTotp = authLevel == AppConstants.authLevelL3 || authLevel == AppConstants.authLevelL4;
    final requiresQuestions = authLevel == AppConstants.authLevelL4;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MFA Setup Wizard'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.security, size: 64, color: Colors.indigoAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Two-Factor Authentication Setup',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your account requires Level ${authLevel.substring(1)} security. Please complete the setup below.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // Email OTP is always implied as enabled for L2+
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 16),
                        Expanded(child: Text('Email OTP is automatically enabled for your account.', style: TextStyle(color: Colors.green))),
                      ],
                    ),
                  ),

                  if (requiresTotp) _buildTotpSection(),
                  if (requiresQuestions) _buildSecurityQuestionsSection(),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Complete Setup'),
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