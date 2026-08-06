import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../native/supabase_client.dart';
import '../../state/app_settings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_logo.dart';

/// Port of app/(auth)/register.tsx.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(String Function(String) t) async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await supabase.auth.signUp(email: _email.text, password: _password.text);
      if (!mounted) return;
      context.go('/');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message == 'User already registered' ? t('userAlreadyRegistered') : t('invalidEmail'));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = t('invalidEmail'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key) => i18n.t('auth', key);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    const AppLogo(size: 56),
                    const SizedBox(height: 18),
                    Text(t('createAccount'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colors.foreground)),
                    const SizedBox(height: 4),
                    Text(t('tagline'),
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.05),
                    border: Border.all(color: colors.primary.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 14, color: colors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(t('requiresInternet'),
                            style: TextStyle(fontSize: 11, height: 1.3, color: colors.foreground)),
                      ),
                    ],
                  ),
                ),
                AppInput(
                  icon: Icons.mail_outline_rounded,
                  placeholder: t('emailPlaceholder'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                ),
                const SizedBox(height: 12),
                AppInput(
                  icon: Icons.lock_outline_rounded,
                  placeholder: t('createPassword'),
                  controller: _password,
                  obscureText: true,
                  textCapitalization: TextCapitalization.none,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 12)),
                ],
                const SizedBox(height: 20),
                AppButton(label: t('register'), loading: _loading, onPressed: () => _submit(t)),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child:
                        Text(t('backToLogin'), style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
