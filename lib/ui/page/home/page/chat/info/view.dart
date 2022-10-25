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
import '/l10n/l10n.dart';
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
      key: const Key('ChatInfoView'),
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
                                _avatar(c),
                                _name(c),
                                _link(context, c),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 10, 8, 0),
                                  child: Text(
                                    'label_chat_members'.l10n,
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
              body: Center(child: Text('label_no_chat_found'.l10n)),
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

  /// Returns a [Chat.avatar] visual representation along with its manipulation
  /// buttons.
  Widget _avatar(ChatInfoController c) {
    // Builds the manipulation buttons with [Chat.avatar] upload or removal
    // indication.
    Widget buttons() {
      if (c.avatar.value.isLoading) {
        return const CircularProgressIndicator();
      } else if (c.avatar.value.isSuccess) {
        return const Center(child: Icon(Icons.check));
      } else {
        return Row(
          children: [
            TextButton(
              key: const Key('ChangeAvatar'),
              onPressed: c.pickAvatar,
              child: Text('btn_change_avatar'.l10n),
            ),
            if (c.chat?.avatar.value != null)
              TextButton(
                key: const Key('DeleteAvatar'),
                onPressed: c.deleteAvatar,
                child: Text('btn_delete_avatar'.l10n),
              ),
          ],
        );
      }
    }

    return Obx(() {
      return _padding(
        Row(
          children: [
            AvatarWidget.fromRxChat(
              c.chat,
              key: const Key('ChatAvatar'),
              radius: 29,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: buttons(),
              ),
            )
          ],
        ),
      );
    });
  }

  /// Returns a [Chat.name] editable field.
  Widget _name(ChatInfoController c) {
    return Obx(() {
      return _padding(
        ReactiveTextField(
          key: const Key('RenameChatField'),
          state: c.chatName,
          style: const TextStyle(fontSize: 20),
          suffix: Icons.edit,
          label: c.chat?.chat.value.name == null
              ? c.chat?.title.value
              : 'label_name'.l10n,
          hint: 'label_name_hint'.l10n,
        ),
      );
    });
  }

  /// Returns a [Chat.directLink] editable field.
  Widget _link(BuildContext context, ChatInfoController c) => Obx(
        () => ExpandablePanel(
          key: const Key('ChatDirectLinkExpandable'),
          header: ListTile(
            leading: const Icon(Icons.link),
            title: Text('label_direct_chat_link'.l10n),
          ),
          collapsed: Container(),
          expanded: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('label_direct_chat_link_in_chat_description'.l10n),
                const SizedBox(height: 10),
                _padding(
                  ReactiveTextField(
                    key: const Key('DirectChatLinkTextField'),
                    enabled: true,
                    state: c.link,
                    prefixText: '${Config.origin}${Routes.chatDirectLink}/',
                    label: 'label_direct_chat_link'.l10n,
                    suffix: Icons.copy,
                    onSuffixPressed: c.chat?.chat.value.directLink == null
                        ? null
                        : c.copyLink,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${'label_transition_count'.l10n}: ${c.chat?.chat.value.directLink?.usageCount ?? 0}',
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
                                  'btn_delete_direct_chat_link'.l10n,
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
                                    ? 'btn_generate_direct_chat_link'.l10n
                                    : 'btn_submit'.l10n,
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
              (u) => ListTile(
                title: Text(u.user.value.name?.val ?? u.user.value.num.val),
                leading: AvatarWidget.fromRxUser(u),
                trailing: IconButton(
                  key: const Key('DeleteChatMember'),
                  icon: Icon(u.id == c.me ? Icons.exit_to_app : Icons.delete),
                  onPressed: c.membersOnRemoval.contains(u.id)
                      ? null
                      : () => c.removeChatMember(u.id),
                ),
                onTap: () => router.user(u.id, push: true),
              ),
            ),
            ListTile(
              key: const Key('AddMemberButton'),
              title: Text('btn_add_participant'.l10n),
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
