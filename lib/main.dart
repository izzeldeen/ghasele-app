import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'splash_screen.dart';

import 'views/order_success_view.dart';
import 'views/order_failure_view.dart';
import 'views/privacy_policy_view.dart';
import 'providers/locale_provider.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'theme/app_theme.dart';


import 'package:firebase_core/firebase_core.dart';
import 'package:ghasele/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (will only work if google-services.json/GoogleService-Info.plist are present)
  try {
    await Firebase.initializeApp();
    await NotificationService.initialize();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e. Make sure you have added google-services.json to android/app and GoogleService-Info.plist to ios/Runner.");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: const MyApp(),
    ),
  );
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
            '/main': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              final index = args is int ? args : 2;
              return HomeScreen(initialIndex: index);
            },
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
