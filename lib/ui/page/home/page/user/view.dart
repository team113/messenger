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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/action.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/big_avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/info_tile.dart';
import '/ui/page/home/widget/copy_or_share.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/page/home/widget/unblock_button.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import 'controller.dart';
import 'widget/blocklist_record.dart';

/// View of the [Routes.user] page.
class UserView extends StatelessWidget {
  const UserView(this.id, {super.key});

  /// ID of the [User] this [UserView] represents.
  final UserId id;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: UserController(id, Get.find(), Get.find(), Get.find(), Get.find()),
      tag: id.val,
      global: !Get.isRegistered<UserController>(tag: id.val),
      builder: (UserController c) {
        return Obx(() {
          if (!c.status.value.isSuccess) {
            return Scaffold(
              appBar: const CustomAppBar(
                padding: EdgeInsets.only(left: 4, right: 20),
                leading: [StyledBackButton()],
              ),
              body: Center(
                child: c.status.value.isEmpty
                    ? Text('err_unknown_user'.l10n)
                    : const CustomProgressIndicator(),
              ),
            );
          }

          return LayoutBuilder(builder: (context, constraints) {
            return Scaffold(
              appBar: CustomAppBar(title: _bar(c, context)),
              body: Scrollbar(
                controller: c.scrollController,
                child: Obx(() {
                  return SelectionArea(
                    child: ListView(
                      key: const Key('UserScrollable'),
                      controller: c.scrollController,
                      children: [
                        const SizedBox(height: 8),
                        if (c.isBlocked != null)
                          Block(
                            title: 'label_user_is_blocked'.l10n,
                            children: [BlocklistRecordWidget(c.isBlocked!)],
                          ),
                        Block(
                          children: [
                            SelectionContainer.disabled(
                              child: BigAvatarWidget.user(c.user),
                            ),
                            const SizedBox(height: 18),
                            _name(c, context),
                          ],
                        ),
                        _status(c, context),
                        Block(
                          children: [_num(c)],
                        ),
                        SelectionContainer.disabled(
                          child: Block(children: [_actions(c, context)]),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                }),
              ),
              bottomNavigationBar: Obx(() {
                if (c.isBlocked == null) {
                  return const SizedBox();
                }

                return Padding(
                  padding: Insets.dense.copyWith(top: 0),
                  child: SafeArea(child: UnblockButton(c.unblock)),
                );
              }),
            );
          });
        });
      },
    );
  }

  /// Returns a [Contact.name] editable field.
  Widget _name(UserController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Obx(() {
      final Widget child;

      if (c.editing.value) {
        child = Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: ReactiveTextField(
            state: c.name,
            label: 'label_name'.l10n,
            hint: c.contact.value?.contact.value.name.val ??
                c.user!.user.value.name?.val ??
                c.user!.user.value.num.toString(),
          ),
        );
      } else {
        child = Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Text(
            c.name.text,
            style: style.fonts.large.regular.onBackground,
          ),
        );
      }

      return AnimatedSizeAndFade(
        sizeDuration: const Duration(milliseconds: 250),
        fadeDuration: const Duration(milliseconds: 250),
        child: child,
      );
    });
  }

  /// Returns the [User.status] visual representation.
  Widget _status(UserController c, BuildContext context) {
    final style = Theme.of(context).style;

    final UserTextStatus? status = c.user?.user.value.status;

    if (status != null) {
      return Block(
        padding: Block.defaultPadding.copyWith(top: 8, bottom: 8),
        children: [
          Text(
            status.toString(),
            style: style.fonts.normal.regular.secondary,
          ),
        ],
      );
    } else {
      return const SizedBox();
    }
  }

  /// Returns the [User.num] visual representation.
  Widget _num(UserController c) {
    return Paddings.basic(
      InfoTile(
        key: const Key('UserNum'),
        padding: EdgeInsets.zero,
        title: 'label_num'.l10n,
        content: c.user!.user.value.num.toString(),
        trailing: CopyOrShareButton(
          c.user!.user.value.num.toString(),
        ),
      ),
    );
  }

  /// Returns information about the [User] and related to it action buttons in
  /// the [CustomAppBar].
  Widget _bar(UserController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Center(
      child: Row(
        children: [
          const SizedBox(width: 8),
          const StyledBackButton(),
          Material(
            elevation: 6,
            type: MaterialType.circle,
            shadowColor: style.colors.onBackgroundOpacity27,
            color: style.colors.onPrimary,
            child: Center(
              child: AvatarWidget.fromRxUser(
                c.user,
                radius: AvatarRadius.medium,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DefaultTextStyle.merge(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: Obx(() {
                final String? subtitle = c.user?.user.value.getStatus();

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.contact.value?.contact.value.name.val ?? c.user?.user.value.name?.val ?? c.user?.user.value.num}',
                    ),
                    if (subtitle?.isNotEmpty == true)
                      Text(
                        key: Key(
                          c.user?.user.value.presence?.name.capitalizeFirst ??
                              '',
                        ),
                        subtitle!,
                        style: style.fonts.small.regular.secondary,
                      )
                  ],
                );
              }),
            ),
          ),
          const SizedBox(width: 40),
          Obx(() {
            final Widget child;

            if (c.editing.value) {
              child = AnimatedButton(
                onPressed: c.editing.toggle,
                decorator: (child) => Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: child,
                ),
                child: const SvgIcon(SvgIcons.closePrimary),
              );
            } else {
              child = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedButton(
                    onPressed: c.openChat,
                    child: const SvgIcon(SvgIcons.chat),
                  ),
                  Obx(() {
                    final bool contact = c.contact.value != null;
                    final bool favorite =
                        c.contact.value?.contact.value.favoritePosition != null;

                    return KeyedSubtree(
                      key: const Key('MoreButton'),
                      child: ContextMenuRegion(
                        key: c.moreKey,
                        selector: c.moreKey,
                        alignment: Alignment.topRight,
                        enablePrimaryTap: true,
                        margin: const EdgeInsets.only(bottom: 4, left: 20),
                        actions: [
                          ContextMenuButton(
                            label: 'btn_audio_call'.l10n,
                            onPressed: () => c.call(false),
                            trailing: const SvgIcon(SvgIcons.makeAudioCall),
                            inverted:
                                const SvgIcon(SvgIcons.makeAudioCallWhite),
                          ),
                          ContextMenuButton(
                            label: 'btn_video_call'.l10n,
                            onPressed: () => c.call(true),
                            trailing: Transform.translate(
                              offset: const Offset(2, 0),
                              child: const SvgIcon(SvgIcons.makeVideoCall),
                            ),
                            inverted: Transform.translate(
                              offset: const Offset(2, 0),
                              child: const SvgIcon(SvgIcons.makeVideoCallWhite),
                            ),
                          ),
                          if (contact)
                            ContextMenuButton(
                              label: 'btn_edit'.l10n,
                              onPressed: c.editing.toggle,
                              trailing: const SvgIcon(SvgIcons.edit),
                              inverted: const SvgIcon(SvgIcons.editWhite),
                            ),
                          ContextMenuButton(
                            key: contact
                                ? const Key('DeleteFromContactsButton')
                                : const Key('AddToContactsButton'),
                            label: contact
                                ? 'btn_delete_from_contacts'.l10n
                                : 'btn_add_to_contacts'.l10n,
                            onPressed: contact
                                ? c.removeFromContacts
                                : c.addToContacts,
                            trailing: SvgIcon(
                              contact
                                  ? SvgIcons.deleteContact
                                  : SvgIcons.addContact,
                            ),
                            inverted: SvgIcon(
                              contact
                                  ? SvgIcons.deleteContactWhite
                                  : SvgIcons.addContactWhite,
                            ),
                          ),
                          if (contact)
                            ContextMenuButton(
                              label: favorite
                                  ? 'btn_delete_from_favorites'.l10n
                                  : 'btn_add_to_favorites'.l10n,
                              onPressed: favorite
                                  ? c.unfavoriteContact
                                  : c.favoriteContact,
                              trailing: SvgIcon(
                                favorite
                                    ? SvgIcons.favoriteSmall
                                    : SvgIcons.unfavoriteSmall,
                              ),
                              inverted: SvgIcon(
                                favorite
                                    ? SvgIcons.favoriteSmallWhite
                                    : SvgIcons.unfavoriteSmallWhite,
                              ),
                            ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.only(left: 31, right: 25),
                          height: double.infinity,
                          child: const SvgIcon(SvgIcons.more),
                        ),
                      ),
                    );
                  }),
                ],
              );
            }

            return AnimatedSizeAndFade(
              fadeDuration: const Duration(milliseconds: 200),
              sizeDuration: const Duration(milliseconds: 200),
              child: child,
            );
          }),
        ],
      ),
    );
  }

  /// Returns the action buttons to do with this [User].
  Widget _actions(UserController c, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ActionButton(
          text: 'btn_report'.l10n,
          trailing: const SvgIcon(SvgIcons.report),
          onPressed: () {},
        ),
        Obx(() {
          final bool blocked = c.isBlocked != null;

          return ActionButton(
            key: blocked ? const Key('Unblock') : const Key('Block'),
            text: blocked ? 'btn_unblock'.l10n : 'btn_block'.l10n,
            onPressed: blocked ? c.unblock : () => _blockUser(c, context),
            trailing: Obx(() {
              final Widget child;
              if (c.blocklistStatus.value.isEmpty) {
                child = const SvgIcon(SvgIcons.block);
              } else {
                child = const CustomProgressIndicator();
              }

              return SafeAnimatedSwitcher(
                duration: 200.milliseconds,
                child: child,
              );
            }),
          );
        }),
      ],
    );
  }

  /// Opens a confirmation popup blocking the [User].
  Future<void> _blockUser(UserController c, BuildContext context) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_block'.l10n,
      description: [
        TextSpan(text: 'alert_user_will_be_blocked1'.l10n),
        TextSpan(
          text: c.contact.value?.contact.value.name.val ??
              c.user?.user.value.name?.val ??
              c.user?.user.value.num.toString(),
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_user_will_be_blocked2'.l10n),
      ],
      additional: [
        const SizedBox(height: 25),
        ReactiveTextField(state: c.reason, label: 'label_reason'.l10n),
      ],
    );

    if (result == true) {
      await c.block();
    }
  }
}
