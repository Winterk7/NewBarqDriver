import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── ChangeNotifier that GoRouter listens to ───────────────────────────────────
//
// isLoggedIn is only true AFTER role is confirmed — the router can never
// redirect to a protected screen before the profile check completes.
class AuthNotifier extends ChangeNotifier {
  final String requiredRole;
  StreamSubscription<AuthState>? _sub;
  bool _verified = false;

  AuthNotifier({required this.requiredRole}) {
    // If a session is already present (e.g. hot-reload or app resume),
    // verify role immediately. We set _verified optimistically until the
    // check completes so the router doesn't flash /login.
    if (Supabase.instance.client.auth.currentSession != null) {
      _verified = true; // optimistic: already had a session
      notifyListeners();
      _verifyRole();
    }
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        // Reset first → router stays on login until check completes
        _verified = false;
        notifyListeners();
        _verifyRole();
      } else if (data.event == AuthChangeEvent.signedOut) {
        _verified = false;
        notifyListeners();
      }
    });
  }

  Future<void> _verifyRole() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _verified = false;
        notifyListeners();
        return;
      }
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      final role = profile?['role'] as String?;
      if (role == requiredRole) {
        _verified = true;
      } else {
        _verified = false;
        await Supabase.instance.client.auth.signOut();
      }
    } catch (_) {
      _verified = false;
      await Supabase.instance.client.auth.signOut();
    }
    notifyListeners();
  }

  /// True only after Supabase session exists AND role is confirmed.
  bool get isLoggedIn => _verified;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final authNotifierProvider = Provider<AuthNotifier>((ref) {
  final notifier = AuthNotifier(requiredRole: 'driver');
  ref.onDispose(notifier.dispose);
  return notifier;
});
