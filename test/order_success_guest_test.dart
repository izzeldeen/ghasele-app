import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/views/order_success_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the order-success screen with the route arguments it is pushed with.
Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('ar')],
    onGenerateRoute: (_) => MaterialPageRoute(
      builder: (_) => const OrderSuccessView(),
      settings: const RouteSettings(arguments: {
        'lat': 31.9539,
        'lng': 35.9106,
        'address': 'Jabal Amman',
      }),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('a guest is not offered the save-location prompt', (tester) async {
    // No session at all - the guest-checkout case.
    SharedPreferences.setMockInitialValues({});

    await _pump(tester);
    // The session read is async; let it land.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));

    // The order itself still confirms.
    expect(find.text(l10n.orderSuccessTitle), findsOneWidget);

    // But nothing offers to save a location, so the dialog and its name field are
    // unreachable rather than leading to a save that cannot happen.
    expect(find.text(l10n.saveLocation), findsNothing);
    expect(find.text(l10n.askSaveLocation), findsNothing);
    expect(find.byIcon(Icons.bookmark_add_rounded), findsNothing);
  });

  testWidgets('the prompt stays hidden while the session is still being read', (tester) async {
    // _isGuest starts true on purpose: the prompt must never flash on screen and then
    // be withdrawn once the session turns out to be absent.
    SharedPreferences.setMockInitialValues({});

    await _pump(tester);
    // Deliberately no settle - this is the first frame.

    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(find.text(l10n.askSaveLocation), findsNothing);
  });

  testWidgets('an empty-string token counts as a guest, not a session', (tester) async {
    // Cleared sessions have been written as '' rather than removed before now, so a
    // null check alone would treat a signed-out customer as signed in.
    SharedPreferences.setMockInitialValues({'auth_token': '', 'user_id': ''});

    await _pump(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(find.text(l10n.askSaveLocation), findsNothing);
  });
}
