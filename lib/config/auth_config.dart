/// Which channel delivers the registration OTP.
///
/// Both paths are fully implemented and the backend serves both, so this is a switch rather than a
/// migration: flipping it back restores the WhatsApp flow with no other change.
///
/// Override at build time:
///   flutter run --dart-define=USE_FIREBASE_OTP=false
class AuthConfig {
  /// When true, signup verifies the phone through Firebase Phone Authentication - Google sends and
  /// checks the SMS - and exchanges the resulting ID token at `POST /api/auth/firebase-login`.
  ///
  /// When false, the original flow runs: the backend generates the code and sends it over WhatsApp.
  static const bool useFirebaseOtp =
      bool.fromEnvironment('USE_FIREBASE_OTP', defaultValue: true);

  const AuthConfig._();
}
