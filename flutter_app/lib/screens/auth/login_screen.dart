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
import '../../widgets/social_login_buttons.dart';

/// Port of app/(auth)/login.tsx.
class LoginScreen extends ConsumerStatefulWidget {
  /// Set when arriving here right after registering (see
  /// RegisterScreen._submit) — shown as a persistent banner rather than a
  /// SnackBar, since the user has to leave the app to check their email
  /// before it's actionable, by which point a transient toast is long gone.
  final String? initialMessage;
  const LoginScreen({super.key, this.initialMessage});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _infoMessage;

  @override
  void initState() {
    super.initState();
    // widget.initialMessage isn't safe to read in a field initializer —
    // the State's _widget backref isn't assigned yet at that point — so
    // this has to happen here instead.
    _infoMessage = widget.initialMessage;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(String Function(String) t) async {
    setState(() {
      _error = null;
      _infoMessage = null;
      _loading = true;
    });
    try {
      await supabase.auth.signInWithPassword(email: _email.text, password: _password.text);
      if (!mounted) return;
      context.go('/');
    } on AuthException catch (e) {
      if (!mounted) return;
      // Registered but hasn't clicked the confirmation link yet — a
      // distinct, more useful message than "wrong email/password" since the
      // credentials are actually correct.
      setState(() => _error = e.message == 'Email not confirmed' ? t('notActivated') : t('invalidCredentials'));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = t('invalidCredentials'));
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
                    Text(t('signIn'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colors.foreground)),
                    const SizedBox(height: 4),
                    Text(t('tagline'),
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
                  ],
                ),
                const SizedBox(height: 32),
                if (_infoMessage != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D399).withOpacity(0.08),
                      border: Border.all(color: const Color(0xFF34D399).withOpacity(0.25)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.mark_email_read_outlined, size: 14, color: Color(0xFF34D399)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_infoMessage!, style: TextStyle(fontSize: 11, height: 1.3, color: colors.foreground)),
                        ),
                      ],
                    ),
                  ),
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
                  placeholder: t('password'),
                  controller: _password,
                  obscureText: true,
                  textCapitalization: TextCapitalization.none,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 12)),
                ],
                const SizedBox(height: 20),
                AppButton(label: t('signIn'), loading: _loading, onPressed: () => _submit(t)),
                const SizedBox(height: 24),
                const SocialLoginButtons(),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/register'),
                    child: Text(t('createAccount'),
                        style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
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
