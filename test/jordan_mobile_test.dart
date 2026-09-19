import 'package:flutter_test/flutter_test.dart';
import 'package:ghasele/utils/jordan_phone.dart';

void main() {
  group('jordanMobileDigits accepts', () {
    // 10 digits, 07 then 7/8/9, in every spelling the field accepts.
    for (final n in ['0771234567', '0781234567', '0791234567']) {
      test(n, () => expect(jordanMobileDigits(n), n.substring(1)));
    }
    test('without the leading zero', () => expect(jordanMobileDigits('791234567'), '791234567'));
    test('with 962', () => expect(jordanMobileDigits('962791234567'), '791234567'));
    test('with +962', () => expect(jordanMobileDigits('+962791234567'), '791234567'));
    test('surrounding whitespace', () => expect(jordanMobileDigits('  0791234567 '), '791234567'));
  });

  group('jordanMobileDigits rejects', () {
    test('third digit 0-6', () {
      for (final d in ['0', '1', '2', '3', '4', '5', '6']) {
        expect(jordanMobileDigits('07${d}1234567'), isNull, reason: '07$d should not be a mobile');
      }
    });
    test('landline 06', () => expect(jordanMobileDigits('0612345678'), isNull));
    test('nine digits total (one short)', () => expect(jordanMobileDigits('079123456'), isNull));
    test('eleven digits total (one long)', () => expect(jordanMobileDigits('07912345678'), isNull));
    test('empty', () => expect(jordanMobileDigits(''), isNull));
    test('letters', () => expect(jordanMobileDigits('07912345ab'), isNull));
  });

  test('the lenient rule is untouched, so sign-in still accepts older numbers', () {
    // localJordanDigits backs login / forgot-password, where the number is only
    // matched against an account that already exists.
    expect(localJordanDigits('0711234567'), '711234567');
    expect(jordanMobileDigits('0711234567'), isNull);
  });

  test('E.164 conversion of an accepted mobile', () {
    expect(jordanPhoneToE164('0791234567'), '+962791234567');
  });
}
