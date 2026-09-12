import 'dart:math';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

/// The per-install identifier that lets a guest come back to the orders and support
/// tickets they created without an account.
///
/// A guest has no user row on the server, so this value is the only handle on their
/// records: it is stamped on anything they create and is what the guest listings are
/// looked up by. It is generated once on first launch and then never changes, which is
/// what makes an order placed last week still visible today.
///
/// Two consequences worth knowing about:
///
///  * It is effectively a password for those records - whoever holds it can read them.
///    That is why it is sent in a header rather than a URL (headers stay out of access
///    logs) and is never displayed in the UI.
///  * It lives in SharedPreferences, so it dies with the app's data. Clearing storage,
///    reinstalling or switching phones loses the history - the fix for that is signing
///    in, not a longer-lived token.
class DeviceService {
  static const String _prefsKey = 'device_token';

  static String? _token;

  /// The current device token, or null before [ensureToken] has run.
  static String? get token => _token;

  /// Loads the device token, generating and persisting one on first launch.
  ///
  /// Safe to call more than once; later calls return the stored value.
  static Future<String> ensureToken() async {
    if (_token != null) return _token!;

    final prefs = await SharedPreferences.getInstance();
    var stored = prefs.getString(_prefsKey);

    if (stored == null || stored.isEmpty) {
      stored = _generateToken();
      await prefs.setString(_prefsKey, stored);
    }

    _token = stored;
    return stored;
  }

  /// Clears the in-memory cache so a test can simulate a fresh install. Has no effect on
  /// what is stored; production code never needs it.
  @visibleForTesting
  static void debugReset() => _token = null;

  /// 32 hex characters (128 bits) from the platform's secure generator, so the value
  /// cannot be guessed by someone hoping to read another device's guest orders.
  static String _generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
