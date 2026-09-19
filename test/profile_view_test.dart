import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/providers/locale_provider.dart';
import 'package:ghasele/views/profile_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A signed-in session, as the login screen writes it.
const _signedIn = {
  'auth_token': 'token-abc',
  'user_id': '11111111-1111-1111-1111-111111111111',
  'user_fullname': 'Izz Kalbouneh',
  'user_phone': '+962790000001',
  'user_username': '+962790000001',
  'user_email': '',
};

Future<void> _pump(WidgetTester tester, {Locale locale = const Locale('en')}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: const ProfileView(),
      ),
    ),
  );
  // The session read is async; let it land.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// The l10n strings for the locale under test, so assertions never hard-code UI copy.
AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(ProfileView)))!;

void main() {
  group('guest', () {
    testWidgets('opens the tab instead of demanding a sign-in', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pump(tester);

      final l10n = _l10n(tester);
      // The whole point of the change: the screen renders, rather than the tab bouncing the
      // customer to a full-screen login that reads as having been signed out.
      expect(find.byType(ProfileView), findsOneWidget);
      expect(find.text(l10n.guest), findsOneWidget);
      expect(find.text(l10n.browsingAsGuest), findsOneWidget);
      expect(find.text(l10n.guestBenefitsTitle), findsOneWidget);
    });

    testWidgets('can still change the language', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pump(tester);

      // Language belongs to the handset, not to an account - an Arabic speaker must not have
      // to register before they can read the app.
      expect(find.text(_l10n(tester).language), findsOneWidget);

      // Below the fold on a test-sized viewport, under the header and the benefits card.
      await tester.ensureVisible(find.text(_l10n(tester).language));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_l10n(tester).language));
      await tester.pumpAndSettle();

      expect(find.text(_l10n(tester).chooseLanguage), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);
      // Two: the row's current value behind the sheet, and the sheet's own option.
      expect(find.text('English'), findsNWidgets(2));
    });

    testWidgets('is offered no session controls it cannot use', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pump(tester);

      final l10n = _l10n(tester);
      expect(find.text(l10n.signIn), findsOneWidget);
      expect(find.text(l10n.logout), findsNothing);
      expect(find.text(l10n.deleteAccount), findsNothing);
      // Nothing to edit without an account.
      expect(find.text(l10n.name), findsNothing);
      expect(find.text(l10n.phone), findsNothing);
    });
  });

  group('signed in', () {
    testWidgets('shows the stored name and phone as editable rows', (tester) async {
      SharedPreferences.setMockInitialValues(_signedIn);
      await _pump(tester);

      final l10n = _l10n(tester);
      expect(find.text(l10n.name), findsOneWidget);
      expect(find.text(l10n.phone), findsOneWidget);
      expect(find.text('Izz Kalbouneh'), findsWidgets);
      expect(find.text('+962790000001'), findsWidgets);

      // A pencil on each, so the row says it edits in place before it is tapped.
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
      expect(find.text(l10n.guestBenefitsTitle), findsNothing);
    });

    testWidgets('opens the name editor seeded with the current name', (tester) async {
      SharedPreferences.setMockInitialValues(_signedIn);
      await _pump(tester);

      final l10n = _l10n(tester);
      await tester.tap(find.text(l10n.name));
      await tester.pumpAndSettle();

      expect(find.text(l10n.editName), findsOneWidget);
      expect(find.text(l10n.nameChangeNote), findsOneWidget);

      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.controller!.text, 'Izz Kalbouneh');
    });

    testWidgets('seeds the phone editor with the local digits, not E.164', (tester) async {
      SharedPreferences.setMockInitialValues(_signedIn);
      await _pump(tester);

      await tester.tap(find.text(_l10n(tester).phone));
      await tester.pumpAndSettle();

      // The field sits next to a "+962 " prefix, so showing the stored +962790000001 would
      // read as +962 +962790000001.
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.controller!.text, '790000001');
    });

    testWidgets('refuses a phone number that is not a Jordan mobile', (tester) async {
      SharedPreferences.setMockInitialValues(_signedIn);
      await _pump(tester);

      final l10n = _l10n(tester);
      await tester.tap(find.text(l10n.phone));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '12345');
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      expect(find.text(l10n.invalidPhoneNumber), findsOneWidget);
      // Still open: a rejected save must not look like a successful one.
      expect(find.text(l10n.editPhoneNumber), findsOneWidget);
    });

    testWidgets('refuses an empty name', (tester) async {
      SharedPreferences.setMockInitialValues(_signedIn);
      await _pump(tester);

      final l10n = _l10n(tester);
      await tester.tap(find.text(l10n.name));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '   ');
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      expect(find.text(l10n.pleaseEnterName), findsOneWidget);
    });

    testWidgets('hides the email row when the account has none', (tester) async {
      SharedPreferences.setMockInitialValues(_signedIn);
      await _pump(tester);

      // Phone-first signup collects no email; an empty row would be pure noise.
      expect(find.text(_l10n(tester).email), findsNothing);
    });

    testWidgets('shows the email row when there is one', (tester) async {
      SharedPreferences.setMockInitialValues({
        ..._signedIn,
        'user_email': 'izz@example.com',
      });
      await _pump(tester);

      expect(find.text(_l10n(tester).email), findsOneWidget);
      expect(find.text('izz@example.com'), findsOneWidget);
    });
  });

  group('arabic', () {
    testWidgets('renders the guest state in Arabic', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pump(tester, locale: const Locale('ar'));

      final l10n = _l10n(tester);
      expect(l10n.browsingAsGuest, 'أنت تتصفح كضيف');
      expect(find.text(l10n.browsingAsGuest), findsOneWidget);
    });

    testWidgets('keeps the phone number left-to-right', (tester) async {
      SharedPreferences.setMockInitialValues(_signedIn);
      await _pump(tester, locale: const Locale('ar'));

      // A number under an RTL ambient direction renders as "962790000001+" without this.
      final ltr = find.ancestor(
        of: find.text('+962790000001').first,
        matching: find.byType(Directionality),
      );
      expect(
        tester.widgetList<Directionality>(ltr).first.textDirection,
        TextDirection.ltr,
      );
    });
  });
}
