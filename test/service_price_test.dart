import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/models/service_price.dart';

void main() {
  late AppLocalizations en;
  late AppLocalizations ar;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    ar = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  group('the three shapes a catalogue price can take', () {
    test('base equal to max is a fixed price, not a range of width zero', () {
      const price = ServicePrice(base: 1.25, max: 1.25);

      expect(price.isRange, isFalse);
      expect(price.isOpenEnded, isFalse);
      expect(price.label(ar), '1.25 دينار');
      expect(price.label(en), '1.25 JOD');
    });

    test('max above base reads as a range', () {
      const price = ServicePrice(base: 3, max: 10);

      expect(price.isRange, isTrue);
      expect(price.label(ar), 'من 3 إلى 10 دينار');
      expect(price.label(en), '3 to 10 JOD');
    });

    test('no max reads as a starting price', () {
      const price = ServicePrice(base: 3);

      expect(price.isOpenEnded, isTrue);
      expect(price.isRange, isFalse);
      expect(price.label(ar), 'يبدأ من 3 دينار');
      expect(price.label(en), 'From 3 JOD');
    });
  });

  group('formatting', () {
    test('a whole number loses its decimals, a fractional one keeps two', () {
      expect(const ServicePrice(base: 3).label(en), 'From 3 JOD');
      expect(const ServicePrice(base: 1.5).label(en), 'From 1.50 JOD');
      expect(const ServicePrice(base: 1.25).label(en), 'From 1.25 JOD');
    });

    test('a range of whole numbers stays whole on both ends', () {
      expect(const ServicePrice(base: 3, max: 10).label(en), '3 to 10 JOD');
    });
  });

  group('reading the API payload', () {
    test('picks up both halves of a pair', () {
      final price = ServicePrice.fromJson(
        const {'price': 3.0, 'maxPrice': 10.0},
        baseKey: 'price',
        maxKey: 'maxPrice',
      );

      expect(price, const ServicePrice(base: 3, max: 10));
    });

    test('a missing ceiling means open-ended, not zero', () {
      final price = ServicePrice.fromJson(
        const {'price': 2.0},
        baseKey: 'price',
        maxKey: 'maxPrice',
      );

      expect(price.isOpenEnded, isTrue);
      expect(price.base, 2);
    });

    test('integers from the server are accepted, not just doubles', () {
      final price = ServicePrice.fromJson(
        const {'price': 4, 'maxPrice': 9},
        baseKey: 'price',
        maxKey: 'maxPrice',
      );

      expect(price.label(en), '4 to 9 JOD');
    });
  });

  test('a ceiling below the base is shown as fixed rather than backwards', () {
    // The API rejects this pair, so it should never arrive - but if it does, "from 10 to
    // 3" would be worse than quietly showing the base.
    const price = ServicePrice(base: 10, max: 3);

    expect(price.isRange, isFalse);
    expect(price.label(en), '10 JOD');
  });
}
