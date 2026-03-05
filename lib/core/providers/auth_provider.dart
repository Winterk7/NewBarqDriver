import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Live auth-state stream ────────────────────────────────────────────────────
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// ── ChangeNotifier that GoRouter can listen to ───────────────────────────────
class AuthNotifier extends ChangeNotifier {
  StreamSubscription<AuthState>? _sub;

  AuthNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  bool get isLoggedIn =>
      Supabase.instance.client.auth.currentSession != null;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final authNotifierProvider = Provider<AuthNotifier>((ref) {
  final notifier = AuthNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});
