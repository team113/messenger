// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'package:flutter/material.dart';

import '/routes.dart';
import '/themes.dart';
import '/ui/widget/svg/svgs.dart';
import '/util/platform_utils.dart';
import 'safe_area/safe_area.dart';
import 'widget_button.dart';

/// Stylized modal popup.
///
/// Intended to be displayed with the [show] method.
abstract class ModalPopup {
  /// Returns a padding that should be applied to the elements inside a
  /// [ModalPopup].
  static EdgeInsets padding(BuildContext context) =>
      const EdgeInsets.symmetric(horizontal: 30);

  /// Opens a new [ModalPopup] wrapping the provided [child].
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    BoxConstraints desktopConstraints = const BoxConstraints(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
    ),
    BoxConstraints modalConstraints = const BoxConstraints(maxWidth: 380),
    BoxConstraints mobileConstraints = const BoxConstraints(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
    ),
    EdgeInsets mobilePadding = const EdgeInsets.fromLTRB(10, 0, 10, 16),
    EdgeInsets desktopPadding = const EdgeInsets.fromLTRB(0, 0, 0, 10),
    bool isDismissible = true,
    Color? background,
  }) async {
    final style = Theme.of(context).style;

    if (context.isMobile) {
      final NavigatorState navigator = Navigator.of(
        context,
        rootNavigator: true,
      );

      final route = ModalBottomSheetRoute<T>(
        modalBarrierColor: style.barrierColor,
        isScrollControlled: true,
        backgroundColor: background ?? style.colors.background,
        isDismissible: isDismissible,
        enableDrag: isDismissible,
        elevation: 0,
        capturedThemes: InheritedTheme.capture(
          from: context,
          to: navigator.context,
        ),
        transitionAnimationController: BottomSheet.createAnimationController(
          navigator,
        )..duration = const Duration(milliseconds: 350),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
          ),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height - 60,
        ),
        builder: (context) {
          return CustomSafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                if (isDismissible) ...[
                  Center(
                    child: Container(
                      width: 60,
                      height: 3,
                      decoration: BoxDecoration(
                        color: style.colors.secondaryHighlightDarkest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Flexible(
                  child: Padding(
                    padding: mobilePadding,
                    child: ConstrainedBox(
                      constraints: mobileConstraints,
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      router.obscuring.add(route);

      try {
        return await Navigator.of(context, rootNavigator: true).push<T>(route);
      } finally {
        router.obscuring.remove(route);
      }
    } else {
      final route = RawDialogRoute<T>(
        barrierColor: style.barrierColor,
        barrierDismissible: isDismissible,
        pageBuilder: (_, _, _) {
          final Widget body = Center(
            child: Container(
              constraints: modalConstraints,
              width: modalConstraints.maxWidth,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              padding: desktopPadding,
              decoration: BoxDecoration(
                color: background ?? style.colors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: desktopConstraints,
                child: child,
              ),
            ),
          );

          return CustomSafeArea(
            child: Material(type: MaterialType.transparency, child: body),
          );
        },
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (_, Animation<double> animation, _, Widget child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.linear),
            child: child,
          );
        },
      );

      router.obscuring.add(route);

      try {
        return await Navigator.of(context, rootNavigator: true).push<T>(route);
      } finally {
        router.obscuring.remove(route);
      }
    }
  }
}

/// [Row] with [text] and [WidgetButton] stylized to be a [ModalPopup] header.
class ModalPopupHeader extends StatelessWidget {
  const ModalPopupHeader({
    super.key,
    this.text,
    this.onBack,
    this.close = true,
    this.dense = false,
    this.subtitle,
  });

  /// Text to display as a title of this [ModalPopupHeader].
  final String? text;

  /// Text to display as a subtitle of this [ModalPopupHeader].
  final String? subtitle;

  /// Callback, called when a back button is pressed.
  ///
  /// If `null`, then no back button is displayed at all.
  final void Function()? onBack;

  /// Indicator whether a close button should be displayed.
  final bool close;

  /// Indicator whether this [ModalPopupHeader] should be dense, meaning it's
  /// height will be as little as possible with no paddings.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: dense ? 0 : 42),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (onBack != null)
                  WidgetButton(
                    onPressed: onBack,
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(12, 14, 14, 8),
                      child: SvgIcon(SvgIcons.backSmall),
                    ),
                  )
                else
                  const SizedBox(width: 40),

                if (text != null)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 19,
                      ),
                      child: Center(
                        child: Text(
                          text!,
                          style: style.fonts.big.regular.onBackground,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),

                if (!context.isMobile && close)
                  WidgetButton(
                    key: const Key('CloseButton'),
                    onPressed: Navigator.of(context).pop,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
                      child: const SvgIcon(
                        SvgIcons.closeSmallPrimary,
                        width: 9,
                        height: 9,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 40),
              ],
            ),

            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: style.colors.secondaryHighlightDarkest,
                      ),
                    ),
                    Text(subtitle!, style: style.fonts.small.regular.secondary),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: style.colors.secondaryHighlightDarkest,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
