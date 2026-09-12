import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/jordan_time.dart';

/// One bookable collection time from the operator's trip schedule: a recurring window
/// projected onto a single date.
///
/// The app never invents these. Every value comes from `GET /api/delivery-windows/slots`,
/// which is the same schedule the operator edits in the dashboard, so there is one source
/// of truth for when a collection can happen.
class DeliverySlot {
  /// The recurring window this slot came from. Sent back when booking.
  final String windowId;

  /// Local (Amman) collection date.
  final DateTime date;

  /// Window bounds as "HH:mm", exactly as the operator configured them.
  final String start;
  final String end;

  /// How many more orders this slot can take. Zero means fully booked.
  final int remaining;

  const DeliverySlot({
    required this.windowId,
    required this.date,
    required this.start,
    required this.end,
    required this.remaining,
  });

  factory DeliverySlot.fromJson(Map<String, dynamic> json) {
    return DeliverySlot(
      windowId: json['windowId'] as String,
      date: DateTime.parse(json['date'] as String),
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
      // Tolerates an older server that predates capacity reporting: treating the slot as
      // bookable and letting the server reject it is better than hiding the whole schedule.
      remaining: (json['remaining'] as num?)?.toInt() ?? 1,
    );
  }

  bool get isAvailable => remaining > 0;

  /// The date as the API wants it back, "yyyy-MM-dd".
  String get dateKey => DateFormat('yyyy-MM-dd').format(date);

  /// "10:00 AM - 12:00 PM", localized. Built from the raw "HH:mm" strings so the
  /// operator's configured times are what the customer reads.
  String timeRangeLabel(Locale locale) {
    final format = DateFormat.jm(locale.toLanguageTag());
    return '${format.format(_at(start))} - ${format.format(_at(end))}';
  }

  /// The whole choice on one line: "اليوم (١:٠٠ م - ٢:٠٠ م)" or "غداً (١:٠٠ م - ٢:٠٠ م)".
  ///
  /// Today and tomorrow read as words because that is how a customer thinks about them.
  /// Anything further out falls back to a short date ("١٥ سبتمبر") - unreachable while the
  /// booking horizon is two days, but it keeps the label honest if the horizon widens or
  /// if an open sheet crosses midnight, rather than calling a later day "tomorrow".
  ///
  /// Built with `intl` so the numerals, month name and meridiem all follow the app's
  /// locale, and composed day-first so it reads naturally in both LTR and RTL.
  String dateTimeLabel(
    Locale locale, {
    required DateTime today,
    required String todayLabel,
    required String tomorrowLabel,
  }) {
    final difference = DateUtils.dateOnly(date).difference(DateUtils.dateOnly(today)).inDays;
    final day = difference == 0
        ? todayLabel
        : difference == 1
            ? tomorrowLabel
            : shortDateLabel(locale);
    return '$day (${timeRangeLabel(locale)})';
  }

  /// "12 Sep", for days beyond tomorrow where a relative label would not help.
  String shortDateLabel(Locale locale) =>
      DateFormat.MMMd(locale.toLanguageTag()).format(date);

  /// Parses "HH:mm" onto an arbitrary date - only the time is ever formatted.
  DateTime _at(String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// The slots to offer, as one flat list in schedule order.
  ///
  /// The server has already dropped today's started windows and returns the rest
  /// date-ascending then time-ascending, so this deliberately does NOT re-sort or
  /// re-derive the schedule - that would be a second place deciding what is bookable,
  /// and the two would eventually disagree.
  ///
  /// What it does add is a guard against the list going stale in the customer's hands:
  /// the checkout sheet can sit open while a window starts, and an option that is now in
  /// the past has to stop being offered even though the fetch said otherwise. The rule
  /// and the clock are the backend's, via [JordanTime], so a slot dropped here is exactly
  /// one the server would now reject.
  ///
  /// Rollover needs no special case. Today's elapsed windows simply fall away, and
  /// because every window recurs daily the same times are already present on the
  /// following dates - so the first item becomes tomorrow's first slot on its own.
  static List<DeliverySlot> bookable(List<DeliverySlot> slots) =>
      slots.where((s) => JordanTime.isUpcoming(s.date, s.start)).toList();
}
