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
    this.onCreate,
  });

  /// Reactive state of the [ReactiveTextField].
  final ChatDirectLink? link;

  /// Callback, called when a `ChatDirectLinkSlug` is spotted.
  final FutureOr<void> Function(ChatDirectLinkSlug)? onCreate;

  @override
  State<DirectLinkField> createState() => _DirectLinkFieldState();
}

/// State of an [DirectLinkField] maintaining the [_state].
class _DirectLinkFieldState extends State<DirectLinkField> {
  /// State of the [ReactiveTextField].
  late final TextFieldState _state = TextFieldState(
    text: widget.link?.slug.val ?? ChatDirectLinkSlug.generate(10).val,
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

      if (slug == null || slug == widget.link?.slug) {
        return;
      }

      if (s.error.value == null) {
        s.editable.value = false;
        s.status.value = RxStatus.loading();

        try {
          await widget.onCreate?.call(slug);
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
    final (style, fonts) = Theme.of(context).styles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ReactiveTextField(
          key: const Key('LinkField'),
          state: _state,
          onSuffixPressed: _state.isEmpty.value
              ? null
              : () {
                  PlatformUtils.copy(
                    text:
                        '${Config.origin}${Routes.chatDirectLink}/${_state.text}',
                  );
                  MessagePopup.success('label_copied'.l10n);
                },
          trailing: _state.isEmpty.value
              ? null
              : Transform.translate(
                  offset: const Offset(0, -1),
                  child: Transform.scale(
                    scale: 1.15,
                    child: SvgImage.asset('assets/icons/copy.svg', height: 15),
                  ),
                ),
          label: '${Config.origin}/',
          subtitle: RichText(
            text: TextSpan(
              style: fonts.labelSmall,
              children: [
                TextSpan(
                  text: 'label_transition_count'.l10nfmt({
                        'count': widget.link?.usageCount ?? 0,
                      }) +
                      'dot_space'.l10n,
                  style: fonts.labelSmall!.copyWith(
                    color: style.colors.secondary,
                  ),
                ),
                TextSpan(
                  text: 'label_details'.l10n,
                  style: fonts.labelSmall!.copyWith(
                    color: style.colors.primary,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => LinkDetailsView.show(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
