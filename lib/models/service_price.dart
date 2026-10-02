import 'package:flutter/widgets.dart';

import '../generated/l10n/app_localizations.dart';

/// What one service costs for one item type: a base price, and optionally a ceiling.
///
/// A catalogue price is a quote rather than a bill. What an evening dress costs is not
/// knowable until a driver has the garment in hand, so most items carry a range and the
/// final figure is settled at collection.
///
/// The shape of that quote decides how it reads, and there are exactly three shapes:
///
/// | base | max        | shown as              |
/// |------|------------|-----------------------|
/// | 1.25 | 1.25       | `1.25 دينار`          |
/// | 3    | 10         | `من 3 إلى 10 دينار`   |
/// | 3    | null       | `يبدأ من 3 دينار`     |
///
/// The rule lives here rather than in the screen so that every place a price appears
/// agrees on it - a price that reads as fixed on one screen and open-ended on another is
/// worse than either reading on its own.
@immutable
class ServicePrice {
  const ServicePrice({required this.base, this.max});

  /// The least this service can cost. Always present.
  final double base;

  /// The most it can cost, or null when the price is open-ended.
  final double? max;

  /// Reads the pair out of an item-type payload, e.g. `cleaningPrice` + `cleaningMaxPrice`.
  ///
  /// Tolerates a server that predates the ceiling: a missing `maxKey` simply means an
  /// open-ended price, which is what every item was before ranges existed.
  factory ServicePrice.fromJson(
    Map<String, dynamic> json, {
    required String baseKey,
    required String maxKey,
  }) {
    return ServicePrice(
      base: (json[baseKey] as num?)?.toDouble() ?? 0,
      max: (json[maxKey] as num?)?.toDouble(),
    );
  }

  /// True when the ceiling is genuinely above the floor, so there is a range to show.
  ///
  /// A ceiling equal to the base is a fixed price, not a range of width zero. A ceiling
  /// below the base should never arrive - the API rejects it - but if one does it is
  /// treated as fixed rather than rendered as "from 10 to 3".
  bool get isRange => max != null && max! > base;

  /// True when no ceiling has been set, so the base is a starting price.
  bool get isOpenEnded => max == null;

  /// The whole price as one localized phrase, currency included.
  String label(AppLocalizations l10n) {
    if (isRange) {
      return l10n.priceRange(_format(base), _format(max!));
    }
    if (isOpenEnded) {
      return l10n.priceStartingFrom(_format(base));
    }
    return l10n.priceFixed(_format(base));
  }

  /// Trims the trailing decimals a whole number does not need: prices are quoted as "3"
  /// and "1.25", not "3.00" - and a range of "from 3.00 to 10.00" reads like a machine.
  static String _format(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  @override
  bool operator ==(Object other) =>
      other is ServicePrice && other.base == base && other.max == max;

  @override
  int get hashCode => Object.hash(base, max);
}
