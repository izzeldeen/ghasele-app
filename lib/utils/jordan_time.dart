import 'package:flutter/foundation.dart';

/// The operator's local clock, mirroring `JordanTime` on the backend.
///
/// The schedule is decided in Amman, not on the phone: a window is "13:00 to 14:00"
/// there, and whether it has passed has to be asked in that same clock. Using the
/// device's own `DateTime.now()` would make a phone set to another timezone hide slots
/// the server still accepts - or offer ones it rejects - and the customer would see a
/// schedule that disagrees with the operation.
///
/// Jordan abolished daylight saving in 2022 and sits on a fixed UTC+03, so a constant
/// offset is exact rather than an approximation, and needs no timezone database.
class JordanTime {
  const JordanTime._();

  /// Jordan's fixed offset from UTC.
  static const Duration offset = Duration(hours: 3);

  /// Fixed Amman time for tests, so the rollover rule can be exercised at a chosen hour
  /// instead of only at whatever time the suite happens to run.
  @visibleForTesting
  static DateTime? debugNow;

  /// The current local date and time in Amman, derived from UTC so the device's own
  /// timezone setting cannot shift it.
  static DateTime now() => debugNow ?? DateTime.now().toUtc().add(offset);

  /// Midnight today in Amman.
  static DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }

  /// True when a window on [date] starting at [start] ("HH:mm") is still ahead locally.
  ///
  /// A window is dropped the moment it starts, not when it ends: booking a 13:00-14:00
  /// collection at 13:40 would promise a visit the driver has already made. This is the
  /// same rule the backend applies, so the two cannot disagree about what is bookable.
  static bool isUpcoming(DateTime date, String start) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final todayStart = today();

    if (startOfDay.isAfter(todayStart)) return true;
    if (startOfDay.isBefore(todayStart)) return false;

    final parts = start.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    final n = now();
    return hour * 60 + minute > n.hour * 60 + n.minute;
  }
}
