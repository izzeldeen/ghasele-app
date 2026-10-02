import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'generated/l10n/app_localizations.dart';
import 'theme/app_theme.dart';

/// The four-step explanation of how an order works, shown once on a first install and
/// never again.
///
/// It exists because the service does something customers do not expect: the price is
/// settled *after* the driver has collected and itemised the bag, not at checkout. Without
/// that said up front, the first order is placed without a total and the pricing push that
/// follows reads as a surprise charge.
///
/// The illustrations are drawn here rather than being screenshots. Screenshots of a real
/// build age the moment a screen is touched, and two of the four steps - collection and
/// delivery - cannot be photographed at all without an account holding orders in exactly
/// those states. Drawing them keeps every step on the same footing and lets each one show
/// only the part that matters.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  /// Set once the customer has been through this, so it never opens again.
  static const String seenKey = 'onboarding_seen';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const int _stepCount = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Marks the walkthrough as seen and hands over to the app.
  ///
  /// The flag is written before navigating, and a failure to write it is swallowed: being
  /// shown the walkthrough twice is a far smaller problem than being held at it because
  /// storage misbehaved.
  Future<void> _finish() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(OnboardingScreen.seenKey, true);
    } catch (_) {
      // Ignored on purpose - see above.
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/main');
  }

  void _next() {
    if (_page >= _stepCount - 1) {
      _finish();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLast = _page == _stepCount - 1;

    final steps = <_OnboardingStep>[
      _OnboardingStep(
        title: l10n.onboardingPickPlaceTitle,
        body: l10n.onboardingPickPlaceBody,
        art: const _PickPlaceArt(),
      ),
      _OnboardingStep(
        title: l10n.onboardingChooseTimeTitle,
        body: l10n.onboardingChooseTimeBody,
        art: const _ChooseTimeArt(),
      ),
      _OnboardingStep(
        title: l10n.onboardingCollectTitle,
        body: l10n.onboardingCollectBody,
        art: const _CollectArt(),
      ),
      _OnboardingStep(
        title: l10n.onboardingDeliverTitle,
        body: l10n.onboardingDeliverBody,
        art: const _DeliverArt(),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              // Mirrors itself in Arabic, so "skip" sits in the far corner either way.
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: TextButton(
                  // Hidden rather than disabled on the last step: there is nothing left to
                  // skip past, and the primary button already says the same thing.
                  onPressed: isLast ? null : _finish,
                  child: Text(
                    isLast ? '' : l10n.skip,
                    style: const TextStyle(
                      color: AppTheme.neutral500,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _stepCount,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) => _buildStep(steps[index]),
              ),
            ),
            _buildDots(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isLast ? l10n.onboardingStart : l10n.next,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(_OnboardingStep step) {
    // The drawing gives up height before the words do. On a short screen - or with the
    // system font scaled up - the text is what the customer needs, so the illustration
    // shrinks to fit rather than pushing the sentence off the bottom.
    return LayoutBuilder(
      builder: (context, constraints) {
        final artHeight = (constraints.maxHeight * 0.52).clamp(140.0, 320.0);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: ConstrainedBox(
            // Keeps the step centred on a tall screen while still allowing a scroll on a
            // screen too short to hold it.
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // The drawing is decoration, not controls. Nothing inside it responds to
                // a tap, and it is kept out of the semantics tree so a screen reader does
                // not announce a screenful of fake buttons.
                ExcludeSemantics(
                  child: IgnorePointer(
                    child: SizedBox(
                      height: artHeight,
                      // Scales the whole drawing down as one, so the phone frame keeps its
                      // proportions instead of the contents being clipped.
                      child: FittedBox(fit: BoxFit.contain, child: step.art),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.neutral900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  step.body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppTheme.neutral600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_stepCount, (index) {
        final active = index == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          // The current step reads as a bar rather than a bigger dot, so the progress is
          // legible at a glance instead of being a size comparison.
          width: active ? 24 : 8,
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : AppTheme.neutral300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.title,
    required this.body,
    required this.art,
  });

  final String title;
  final String body;
  final Widget art;
}

// ---------------------------------------------------------------------------
// Illustrations
//
// Each one is a simplified stand-in for a real screen, built from the app's own colours
// and shapes so the walkthrough looks like the product rather than like clip art. They
// are deliberately less detailed than the screens they stand for: a faithful copy would
// invite the customer to read it as the live screen and try to use it.
// ---------------------------------------------------------------------------

/// A phone-shaped frame for the drawings to sit in, so each step reads as "a screen".
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.neutral200, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: child,
        ),
      ),
    );
  }
}

/// A flat stand-in for the primary button, used across the drawings.
class _FakeButton extends StatelessWidget {
  const _FakeButton({this.width = 120});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 26,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(9),
      ),
    );
  }
}

/// A grey bar standing in for a line of text, so the drawings suggest content without
/// putting untranslated words inside the phone.
class _FakeLine extends StatelessWidget {
  const _FakeLine({required this.width, this.height = 6, this.color = AppTheme.neutral200});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

/// Step 1 - the map with the pin dropped on the customer's door.
class _PickPlaceArt extends StatelessWidget {
  const _PickPlaceArt();

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Stack(
        children: [
          // The map itself: a wash of the brand's surface green crossed by a couple of
          // roads, which is as much map as this needs to be.
          Positioned.fill(
            child: CustomPaint(painter: _MapPainter()),
          ),
          const Positioned.fill(
            child: Center(
              child: Icon(
                Icons.location_on,
                size: 56,
                color: AppTheme.primary,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _FakeLine(width: 90),
                  SizedBox(height: 6),
                  _FakeLine(width: 60),
                  SizedBox(height: 10),
                  _FakeButton(width: 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 2 - the collection times, with one of them chosen.
class _ChooseTimeArt extends StatelessWidget {
  const _ChooseTimeArt();

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.event_outlined, size: 16, color: AppTheme.primary),
                SizedBox(width: 6),
                _FakeLine(width: 70, height: 7),
              ],
            ),
            const SizedBox(height: 16),
            // Three slots, the middle one selected - the same shape the real picker uses,
            // so the step the customer is about to take is already recognisable.
            _slot(selected: false),
            const SizedBox(height: 8),
            _slot(selected: true),
            const SizedBox(height: 8),
            _slot(selected: false),
            const Spacer(),
            const Center(child: _FakeButton(width: 150)),
          ],
        ),
      ),
    );
  }

  Widget _slot({required bool selected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppTheme.primary : AppTheme.neutral200,
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 14,
            color: selected ? AppTheme.primary : AppTheme.neutral400,
          ),
          const SizedBox(width: 8),
          _FakeLine(
            width: 76,
            color: selected ? AppTheme.primary : AppTheme.neutral200,
          ),
          const Spacer(),
          if (selected)
            const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.primary),
        ],
      ),
    );
  }
}

/// Step 3 - the driver collects the bag and the items are priced.
///
/// The receipt is the point of this drawing. It is the step customers do not expect, so
/// the total is the one piece of real text in any of the illustrations.
class _CollectArt extends StatelessWidget {
  const _CollectArt();

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          // Centred, or the receipt hangs from the top of the frame and leaves a band of
          // empty white under it.
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppTheme.brandGreenSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                size: 32,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            // An itemised list resolving into a total: what the driver hands back after
            // counting the bag.
            _row(),
            const SizedBox(height: 10),
            _row(),
            const SizedBox(height: 10),
            _row(),
            const SizedBox(height: 14),
            Container(height: 1, color: AppTheme.neutral200),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _FakeLine(width: 40, height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.brandGreenSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '12.50',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _FakeLine(width: 80),
        _FakeLine(width: 28),
      ],
    );
  }
}

/// Step 4 - the clean items come back, and the order reads as delivered.
class _DeliverArt extends StatelessWidget {
  const _DeliverArt();

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppTheme.brandGreenSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const _FakeLine(width: 100, height: 8),
            const SizedBox(height: 10),
            const _FakeLine(width: 70),
            const SizedBox(height: 28),
            // The status chip from the orders list, arrived at its last step.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: AppTheme.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The map backdrop for step 1: a tinted field with two roads and a block or two, which
/// reads as a map at a glance without pretending to be anywhere real.
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = AppTheme.brandGreenSurface;
    canvas.drawRect(Offset.zero & size, background);

    final road = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    // A horizontal and a diagonal road, crossing off-centre so the pin does not land on
    // the junction.
    canvas.drawLine(
      Offset(0, size.height * 0.34),
      Offset(size.width, size.height * 0.38),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.28, 0),
      Offset(size.width * 0.52, size.height),
      road,
    );

    final block = Paint()..color = Colors.white.withOpacity(0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.58, size.height * 0.48, 44, 34),
        const Radius.circular(6),
      ),
      block,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.06, size.height * 0.52, 34, 28),
        const Radius.circular(6),
      ),
      block,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
