import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghasele/models/delivery_slot.dart';
import 'package:ghasele/utils/jordan_time.dart';
import 'package:intl/date_symbol_data_local.dart';

/// `intl` separates the time from the meridiem with a narrow no-break space (U+202F).
/// It is invisible in a failure diff, so comparing raw strings fails for a reason that
/// tells you nothing. These assertions are about wording and order, not which flavour of
/// space the formatter chose.
String _plain(String s) => s.replaceAll(RegExp(r'\s'), ' ');

/// The operator's three windows, as configured in the dashboard.
const _windows = [
  ('d1', '13:00', '14:00'),
  ('d2', '15:00', '16:00'),
  ('d3', '19:00', '20:00'),
];

/// Builds what `GET /api/delivery-windows/slots` returns: every window projected onto
/// each of the next [days] dates, date-ascending then time-ascending.
///
/// Deliberately unfiltered - the point of these tests is what the app does with a list
/// that has aged since it was fetched.
List<DeliverySlot> _slotsFrom(DateTime firstDate, {int days = 3, int remaining = 20}) {
  return [
    for (var d = 0; d < days; d++)
      for (final (id, start, end) in _windows)
        DeliverySlot(
          windowId: id,
          date: firstDate.add(Duration(days: d)),
          start: start,
          end: end,
          remaining: remaining,
        ),
  ];
}

void main() {
  setUpAll(initializeDateFormatting);

  // 12 Sep 2026 in Amman. Each test pins the hour it needs.
  final today = DateTime(2026, 9, 12);
  final tomorrow = DateTime(2026, 9, 13);

  tearDown(() => JordanTime.debugNow = null);

  group('bookable - rollover', () {
    test('before any window has started, every window is offered for today', () {
      JordanTime.debugNow = DateTime(2026, 9, 12, 9, 0);

      final slots = DeliverySlot.bookable(_slotsFrom(today));
      final todays = slots.where((s) => s.dateKey == '2026-09-12');

      expect(todays.map((s) => s.start), ['13:00', '15:00', '19:00']);
      // The soonest collection is the first thing in the list.
      expect(slots.first.dateKey, '2026-09-12');
      expect(slots.first.start, '13:00');
    });

    test('mid-afternoon, started windows drop and later ones stay on today', () {
      // 15:12 - the 13:00 window is over and the 15:00 one has already begun.
      JordanTime.debugNow = DateTime(2026, 9, 12, 15, 12);

      final slots = DeliverySlot.bookable(_slotsFrom(today));

      expect(
        slots.where((s) => s.dateKey == '2026-09-12').map((s) => s.start),
        ['19:00'],
      );
      // The dropped times are still bookable tomorrow, because the windows recur.
      expect(
        slots.where((s) => s.dateKey == '2026-09-13').map((s) => s.start),
        ['13:00', '15:00', '19:00'],
      );
    });

    test('a window is dropped when it starts, not when it ends', () {
      // 13:40: inside 13:00-14:00. The driver has already been.
      JordanTime.debugNow = DateTime(2026, 9, 12, 13, 40);

      final slots = DeliverySlot.bookable(_slotsFrom(today));

      expect(slots.any((s) => s.dateKey == '2026-09-12' && s.start == '13:00'), isFalse);
    });

    test('once all of today has elapsed, the list rolls over to tomorrow', () {
      JordanTime.debugNow = DateTime(2026, 9, 12, 19, 22);

      final slots = DeliverySlot.bookable(_slotsFrom(today));

      expect(slots.where((s) => s.dateKey == '2026-09-12'), isEmpty);
      // The first item is tomorrow's first slot - no empty day, no "nothing available".
      expect(slots.first.dateKey, '2026-09-13');
      expect(slots.first.start, '13:00');
      expect(slots, isNotEmpty);
    });

    test('a past date is never offered, whatever the time of day', () {
      JordanTime.debugNow = DateTime(2026, 9, 12, 0, 5);

      final slots = DeliverySlot.bookable(_slotsFrom(DateTime(2026, 9, 11)));

      expect(slots.any((s) => s.dateKey == '2026-09-11'), isFalse);
    });

    test('an empty schedule stays empty rather than inventing a slot', () {
      JordanTime.debugNow = DateTime(2026, 9, 12, 10, 0);

      expect(DeliverySlot.bookable(const []), isEmpty);
    });
  });

  group('dateTimeLabel', () {
    const arabic = Locale('ar');
    const english = Locale('en');

    DeliverySlot slotOn(DateTime date) => DeliverySlot(
          windowId: 'd1',
          date: date,
          start: '13:00',
          end: '14:00',
          remaining: 5,
        );

    test('today and tomorrow use the relative words, with the window in brackets', () {
      expect(
        _plain(slotOn(today)
            .dateTimeLabel(english, today: today, todayLabel: 'Today', tomorrowLabel: 'Tomw')),
        'Today (1:00 PM - 2:00 PM)',
      );
      expect(
        _plain(slotOn(tomorrow)
            .dateTimeLabel(english, today: today, todayLabel: 'Today', tomorrowLabel: 'Tomw')),
        'Tomw (1:00 PM - 2:00 PM)',
      );
    });

    test('beyond tomorrow falls back to a short date', () {
      final label = _plain(slotOn(DateTime(2026, 9, 15)).dateTimeLabel(
        english,
        today: today,
        todayLabel: 'Today',
        tomorrowLabel: 'Tomw',
      ));

      expect(label, 'Sep 15 (1:00 PM - 2:00 PM)');
      expect(label, isNot(contains('Tomw')));
    });

    test('Arabic renders the day, month and meridiem in Arabic', () {
      final label = slotOn(DateTime(2026, 9, 15)).dateTimeLabel(
        arabic,
        today: today,
        todayLabel: 'اليوم',
        tomorrowLabel: 'غداً',
      );

      // Localised numerals and month, not a Western date pushed through an Arabic UI.
      expect(label, contains('سبتمبر'));
      expect(label, contains('م'));
      expect(label, isNot(contains('Sep')));
    });

    test('the relative word comes first, so the day reads before the window', () {
      final label = slotOn(tomorrow).dateTimeLabel(
        arabic,
        today: today,
        todayLabel: 'اليوم',
        tomorrowLabel: 'غداً',
      );

      expect(label.startsWith('غداً ('), isTrue);
      expect(label.endsWith(')'), isTrue);
    });
  });
}
