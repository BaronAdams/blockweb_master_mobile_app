import 'package:supabase_flutter/supabase_flutter.dart';

/// Port of lib/supabase.ts. Dart has no process.env — the Flutter
/// equivalent of Expo's EXPO_PUBLIC_* build-time env vars is
/// --dart-define, read here via String.fromEnvironment. Build/run with:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
/// (sourced from repo secrets in CI — see .github/workflows/flutter-build.yml).
/// "Publishable key" is Supabase's current naming for what used to be
/// called the anon key — same kind of value (safe to embed client-side,
/// scoped by RLS), just the current dashboard/docs term for it. The
/// supabase_flutter SDK parameter is still named `anonKey` (that's the
/// package API, not ours to rename), so it's passed the publishable key's
/// value there.
const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> initSupabase() async {
  if (_supabaseUrl.isEmpty || _supabasePublishableKey.isEmpty) {
    // No credentials at build time — auth screens will surface Supabase's
    // own error rather than crash startup. Matches the RN app's posture of
    // "usage works anonymously without auth" (see AGENTS.md history).
    return;
  }
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabasePublishableKey);
}

SupabaseClient get supabase => Supabase.instance.client;

bool get isSupabaseConfigured => _supabaseUrl.isNotEmpty && _supabasePublishableKey.isNotEmpty;
