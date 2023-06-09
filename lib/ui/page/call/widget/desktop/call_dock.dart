import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../conditional_backdrop.dart';
import '../dock.dart';
import '/themes.dart';
import '/ui/page/home/widget/animated_slider.dart';

/// Builds the [Dock] containing the [CallController.buttons].
class CallDockWidget extends StatelessWidget {
  const CallDockWidget({
    super.key,
    required this.dockKey,
    required this.isOutgoing,
    required this.showBottomUi,
    required this.answer,
    required this.dock,
    required this.acceptAudioButton,
    required this.acceptVideoButton,
    required this.declineButton,
    required this.onEnter,
    required this.onHover,
    required this.onExit,
    required this.listener,
  });

  /// [Key] for handling [dock] widget states.
  final GlobalKey<State<StatefulWidget>> dockKey;

  /// Indicator whether the call is outgoing.
  final bool? isOutgoing;

  /// Indicator whether to show the [dock].
  final bool showBottomUi;

  /// Indicator whether the call is incoming.
  final bool answer;

  /// [Widget] that will be shown at the bottom of the screen.
  final Widget? dock;

  /// [Widget] of the call button with audio.
  final Widget acceptAudioButton;

  /// [Widget] of the call button with video.
  final Widget acceptVideoButton;

  /// [Widget] of the reject call button.
  final Widget declineButton;

  /// Callback, called when the mouse cursor enters the area of this [CallDockWidget].
  final void Function(PointerEnterEvent)? onEnter;

  /// Callback, called when the mouse cursor moves in the area of this
  /// [CallDockWidget].
  final void Function(PointerHoverEvent)? onHover;

  /// Callback, called when the mouse cursor leaves the area of this [CallDockWidget].
  final void Function(PointerExitEvent)? onExit;

  /// Callback, called every time the value of the animation changes.
  final void Function()? listener;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return AnimatedPadding(
      key: const Key('DockedAnimatedPadding'),
      padding: const EdgeInsets.only(bottom: 5),
      curve: Curves.ease,
      duration: 200.milliseconds,
      child: AnimatedSwitcher(
        key: const Key('DockedAnimatedSwitcher'),
        duration: 200.milliseconds,
        child: AnimatedSlider(
          key: const Key('DockedPanelPadding'),
          isOpen: showBottomUi,
          duration: 400.milliseconds,
          translate: false,
          listener: listener,
          child: MouseRegion(
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
              margin: const EdgeInsets.fromLTRB(10, 2, 10, 2),
              child: ConditionalBackdropFilter(
                key: dockKey,
                borderRadius: BorderRadius.circular(30),
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: style.colors.onSecondaryOpacity20,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 5,
                  ),
                  child: answer
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 11),
                            acceptAudioButton,
                            const SizedBox(width: 24),
                            acceptVideoButton,
                            const SizedBox(width: 24),
                            declineButton,
                            const SizedBox(width: 11),
                          ],
                        )
                      : dock,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
