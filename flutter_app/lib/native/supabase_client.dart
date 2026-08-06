import 'package:supabase_flutter/supabase_flutter.dart';

/// Port of lib/supabase.ts. Dart has no process.env — the Flutter
/// equivalent of Expo's EXPO_PUBLIC_* build-time env vars is
/// --dart-define, read here via String.fromEnvironment. Build/run with:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// (the CI workflow will need these added as --dart-define args sourced
/// from repo secrets once real backend calls are wired up end to end —
/// not yet done, since only login/register call Supabase so far).
const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> initSupabase() async {
  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    // No credentials at build time — auth screens will surface Supabase's
    // own error rather than crash startup. Matches the RN app's posture of
    // "usage works anonymously without auth" (see AGENTS.md history).
    return;
  }
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
}

SupabaseClient get supabase => Supabase.instance.client;

bool get isSupabaseConfigured => _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;
