// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/confirm_dialog.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import 'controller.dart';
import 'create_group/controller.dart';
import 'widget/recent_chat.dart';

/// View of the `HomeTab.chats` tab.
class ChatsTabView extends StatelessWidget {
  const ChatsTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      key: const Key('ChatsTab'),
      init: ChatsTabController(
        Navigator.of(context).pop,
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
      builder: (ChatsTabController c) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            title: Text('label_chats'.l10n),
            padding: const EdgeInsets.symmetric(horizontal: 21),
            leading: [
              WidgetButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const CreateGroupView(),
                ),
                child: SvgLoader.asset('assets/icons/group.svg', height: 18.44),
              ),
            ],
            actions: [
              WidgetButton(
                onPressed: () {
                  // TODO: Implement search.
                },
                child: SvgLoader.asset('assets/icons/search.svg', width: 17.77),
              ),
            ],
          ),
          body: Obx(() {
            if (c.chatsReady.value) {
              if (c.chats.isEmpty) {
                return Center(child: Text('label_no_chats'.l10n));
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: ContextMenuInterceptor(
                  child: AnimationLimiter(
                    child: ListView.builder(
                      controller: ScrollController(),
                      itemCount: c.chats.length,
                      itemBuilder: (_, i) {
                        final RxChat chat = c.chats[i];
                        return AnimationConfiguration.staggeredList(
                          position: i,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            horizontalOffset: 50,
                            child: FadeInAnimation(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: RecentChatTile(
                                  chat,
                                  me: c.me,
                                  getUser: c.getUser,
                                  onJoin: () => c.joinCall(chat.id),
                                  onDrop: () => c.dropCall(chat.id),
                                  onLeave: () => c.leaveChat(chat.id),
                                  onHide: () => c.hideChat(chat.id),
                                  inCall: () => c.inCall(chat.id),
                                  muteDialogOpened: () async {
                                    c.openedMuteDialogChatId.value = chat.id;
                                    await ConfirmDialog.show(
                                      context,
                                      title: 'label_mute_chat_for'.l10n,
                                      variants: c.muteDateTimes
                                          .map((e) => ConfirmDialogVariant(
                                                onProceed: () => c.muteChat(
                                                  chat.id,
                                                  duration: e,
                                                ),
                                                child: Text(
                                                  'label_mute_for'.l10nfmt({
                                                    'days': e?.inDays ?? 0,
                                                    'hours': e?.inHours ?? 0,
                                                    'minutes':
                                                        e?.inMinutes ?? 0,
                                                  }),
                                                  key: e == null
                                                      ? const Key('MuteForever')
                                                      : null,
                                                ),
                                              ))
                                          .toList(),
                                    );
                                    c.openedMuteDialogChatId.value = null;
                                  },
                                  unmuteChat: () => c.unmuteChat(chat.id),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          }),
        );
      },
    );
  }
}
