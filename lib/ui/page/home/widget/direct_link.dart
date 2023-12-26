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

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/home/page/user/widget/contact_info.dart';
import 'package:messenger/ui/page/home/page/user/widget/copy_or_share.dart';
import 'package:messenger/ui/widget/animated_size_and_fade.dart';
import 'package:messenger/ui/widget/animated_switcher.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:share_plus/share_plus.dart';

import '/config.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show CreateChatDirectLinkException;
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/my_profile/link_details/view.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// [ReactiveTextField] displaying the provided [link].
///
/// If [link] is `null`, generates and displays a random [ChatDirectLinkSlug].
class DirectLinkField extends StatefulWidget {
  const DirectLinkField(
    this.link, {
    super.key,
    this.onSubmit,
    this.transitions = true,
  });

  /// Reactive state of the [ReactiveTextField].
  final ChatDirectLink? link;

  /// Callback, called when [ChatDirectLinkSlug] is submitted.
  final FutureOr<void> Function(ChatDirectLinkSlug)? onSubmit;

  final bool transitions;

  @override
  State<DirectLinkField> createState() => _DirectLinkFieldState();
}

/// State of an [DirectLinkField] maintaining the [_state].
class _DirectLinkFieldState extends State<DirectLinkField> {
  /// Generated [ChatDirectLinkSlug], used in the [_state], if any.
  String? _generated;

  /// State of the [ReactiveTextField].
  late final TextFieldState _state;

  bool _editing = false;
  bool _expanded = false;

  @override
  void initState() {
    if (widget.link == null) {
      _generated = ChatDirectLinkSlug.generate(10).val;
    }

    _state = TextFieldState(
      text: widget.link?.slug.val ?? _generated,
      approvable: true,
      submitted: widget.link != null,
      onChanged: (s) {
        s.error.value = null;

        try {
          ChatDirectLinkSlug(s.text);
        } on FormatException {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      },
      onSubmitted: (s) async {
        ChatDirectLinkSlug? slug;
        try {
          slug = ChatDirectLinkSlug(s.text);
        } on FormatException {
          s.error.value = 'err_incorrect_input'.l10n;
        }

        setState(() => _editing = false);

        if (slug == null || slug == widget.link?.slug) {
          return;
        }

        if (s.error.value == null) {
          s.editable.value = false;
          s.status.value = RxStatus.loading();

          try {
            await widget.onSubmit?.call(slug);
            s.status.value = RxStatus.success();
            await Future.delayed(const Duration(seconds: 1));
            s.status.value = RxStatus.empty();
          } on CreateChatDirectLinkException catch (e) {
            s.status.value = RxStatus.empty();
            s.error.value = e.toMessage();
          } catch (e) {
            s.status.value = RxStatus.empty();
            MessagePopup.error(e);
            s.unsubmit();
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );

    super.initState();
  }

  @override
  void didUpdateWidget(DirectLinkField oldWidget) {
    if (!_state.focus.hasFocus &&
        !_state.changed.value &&
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
        padding: const EdgeInsets.only(top: 8.0),
        child: ReactiveTextField(
          key: const Key('LinkField'),
          state: _state,
          onSuffixPressed: _state.isEmpty.value || !widget.transitions
              ? null
              : () {
                  final share =
                      '${Config.origin}${Routes.chatDirectLink}/${_state.text}';

                  if (PlatformUtils.isMobile) {
                    Share.share(share);
                  } else {
                    PlatformUtils.copy(text: share);
                    MessagePopup.success('label_copied'.l10n);
                  }
                },
          trailing: _state.isEmpty.value || !widget.transitions
              ? null
              : PlatformUtils.isMobile
                  ? const SvgIcon(SvgIcons.share)
                  : const SvgIcon(SvgIcons.copy),
          label: '${Config.origin}/',
          subtitle: false && widget.transitions
              ? RichText(
                  text: TextSpan(
                    style: style.fonts.small.regular.onBackground,
                    children: [
                      TextSpan(
                        text: 'label_transition_count'.l10nfmt({
                              'count': widget.link?.usageCount ?? 0,
                            }) +
                            'dot_space'.l10n,
                        style: style.fonts.small.regular.secondary,
                      ),
                      // TextSpan(
                      //   text: 'label_details'.l10n,
                      //   style: style.fonts.small.regular.primary,
                      //   recognizer: TapGestureRecognizer()
                      //     ..onTap = () => LinkDetailsView.show(context),
                      // ),
                    ],
                  ),
                )
              : null,
        ),
      );
    } else {
      child = ContactInfoContents(
        padding: EdgeInsets.zero,
        title: '${Config.origin}/',
        content: _state.text,
        trailing: Row(
          children: [
            // const SvgIcon(SvgIcons.delete),
            // const SizedBox(width: 16),
            CopyOrShareButton(
              '${Config.origin}/${_state.text}',
            ),
          ],
        ),
        subtitle: [
          const SizedBox(height: 24),
          Row(
            children: [
              if (widget.transitions)
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'label_transition_count'.l10nfmt({
                            'count': widget.link?.usageCount ?? 0,
                          }), //+
                          // 'dot_space'.l10n,
                          style: style.fonts.small.regular.primary,
                        ),
                        // TextSpan(
                        //   text: 'label_details'.l10n,
                        //   style: style.fonts.small.regular.primary,
                        //   recognizer: TapGestureRecognizer()
                        //     ..onTap = () => LinkDetailsView.show(context),
                        // ),
                      ],
                    ),
                  ),
                ),
              WidgetButton(
                onPressed: () => setState(() {
                  _state.unsubmit();
                  _state.changed.value = true;
                  _editing = true;
                }),
                child: Text(
                  'Удалить',
                  style: style.fonts.small.regular.primary,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSizeAndFade(
          sizeDuration: const Duration(milliseconds: 300),
          fadeDuration: const Duration(milliseconds: 300),
          child: child,
        ),
        // const SizedBox(height: 16),
        // WidgetButton(
        //   onPressed: () => setState(() => _expanded = !_expanded),
        //   child: Row(
        //     children: [
        //       Expanded(
        //         child: Container(
        //           width: double.infinity,
        //           height: 0.5,
        //           color: style.colors.primary,
        //         ),
        //       ),
        //       const SizedBox(width: 8),
        //       Text(
        //         _expanded ? 'Скрыть' : 'Ещё',
        //         style: style.fonts.small.regular.primary,
        //       ),
        //       const SizedBox(width: 8),
        //       Expanded(
        //         child: Container(
        //           width: double.infinity,
        //           height: 0.5,
        //           color: style.colors.primary,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}
