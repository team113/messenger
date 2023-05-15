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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/config.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/my_profile/link_details/view.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View for changing [MyUser.chatDirectLink] and [MyUser.muted].
///
/// Intended to be displayed with the [show] method.
class ChatsMoreView extends StatelessWidget {
  const ChatsMoreView({super.key});

  /// Displays a [ChatsMoreView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const ChatsMoreView());
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      key: const Key('ChatsMoreView'),
      init: ChatsMoreController(Get.find()),
      builder: (ChatsMoreController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalPopupHeader(
              header: Center(
                child: Text(
                  'label_audio_notifications'.l10n,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.black, fontSize: 18),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                padding: ModalPopup.padding(context),
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 8),
                  SwitchMute(c.myUser, c.isMuting, c.toggleMute),
                  const SizedBox(height: 21),
                  MoreHeader(text: 'label_your_direct_link'.l10n),
                  const SizedBox(height: 4),
                  ChatDirectLink(c.myUser, c.link),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

/// [Widget] which returns a styled as a header [Container] with the provided
/// [text].
class MoreHeader extends StatelessWidget {
  const MoreHeader({super.key, required this.text});

  /// Text that will be displayed in this [MoreHeader].
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            text,
            style: Theme.of(context)
                .extension<Style>()!
                .systemMessageStyle
                .copyWith(color: Colors.black, fontSize: 18),
          ),
        ),
      ),
    );
  }
}

/// [Widget] which returns a [Switch] toggling [MyUser.muted].
class SwitchMute extends StatelessWidget {
  const SwitchMute(this.myUser, this.isMuting, this.toggleMute, {super.key});

  /// Reactive variable that stores the currently authenticated [MyUser].
  final Rx<MyUser?> myUser;

  /// Indicator whether there's an ongoing [toggleMute] happening.
  final RxBool isMuting;

  /// Toggles [MyUser.muted] status.
  final Future<void> Function(bool enabled) toggleMute;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Stack(
        alignment: Alignment.centerRight,
        children: [
          IgnorePointer(
            child: ReactiveTextField(
              state: TextFieldState(
                text: (myUser.value?.muted == null
                        ? 'label_enabled'
                        : 'label_disabled')
                    .l10n,
                editable: false,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Transform.scale(
                scale: 0.7,
                transformHitTests: false,
                child: Theme(
                  data: ThemeData(
                    platform: TargetPlatform.macOS,
                  ),
                  child: Switch.adaptive(
                    key: const Key('MuteMyUserSwitch'),
                    activeColor: Theme.of(context).colorScheme.secondary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: myUser.value?.muted == null,
                    onChanged: isMuting.value ? null : toggleMute,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// [Widget] which returns a [MyUser.chatDirectLink] editable field.
class ChatDirectLink extends StatelessWidget {
  const ChatDirectLink(this.myUser, this.link, {super.key});

  /// Reactive variable that stores the currently authenticated [MyUser].
  final Rx<MyUser?> myUser;

  /// [MyUser.chatDirectLink] copyable state.
  final TextFieldState link;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
                                  myUser.value?.chatDirectLink?.usageCount ?? 0
                            }) +
                            'dot_space'.l10n,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      TextSpan(
                        text: 'label_details'.l10n,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            await LinkDetailsView.show(context);
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
