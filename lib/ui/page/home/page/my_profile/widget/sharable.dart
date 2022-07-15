import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

/// Copyable text field that puts a [copy] of data into the clipboard on click
/// or on context menu action.
class SharableTextField extends StatelessWidget {
  SharableTextField({
    Key? key,
    required String? text,
    this.copy,
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

  /// Data to put into the clipboard.
  final String? copy;

  /// Optional leading icon.
  final IconData? icon;

  final Widget? trailing;
  final Widget? leading;

  /// Optional label of this [SharableTextField].
  final String? label;

  final TextStyle? style;

  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 25),
            child: Icon(
              icon,
              color: context.theme.colorScheme.primary,
            ),
          ),
        Expanded(
          child: ContextMenuRegion(
            enabled: (copy ?? state.text).isNotEmpty,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
            ),
            menu: ContextMenu(
              actions: [
                ContextMenuButton(
                  label: 'label_copy'.tr,
                  onPressed: () => _copy(context),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap:
                  (copy ?? state.text).isEmpty ? null : () => _share(context),
              child: IgnorePointer(
                child: ReactiveTextField(
                  key: _key,
                  prefix: leading,
                  state: state,
                  suffix: trailing == null ? Icons.ios_share : null,
                  trailing: trailing,
                  label: label,
                  style: style,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Puts a [copy] of data into the clipboard and shows a snackbar.
  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: copy ?? state.text));
    MessagePopup.success('label_copied_to_clipboard'.tr);
  }

  Future<void> _share(BuildContext context) async {
    Rect? rect;

    try {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        rect = box.localToGlobal(Offset.zero) & box.size;
      }
    } catch (e) {
      //No-op.
    }

    await Share.share(copy ?? state.text, sharePositionOrigin: rect);
  }
}
