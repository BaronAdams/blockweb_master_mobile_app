import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../native/supabase_client.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';

/// Google/Apple/Facebook sign-in row for the login/register screens. Real
/// Supabase OAuth calls (supabase.auth.signInWithOAuth), not placeholders —
/// but each provider only actually works once it's turned on in the
/// Supabase dashboard (Authentication > Providers) with that provider's
/// own OAuth client credentials, which is a manual dashboard step outside
/// what this code can do. Until then Supabase returns an error, which
/// surfaces the same way a wrong password does on this screen.
class SocialLoginButtons extends ConsumerStatefulWidget {
  const SocialLoginButtons({super.key});

  @override
  ConsumerState<SocialLoginButtons> createState() => _SocialLoginButtonsState();
}

class _SocialLoginButtonsState extends ConsumerState<SocialLoginButtons> {
  OAuthProvider? _loading;
  String? _error;

  Future<void> _signIn(OAuthProvider provider) async {
    setState(() {
      _loading = provider;
      _error = null;
    });
    try {
      await supabase.auth.signInWithOAuth(provider);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = ref.read(i18nProvider).t('auth', 'invalidCredentials'));
    } finally {
      if (mounted) setState(() => _loading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final i18n = ref.watch(i18nProvider);
    String t(String key) => i18n.t('auth', key);

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Container(height: 1, color: colors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(t('orContinueWith'), style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
            ),
            Expanded(child: Container(height: 1, color: colors.border)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                icon: const _GoogleMark(),
                loading: _loading == OAuthProvider.google,
                onPressed: () => _signIn(OAuthProvider.google),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                icon: Icon(Icons.apple, size: 22, color: colors.foreground),
                loading: _loading == OAuthProvider.apple,
                onPressed: () => _signIn(OAuthProvider.apple),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                icon: const _FacebookMark(),
                loading: _loading == OAuthProvider.facebook,
                onPressed: () => _signIn(OAuthProvider.facebook),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 12)),
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final bool loading;
  final VoidCallback onPressed;
  const _SocialButton({required this.icon, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return OutlinedButton(
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colors.border),
        backgroundColor: colors.card,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.mutedForeground),
            )
          : icon,
    );
  }
}

/// Simplified Google "G" monogram (single-color, not the official
/// multi-color asset — this sandbox has no way to fetch/bundle Google's
/// official brand SVG) drawn as a ring with a notch + crossbar, the same
/// silhouette as the real logo.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const SizedBox(width: 22, height: 22, child: CustomPaint(painter: _GooglePainter()));
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const colors = [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335)];
    const sweep = 1.5708; // pi/2
    for (var i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - paint.strokeWidth / 2),
        -0.35 + i * sweep,
        sweep - 0.1,
        false,
        paint,
      );
    }
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(center.dx, center.dy - size.height * 0.11, size.width * 0.42, size.height * 0.22), barPaint);
  }

  @override
  bool shouldRepaint(covariant _GooglePainter oldDelegate) => false;
}

/// Facebook "f" glyph, white on the brand's blue circle.
class _FacebookMark extends StatelessWidget {
  const _FacebookMark();

  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(color: Color(0xFF1877F2), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const Text('f', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, height: 1)),
      );
}
