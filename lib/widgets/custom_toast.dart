import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ghasele/theme/app_theme.dart';

enum ToastType { success, error, info, warning }

/// Centre-screen message popup.
///
/// Named "toast" for history: it started as a banner sliding in from the top and
/// the call sites - 36 of them - still read `CustomToast.show(...)`. The
/// signature is deliberately unchanged so the presentation could be reworked
/// without touching a single caller.
class CustomToast {
  static void show(
    BuildContext context, {
    required String message,
    required ToastType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          // The widget drives its own removal so the exit animation can finish
          // first; guarded because a tap and the auto-dismiss timer can both
          // land, and removing an entry twice throws.
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  Timer? _autoDismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 180),
      vsync: this,
    );

    // Settles slightly past full size rather than springing hard: this sits in
    // the middle of the screen where an exaggerated bounce reads as a glitch.
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
    _autoDismissTimer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_isDismissing) return;
    _isDismissing = true;

    _autoDismissTimer?.cancel();
    await _controller.reverse();

    if (mounted) widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final _ToastStyle style = _styleFor(widget.type);

    return Positioned.fill(
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          // Tap anywhere to dismiss early. The scrim also swallows taps, so a
          // message cannot be missed by the user acting on the screen beneath it.
          onTap: _dismiss,
          behavior: HitTestBehavior.opaque,
          child: Material(
            color: Colors.black.withValues(alpha: 0.45),
            child: Center(
              child: ScaleTransition(
                scale: _scale,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  constraints: const BoxConstraints(maxWidth: 340),
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          // Tinted wash rather than a solid fill - the status
                          // colour still reads at a glance without competing
                          // with the brand green used for actions.
                          color: style.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(style.icon, size: 38, color: style.color),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.neutral800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ToastStyle _styleFor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const _ToastStyle(AppTheme.success, Icons.check_circle_rounded);
      case ToastType.error:
        return const _ToastStyle(AppTheme.error, Icons.error_rounded);
      case ToastType.info:
        return const _ToastStyle(AppTheme.info, Icons.info_rounded);
      case ToastType.warning:
        return const _ToastStyle(
          AppTheme.warning,
          Icons.warning_amber_rounded,
        );
    }
  }
}

class _ToastStyle {
  final Color color;
  final IconData icon;

  const _ToastStyle(this.color, this.icon);
}
