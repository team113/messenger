import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/l10n/l10n.dart';

import '../../../../../domain/repository/chat.dart';
import '../../../../widget/svg/svg.dart';
import '../../../home/widget/avatar.dart';
import '../../controller.dart';
import '../tooltip_button.dart';

/// [Widget] that displays the title bar at the top of the screen.
///
/// [TitleBar] contains information such as the recipient or caller's
/// name, avatar, and call state, as well as buttons for full-screen mode
/// and other actions.
class TitleBar extends StatelessWidget {
  const TitleBar({
    super.key,
    required this.constraints,
    required this.chat,
    required this.titleArguments,
    required this.fullscreen,
    this.onDoubleTap,
    this.onTap,
    this.toggleFullscreen,
  });

  /// Callback called when double-tapping on the [TitleBar].
  final VoidCallback? onDoubleTap;

  /// Variable that imposes restrictions on the size of the element.
  final BoxConstraints constraints;

  /// Callback that is called when you touch on the left side
  /// of the [TitleBar].
  final VoidCallback? onTap;

  /// Chat Information.
  final Rx<RxChat?> chat;

  /// Header arguments.
  final Map<String, String> titleArguments;

  /// Callback that is called when you click on the "full-screen" button.
  final VoidCallback? toggleFullscreen;

  /// Indicator indicating whether the application is in full-screen mode.
  final RxBool fullscreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('TitleBar'),
      color: const Color(0xFF162636),
      height: CallController.titleHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Handles double tap to toggle fullscreen.
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: onDoubleTap,
          ),

          // Left part of the title bar that displays the recipient or
          // the caller, its avatar and the call's state.
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: constraints,
              child: GestureDetector(
                onTap: onTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 10),
                    AvatarWidget.fromRxChat(chat.value, radius: 8),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'label_call_title'.l10nfmt(titleArguments),
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontSize: 13,
                          color: const Color(0xFFFFFFFF),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right part of the title bar that displays buttons.
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TooltipButton(
                    onTap: toggleFullscreen,
                    hint: fullscreen.value
                        ? 'btn_fullscreen_exit'.l10n
                        : 'btn_fullscreen_enter'.l10n,
                    child: SvgImage.asset(
                      'assets/icons/fullscreen_${fullscreen.value ? 'exit' : 'enter'}.svg',
                      width: 12,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
