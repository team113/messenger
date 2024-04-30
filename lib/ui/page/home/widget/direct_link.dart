// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/config.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show CreateChatDirectLinkException;
import '/themes.dart';
import '/ui/page/home/page/my_profile/widget/background_preview.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

/// [ReactiveTextField] displaying the provided [link].
///
/// If [link] is `null`, generates and displays a random [ChatDirectLinkSlug].
class DirectLinkField extends StatefulWidget {
  const DirectLinkField(
    this.link, {
    super.key,
    this.onSubmit,
    this.background,
    this.onEditing,
  });

  /// [ChatDirectLink] to display.
  final ChatDirectLink? link;

  /// Callback, called when [ChatDirectLinkSlug] is submitted.
  final FutureOr<void> Function(ChatDirectLinkSlug?)? onSubmit;

  /// Bytes of the background to display under the widget.
  final Uint8List? background;

  /// Callback, called when editing mode changes.
  final void Function(bool)? onEditing;

  @override
  State<DirectLinkField> createState() => _DirectLinkFieldState();
}

/// State of an [DirectLinkField] maintaining the [_state].
class _DirectLinkFieldState extends State<DirectLinkField> {
  /// Generated [ChatDirectLinkSlug], used in the [_state].
  final String _generated = ChatDirectLinkSlug.generate(10).val;

  /// State of the [ReactiveTextField].
  late final TextFieldState _state;

  /// Indicator whether editing of the [ChatDirectLinkSlug] is enabled
  /// currently.
  bool _editing = false;

  @override
  void initState() {
    _state = TextFieldState(
      text: widget.link?.slug.val,
      submitted: widget.link != null,
      debounce: true,
      onChanged: (s) {
        s.error.value = null;

        if (s.text.isNotEmpty) {
          try {
            ChatDirectLinkSlug(s.text);
          } on FormatException {
            s.error.value = 'err_invalid_symbols_in_link'.l10n;
          }
        }
      },
    );

    if (widget.link == null) {
      _state.text = _generated;
    }

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

    if (_editing) {
      child = Padding(
        key: const Key('Editing'),
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          children: [
            Obx(() {
              final bool deletable = !_state.isEmpty.value &&
                  _state.error.value == null &&
                  _state.text.isNotEmpty &&
                  widget.link != null;

              return ReactiveTextField(
                key: const Key('LinkField'),
                state: _state,
                clearable: true,
                onSuffixPressed: deletable
                    ? () async {
                        await widget.onSubmit?.call(null);
                        setState(() => _editing = false);
                      }
                    : null,
                trailing: deletable ? const SvgIcon(SvgIcons.delete) : null,
                label: '${Config.link}/',
              );
            }),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 16),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: WidgetButton(
                    onPressed: () {
                      if (widget.link != null) {
                        _state.text = widget.link?.slug.val ?? _state.text;
                      }
                      setState(() => _editing = false);
                      widget.onEditing?.call(_editing);
                    },
                    child: Text(
                      'btn_cancel'.l10n,
                      style: style.fonts.small.regular.primary,
                    ),
                  ),
                ),
                const Spacer(),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: WidgetButton(
                    key: const Key('SaveLinkButton'),
                    onPressed: _submitLink,
                    child: Text(
                      'btn_save'.l10n,
                      style: style.fonts.small.regular.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ],
        ),
      );
    } else if (widget.link == null) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: style.primaryBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: widget.background == null
                        // TODO: Safari lags.
                        ? WebUtils.isSafari
                            ? Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: style.colors.background,
                              )
                            : const SvgImage.asset(
                                'assets/images/background_light.svg',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                        : Image.memory(widget.background!, fit: BoxFit.cover),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 14),
                  WidgetButton(
                    key: const Key('CreateLinkButton'),
                    onPressed: () {
                      _state.text = _generated;
                      setState(() => _editing = true);
                      widget.onEditing?.call(_editing);
                    },
                    child: _info(
                      context,
                      Text(
                        'btn_create'.l10n,
                        style: style.fonts.small.regular.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
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
          Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: style.primaryBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: widget.background == null
                        ? WebUtils.isSafari
                            ? Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: style.colors.background,
                              )
                            : const SvgImage.asset(
                                'assets/images/background_light.svg',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                        : Image.memory(widget.background!, fit: BoxFit.cover),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 14),
                  _info(context, Text(DateTime.now().yMd)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 0, 0, 0),
                    child: ContextMenuRegion(
                      actions: [
                        ContextMenuButton(
                          label: 'btn_copy'.l10n,
                          trailing: const SvgIcon(SvgIcons.copy19),
                          inverted: const SvgIcon(SvgIcons.copy19White),
                          onPressed: () {
                            final share = '${Config.link}/${_state.text}';
                            PlatformUtils.copy(text: share);
                            MessagePopup.success('label_copied'.l10n);
                          },
                        ),
                        if (PlatformUtils.isMobile)
                          ContextMenuButton(
                            label: 'btn_share'.l10n,
                            trailing: const SvgIcon(SvgIcons.share19),
                            inverted: const SvgIcon(SvgIcons.share19White),
                            onPressed: () {
                              final share = '${Config.link}/${_state.text}';
                              Share.share(share);
                            },
                          ),
                      ],
                      child: WidgetButton(
                        onPressed: () async {
                          final share = '${Config.link}/${_state.text}';
                          await launchUrlString(share);
                        },
                        child: MessagePreviewWidget(
                          fromMe: true,
                          style: style.fonts.medium.regular.primary,
                          text:
                              '${Config.link}/${widget.link?.slug.val ?? _state.text}',
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 0, 6, 0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          border: style.secondaryBorder,
                          color: style.readMessageColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: QrImageView(
                          data: '${Config.link}/${_state.text}',
                          version: QrVersions.auto,
                          size: 300.0,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 0, 0, 0),
                    child: MessagePreviewWidget(
                      fromMe: true,
                      text: 'label_clicks_count'
                          .l10nfmt({'count': widget.link?.usageCount ?? 0}),
                      style: style.fonts.medium.regular.secondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 16),
              WidgetButton(
                onPressed: () {
                  final share = '${Config.link}/${_state.text}';

                  if (PlatformUtils.isMobile) {
                    Share.share(share);
                  } else {
                    PlatformUtils.copy(text: share);
                    MessagePopup.success('label_copied'.l10n);
                  }
                },
                child: Text(
                  PlatformUtils.isMobile ? 'btn_share'.l10n : 'btn_copy'.l10n,
                  style: style.fonts.small.regular.primary,
                ),
              ),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: WidgetButton(
                  onPressed: () {
                    setState(() => _editing = true);
                    widget.onEditing?.call(_editing);
                  },
                  child: Text(
                    'btn_change'.l10n,
                    style: style.fonts.small.regular.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          )
        ],
      );
    }

    return AnimatedSizeAndFade(
      sizeDuration: const Duration(milliseconds: 300),
      fadeDuration: const Duration(milliseconds: 300),
      child: child,
    );
  }

  /// Builds a wrapper around the [child] visually representing a [ChatInfo]
  /// message.
  Widget _info(BuildContext context, Widget child) {
    final style = Theme.of(context).style;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: style.systemMessageBorder,
            color: style.systemMessageColor,
          ),
          child: DefaultTextStyle(
            style: style.systemMessageStyle,
            child: child,
          ),
        ),
      ),
    );
  }

  /// Submits this [DirectLinkField].
  void _submitLink() async {
    ChatDirectLinkSlug? slug;

    if (_state.text.isNotEmpty) {
      try {
        slug = ChatDirectLinkSlug(_state.text);
      } on FormatException {
        _state.error.value = 'err_invalid_symbols_in_link'.l10n;
      }
    }

    if (_state.error.value == null) {
      if (slug == widget.link?.slug) {
        setState(() => _editing = false);
        widget.onEditing?.call(false);
        return;
      }

      _state.editable.value = false;
      _state.status.value = RxStatus.loading();

      try {
        await widget.onSubmit?.call(slug);
        _state.status.value = RxStatus.empty();
      } on CreateChatDirectLinkException catch (e) {
        _state.status.value = RxStatus.empty();
        _state.error.value = e.toMessage();
      } catch (e) {
        _state.status.value = RxStatus.empty();
        _state.error.value = 'err_data_transfer'.l10n;
        _state.unsubmit();
        rethrow;
      } finally {
        setState(() => _editing = false);
        widget.onEditing?.call(false);
        _state.editable.value = true;
      }
    }
  }
}
