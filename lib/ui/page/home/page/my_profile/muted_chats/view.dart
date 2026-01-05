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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/mute_duration.dart';
import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/chat_tile.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import 'controller.dart';

/// View for displaying muted [Chat]s.
///
/// Intended to be displayed with the [show] method.
class MutedChatsView extends StatelessWidget {
  const MutedChatsView({super.key});

  /// Displays a [MutedChatsView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: MutedChatsView());
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: MutedChatsController(Get.find()),
      builder: (MutedChatsController c) {
        return AnimatedSizeAndFade(
          fadeDuration: const Duration(milliseconds: 250),
          sizeDuration: const Duration(milliseconds: 250),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              ModalPopupHeader(text: 'label_muted_chats'.l10n),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  controller: c.scrollController,
                  children: [
                    const SizedBox(height: 13),
                    Obx(() {
                      if (c.status.value.isEmpty || c.chats.isEmpty) {
                        return Center(child: Text('label_no_chats'.l10n));
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        padding: ModalPopup.padding(context),
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemCount: c.chats.length,
                        itemBuilder: (_, i) {
                          return Obx(() {
                            final RxChat e = c.chats.values.elementAt(i);
                            final MuteDuration? muted = e.chat.value.muted;

                            return ChatTile(
                              chat: e,
                              subtitle: [
                                SizedBox(height: 3),
                                Text(
                                  muted?.forever == true
                                      ? 'label_muted_until_i_turn_on'.l10n
                                      : 'label_muted_until_period'.l10nfmt({
                                          'period': muted?.until?.val.yMdHm,
                                        }),
                                  style: style.fonts.small.regular.secondary,
                                ),
                              ],
                              trailing: [
                                WidgetButton(
                                  onPressed: () => c.unmute(e.id),
                                  child: SvgIcon(SvgIcons.unmute),
                                ),
                                SizedBox(width: 4),
                              ],
                            );
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
