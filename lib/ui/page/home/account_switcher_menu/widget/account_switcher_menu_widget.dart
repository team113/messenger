import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../themes.dart';
import '../view.dart';

class AccountSwitcherMenuWidget extends StatefulWidget {
  const AccountSwitcherMenuWidget({super.key, required this.child});

  /// widget that viewed in layout
  final Widget child;

  @override
  State<AccountSwitcherMenuWidget> createState() =>
      _AccountSwitcherMenuWidgetState();
}

class _AccountSwitcherMenuWidgetState extends State<AccountSwitcherMenuWidget>
    with SingleTickerProviderStateMixin {
  late final OverlayPortalController _overlayController;

  late final AnimationController _animationController;

  @override
  initState() {
    _overlayController = OverlayPortalController();
    _animationController = AnimationController(
      duration: 150.milliseconds,
      vsync: this,
    );

    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();

    super.dispose();
  }

  void _show() {
    _overlayController.show();
    _animationController
      ..forward()
      ..animateTo(1);
  }

  void _animationStatus(AnimationStatus status) {
    if (!status.isForwardOrCompleted) return;
    _overlayController.hide();

    _animationController.removeStatusListener(_animationStatus);
  }

  void _hide() {
    _animationController
      ..animateTo(0)
      ..addStatusListener(_animationStatus);
  }

  final GlobalKey _portalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return OverlayPortal.overlayChildLayoutBuilder(
      key: _portalKey,

      controller: _overlayController,
      overlayChildBuilder: _buildOverlay,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: _show,
        onSecondaryTap: _show,
        child: widget.child,
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, OverlayChildLayoutInfo info) {
    final Offset childOffset = Offset(
      info.childPaintTransform.row0[3],
      info.childPaintTransform.row1[3],
    );

    final childSize = info.childSize;

    final childCenter = childSize.center(childOffset);
    var style = Theme.of(context).style;
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _hide,
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _animationController,
                    child: child!,
                  );
                },
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.1,
                    ), // Semi-transparent overlay
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  var bottom = (constraints.maxHeight - childOffset.dy + 12);
                  return Positioned(
                    bottom: bottom,
                    right:
                        constraints.maxWidth -
                        childOffset.dx -
                        childSize.width -
                        2,
                    left: math.max(
                      math.min(12, constraints.maxWidth - 500),
                      12,
                    ),
                    child: FadeTransition(
                      opacity: _animationController,
                      child: child!,
                    ),
                  );
                },

                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: math.min(MediaQuery.sizeOf(context).width, 320),
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.deferToChild,
                    // must be empty for cancel propagation click event
                    onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        color: style.colors.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [AccountSwitcherMenuView()],
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Positioned.fromRect(
                    rect: Rect.fromCircle(
                      center: childCenter.translate(0, -1),
                      radius: childSize.width / 2 + 4,
                    ),
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 1,
                        end: 1.1,
                      ).animate(_animationController),
                      child: FadeTransition(
                        opacity: Tween<double>(
                          begin: .7,
                          end: 1,
                        ).animate(_animationController),
                        child: child,
                      ),
                    ),
                  );
                },
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.only(
                      left: 3,
                      right: 3,
                      top: 4,
                      bottom: 2,
                    ),
                    child: Transform.scale(scale: .95, child: widget.child),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
