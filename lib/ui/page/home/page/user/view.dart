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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/ui/page/home/page/chat/get_paid/controller.dart';
import 'package:messenger/ui/page/home/page/chat/get_paid/view.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/page/home/widget/chat_tile.dart';
import 'package:messenger/ui/page/home/widget/direct_link.dart';
import 'package:messenger/ui/page/home/widget/field_button.dart';
import 'package:messenger/ui/page/home/widget/num.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';
import 'package:messenger/ui/widget/expandable_text.dart';
import 'package:messenger/ui/widget/info_tile.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../my_profile/add_email/view.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/action.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/big_avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/page/home/widget/unblock_button.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import 'controller.dart';
import 'widget/blocklist_record.dart';
import 'widget/contact_info.dart';
import 'widget/copy_or_share.dart';

/// View of the [Routes.user] page.
class UserView extends StatelessWidget {
  const UserView(this.id, {super.key, this.scrollToPaid = false});

  /// ID of the [User] this [UserView] represents.
  final UserId id;

  final bool scrollToPaid;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: UserController(
        id,
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        scrollToPaid: scrollToPaid,
      ),
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
              appBar: CustomAppBar(
                title: Stack(
                  children: [
                    Center(
                      child: Obx(() {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: c.displayName.value
                              ? Text(
                                  '${c.user?.user.value.name ?? c.user?.user.value.num}',
                                )
                              : Text('label_profile'.l10n, key: const Key('1')),
                        );
                      }),
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: StyledBackButton(enlarge: true),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedButton(
                        key: const Key('EditButton'),
                        decorator: (child) => Padding(
                          padding: const EdgeInsets.fromLTRB(19, 8, 19, 8),
                          child: child,
                        ),
                        onPressed: c.editing.toggle,
                        child: Obx(() {
                          return Text(
                            key: Key(c.editing.value ? '1' : '2'),
                            c.editing.value ? 'Готово' : 'Изменить',
                            style: style.fonts.normal.regular.primary,
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              // appBar: CustomAppBar(title: _bar(c, context)),
              body: Scrollbar(
                controller: c.scrollController,
                child: Obx(() {
                  // final String? status = c.user?.user.value.getStatus();
                  final UserBio? status = c.user?.user.value.bio;
                  Widget? subtitle;

                  if (status != null) {
                    subtitle = Text(
                      status.toString(),
                      style: style.fonts.normal.regular.secondary,
                    );
                  }

                  // if (textStatus != null || onlineStatus != null) {
                  //   final StringBuffer buffer = StringBuffer(textStatus ?? '');

                  //   if (textStatus != null && onlineStatus != null) {
                  //     buffer.write('space_vertical_space'.l10n);
                  //   }

                  //   buffer.write(onlineStatus ?? '');

                  //   subtitle = Text(
                  //     buffer.toString(),
                  //     style: style.fonts.small.regular.secondary,
                  //   );
                  // }

                  final List<Widget> blocks = [
                    const SizedBox(height: 8),
                    if (c.isBlocked != null)
                      Block(
                        title: 'label_user_is_blocked'.l10n,
                        children: [
                          BlocklistRecordWidget(
                            c.isBlocked!,
                            onUnblock: c.unblacklist,
                          )
                        ],
                      ),
                    Block(
                      children: [
                        SelectionContainer.disabled(
                          child: BigAvatarWidget.user(
                            c.user,
                            onUpload: c.editing.value ? () {} : null,
                            onDelete: c.editing.value &&
                                    c.user?.user.value.avatar != null
                                ? () {}
                                : null,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Obx(() {
                          if (c.editing.value) {
                            return SelectionContainer.disabled(
                              child: ReactiveTextField(
                                state: c.name,
                                label: 'Name',
                                hint: c.user!.user.value.name?.val ??
                                    c.user!.user.value.num.toString(),
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            child: Text(
                              c.name.text,
                              style: style.fonts.large.regular.onBackground,
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                        Text(
                          c.user!.user.value.getStatus2()!,
                          style: style.fonts.small.regular.secondary,
                        ),
                      ],
                    ),
                    _quick(c, context),
                    if (subtitle != null) Block(children: [subtitle]),
                    Block(
                      children: [
                        Paddings.basic(
                          const InfoTile(
                            title: 'Login',
                            content: 'alice',
                            trailing: CopyOrShareButton('alice'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Paddings.basic(
                          InfoTile(
                            title: 'Gapopa ID',
                            content: c.user!.user.value.num.toString(),
                            trailing: CopyOrShareButton(
                              c.user!.user.value.num.toString(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Paddings.basic(
                          const InfoTile(
                            title: 'E-mail',
                            content: 'hello@example.com',
                            trailing: CopyOrShareButton('hello@example.com'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Paddings.basic(
                          const InfoTile(
                            title: 'Phone',
                            content: '+1 234 5678 90',
                            trailing: CopyOrShareButton('+1 234 5678 90'),
                          ),
                        ),
                      ],
                    ),
                    Block(
                      title: 'label_direct_chat_link'.l10n,
                      children: [
                        DirectLinkField(
                          ChatDirectLink(
                            slug: ChatDirectLinkSlug('dqwdqwdqwd'),
                          ),
                          transitions: false,
                          background: c.background.value,
                        ),
                      ],
                    ),
                    SelectionContainer.disabled(
                      child: Stack(
                        children: [
                          Block(
                            title: 'label_get_paid_for_incoming_from'.l10nfmt({
                              'user': c.user!.user.value.name?.val ??
                                  c.user!.user.value.num.toString(),
                            }),
                            children: [_paid(c, context)],
                          ),
                          Positioned.fill(
                            child: Obx(() {
                              return IgnorePointer(
                                ignoring: c.verified.value,
                                child: Center(
                                  child: AnimatedContainer(
                                    margin:
                                        const EdgeInsets.fromLTRB(8, 4, 8, 4),
                                    duration: 200.milliseconds,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      color: c.verified.value
                                          ? const Color(0x00000000)
                                          : const Color(0x0A000000),
                                    ),
                                    constraints: context.isNarrow
                                        ? null
                                        : const BoxConstraints(maxWidth: 400),
                                  ),
                                ),
                              );
                            }),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Obx(() {
                                return AnimatedSwitcher(
                                  duration: 200.milliseconds,
                                  child: c.verified.value
                                      ? const SizedBox()
                                      : Container(
                                          key: const Key('123'),
                                          alignment: Alignment.bottomCenter,
                                          padding: const EdgeInsets.fromLTRB(
                                            32,
                                            16,
                                            32,
                                            16,
                                          ),
                                          margin: const EdgeInsets.fromLTRB(
                                            8,
                                            4,
                                            8,
                                            4,
                                          ),
                                          constraints: context.isNarrow
                                              ? null
                                              : const BoxConstraints(
                                                  maxWidth: 400,
                                                ),
                                          child: Column(
                                            children: [
                                              const Spacer(),
                                              _verification(context, c),
                                            ],
                                          ),
                                        ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SelectionContainer.disabled(
                      child: Block(children: [_actions(c, context)]),
                    ),
                  ];

                  return SelectionArea(
                    child: ScrollablePositionedList.builder(
                      key: const Key('UserScrollable'),
                      itemCount: blocks.length,
                      itemBuilder: (_, i) => blocks[i],
                      scrollController: c.scrollController,
                      itemScrollController: c.itemScrollController,
                      itemPositionsListener: c.positionsListener,
                      initialScrollIndex: c.initialScrollIndex,
                    ),
                  );
                }),
              ),
            );
          });
        });
      },
    );
  }

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
                final String? status = c.user?.user.value.getStatus();
                // final UserTextStatus? text = c.user?.user.value.status;
                final StringBuffer buffer = StringBuffer();

                if (status != null) {
                  buffer.write(status);
                }
                // if (status != null || text != null) {
                //   buffer.write(text ?? '');

                //   if (status != null && text != null) {
                //     buffer.write('space_vertical_space'.l10n);
                //   }

                //   buffer.write(status ?? '');
                // }

                final String subtitle = buffer.toString();

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${c.user?.user.value.name?.val ?? c.user?.user.value.num}'),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
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
                  padding: const EdgeInsets.fromLTRB(0, 0, 18, 0),
                  child: child,
                ),
                child: const SvgIcon(SvgIcons.closePrimary),
              );
            } else {
              child = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // AnimatedButton(
                  //   onPressed: c.openChat,
                  //   child: const SvgIcon(SvgIcons.chat),
                  // ),
                  Obx(() {
                    final bool contact = c.inContacts.value;
                    final bool favorite = c.inFavorites.value;
                    final bool blocked = c.isBlocked != null;

                    final RxChat? dialog =
                        c.user?.user.value.dialog.isLocal == false
                            ? c.user?.dialog.value
                            : null;

                    final bool muted = dialog?.chat.value.muted != null;

                    return AnimatedButton(
                      key: const Key('EditButton'),
                      decorator: (child) => Padding(
                        padding: const EdgeInsets.fromLTRB(19, 8, 19, 8),
                        child: child,
                      ),
                      onPressed: c.editing.toggle,
                      child: const SvgIcon(SvgIcons.edit22),
                    );

                    // return ContextMenuRegion(
                    //   key: c.moreKey,
                    //   selector: c.moreKey,
                    //   alignment: Alignment.topRight,
                    //   enablePrimaryTap: true,
                    //   margin: const EdgeInsets.only(bottom: 4, left: 20),
                    //   actions: [
                    //     // ContextMenuButton(
                    //     //   label: 'btn_set_price'.l10n,
                    //     //   onPressed: () => GetPaidView.show(
                    //     //     context,
                    //     //     mode: GetPaidMode.user,
                    //     //     user: c.user,
                    //     //   ),
                    //     //   trailing: const SvgIcon(SvgIcons.gapopaCoin),
                    //     //   inverted: const SvgIcon(SvgIcons.gapopaCoinWhite),
                    //     // ),

                    //     ContextMenuButton(
                    //       label: 'btn_audio_call'.l10n,
                    //       onPressed: () => c.call(false),
                    //       trailing: const SvgIcon(SvgIcons.makeAudioCall),
                    //       inverted: const SvgIcon(SvgIcons.makeAudioCallWhite),
                    //     ),
                    //     ContextMenuButton(
                    //       label: 'btn_video_call'.l10n,
                    //       onPressed: () => c.call(true),
                    //       trailing: Transform.translate(
                    //         offset: const Offset(2, 0),
                    //         child: const SvgIcon(SvgIcons.makeVideoCall),
                    //       ),
                    //       inverted: Transform.translate(
                    //         offset: const Offset(2, 0),
                    //         child: const SvgIcon(SvgIcons.makeVideoCallWhite),
                    //       ),
                    //     ),
                    //     if (c.inContacts.value)
                    //       ContextMenuButton(
                    //         label: 'btn_edit'.l10n,
                    //         onPressed: c.editing.toggle,
                    //         trailing: const SvgIcon(SvgIcons.edit),
                    //         inverted: const SvgIcon(SvgIcons.editWhite),
                    //       ),
                    //     ContextMenuButton(
                    //       label: contact
                    //           ? 'btn_delete_from_contacts'.l10n
                    //           : 'btn_add_to_contacts'.l10n,
                    //       onPressed:
                    //           contact ? c.removeFromContacts : c.addToContacts,
                    //       trailing: SvgIcon(
                    //         contact
                    //             ? SvgIcons.deleteContact
                    //             : SvgIcons.addContact,
                    //       ),
                    //       inverted: SvgIcon(
                    //         contact
                    //             ? SvgIcons.deleteContactWhite
                    //             : SvgIcons.addContactWhite,
                    //       ),
                    //     ),

                    //     ContextMenuButton(
                    //       label: favorite
                    //           ? 'btn_delete_from_favorites'.l10n
                    //           : 'btn_add_to_favorites'.l10n,

                    //       // TODO: ADD TO CONTACTS AND THEN FAVORITE.
                    //       onPressed: favorite
                    //           ? c.unfavoriteContact
                    //           : c.favoriteContact,
                    //       trailing: SvgIcon(
                    //         favorite
                    //             ? SvgIcons.favoriteSmall
                    //             : SvgIcons.unfavoriteSmall,
                    //       ),
                    //       inverted: SvgIcon(
                    //         favorite
                    //             ? SvgIcons.favoriteSmallWhite
                    //             : SvgIcons.unfavoriteSmallWhite,
                    //       ),
                    //     ),
                    //   ],
                    //   child: Container(
                    //     padding:
                    //         const EdgeInsets.only(left: 21 + 10, right: 4 + 21),
                    //     height: double.infinity,
                    //     child: const SvgIcon(SvgIcons.more),
                    //   ),
                    // );
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
          // if (c.editing.value) ...[
          //   AnimatedButton(
          //     onPressed: c.editing.toggle,
          //     decorator: (child) => Padding(
          //       padding: const EdgeInsets.fromLTRB(0, 0, 18, 0),
          //       child: child,
          //     ),
          //     child: const SvgIcon(SvgIcons.closePrimary),
          //   ),
          // ] else ...[
          //   // AnimatedButton(
          //   //   onPressed: c.openChat,
          //   //   child: const SvgIcon(SvgIcons.chat),
          //   // ),
          //   // const SizedBox(width: 28),
          //   // AnimatedButton(
          //   //   onPressed: () => c.call(true),
          //   //   child: const SvgIcon(SvgIcons.chatVideoCall),
          //   // ),
          //   // const SizedBox(width: 28),
          //   // AnimatedButton(
          //   //   onPressed: () => c.call(false),
          //   //   child: const SvgIcon(SvgIcons.chatAudioCall),
          //   // ),
          // ],
        ],
      ),
    );
  }

  /// Returns the action buttons to do with this [User].
  Widget _actions(UserController c, BuildContext context) {
    final bool contact = c.inContacts.value;
    final bool favorite = c.inFavorites.value;
    final bool blocked = c.isBlocked != null;

    final RxChat? dialog = c.user?.user.value.dialog.isLocal == false
        ? c.user?.dialog.value
        : null;

    final bool muted = dialog?.chat.value.muted != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ActionButton(
          text: 'btn_audio_call'.l10n,
          onPressed: () => c.call(false),
          trailing: Transform.translate(
            offset: const Offset(0, 0),
            child: const SvgIcon(SvgIcons.audioCall16),
          ),
        ),
        ActionButton(
          text: 'btn_video_call'.l10n,
          onPressed: () => c.call(true),
          trailing: Transform.translate(
            offset: const Offset(-2, 0),
            child: const SvgIcon(SvgIcons.videoCall16),
          ),
        ),
        ActionButton(
          text: 'label_chat'.l10n,
          onPressed: () => router.chat(c.user!.user.value.dialog),
          trailing: Transform.translate(
            offset: const Offset(0, 0),
            child: const SvgIcon(SvgIcons.chat16),
          ),
        ),

        ActionButton(
          text: contact
              ? 'btn_delete_from_contacts'.l10n
              : 'btn_add_to_contacts'.l10n,
          onPressed: contact ? c.removeFromContacts : c.addToContacts,
          trailing: SvgIcon(
            contact ? SvgIcons.deleteContact16 : SvgIcons.addContact16,
          ),
        ),

        ActionButton(
          text: favorite
              ? 'btn_delete_from_favorites'.l10n
              : 'btn_add_to_favorites'.l10n,
          onPressed: favorite ? c.unfavoriteContact : c.favoriteContact,
          trailing: SvgIcon(
            favorite ? SvgIcons.favorite16 : SvgIcons.unfavorite16,
          ),
        ),
        // Obx(() {
        //   return ActionButton(
        //     key: Key(c.inContacts.value
        //         ? 'DeleteFromContactsButton'
        //         : 'AddToContactsButton'),
        //     text: c.inContacts.value
        //         ? 'btn_delete_from_contacts'.l10n
        //         : 'btn_add_to_contacts'.l10n,
        //     trailing: SvgIcon(
        //       c.inContacts.value
        //           ? SvgIcons.deleteContact16
        //           : SvgIcons.addContact16,
        //     ),
        //     onPressed: c.status.value.isLoadingMore
        //         ? null
        //         : c.inContacts.value
        //             ? () => _removeFromContacts(c, context)
        //             : c.addToContacts,
        //   );
        // }),
        // Obx(() {
        //   return ActionButton(
        //     text: c.inFavorites.value
        //         ? 'btn_delete_from_favorites'.l10n
        //         : 'btn_add_to_favorites'.l10n,
        //     onPressed:
        //         c.inFavorites.value ? c.unfavoriteContact : c.favoriteContact,
        //     trailing: SvgIcon(
        //       c.inFavorites.value ? SvgIcons.unfavorite16 : SvgIcons.favorite16,
        //     ),
        //   );
        // }),
        // if (c.user?.user.value.dialog.isLocal == false &&
        //     c.user?.dialog.value != null) ...[
        //   Obx(() {
        //     if (c.isBlocked != null) {
        //       return const SizedBox.shrink();
        //     }

        //     final chat = c.user!.dialog.value!.chat.value;
        //     final bool isMuted = chat.muted != null;

        //     return ActionButton(
        //       text: isMuted ? 'btn_unmute_chat'.l10n : 'btn_mute_chat'.l10n,
        //       trailing:
        //           SvgIcon(isMuted ? SvgIcons.muted16 : SvgIcons.unmuted16),
        //       onPressed: isMuted ? c.unmuteChat : c.muteChat,
        //     );
        //   }),
        //   ActionButton(
        //     text: 'btn_delete_chat'.l10n,
        //     trailing: const SvgIcon(SvgIcons.delete),
        //     onPressed: () => _hideChat(c, context),
        //   ),
        //   ActionButton(
        //     key: const Key('ClearHistoryButton'),
        //     text: 'btn_clear_history'.l10n,
        //     trailing: const SvgIcon(SvgIcons.cleanHistory16),
        //     onPressed: () => _clearChat(c, context),
        //   ),
        // ],
        // Obx(() {
        //   return ActionButton(
        //     key: Key(c.isBlocked != null ? 'Unblock' : 'Block'),
        //     text: c.isBlocked != null ? 'btn_unblock'.l10n : 'btn_block'.l10n,
        //     onPressed: c.isBlocked != null
        //         ? c.unblacklist
        //         : () => _blacklistUser(c, context),
        //     trailing: Obx(() {
        //       final Widget child;
        //       if (c.blacklistStatus.value.isEmpty) {
        //         child = const SvgIcon(SvgIcons.block16);
        //       } else {
        //         child = const CustomProgressIndicator();
        //       }

        //       return SafeAnimatedSwitcher(
        //         duration: 200.milliseconds,
        //         child: child,
        //       );
        //     }),
        //   );
        // }),

        ActionButton(
          text: 'btn_report'.l10n,
          onPressed: c.report,
          trailing: const SvgIcon(SvgIcons.report16),
        ),
        if (c.isBlocked == null)
          Obx(() {
            final bool blocked = c.isBlocked != null;

            return ActionButton(
              text: blocked ? 'btn_unblock'.l10n : 'btn_block'.l10n,
              onPressed:
                  blocked ? c.unblacklist : () => _blacklistUser(c, context),
              trailing: Obx(() {
                final Widget child;
                if (c.blacklistStatus.value.isEmpty) {
                  child = const SvgIcon(SvgIcons.block16);
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
        // Obx(() {
        //   if (c.user?.dialog.value?.id.isLocal != false) {
        //     return const SizedBox();
        //   }

        //   return ActionButton(
        //     text: 'btn_delete_chat'.l10n,
        //     onPressed: () => _hideChat(c, context),
        //     trailing: const SvgIcon(SvgIcons.delete),
        //   );
        // }),
      ],
    );
  }

  Widget _verification(BuildContext context, UserController c) {
    final style = Theme.of(context).style;

    return Obx(() {
      return AnimatedSizeAndFade(
        fadeDuration: 300.milliseconds,
        sizeDuration: 300.milliseconds,
        child: c.verified.value
            ? const SizedBox(width: double.infinity)
            : Column(
                key: const Key('123'),
                children: [
                  const SizedBox(height: 12 * 2),
                  Paddings.dense(
                    Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme:
                            Theme.of(context).inputDecorationTheme.copyWith(
                                  border: Theme.of(context)
                                      .inputDecorationTheme
                                      .border
                                      ?.copyWith(
                                        borderSide: c.hintVerified.value
                                            ? BorderSide(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              )
                                            : Theme.of(context)
                                                .inputDecorationTheme
                                                .border
                                                ?.borderSide,
                                      ),
                                ),
                      ),
                      child: FieldButton(
                        text: 'btn_verify_email'.l10n,
                        onPressed: () async {
                          await AddEmailView.show(
                            context,
                            email: c.myUser.value?.emails.unconfirmed,
                          );
                        },
                        trailing: const SvgIcon(SvgIcons.verifyEmail),
                        style: TextStyle(color: style.colors.primary),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 6),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                        ),
                        children: [
                          TextSpan(
                            text:
                                'Данная опция доступна только для аккаунтов с верифицированным E-mail'
                                    .l10n,
                            style: const TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      );
    });
  }

  Widget _quick(UserController c, BuildContext context) {
    final style = Theme.of(context).style;

    Widget button({
      required SvgData icon,
      required String label,
      void Function()? onPressed,
    }) {
      return WidgetButton(
        onPressed: onPressed,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: style.cardColor,
            border: style.cardBorder,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgIcon(icon),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                  child: FittedBox(
                    child: Text(
                      label,
                      style: style.fonts.small.regular.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SelectionContainer.disabled(
      child: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          constraints:
              context.isNarrow ? null : const BoxConstraints(maxWidth: 400),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: button(
                  label: 'label_chat'.l10n,
                  icon: SvgIcons.chat,
                  onPressed: () => router.chat(c.user!.user.value.dialog),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: button(
                  label: 'btn_audio'.l10n,
                  icon: SvgIcons.chatAudioCall,
                  onPressed: () => c.call(false),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: button(
                  label: 'btn_video'.l10n,
                  icon: SvgIcons.chatVideoCall,
                  onPressed: () => c.call(true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns a [User.name] copyable field.
  Widget _paid(UserController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Column(
      children: [
        Paddings.basic(
          Stack(
            children: [
              ReactiveTextField(
                state: c.messageCost,
                style: style.fonts.medium.regular.onBackground,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                hint: '0',
                // prefixText: '    ',
                // prefixText: '¤',
                // prefixStyle: style.fonts.medium.regular.onBackground,

                prefix: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 1, 0),
                  child: Transform.translate(
                    offset: PlatformUtils.isWeb
                        ? const Offset(0, -0)
                        : const Offset(0, -0.5),
                    child: Text(
                      '¤',
                      style: style.fonts.medium.regular.onBackground,
                    ),
                  ),
                ),
                label: 'Входящие сообщения, за 1 сообщение',
              ),
              // Padding(
              //   padding: const EdgeInsets.fromLTRB(21, 16.3, 0, 0),
              //   child: Text(
              //     // 'G',
              //     '¤',
              //     style: style.fonts.medium.regular.onBackground,
              //   ),
              // ),
            ],
          ),
        ),
        Paddings.basic(
          Stack(
            children: [
              ReactiveTextField(
                state: c.callsCost,
                style: style.fonts.medium.regular.onBackground,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                hint: '0',
                // prefixText: '    ',
                // prefixStyle: TextStyle(fontSize: 12),
                // prefixText: '¤',
                // prefixStyle: style.fonts.medium.regular.onBackground,
                prefix: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 1, 0),
                  child: Transform.translate(
                    offset: PlatformUtils.isWeb
                        ? const Offset(0, -0)
                        : const Offset(0, -1),
                    child: Text(
                      '¤',
                      style: style.fonts.medium.regular.onBackground,
                    ),
                  ),
                ),
                label: 'Входящие звонки, за 1 минуту',
              ),
              // Padding(
              //   padding: const EdgeInsets.fromLTRB(21, 16.3, 0, 0),
              //   child: Text(
              //     '¤',
              //     style: style.fonts.medium.regular.onBackground.copyWith(
              //       fontFamily: 'RobotoGapopa',
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
        Opacity(opacity: 0, child: _verification(context, c)),
      ],
    );

    return Obx(() {
      return Column(
        children: [
          Paddings.basic(
            Stack(
              alignment: Alignment.centerLeft,
              children: [
                FieldButton(
                  text: c.messageCost.text,
                  prefixText: '    ',
                  prefixStyle: const TextStyle(fontSize: 13),
                  label: 'label_fee_per_incoming_message'.l10n,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  onPressed: () async {
                    await GetPaidView.show(
                      context,
                      mode: GetPaidMode.user,
                      user: c.user,
                    );
                  },
                  style: TextStyle(
                    color: c.verified.value
                        ? style.colors.primary
                        : style.colors.secondary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 21, bottom: 0),
                  child: Text(
                    // '¤',
                    'G',
                    style: TextStyle(
                      color: style.colors.primary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Paddings.basic(
            Stack(
              alignment: Alignment.centerLeft,
              children: [
                FieldButton(
                  text: c.callsCost.text,
                  prefixText: '    ',
                  prefixStyle: const TextStyle(fontSize: 13),
                  label: 'label_fee_per_incoming_call_minute'.l10n,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  onPressed: () async {
                    await GetPaidView.show(
                      context,
                      mode: GetPaidMode.user,
                      user: c.user,
                    );
                  },
                  style: TextStyle(
                    color: c.verified.value
                        ? style.colors.primary
                        : style.colors.secondary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 21, bottom: 0),
                  child: Text(
                    // '¤',
                    'G',
                    style: TextStyle(
                      // fontFamily: 'Gapopa',
                      fontWeight: FontWeight.w400,
                      color: style.colors.primary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Opacity(opacity: 0, child: _verification(context, c)),
        ],
      );
    });
  }

  /// Opens a confirmation popup deleting the [User] from address book.
  Future<void> _removeFromContacts(
    UserController c,
    BuildContext context,
  ) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_delete_contact'.l10n,
      description: [
        TextSpan(text: 'alert_contact_will_be_removed1'.l10n),
        TextSpan(
          text:
              c.user?.user.value.name?.val ?? c.user?.user.value.num.toString(),
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_contact_will_be_removed2'.l10n),
      ],
    );

    if (result == true) {
      await c.removeFromContacts();
    }
  }

  /// Opens a confirmation popup hiding the [Chat]-dialog with the [User].
  Future<void> _hideChat(UserController c, BuildContext context) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_delete_chat'.l10n,
      description: [
        TextSpan(text: 'alert_dialog_will_be_deleted1'.l10n),
        TextSpan(
          text:
              c.user?.user.value.name?.val ?? c.user?.user.value.num.toString(),
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_dialog_will_be_deleted2'.l10n),
      ],
    );

    if (result == true) {
      await c.hideChat();
    }
  }

  /// Opens a confirmation popup clearing the [Chat]-dialog with the [User].
  Future<void> _clearChat(UserController c, BuildContext context) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_clear_history'.l10n,
      description: [
        TextSpan(text: 'alert_dialog_will_be_cleared1'.l10n),
        TextSpan(
          text:
              c.user?.user.value.name?.val ?? c.user?.user.value.num.toString(),
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_dialog_will_be_cleared2'.l10n),
      ],
    );

    if (result == true) {
      await c.clearChat();
    }
  }

  /// Opens a confirmation popup blacklisting the [User].
  Future<void> _blacklistUser(UserController c, BuildContext context) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_block'.l10n,
      description: [
        TextSpan(text: 'alert_user_will_be_blocked1'.l10n),
        TextSpan(
          text:
              c.user?.user.value.name?.val ?? c.user?.user.value.num.toString(),
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
      await c.blacklist();
    }
  }
}
