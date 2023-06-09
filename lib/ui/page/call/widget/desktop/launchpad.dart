import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../conditional_backdrop.dart';
import '/themes.dart';
import '/ui/page/call/component/common.dart';

/// Builds the more panel containing the [CallController.panel].
class LaunchpadWidget extends StatelessWidget {
  const LaunchpadWidget({
    super.key,
    required this.enabled,
    required this.displayMore,
    required this.test,
    required this.onEnter,
    required this.onHover,
    required this.onExit,
    required this.onAccept,
    required this.onWillAccept,
    required this.paneledItems,
  });

  /// TODO: docs
  final bool enabled;

  /// Indicator whether additional elements should be displayed
  /// in [Launchpad].
  final bool displayMore;

  /// TODO: docs
  final List<Widget> paneledItems;

  /// Indicator whether at least one element from the [panel] list satisfies
  /// the condition set by the [test] function.
  final bool Function(CallButton?) test;

  /// Callback, called when the mouse cursor enters the area of this [CallDockWidget].
  final void Function(PointerEnterEvent)? onEnter;

  /// Callback, called when the mouse cursor moves in the area of this
  /// [CallDockWidget].
  final void Function(PointerHoverEvent)? onHover;

  /// Callback, called when the mouse cursor leaves the area of this [CallDockWidget].
  final void Function(PointerExitEvent)? onExit;

  /// Callback, called when accepting a draggable element.
  final void Function(CallButton)? onAccept;

  /// Callback, called when the dragged element is above
  /// the widget, but has not yet been released.
  final bool Function(CallButton?)? onWillAccept;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    /// Builder function for the [DragTarget].
    ///
    /// It is responsible for displaying the visual interface when dragging
    /// elements onto the target.
    Widget launchpadBuilder(
      BuildContext context,
      List<CallButton?> candidate,
      List<dynamic> rejected,
    ) {
      return MouseRegion(
        onEnter: onEnter,
        onHover: onHover,
        onExit: onExit,
        child: Container(
          decoration: BoxDecoration(
            color: style.colors.transparent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              CustomBoxShadow(
                color: style.colors.onBackgroundOpacity20,
                blurRadius: 8,
                blurStyle: BlurStyle.outer,
              )
            ],
          ),
          margin: const EdgeInsets.all(2),
          child: ConditionalBackdropFilter(
            borderRadius: BorderRadius.circular(30),
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: candidate.any(test)
                    ? style.colors.onSecondaryOpacity88
                    : style.colors.onSecondaryOpacity60,
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 35),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.start,
                      alignment: WrapAlignment.center,
                      spacing: 4,
                      runSpacing: 21,
                      children: paneledItems,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: displayMore ? 1.0 : 0.0,
        child: displayMore
            ? DragTarget<CallButton>(
                onAccept: onAccept,
                onWillAccept: onWillAccept,
                builder: launchpadBuilder,
              )
            : const SizedBox(),
      ),
    );
  }
}
