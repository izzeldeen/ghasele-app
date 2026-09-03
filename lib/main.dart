import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
import 'driver_home_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'splash_screen.dart';
import 'forgot_password_screen.dart';
import 'otp_verification_screen.dart';
import 'registration_otp_screen.dart';
import 'complete_registration_screen.dart';
import 'reset_password_screen.dart';

import 'views/order_success_view.dart';
import 'views/order_failure_view.dart';
import 'views/privacy_policy_view.dart';
import 'providers/locale_provider.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'theme/app_theme.dart';


import 'package:firebase_core/firebase_core.dart';
import 'package:ghasele/services/notification_service.dart';

/// Accepts self-signed certificates so a local dev API can be reached over
/// HTTPS. This is installed in debug builds ONLY - shipping it would disable
/// certificate validation for every request in production, making the app
/// trivially interceptable on hostile networks.
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    HttpOverrides.global = MyHttpOverrides();
  }

  // Firebase itself is a local, fast init and messaging depends on it, so it
  // stays ahead of the first frame.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e. Make sure you have added google-services.json to android/app and GoogleService-Info.plist to ios/Runner.");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: const MyApp(),
    ),
  );

  // Notification setup prompts for permission, fetches an FCM token and syncs
  // it to the backend - all network-bound. Awaiting it before runApp() held the
  // splash on screen for the duration of those round-trips, so it now runs
  // after the first frame.
  unawaited(_initNotifications());
}

Future<void> _initNotifications() async {
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint("Notification initialization failed: $e");
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          title: 'كليني',
          locale: localeProvider.locale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (_) => const SplashScreen(),
            '/login': (_) => const LoginScreen(),
            '/signup': (_) => const SignUpScreen(),
            '/forgot-password': (_) => const ForgotPasswordScreen(),
            '/verify-otp': (context) {
              final phone = ModalRoute.of(context)?.settings.arguments as String;
              return OtpVerificationScreen(phoneNumber: phone);
            },
            '/verify-registration-otp': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              // A plain String is the WhatsApp path and keeps working untouched. The Firebase
              // path must carry a verificationId (or an already-obtained token), so it passes a Map.
              if (args is Map) {
                return RegistrationOtpScreen(
                  phoneNumber: args['phone'] as String,
                  firebaseVerificationId: args['verificationId'] as String?,
                  firebaseIdToken: args['idToken'] as String?,
                );
              }
              return RegistrationOtpScreen(phoneNumber: args as String);
            },
            '/complete-registration': (context) {
              final phone = ModalRoute.of(context)?.settings.arguments as String;
              return CompleteRegistrationScreen(phoneNumber: phone);
            },
            '/reset-password': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
              return ResetPasswordScreen(phoneNumber: args['phone'], otp: args['otp']);
            },
            '/main': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              final index = args is int ? args : 2;
              return HomeScreen(initialIndex: index);
            },
            '/driver-main': (_) => const DriverHomeScreen(),
            '/order-success': (_) => const OrderSuccessView(),
            '/order-failure': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as String?;
              return OrderFailureView(errorMessage: args);
            },
            '/privacy': (_) => const PrivacyPolicyView(),
          },
        );
      },
    );
  }
}
