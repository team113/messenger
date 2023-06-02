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
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/widget_button.dart';
import 'allow_overflow.dart';
import 'animations.dart';
import 'svg/svg.dart';

/// [Widget] which builds the suffix depending on the provided states.
class SuffixIcon extends StatelessWidget {
  const SuffixIcon({
    super.key,
    required this.approvable,
    required this.changed,
    required this.treatErrorAsStatus,
    required this.status,
    required this.error,
    required this.submit,
    this.suffix,
    this.trailing,
    this.onSuffixPressed,
  });

  /// Optional [IconData] to display instead of the [trailing].
  final IconData? suffix;

  /// Optional trailing [Widget].
  final Widget? trailing;

  /// Indicator whether [controller]'s text should be approved.
  final bool approvable;

  /// Indicator whether [controller]'s text was changed.
  final bool changed;

  /// Indicator whether the [ReactiveFieldState.error] being non-null
  /// should be treated as a [RxStatus.error].
  final bool treatErrorAsStatus;

  ///  [RxStatus] of this [ReactiveFieldState].
  final RxStatus status;

  /// Error message.
  final String? error;

  /// Submits this [ReactiveFieldState].
  final void Function() submit;

  /// Callback, called when user presses the [suffix].
  final void Function()? onSuffixPressed;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return WidgetButton(
      onPressed: approvable && changed ? submit : onSuffixPressed,
      child: ElasticAnimatedSwitcher(
        child: (approvable ||
                suffix != null ||
                trailing != null ||
                !status.isEmpty)
            ? Padding(
                padding: const EdgeInsets.only(right: 20),
                child: SizedBox(
                  height: 24,
                  child: ElasticAnimatedSwitcher(
                    child: status.isLoading
                        ? SvgImage.asset(
                            'assets/icons/timer.svg',
                            width: 17,
                            height: 17,
                          )
                        : status.isSuccess
                            ? SizedBox(
                                key: const ValueKey('Success'),
                                width: 24,
                                child: Icon(
                                  Icons.check,
                                  size: 18,
                                  color: style.colors.acceptAuxiliaryColor,
                                ),
                              )
                            : (error != null && treatErrorAsStatus) ||
                                    status.isError
                                ? SizedBox(
                                    key: const ValueKey('Error'),
                                    width: 24,
                                    child: Icon(
                                      Icons.error,
                                      size: 18,
                                      color: style.colors.dangerColor,
                                    ),
                                  )
                                : (approvable && changed)
                                    ? AllowOverflow(
                                        key: const ValueKey('Approve'),
                                        child: Text(
                                          'btn_save'.l10n,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: style.colors.primary,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      )
                                    : SizedBox(
                                        key: const ValueKey('Icon'),
                                        width: 24,
                                        child: suffix != null
                                            ? Icon(suffix)
                                            : trailing == null
                                                ? Container()
                                                : trailing!,
                                      ),
                  ),
                ),
              )
            : const SizedBox(width: 1, height: 0),
      ),
    );
  }
}
