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

import 'package:expandable/expandable.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '/config.dart';
import '/domain/model/chat.dart';
import '/routes.dart';
import '/ui/page/home/page/chat/info/add_member/controller.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';

/// View of the [Routes.chatInfo] page.
class ChatInfoView extends StatelessWidget {
  const ChatInfoView(this.id, {Key? key}) : super(key: key);

  /// ID of the [Chat] of this info page.
  final ChatId id;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatInfoController>(
      init: ChatInfoController(id, Get.find(), Get.find()),
      tag: id.val,
      builder: (c) => Obx(
        () {
          if (c.status.value.isSuccess) {
            return Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: Text(c.chat!.title.value),
              ),
              body: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate.fixed(
                      [
                        Align(
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 450),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                _name(c),
                                _link(context, c),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 10, 8, 0),
                                  child: Text(
                                    'label_chat_members'.tr,
                                    style: const TextStyle(fontSize: 17),
                                  ),
                                ),
                                const Divider(),
                                _members(c, context),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else if (c.status.value.isEmpty) {
            return Scaffold(
              body: Center(child: Text('label_no_chat_found'.tr)),
            );
          } else {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }

  /// Basic [Padding] wrapper.
  Widget _padding(Widget child) =>
      Padding(padding: const EdgeInsets.all(8), child: child);

  /// Returns [Chat.name] editable field.
  Widget _name(ChatInfoController c) => Obx(
        () => _padding(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarWidget.fromRxChat(c.chat, radius: 29),
              const SizedBox(width: 10),
              Expanded(
                child: ReactiveTextField(
                  key: const Key('RenameChatField'),
                  state: c.chatName,
                  style: const TextStyle(fontSize: 20),
                  suffix: Icons.edit,
                  label: c.chat?.chat.value.name == null
                      ? c.chat?.title.value
                      : 'label_name'.tr,
                  hint: 'label_name_hint'.tr,
                ),
              )
            ],
          ),
        ),
      );

  /// Returns a [Chat.directLink] editable field.
  Widget _link(BuildContext context, ChatInfoController c) => Obx(
        () => ExpandablePanel(
          key: const Key('ChatDirectLinkExpandable'),
          header: ListTile(
            leading: const Icon(Icons.link),
            title: Text('label_direct_chat_link'.tr),
          ),
          collapsed: Container(),
          expanded: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('label_direct_chat_link_in_chat_description'.tr),
                const SizedBox(height: 10),
                _padding(
                  ReactiveTextField(
                    key: const Key('DirectChatLinkTextField'),
                    enabled: true,
                    state: c.link,
                    prefixText: '${Config.origin}${Routes.chatDirectLink}/',
                    label: 'label_direct_chat_link'.tr,
                    suffix: Icons.copy,
                    onSuffixPressed: c.chat?.chat.value.directLink == null
                        ? null
                        : c.copyLink,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${'label_transition_count'.tr}: ${c.chat?.chat.value.directLink?.usageCount ?? 0}',
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (c.chat?.chat.value.directLink != null &&
                              !c.link.isEmpty.value)
                            Flexible(
                              child: TextButton(
                                key: const Key('RemoveChatDirectLink'),
                                onPressed: !c.link.editable.value
                                    ? null
                                    : c.deleteLink,
                                child: Text(
                                  'btn_delete_direct_chat_link'.tr,
                                  style: context.textTheme.bodyText1!.copyWith(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          Flexible(
                            child: TextButton(
                              key: const Key('GenerateChatDirectLink'),
                              onPressed: c.link.editable.value
                                  ? c.link.isEmpty.value
                                      ? c.generateLink
                                      : c.link.submit
                                  : null,
                              child: Text(
                                c.link.isEmpty.value
                                    ? 'btn_generate_direct_chat_link'.tr
                                    : 'btn_submit'.tr,
                                style: context.textTheme.bodyText1!.copyWith(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  /// Returns a list of [Chat.members].
  Widget _members(ChatInfoController c, BuildContext context) => Obx(
        () => Column(
          children: [
            ...c.chat!.members.values.map(
              (rxUser) => ListTile(
                title: Text(
                    rxUser.user.value.name?.val ?? rxUser.user.value.num.val),
                leading: AvatarWidget.fromUser(rxUser.user.value),
                trailing: IconButton(
                  key: const Key('DeleteChatMember'),
                  icon: Icon(rxUser.user.value.id == c.me
                      ? Icons.exit_to_app
                      : Icons.delete),
                  onPressed: c.membersOnRemoval.contains(rxUser.user.value.id)
                      ? null
                      : () => c.removeChatMember(rxUser.user.value.id),
                ),
                onTap: () => router.user(rxUser.user.value.id, push: true),
              ),
            ),
            ListTile(
              key: const Key('AddMemberButton'),
              title: Text('btn_add_participant'.tr),
              leading: CircleAvatar(
                child: SvgLoader.asset(
                  'assets/icons/add_user.svg',
                  width: 26,
                  height: 28,
                ),
              ),
              onTap: () => showDialog(
                context: context,
                builder: (c) => AddChatMemberView(id),
              ),
            ),
          ],
        ),
      );
}
