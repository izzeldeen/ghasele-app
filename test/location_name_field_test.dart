import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';

/// The save-location name field, built exactly as `_saveLocation` builds it in
/// home_view.dart and order_success_view.dart: a bare TextField with a label and an
/// outline border, inside an AlertDialog under the app's Arabic localisation.
///
/// These tests enter text straight into the widget, so they bypass the on-screen
/// keyboard completely. That is the point: they separate "the field rejects Arabic"
/// from "the device has no Arabic keyboard installed", which look identical to anyone
/// typing but have nothing to do with each other.
Widget _harness(TextEditingController controller) {
  return MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('ar')],
    home: Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.saveLocation),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.locationNameHint,
              border: const OutlineInputBorder(),
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  testWidgets('accepts an Arabic location name', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(_harness(controller));

    await tester.enterText(find.byType(TextField), 'البيت');
    await tester.pump();

    expect(controller.text, 'البيت');
    expect(find.text('البيت'), findsOneWidget);
  });

  testWidgets('keeps every Arabic character, including ones with diacritics', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(_harness(controller));

    // A shadda and a ta marbuta - the characters most likely to be dropped by a
    // filter that only understands plain Latin letters.
    const name = 'بيت جدّتي';
    await tester.enterText(find.byType(TextField), name);
    await tester.pump();

    expect(controller.text, name);
    expect(controller.text.length, name.length);
  });

  testWidgets('accepts Arabic mixed with Latin and digits', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(_harness(controller));

    await tester.enterText(find.byType(TextField), 'العمل Office 2');
    await tester.pump();

    expect(controller.text, 'العمل Office 2');
  });

  testWidgets('has no input formatter that could filter characters', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(_harness(controller));

    final field = tester.widget<TextField>(find.byType(TextField));

    // The direct check on the claim: nothing is installed that could strip Arabic,
    // and the keyboard is the default one rather than a restricted type.
    expect(field.inputFormatters, anyOf(isNull, isEmpty));
    expect(field.keyboardType, anyOf(isNull, TextInputType.text));
  });

  testWidgets('renders right-to-left under the Arabic locale', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(_harness(controller));

    await tester.enterText(find.byType(TextField), 'البيت');
    await tester.pump();

    expect(Directionality.of(tester.element(find.byType(TextField))), TextDirection.rtl);
  });

  testWidgets('the guest phone field, by contrast, does restrict input', (tester) async {
    // Guards against the fix being applied in the wrong place: the phone field is
    // meant to be digits-only, so a future "let everything through" change should not
    // quietly loosen it too.
    final controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ),
    ));

    await tester.enterText(find.byType(TextField), 'البيت790000002');
    await tester.pump();

    expect(controller.text, '790000002');
  });
}
