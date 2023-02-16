// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import '/themes.dart';
import '/util/platform_utils.dart';
import 'widget_button.dart';

/// Stylized modal popup.
///
/// Intended to be displayed with the [show] method.
abstract class ModalPopup {
  /// Returns a padding that should be applied to the elements inside a
  /// [ModalPopup].
  static EdgeInsets padding(BuildContext context) => context.isMobile
      ? EdgeInsets.zero
      : const EdgeInsets.symmetric(horizontal: 30);

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
    EdgeInsets mobilePadding = const EdgeInsets.fromLTRB(10, 0, 10, 0),
    EdgeInsets desktopPadding = const EdgeInsets.all(10),
    bool isDismissible = true,
  }) {
    final Style style = Theme.of(context).extension<Style>()!;

    if (context.isMobile) {
      return showModalBottomSheet(
        context: context,
        barrierColor: style.barrierColor,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        isDismissible: isDismissible,
        enableDrag: isDismissible,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
          ),
        ),
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height - 60),
        builder: (context) {
          return SafeArea(
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
                        color: const Color(0xFFCCCCCC),
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
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      );
    } else {
      return showDialog(
        context: context,
        barrierColor: style.barrierColor,
        barrierDismissible: isDismissible,
        builder: (context) {
          return Center(
            child: Container(
              constraints: modalConstraints,
              width: modalConstraints.maxWidth,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              padding: desktopPadding,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: style.cardRadius,
              ),
              child: ConstrainedBox(
                constraints: desktopConstraints,
                child: child,
              ),
            ),
          );
        },
      );
    }
  }
}

/// [Row] with an optional [header] stylized to be a [ModalPopup] header.
class ModalPopupHeader extends StatelessWidget {
  const ModalPopupHeader({
    super.key,
    this.onBack,
    this.onClose,
    this.header,
  });

  /// [Widget] to put as a title of this [ModalPopupHeader].
  final Widget? header;

  /// Callback, called when a back button is pressed.
  ///
  /// If `null`, then no back button is displayed at all.
  final void Function()? onBack;
  final void Function()? onClose;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          if (onBack != null)
            WidgetButton(
              onPressed: onBack,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 14,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            )
          else
            const SizedBox(width: 40),
          if (header != null) Expanded(child: header!) else const Spacer(),
          if (!context.isMobile)
            WidgetButton(
              key: const Key('CloseButton'),
              onPressed: onClose ?? Navigator.of(context).pop,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}
