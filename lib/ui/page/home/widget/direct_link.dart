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
import 'dart:ui';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/config.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show CreateChatDirectLinkException;
import '/themes.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/line_divider.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// [ReactiveTextField] displaying the provided [link].
///
/// If [link] is `null`, generates and displays a random [ChatDirectLinkSlug].
class DirectLinkField extends StatefulWidget {
  const DirectLinkField(this.link, {super.key, this.onSubmit, this.background});

  /// [ChatDirectLink] to display.
  final ChatDirectLink? link;

  /// Callback, called when [ChatDirectLinkSlug] is submitted.
  final FutureOr<void> Function(ChatDirectLinkSlug?)? onSubmit;

  /// Bytes of the background to display under the widget.
  final Uint8List? background;

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
            s.error.value = 'err_invalid_symbols_in_link'.l10n;
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

    final Widget child;

    if (widget.link == null) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            'label_you_can_use_randomly_generated_link'.l10n,
            style: style.fonts.small.regular.secondary,
          ),
          const SizedBox(height: 20),
          LineDivider('label_create_link'.l10n),
          const SizedBox(height: 12),
          SizedBox(height: 8),
          ReactiveTextField(
            state: _state,
            hint: _generated,
            floatingAccent: true,
            label: Config.link,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            spellCheck: false,
          ),
          SizedBox(height: 8),
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: QrImageView(data: '${Config.link}$_generated'),
                  ),
                ),
              ),
              Positioned.fill(
                child: ColoredBox(color: style.colors.onPrimaryOpacity50),
              ),
              Positioned.fill(
                child: Center(
                  child: WidgetButton(
                    key: const Key('CreateLinkButton'),
                    onPressed: () async {
                      if (_state.text.isEmpty) {
                        _state.text = _generated;
                      }

                      PlatformUtils.copy(text: '${Config.link}${_state.text}');
                      MessagePopup.success('label_copied'.l10n);

                      await _submitLink();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: style.colors.primary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: style.colors.onPrimary,
                          width: 4,
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Text(
                        'btn_create_and_copy'.l10n,
                        style: style.fonts.small.regular.onPrimary,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      );
    } else {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: WidgetButton(
                onPressed: () async {
                  await launchUrlString(
                    '${Config.link}${widget.link?.slug.val}',
                  );
                },
                child: Text(
                  '${Config.link}${widget.link?.slug.val}',
                  style: style.fonts.normal.regular.primary,
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: QrImageView(data: '${Config.link}$_generated'),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: WidgetButton(
                    key: const Key('CopyLinkButton'),
                    onPressed: () {
                      PlatformUtils.copy(text: '${Config.link}${_state.text}');
                      MessagePopup.success('label_copied'.l10n);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: style.colors.primary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: style.colors.onPrimary,
                          width: 4,
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Text(
                        'btn_copy'.l10n,
                        style: style.fonts.small.regular.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Row(
              children: [
                Text(
                  'label_visits_count'.l10nfmt({
                    'count': '${widget.link?.usageCount}',
                  }),
                  style: style.fonts.small.regular.secondary,
                ),
                Spacer(),
                ContextMenuRegion(
                  enablePrimaryTap: true,
                  actions: [
                    if (PlatformUtils.isMobile)
                      ContextMenuButton(
                        onPressed: () async {
                          await SharePlus.instance.share(
                            ShareParams(text: '${Config.link}$_generated'),
                          );
                        },
                        label: 'btn_share'.l10n,
                        trailing: SvgIcon(SvgIcons.share),
                        inverted: SvgIcon(SvgIcons.share19White),
                      ),
                    ContextMenuButton(
                      onPressed: () => widget.onSubmit?.call(null),
                      label: 'btn_delete'.l10n,
                      trailing: SvgIcon(SvgIcons.delete19),
                      inverted: SvgIcon(SvgIcons.delete19White),
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
