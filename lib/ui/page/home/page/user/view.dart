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
import 'package:intl/intl.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/ui/page/home/page/chat/get_paid/controller.dart';
import 'package:messenger/ui/page/home/page/chat/get_paid/view.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_subtitle.dart';
import 'package:messenger/ui/page/home/page/user/set_price/view.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/page/home/widget/chat_tile.dart';
import 'package:messenger/ui/page/home/widget/direct_link.dart';
import 'package:messenger/ui/page/home/widget/field_button.dart';
import 'package:messenger/ui/page/home/widget/num.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';
import 'package:messenger/ui/widget/expandable_text.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../my_profile/add_email/view.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/action.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/big_avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/copy_or_share.dart';
import '/ui/page/home/widget/info_tile.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/page/home/widget/unblock_button.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/page/home/widget/quick_button.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'widget/blocklist_record.dart';
import 'widget/contact_info.dart';
import 'widget/money_field.dart';
import 'widget/prices.dart';

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
                          children: [
                            BlocklistRecordWidget(
                              c.isBlocked!,
                              onUnblock: c.unblock,
                            ),
                          ],
                        ),
                      _profile(c, context),
                      _quick(c, context),
                      _bio(c, context),
                      _info(c),
                      SelectionContainer.disabled(
                        child: Block(
                          title: 'label_direct_chat_link'.l10n,
                          children: [
                            DirectLinkField(
                              ChatDirectLink(
                                slug: ChatDirectLinkSlug('dqwdqwdqwd'),
                              ),
                              editing: false,
                              transitions: false,
                              background: c.background.value,
                            ),
                          ],
                        ),
                      ),
                      _money(c, context),
                      SelectionContainer.disabled(
                        child: Block(children: [_actions(c, context)]),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              }),
            ),
          );
        });
      },
    );
  }

  /// Builds a [Block] displaying a [User.avatar] and [User.name].
  Widget _profile(UserController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Obx(() {
      return Block(
        overlay: [
          if (c.contact.value != null)
            EditBlockButton(
              key: const Key('EditProfileButton'),
              onPressed: c.profileEditing.toggle,
              editing: c.profileEditing.value,
            ),
        ],
        children: [
          SelectionContainer.disabled(
            child: BigAvatarWidget.user(
              c.user,
              key: Key('UserAvatar_${c.id}'),
              loading: c.avatar.value.isLoading,
              error: c.avatar.value.errorMessage,
            ),
          ),
          Obx(() {
            final List<Widget> children;

            if (c.profileEditing.value) {
              children = [
                const SizedBox(height: 4),
                SelectionContainer.disabled(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      WidgetButton(
                        key: const Key('UploadAvatar'),
                        onPressed: c.pickAvatar,
                        child: Text(
                          'btn_upload'.l10n,
                          style: style.fonts.small.regular.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SelectionContainer.disabled(
                  child: ReactiveTextField(
                    state: c.name,
                    label: 'label_name'.l10n,
                    hint: c.contact.value?.contact.value.name.val ??
                        c.user!.user.value.name?.val ??
                        c.user!.user.value.num.toString(),
                    formatters: [LengthLimitingTextInputFormatter(100)],
                  ),
                ),
                const SizedBox(height: 4),
              ];
            } else {
              children = [
                const SizedBox(height: 18),
                Container(width: double.infinity),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Text(
                    c.contact.value?.contact.value.name.val ?? c.name.text,
                    style: style.fonts.large.regular.onBackground,
                  ),
                ),
              ];
            }

            return AnimatedSizeAndFade(
              fadeDuration: 250.milliseconds,
              sizeDuration: 250.milliseconds,
              child: Column(
                key: Key(c.profileEditing.value.toString()),
                children: children,
              ),
            );
          }),
        ],
      );
    });
  }

  /// Returns the [User.status] visual representation.
  Widget _bio(UserController c, BuildContext context) {
    final style = Theme.of(context).style;

    final UserBio? bio = c.user?.user.value.bio;

    if (bio != null) {
      return Block(
        padding: Block.defaultPadding.copyWith(top: 8, bottom: 8),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              bio.toString(),
              style: style.fonts.normal.regular.secondary,
            ),
          ),
        ],
      );
    } else {
      return const SizedBox();
    }
  }

  /// Returns the [User.num] visual representation.
  Widget _info(UserController c) {
    return Block(
      title: 'Информация',
      children: [
        Paddings.basic(
          const InfoTile(
            title: 'Login',
            content: '@alice',
            trailing: CopyOrShareButton('alice'),
          ),
        ),
        Paddings.basic(
          InfoTile(
            title: 'Gapopa ID',
            content: c.user!.user.value.num.toString(),
            trailing: CopyOrShareButton(
              c.user!.user.value.num.toString(),
            ),
          ),
        ),
        Paddings.basic(
          const InfoTile(
            title: 'E-mail',
            content: 'hello@example.com',
            trailing: CopyOrShareButton('hello@example.com'),
          ),
        ),
        Paddings.basic(
          const InfoTile(
            title: 'Phone',
            content: '+1 234 5678 90',
            trailing: CopyOrShareButton('+1 234 5678 90'),
          ),
        ),
      ],
    );
  }

  Widget _bar(UserController c, BuildContext context) {
    final style = Theme.of(context).style;

    final Widget editButton = Obx(key: const Key('MoreButton'), () {
      final bool contact = c.contact.value != null;
      final bool favorite =
          c.contact.value?.contact.value.favoritePosition != null;
      final RxChat? dialog = c.user?.dialog.value;
      final bool hasCall = dialog?.chat.value.ongoingCall != null;
      final bool isMuted = dialog?.chat.value.muted != null;

      return ContextMenuRegion(
        key: c.moreKey,
        selector: c.moreKey,
        alignment: Alignment.topRight,
        enablePrimaryTap: true,
        margin: const EdgeInsets.only(bottom: 4, left: 20),
        actions: [
          ContextMenuButton(
            label: 'label_open_chat'.l10n,
            onPressed: c.openChat,
            trailing: const SvgIcon(SvgIcons.chat18),
            inverted: const SvgIcon(SvgIcons.chat18White),
          ),
          ContextMenuButton(
            label: 'btn_audio_call'.l10n,
            onPressed: hasCall ? null : () => c.call(false),
            trailing: hasCall
                ? const SvgIcon(SvgIcons.makeVideoCallDisabled)
                : const SvgIcon(SvgIcons.makeAudioCall),
            inverted: const SvgIcon(SvgIcons.makeAudioCallWhite),
          ),
          ContextMenuButton(
            label: 'btn_video_call'.l10n,
            onPressed: hasCall ? null : () => c.call(true),
            trailing: Transform.translate(
              offset: const Offset(2, 0),
              child: hasCall
                  ? const SvgIcon(SvgIcons.makeVideoCallDisabled)
                  : const SvgIcon(SvgIcons.makeVideoCall),
            ),
            inverted: Transform.translate(
              offset: const Offset(2, 0),
              child: const SvgIcon(SvgIcons.makeVideoCallWhite),
            ),
          ),
          ContextMenuButton(
            key: contact
                ? const Key('DeleteFromContactsButton')
                : const Key('AddToContactsButton'),
            label: contact
                ? 'btn_delete_from_contacts'.l10n
                : 'btn_add_to_contacts'.l10n,
            onPressed: contact ? c.removeFromContacts : c.addToContacts,
            trailing: SvgIcon(
              contact ? SvgIcons.deleteContact : SvgIcons.addContact,
            ),
            inverted: SvgIcon(
              contact ? SvgIcons.deleteContactWhite : SvgIcons.addContactWhite,
            ),
          ),
          ContextMenuButton(
            key: favorite
                ? const Key('DeleteFromFavoriteButton')
                : const Key('AddToFavoriteButton'),
            label: favorite
                ? 'btn_delete_from_favorites'.l10n
                : 'btn_add_to_favorites'.l10n,
            onPressed: favorite
                ? c.unfavoriteContact
                : () async {
                    await c.addToContacts();
                    await c.favoriteContact();
                  },
            trailing: SvgIcon(
              favorite ? SvgIcons.favoriteSmall : SvgIcons.unfavoriteSmall,
            ),
            inverted: SvgIcon(
              favorite
                  ? SvgIcons.favoriteSmallWhite
                  : SvgIcons.unfavoriteSmallWhite,
            ),
          ),
          if (dialog?.id.isLocal == false) ...[
            ContextMenuButton(
              label: isMuted ? 'btn_unmute_chat'.l10n : 'btn_mute_chat'.l10n,
              trailing: SvgIcon(
                isMuted ? SvgIcons.muteSmall : SvgIcons.unmuteSmall,
              ),
              inverted: SvgIcon(
                isMuted ? SvgIcons.muteSmallWhite : SvgIcons.unmuteSmallWhite,
              ),
              onPressed: isMuted ? c.unmuteChat : c.muteChat,
            ),
            ContextMenuButton(
              label: 'btn_delete_chat'.l10n,
              trailing: const SvgIcon(SvgIcons.delete19),
              inverted: const SvgIcon(SvgIcons.delete19White),
              onPressed: () => _hideChat(c, context),
            ),
            ContextMenuButton(
              key: const Key('ClearHistoryButton'),
              label: 'btn_clear_history'.l10n,
              trailing: const SvgIcon(SvgIcons.cleanHistory),
              inverted: const SvgIcon(SvgIcons.cleanHistoryWhite),
              onPressed: () => _clearChat(c, context),
            ),
          ],
          ContextMenuButton(
            label: 'btn_report'.l10n,
            onPressed: c.report,
            trailing: const SvgIcon(SvgIcons.report),
            inverted: const SvgIcon(SvgIcons.reportWhite),
          ),
          if (c.isBlocked == null)
            ContextMenuButton(
              key: const Key('Block'),
              label: 'btn_block'.l10n,
              onPressed: () => _blockUser(c, context),
              trailing: const SvgIcon(SvgIcons.block),
              inverted: const SvgIcon(SvgIcons.blockWhite),
            )
        ],
        child: Container(
          padding: const EdgeInsets.only(left: 31, right: 25),
          height: double.infinity,
          child: const SvgIcon(SvgIcons.more),
        ),
      );
    });

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

                final String subtitle = buffer.toString();

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.contact.value?.contact.value.name.val ?? c.user?.user.value.name?.val ?? c.user?.user.value.num}',
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        key: Key(
                          c.user?.user.value.presence?.name.capitalizeFirst ??
                              '',
                        ),
                        subtitle,
                        style: style.fonts.small.regular.secondary,
                      )
                  ],
                );
              }),
            ),
          ),
          const SizedBox(width: 40),
          editButton,
        ],
      ),
    );
  }

  /// Returns the action buttons to do with this [User].
  Widget _actions(UserController c, BuildContext context) {
    return Obx(() {
      final bool contact = c.contact.value != null;
      final bool favorite =
          c.contact.value?.contact.value.favoritePosition != null;
      final RxChat? dialog = c.user?.dialog.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
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
          if (dialog?.id.isLocal == false) ...[
            Obx(() {
              final bool isMuted = dialog?.chat.value.muted != null;

              return ActionButton(
                text: isMuted ? 'btn_unmute_chat'.l10n : 'btn_mute_chat'.l10n,
                trailing:
                    SvgIcon(isMuted ? SvgIcons.muted16 : SvgIcons.unmuted16),
                onPressed: isMuted ? c.unmuteChat : c.muteChat,
              );
            }),
            ActionButton(
              text: 'btn_delete_chat'.l10n,
              trailing: const SvgIcon(SvgIcons.delete),
              onPressed: () => _hideChat(c, context),
            ),
            ActionButton(
              key: const Key('ClearHistoryButton'),
              text: 'btn_clear_history'.l10n,
              trailing: const SvgIcon(SvgIcons.cleanHistory16),
              onPressed: () => _clearChat(c, context),
            ),
          ],
          ActionButton(
            text: 'btn_report'.l10n,
            trailing: const SvgIcon(SvgIcons.report16),
            onPressed: c.report,
          ),
          Obx(() {
            if (c.isBlocked != null) {
              return const SizedBox();
            }

            return ActionButton(
              key: const Key('Block'),
              text: 'btn_block'.l10n,
              onPressed: () => _blockUser(c, context),
              trailing: const SvgIcon(SvgIcons.block16),
            );
          }),
        ],
      );
    });
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

  /// Returns the [QuickButton] for quick actions to do with this [User].
  Widget _quick(UserController c, BuildContext context) {
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
                child: QuickButton(
                  label: 'label_chat'.l10n,
                  icon: SvgIcons.chat,
                  onPressed: c.openChat,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: QuickButton(
                  label: 'btn_audio'.l10n,
                  icon: SvgIcons.chatAudioCall,
                  onPressed: () => c.call(false),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: QuickButton(
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

  Widget _money(UserController c, BuildContext context) {
    return SelectionContainer.disabled(
      child: Stack(
        children: [
          Block(
            // title:
            //     'Установить цену за сообщения и звонки от ${c.user!.user.value.name?.val ?? c.user!.user.value.num.toString()}',
            title: 'Монетизация (входящие)',
            overlay: [
              Positioned(
                right: 0,
                top: 0,
                child: Center(
                  child: SelectionContainer.disabled(
                    child: AnimatedButton(
                      onPressed: c.moneyEditing.toggle,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(6, 6, 0, 6),
                        child: c.moneyEditing.value
                            ? const Padding(
                                padding: EdgeInsets.all(2),
                                child: SvgIcon(
                                  SvgIcons.closeSmallPrimary,
                                ),
                              )
                            : const SvgIcon(SvgIcons.editSmall),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            children: [_paid(c, context)],
          ),
          Positioned.fill(
            child: Obx(() {
              return IgnorePointer(
                ignoring: c.verified.value,
                child: Center(
                  child: AnimatedContainer(
                    margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
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
                          padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                          margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                          constraints: context.isNarrow
                              ? null
                              : const BoxConstraints(maxWidth: 400),
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
    );
  }

  /// Returns a [User.name] copyable field.
  Widget _paid(UserController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Obx(() {
      final Widget child;

      if (c.moneyEditing.value) {
        child = Paddings.basic(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TODO: Here should be displayed what user really pays, not just their individual.
              MoneyField(
                state: c.messageCost,
                label: 'Входящие сообщения, за 1 сообщение',
              ),
              const SizedBox(height: 24),
              MoneyField(
                state: c.callsCost,
                label: 'Входящие звонки, за 1 минуту',
              ),
            ],
          ),
        );
      } else {
        child = Column(
          key: const Key('1'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: double.infinity),
            Center(
              child: Prices(
                calls: c.callPrice.value,
                messages: c.messagePrice.value,
                onMessagesPressed: () {
                  c.moneyEditing.value = true;
                  c.messageCost.focus.requestFocus();
                },
                onCallsPressed: () {
                  c.moneyEditing.value = true;
                  c.callsCost.focus.requestFocus();
                },
              ),
            ),

            const SizedBox(height: 16),
            // 'alex2 платит Вам за отправку Вам сообщений и совершение звонков.',
            // 'alex2 оплачивает Вам отправку своих сообщений и совершение звонков.'
            Text(
              '${c.user?.user.value.name ?? c.user?.user.value.num} платит Вам за отправку Вам сообщений и совершение звонков.',
              style: style.fonts.small.regular.secondary,
            ),
          ],
        );
      }

      return AnimatedSizeAndFade(
        sizeDuration: const Duration(milliseconds: 300),
        fadeDuration: const Duration(milliseconds: 300),
        child: child,
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

extension on int {
  String withSpaces() => NumberFormat('#,##0').format(this);
}
