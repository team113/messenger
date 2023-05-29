import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '/themes.dart';
import '/config.dart';
import '/domain/model/chat.dart';
import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// [Widget] which returns a [Chat.directLink] editable field.
class ChatLink extends StatelessWidget {
  const ChatLink(this.chat, this.link, {super.key});

  /// Reactive [Chat] with chat items.
  final RxChat? chat;

  /// [Chat.directLink] field state.
  final TextFieldState link;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ReactiveTextField(
          key: const Key('LinkField'),
          state: link,
          onSuffixPressed: link.isEmpty.value
              ? null
              : () {
                  PlatformUtils.copy(
                    text:
                        '${Config.origin}${Routes.chatDirectLink}/${link.text}',
                  );

                  MessagePopup.success('label_copied'.l10n);
                },
          trailing: link.isEmpty.value
              ? null
              : Transform.translate(
                  offset: const Offset(0, -1),
                  child: Transform.scale(
                    scale: 1.15,
                    child: SvgImage.asset(
                      'assets/icons/copy.svg',
                      height: 15,
                    ),
                  ),
                ),
          label: '${Config.origin}/',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
          child: Row(
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                  children: [
                    TextSpan(
                      text: 'label_transition_count'.l10nfmt({
                            'count':
                                chat?.chat.value.directLink?.usageCount ?? 0
                          }) +
                          'dot_space'.l10n,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    TextSpan(
                      text: 'label_details'.l10n,
                      style: TextStyle(color: style.colors.primary),
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
