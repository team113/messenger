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
import 'package:share_plus/share_plus.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// Sharable field opening a [Share] modal with the provided [share] content.
class SharableTextField extends StatelessWidget {
  SharableTextField({
    Key? key,
    required String? text,
    this.share,
    this.icon,
    this.label,
    this.style,
    this.trailing,
    this.leading,
  }) : super(key: key) {
    state = TextFieldState(text: text, editable: false);
  }

  /// Reactive state of this [SharableTextField].
  late final TextFieldState state;

  /// Data to share or put into the clipboard.
  final String? share;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional trailing [Widget].
  final Widget? trailing;

  /// Optional leading [Widget].
  final Widget? leading;

  /// Optional label of this [SharableTextField].
  final String? label;

  /// [TextStyle] of this [SharableTextField].
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 25),
            child: Icon(icon, color: style.colors.primary),
          ),
        Expanded(
          child: ContextMenuRegion(
            enabled: (share ?? state.text).isNotEmpty,
            actions: [
              ContextMenuButton(
                label: 'label_copy'.l10n,
                onPressed: () => _copy(context),
              ),
            ],
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap:
                  (share ?? state.text).isEmpty ? null : () => _share(context),
              child: IgnorePointer(
                child: ReactiveTextField(
                  prefix: leading,
                  state: state,
                  suffix: trailing == null ? Icons.ios_share : null,
                  trailing: trailing,
                  label: label,
                  style: this.style,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Puts the [share] into the clipboard and shows a snackbar.
  void _copy(BuildContext context) {
    PlatformUtils.copy(text: share ?? state.text);
    MessagePopup.success('label_copied'.l10n);
  }

  /// Opens a [Share] modal sharing the [share].
  Future<void> _share(BuildContext context) async {
    Rect? rect;

    try {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        rect = box.localToGlobal(Offset.zero) & box.size;
      }
    } catch (e) {
      // No-op.
    }

    await Share.share(share ?? state.text, sharePositionOrigin: rect);
  }
}
