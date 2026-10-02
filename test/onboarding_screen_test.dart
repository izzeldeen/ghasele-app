import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the walkthrough with a stub route standing in for the app, so finishing can be
/// observed without building the real home screen and everything it pulls in.
Future<void> _pump(WidgetTester tester, {Locale locale = const Locale('en')}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: const OnboardingScreen(),
      routes: {'/main': (_) => const Scaffold(body: Text('HOME'))},
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // The expected text is read from the translation files rather than written out here.
  // These tests are about which step shows what and where the flag ends up; the wording
  // is reviewed and rewritten regularly, and a test that hardcodes it fails on every
  // copy change without a single thing being broken.
  late AppLocalizations en;
  late AppLocalizations ar;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    ar = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('opens on the first step and offers a way past it', (tester) async {
    await _pump(tester);

    expect(find.text(en.onboardingPickPlaceTitle), findsOneWidget);
    expect(find.text(en.next), findsOneWidget);
    expect(find.text(en.skip), findsOneWidget);
  });

  testWidgets('walks through all four steps, ending on the start button', (tester) async {
    await _pump(tester);

    await tester.tap(find.text(en.next));
    await tester.pumpAndSettle();
    expect(find.text(en.onboardingChooseTimeTitle), findsOneWidget);

    await tester.tap(find.text(en.next));
    await tester.pumpAndSettle();
    expect(find.text(en.onboardingCollectTitle), findsOneWidget);

    await tester.tap(find.text(en.next));
    await tester.pumpAndSettle();
    expect(find.text(en.onboardingDeliverTitle), findsOneWidget);

    // Last step: nothing left to skip past, and the primary button changes its offer.
    expect(find.text(en.onboardingStart), findsOneWidget);
    expect(find.text(en.next), findsNothing);
    expect(find.text(en.skip), findsNothing);
  });

  testWidgets('finishing marks it seen and hands over to the app', (tester) async {
    await _pump(tester);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text(en.next));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(en.onboardingStart));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(OnboardingScreen.seenKey), isTrue);
  });

  testWidgets('skipping also marks it seen, so it does not come back', (tester) async {
    await _pump(tester);

    await tester.tap(find.text(en.skip));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(OnboardingScreen.seenKey), isTrue);
  });

  testWidgets('renders in Arabic, which is the default language', (tester) async {
    await _pump(tester, locale: const Locale('ar'));

    expect(find.text(ar.onboardingPickPlaceTitle), findsOneWidget);
    expect(find.text(ar.skip), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
