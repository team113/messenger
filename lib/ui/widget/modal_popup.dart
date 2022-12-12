// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';

/// Stylized modal popup.
///
/// Intended to be displayed with the [show] method.
abstract class ModalPopup {
  /// Returns padding based on the `isMobile` indicator.
  static EdgeInsets padding(BuildContext context) => context.isMobile
      ? EdgeInsets.zero
      : const EdgeInsets.symmetric(horizontal: 30);

  /// Opens a new [ModalPopup] wrapping the provided [child].
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    BoxConstraints desktopConstraints = const BoxConstraints(maxWidth: 300),
    BoxConstraints modalConstraints = const BoxConstraints(maxWidth: 420),
    BoxConstraints mobileConstraints = const BoxConstraints(maxWidth: 360),
    EdgeInsets mobilePadding = const EdgeInsets.fromLTRB(32, 0, 32, 0),
    EdgeInsets desktopPadding = const EdgeInsets.all(10),
    bool isDismissible = true,
    bool showClose = true,
  }) {
    Style style = Theme.of(context).extension<Style>()!;

    if (context.isNarrow) {
      return showModalBottomSheet(
        context: context,
        barrierColor: style.barrierColor,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        isDismissible: isDismissible,
        enableDrag: isDismissible,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: ConstrainedBox(
                          constraints: desktopConstraints,
                          child: child,
                        ),
                      ),
                    ],
                  ),
                  if (isDismissible && showClose)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: desktopPadding.right == 0
                              ? const EdgeInsets.only(right: 10)
                              : EdgeInsets.zero,
                          child: SizedBox(
                            height: 16,
                            child: InkResponse(
                              onTap: Navigator.of(context).pop,
                              radius: 11,
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Color(0xBB818181),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}

/// Stylized header of a popup window.
class ModalPopupHeader extends StatelessWidget {
  const ModalPopupHeader({
    Key? key,
    this.onBack,
    this.header,
  }) : super(key: key);

  /// Callback, called when the back button is pressed.
  ///
  /// If `null`, then no back button will be displayed.
  final void Function()? onBack;

  /// Optional [Widget] displayed in this [ModalPopupHeader].
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
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
              onPressed: Navigator.of(context).pop,
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
