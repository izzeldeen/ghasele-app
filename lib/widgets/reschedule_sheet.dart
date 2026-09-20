import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/delivery_slot.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/jordan_time.dart';
import 'custom_toast.dart';

/// Lets the customer move an order they have already placed to a different collection
/// slot, and returns the updated order, or null if they backed out.
///
/// Deliberately fetches the schedule itself rather than being handed one: the slots the
/// checkout sheet listed may be hours old by the time an order is being rescheduled, and
/// a stale list would offer times that have since filled up or started.
Future<Map<String, dynamic>?> showRescheduleSheet(
  BuildContext context, {
  required String orderId,

  /// The signed-in customer's token, or null for a guest - whose order is identified by
  /// the device token [ApiService] sends on every request.
  String? token,

  /// The slot the order currently holds, so it can be shown as the current choice
  /// rather than making the customer remember what they booked.
  String? currentWindowId,
  String? currentDateKey,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _RescheduleSheet(
      orderId: orderId,
      token: token,
      currentWindowId: currentWindowId,
      currentDateKey: currentDateKey,
    ),
  );
}

class _RescheduleSheet extends StatefulWidget {
  const _RescheduleSheet({
    required this.orderId,
    required this.token,
    required this.currentWindowId,
    required this.currentDateKey,
  });

  final String orderId;
  final String? token;
  final String? currentWindowId;
  final String? currentDateKey;

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  /// Matches the horizon the checkout sheet books against, so the customer is not offered
  /// a different range of days depending on which screen they came from.
  static const int _scheduleHorizonDays = 2;

  List<DeliverySlot> _slots = <DeliverySlot>[];
  DeliverySlot? _selected;
  bool _loading = true;

  /// Kept apart from an empty [_slots]: "we could not reach the schedule" and "the
  /// operator has published nothing" need different things from the customer.
  bool _failed = false;

  /// True while the new slot is being saved, so the confirm button cannot be tapped twice
  /// - a second tap would book the order into the slot it is already being moved to.
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    try {
      final result = await ApiService.getDeliverySlots(days: _scheduleHorizonDays);
      if (!mounted) return;

      if (result['success'] != true) {
        setState(() {
          _loading = false;
          _failed = true;
        });
        return;
      }

      final slots = (result['data'] as List<dynamic>)
          .map((e) => DeliverySlot.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _slots = slots;
        _loading = false;
        _failed = false;
        // Pre-selecting the current slot would make "save" a no-op the customer has to
        // notice; they are here to pick a different time, so nothing starts selected.
        _selected = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  /// True for the slot the order already holds, which is shown as such rather than as a
  /// choice: booking it again would change nothing.
  bool _isCurrent(DeliverySlot slot) =>
      slot.windowId == widget.currentWindowId && slot.dateKey == widget.currentDateKey;

  Future<void> _save() async {
    final slot = _selected;
    if (slot == null || _saving) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);

    final result = await ApiService.rescheduleOrder(
      orderId: widget.orderId,
      deliveryWindowId: slot.windowId,
      scheduledDate: slot.dateKey,
      token: widget.token,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pop(context, result['data'] as Map<String, dynamic>);
      return;
    }

    setState(() => _saving = false);

    // The server's message is already in the customer's language and says which of the
    // several "that time is gone" cases this was, so it is shown as-is.
    CustomToast.show(
      context,
      message: (result['message'] as String?) ?? l10n.collectionTimesFailed,
      type: ToastType.error,
    );

    // Whatever went wrong, the list that produced it is out of date - a slot that just
    // filled up must stop being offered.
    _fetchSlots();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.neutral200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.event_repeat_rounded, color: AppTheme.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.changeCollectionTime,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.neutral900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBody(l10n: l10n, locale: locale),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // Disabled until something is chosen, so the button never posts the slot
              // the order already has.
              onPressed: _selected == null || _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                disabledBackgroundColor: AppTheme.neutral200,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n.saveNewTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: Text(
                l10n.close,
                style: const TextStyle(
                  color: AppTheme.neutral600,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({required AppLocalizations l10n, required Locale locale}) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_failed) {
      return _notice(
        text: l10n.collectionTimesFailed,
        action: GestureDetector(
          onTap: () {
            setState(() {
              _loading = true;
              _failed = false;
            });
            _fetchSlots();
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                l10n.tryAgain,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final slots = DeliverySlot.bookable(_slots);
    if (slots.isEmpty) {
      return _notice(text: l10n.noCollectionTimes);
    }

    // The operator's clock, not the phone's, so "today" means the same day the backend
    // meant when it built this list.
    final today = JordanTime.today();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.35,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: slots.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _buildSlotTile(
          slot: slots[index],
          locale: locale,
          l10n: l10n,
          today: today,
        ),
      ),
    );
  }

  Widget _notice({required String text, Widget? action}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutral50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(fontSize: 13, color: AppTheme.neutral600, height: 1.4),
          ),
          if (action != null) ...[const SizedBox(height: 8), action],
        ],
      ),
    );
  }

  /// One option in the list, styled to match the checkout sheet so a customer changing a
  /// time is looking at the same schedule they booked from.
  Widget _buildSlotTile({
    required DeliverySlot slot,
    required Locale locale,
    required AppLocalizations l10n,
    required DateTime today,
  }) {
    final isCurrent = _isCurrent(slot);
    final selected = _selected?.windowId == slot.windowId &&
        _selected?.dateKey == slot.dateKey;
    // The order's own slot stays visible but unselectable: seeing the time they booked
    // still on the list is how the customer knows the list is the whole schedule.
    final selectable = slot.isAvailable && !isCurrent;

    return GestureDetector(
      onTap: selectable ? () => setState(() => _selected = slot) : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.neutral200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 18,
              color: !selectable
                  ? AppTheme.neutral400
                  : (selected ? AppTheme.primary : AppTheme.neutral500),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                slot.dateTimeLabel(
                  locale,
                  today: today,
                  todayLabel: l10n.today,
                  tomorrowLabel: l10n.tomorrow,
                ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: !selectable
                      ? AppTheme.neutral400
                      : (selected ? AppTheme.primary : AppTheme.neutral900),
                ),
              ),
            ),
            if (isCurrent)
              Text(
                l10n.currentTime,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.neutral500,
                ),
              )
            else if (!slot.isAvailable)
              Text(
                l10n.fullyBooked,
                style: TextStyle(fontSize: 12, color: AppTheme.neutral400),
              )
            else if (selected)
              const Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}
