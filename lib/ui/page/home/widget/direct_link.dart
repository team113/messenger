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

import 'dart:async';
import 'dart:typed_data';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '/config.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show CreateChatDirectLinkException;
import '/themes.dart';
import '/ui/page/home/page/my_profile/qr_code/view.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/line_divider.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'field_button.dart';

/// [ReactiveTextField] displaying the provided [link].
///
/// If [link] is `null`, generates and displays a random [ChatDirectLinkSlug].
class DirectLinkField extends StatefulWidget {
  const DirectLinkField(
    this.link, {
    super.key,
    this.onSubmit,
    this.background,
    this.canAddMore = true,
  });

  /// [ChatDirectLink] to display.
  final ChatDirectLink? link;

  /// Callback, called when [ChatDirectLinkSlug] is submitted.
  final FutureOr<void> Function(ChatDirectLinkSlug?)? onSubmit;

  /// Bytes of the background to display under the widget.
  final Uint8List? background;

  /// Indicator whether a new link can be added.
  final bool canAddMore;

  @override
  State<DirectLinkField> createState() => _DirectLinkFieldState();
}

/// State of an [DirectLinkField] maintaining the [_state].
class _DirectLinkFieldState extends State<DirectLinkField> {
  /// Generated [ChatDirectLinkSlug], used in the [_state].
  final String _generated = ChatDirectLinkSlug.generate(10).val;

  /// State of the [ReactiveTextField].
  late final TextFieldState _state;

  @override
  void initState() {
    _state = TextFieldState(
      text: widget.link?.slug.val,
      submitted: widget.link != null,
      onFocus: (s) {
        if (s.text.trim().isNotEmpty) {
          try {
            ChatDirectLinkSlug(s.text);
          } on FormatException {
            if (s.text.length > 100) {
              s.error.value = 'err_incorrect_link_too_long'.l10n;
            } else {
              s.error.value = 'err_invalid_symbols_in_link'.l10n;
            }
          }
        }
      },
      onSubmitted: (_) async {
        await _submitLink();
      },
    );

    super.initState();
  }

  @override
  void didUpdateWidget(DirectLinkField oldWidget) {
    if (!_state.focus.hasFocus &&
        !_state.changed.value &&
        _state.error.value == null &&
        _state.editable.value) {
      _state.unchecked = widget.link?.slug.val;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;
    final link = widget.link;

    final Widget child;

    if (link == null) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ReactiveTextField(
            state: _state,
            hint: _generated,
            floatingAccent: true,
            label: 'label_add_link'.l10n,
            prefixText: Config.link,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            spellCheck: false,
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            key: const Key('CreateLinkButton'),
            title: 'btn_save_and_copy'.l10n,
            onPressed: () async {
              if (_state.text.isEmpty) {
                _state.text = _generated;
              }

              PlatformUtils.copy(text: '${Config.link}${_state.text}');
              MessagePopup.success('label_copied'.l10n);

              await _submitLink();
            },
            leading: SvgIcon(SvgIcons.copy19White),
          ),
          const SizedBox(height: 12),
        ],
      );
    } else {
      final String url = '${Config.link}${link.slug}';

      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ReactiveTextField(
            state: TextFieldState(text: link.slug.val, editable: false),
            hint: _generated,
            label: link.createdAt.val.yMd,
            prefixText: Config.link,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            spellCheck: false,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SvgIcon(SvgIcons.linkViews),
                    const SizedBox(width: 4),
                    Text(
                      '${link.usageCount}',
                      style: style.fonts.small.regular.primary,
                    ),
                  ],
                ),
                Spacer(),
                WidgetButton(
                  onPressed: () {},
                  onPressedWithDetails: (u) {
                    PlatformUtils.copy(text: url);
                    MessagePopup.success(
                      'label_copied'.l10n,
                      at: u.globalPosition,
                    );
                  },
                  child: Text(
                    'btn_copy'.l10n,
                    style: style.fonts.small.regular.primary,
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(8, 0, 8, 0),
                  width: 1,
                  height: 10,
                  decoration: BoxDecoration(
                    color: style.colors.secondaryHighlight,
                  ),
                ),
                if (PlatformUtils.isMobile) ...[
                  WidgetButton(
                    onPressed: () async {
                      await SharePlus.instance.share(ShareParams(text: url));
                    },
                    child: Text(
                      'btn_share'.l10n,
                      style: style.fonts.small.regular.primary,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(8, 0, 8, 0),
                    width: 1,
                    height: 10,
                    decoration: BoxDecoration(
                      color: style.colors.secondaryHighlight,
                    ),
                  ),
                ],
                ContextMenuRegion(
                  enablePrimaryTap: true,
                  actions: [
                    ContextMenuButton(
                      onPressed: () async {
                        await QrCodeView.show(context, data: url);
                      },
                      label: 'btn_show_qr_code'.l10n,
                      trailing: SvgIcon(SvgIcons.contextQr),
                      inverted: SvgIcon(SvgIcons.contextQrWhite),
                    ),
                    ContextMenuButton(
                      onPressed: () async {
                        final proceed = await MessagePopup.alert(
                          'label_unlink_link'.l10n,
                          additional: [
                            Text(
                              url,
                              style: style.fonts.normal.regular.onBackground,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'label_unlink_link_confirm_description1'.l10n,
                              style: style.fonts.small.regular.secondary,
                            ),
                          ],
                          button: (context) => MessagePopup.deleteButton(
                            context,
                            label: 'btn_unlink'.l10n,
                            icon: SvgIcons.buttonUnlink,
                          ),
                        );

                        if (proceed == true) {
                          await widget.onSubmit?.call(null);
                        }
                      },
                      label: 'btn_unlink'.l10n,
                      trailing: SvgIcon(SvgIcons.contextUnlink),
                      inverted: SvgIcon(SvgIcons.contextUnlinkWhite),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 0, 6),
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: SvgIcon(SvgIcons.more),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
            child: const LineDivider(''),
          ),

          const SizedBox(height: 4),
          if (widget.canAddMore) ...[
            const SizedBox(height: 20),
            FieldButton(
              trailing: SvgIcon(SvgIcons.addLink),
              child: Text('btn_add_link'.l10n),
            ),
          ],
        ],
      );
    }

    return AnimatedSizeAndFade(
      sizeDuration: const Duration(milliseconds: 300),
      fadeDuration: const Duration(milliseconds: 300),
      child: child,
    );
  }

  /// Submits this [DirectLinkField].
  Future<void> _submitLink() async {
    _state.focus.unfocus();

    ChatDirectLinkSlug? slug;

    if (_state.text.isNotEmpty) {
      try {
        slug = ChatDirectLinkSlug(_state.text);
      } on FormatException {
        _state.error.value = 'err_invalid_symbols_in_link'.l10n;
      }
    }

    if (_state.error.value == null || _state.resubmitOnError.isTrue) {
      if (slug == widget.link?.slug) {
        return;
      }

      _state.editable.value = false;
      _state.status.value = RxStatus.loading();

      try {
        await widget.onSubmit?.call(slug);
        setState(() {});
      } on CreateChatDirectLinkException catch (e) {
        _state.error.value = e.toMessage();
      } catch (e) {
        _state.resubmitOnError.value = true;
        _state.error.value = 'err_data_transfer'.l10n;
        _state.unsubmit();
        rethrow;
      } finally {
        _state.status.value = RxStatus.empty();
        _state.editable.value = true;
      }
    }
  }
}
