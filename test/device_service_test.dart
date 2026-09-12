import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ghasele/services/device_service.dart';
import 'package:ghasele/utils/jordan_phone.dart';

void main() {
  group('DeviceService.ensureToken', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      DeviceService.debugReset();
    });

    test('generates a token on first launch and persists it', () async {
      final token = await DeviceService.ensureToken();

      expect(token, isNotEmpty);
      expect(DeviceService.token, token);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('device_token'), token);
    });

    test('returns the stored token on later launches', () async {
      // A guest's orders and tickets are filed under this value, so a token that
      // changed between launches would lose their whole history.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'device_token': 'existing-token-value',
      });

      expect(await DeviceService.ensureToken(), 'existing-token-value');
    });

    test('is stable across repeated calls in one session', () async {
      final first = await DeviceService.ensureToken();
      expect(await DeviceService.ensureToken(), first);
    });

    test('generates a different token per install', () async {
      final first = await DeviceService.ensureToken();

      SharedPreferences.setMockInitialValues(<String, Object>{});
      DeviceService.debugReset();
      final second = await DeviceService.ensureToken();

      // Whoever holds the token can read that device's guest records, so two
      // installs must never collide onto one.
      expect(second, isNot(first));
      expect(first, hasLength(32));
      expect(first, matches(RegExp(r'^[0-9a-f]{32}$')));
    });
  });

  group('jordanPhoneToE164', () {
    test('normalises every accepted spelling to one stored form', () {
      for (final raw in <String>[
        '791234567',
        '0791234567',
        '962791234567',
        '+962791234567',
        '  791234567  ',
      ]) {
        expect(jordanPhoneToE164(raw), '+962791234567', reason: raw);
      }
    });

    test('rejects numbers of the wrong length', () {
      expect(jordanPhoneToE164('79123456'), isNull);
      expect(jordanPhoneToE164('7912345678'), isNull);
      expect(jordanPhoneToE164(''), isNull);
    });
  });
}
