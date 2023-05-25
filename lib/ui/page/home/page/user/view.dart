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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/page/chat/message_field/view.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/my_profile/controller.dart';
import '/ui/page/home/page/my_profile/widget/copyable.dart';
import '/ui/page/home/page/my_profile/widget/field_button.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View of the [Routes.user] page.
class UserView extends StatelessWidget {
  const UserView(this.id, {Key? key}) : super(key: key);

  /// ID of the [User] this [UserView] represents.
  final UserId id;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return GetBuilder(
      init: UserController(id, Get.find(), Get.find(), Get.find(), Get.find()),
      tag: id.val,
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
                title: Row(
                  children: [
                    Material(
                      elevation: 6,
                      type: MaterialType.circle,
                      shadowColor: style.colors.onBackgroundOpacity27,
                      color: style.colors.onPrimary,
                      child: Center(
                        child: AvatarWidget.fromRxUser(c.user, radius: 17),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: DefaultTextStyle.merge(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: Obx(() {
                          final String? status = c.user?.user.value.getStatus();
                          final UserTextStatus? text =
                              c.user?.user.value.status;
                          final StringBuffer buffer = StringBuffer();

                          if (status != null || text != null) {
                            buffer.write(text ?? '');

                            if (status != null && text != null) {
                              buffer.write('space_vertical_space'.l10n);
                            }

                            buffer.write(status ?? '');
                          }

                          final String subtitle = buffer.toString();

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${c.user?.user.value.name?.val ?? c.user?.user.value.num.val}'),
                              if (subtitle.isNotEmpty)
                                Text(
                                  subtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: style.colors.secondary),
                                )
                            ],
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
                padding: const EdgeInsets.only(left: 4, right: 20),
                leading: const [StyledBackButton()],
                actions: [
                  WidgetButton(
                    onPressed: c.openChat,
                    child: Transform.translate(
                      offset: const Offset(0, 1),
                      child: SvgImage.asset(
                        'assets/icons/chat.svg',
                        width: 20.12,
                        height: 21.62,
                      ),
                    ),
                  ),
                  Obx(() {
                    if (c.isBlacklisted != null) {
                      return const SizedBox.shrink();
                    }

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (constraints.maxWidth > 400) ...[
                          const SizedBox(width: 28),
                          WidgetButton(
                            onPressed: () => c.call(true),
                            child: SvgImage.asset(
                              'assets/icons/chat_video_call.svg',
                              height: 17,
                            ),
                          ),
                        ],
                        const SizedBox(width: 28),
                        WidgetButton(
                          onPressed: () => c.call(false),
                          child: SvgImage.asset(
                            'assets/icons/chat_audio_call.svg',
                            height: 19,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              body: Scrollbar(
                controller: c.scrollController,
                child: Obx(() {
                  return ListView(
                    key: const Key('UserScrollable'),
                    controller: c.scrollController,
                    children: [
                      const SizedBox(height: 8),
                      if (c.isBlacklisted != null)
                        Block(
                          title: 'label_user_is_blocked'.l10n,
                          children: [_blocked(c, context)],
                        ),
                      Block(
                        title: 'label_public_information'.l10n,
                        children: [
                          WidgetButton(
                            onPressed: c.user?.user.value.avatar == null
                                ? null
                                : () async {
                                    await GalleryPopup.show(
                                      context: context,
                                      gallery: GalleryPopup(
                                        initialKey: c.avatarKey,
                                        children: [
                                          GalleryItem.image(
                                            c.user!.user.value.avatar!.original
                                                .url,
                                            c.user!.id.val,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                            child: AvatarWidget.fromRxUser(
                              c.user,
                              key: c.avatarKey,
                              radius: 100,
                              badge: false,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _name(c, context),
                          _status(c, context),
                          _presence(c, context),
                        ],
                      ),
                      Block(
                        title: 'label_contact_information'.l10n,
                        children: [_num(c, context)],
                      ),
                      Block(
                        title: 'label_actions'.l10n,
                        children: [_actions(c, context)],
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }),
              ),
              bottomNavigationBar: Obx(() {
                if (c.isBlacklisted == null) {
                  return const SizedBox();
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                  child: _blockedField(context, c),
                );
              }),
            );
          });
        });
      },
    );
  }

  /// Dense [Padding] wrapper.
  Widget _dense(Widget child) =>
      Padding(padding: const EdgeInsets.fromLTRB(8, 4, 8, 4), child: child);

  /// Basic [Padding] wrapper.
  Widget _padding(Widget child) =>
      Padding(padding: const EdgeInsets.all(8), child: child);

  /// Returns the action buttons to do with this [User].
  Widget _actions(UserController c, BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    // Builds a stylized button representing a single action.
    Widget action({
      Key? key,
      String? text,
      void Function()? onPressed,
      Widget? trailing,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: _dense(
          FieldButton(
            key: key,
            onPressed: onPressed,
            text: text ?? '',
            style: TextStyle(color: style.colors.primary),
            trailing: trailing != null
                ? Transform.translate(
                    offset: const Offset(0, -1),
                    child: Transform.scale(scale: 1.15, child: trailing),
                  )
                : null,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          return action(
            key: Key(c.inContacts.value
                ? 'DeleteFromContactsButton'
                : 'AddToContactsButton'),
            text: c.inContacts.value
                ? 'btn_delete_from_contacts'.l10n
                : 'btn_add_to_contacts'.l10n,
            onPressed: c.status.value.isLoadingMore
                ? null
                : c.inContacts.value
                    ? () => _removeFromContacts(c, context)
                    : c.addToContacts,
          );
        }),
        Obx(() {
          return action(
            text: c.inFavorites.value
                ? 'btn_delete_from_favorites'.l10n
                : 'btn_add_to_favorites'.l10n,
            onPressed:
                c.inFavorites.value ? c.unfavoriteContact : c.favoriteContact,
          );
        }),
        if (c.user?.user.value.dialog.isLocal == false &&
            c.user?.dialog.value != null) ...[
          Obx(() {
            if (c.isBlacklisted != null) {
              return const SizedBox.shrink();
            }

            final chat = c.user!.dialog.value!.chat.value;
            final bool isMuted = chat.muted != null;

            return action(
              text: isMuted ? 'btn_unmute_chat'.l10n : 'btn_mute_chat'.l10n,
              trailing: isMuted
                  ? SvgImage.asset(
                      'assets/icons/btn_mute.svg',
                      width: 18.68,
                      height: 15,
                    )
                  : SvgImage.asset(
                      'assets/icons/btn_unmute.svg',
                      width: 17.86,
                      height: 15,
                    ),
              onPressed: isMuted ? c.unmuteChat : c.muteChat,
            );
          }),
          action(
            text: 'btn_hide_chat'.l10n,
            trailing: SvgImage.asset('assets/icons/delete.svg', height: 14),
            onPressed: () => _hideChat(c, context),
          ),
          action(
            key: const Key('ClearHistoryButton'),
            text: 'btn_clear_history'.l10n,
            trailing: SvgImage.asset('assets/icons/delete.svg', height: 14),
            onPressed: () => _clearChat(c, context),
          ),
        ],
        Obx(() {
          return action(
            key: Key(c.isBlacklisted != null ? 'Unblock' : 'Block'),
            text:
                c.isBlacklisted != null ? 'btn_unblock'.l10n : 'btn_block'.l10n,
            onPressed: c.isBlacklisted != null
                ? c.unblacklist
                : () => _blacklistUser(c, context),
            trailing: Obx(() {
              final Widget child;
              if (c.blacklistStatus.value.isEmpty) {
                child = const SizedBox();
              } else {
                child = const CustomProgressIndicator();
              }

              return AnimatedSwitcher(
                duration: 200.milliseconds,
                child: child,
              );
            }),
          );
        }),
        action(text: 'btn_report'.l10n, onPressed: () {}),
      ],
    );
  }

  /// Returns a [User.name] copyable field.
  Widget _name(UserController c, BuildContext context) {
    return _padding(
      CopyableTextField(
        key: const Key('NameField'),
        state: TextFieldState(
          text: '${c.user?.user.value.name?.val ?? c.user?.user.value.num.val}',
        ),
        label: 'label_name'.l10n,
        copy: '${c.user?.user.value.name?.val ?? c.user?.user.value.num.val}',
      ),
    );
  }

  /// Returns a [User.status] copyable field.
  Widget _status(UserController c, BuildContext context) {
    return Obx(() {
      final UserTextStatus? status = c.user?.user.value.status;

      if (status == null) {
        return Container();
      }

      return _padding(
        CopyableTextField(
          key: const Key('StatusField'),
          state: TextFieldState(text: status.val),
          label: 'label_status'.l10n,
          copy: status.val,
        ),
      );
    });
  }

  /// Returns a [User.num] copyable field.
  Widget _num(UserController c, BuildContext context) {
    return _padding(
      CopyableTextField(
        key: const Key('UserNum'),
        state: TextFieldState(
          text: c.user!.user.value.num.val.replaceAllMapped(
            RegExp(r'.{4}'),
            (match) => '${match.group(0)} ',
          ),
        ),
        label: 'label_num'.l10n,
        copy: c.user?.user.value.num.val,
      ),
    );
  }

  /// Returns a [User.presence] text.
  Widget _presence(UserController c, BuildContext context) {
    return Obx(() {
      final Presence? presence = c.user?.user.value.presence;
      if (presence == null) {
        return Container();
      }

      final subtitle = c.user?.user.value.getStatus();

      return _padding(
        ReactiveTextField(
          key: const Key('Presence'),
          state: TextFieldState(text: subtitle),
          label: 'label_presence'.l10n,
          enabled: false,
          trailing: CircleAvatar(
            key: Key(presence.name.capitalizeFirst!),
            backgroundColor: presence.getColor(),
            radius: 7,
          ),
        ),
      );
    });
  }

  /// Returns the blacklisted information of this [User].
  Widget _blocked(UserController c, BuildContext context) {
    return Column(
      children: [
        if (c.isBlacklisted?.at != null)
          _padding(
            ReactiveTextField(
              state: TextFieldState(text: c.isBlacklisted!.at.toString()),
              label: 'label_date'.l10n,
              enabled: false,
            ),
          ),
        if (c.isBlacklisted?.reason != null)
          _padding(
            ReactiveTextField(
              state: TextFieldState(text: c.isBlacklisted!.reason?.val),
              label: 'label_reason'.l10n,
              enabled: false,
            ),
          ),
      ],
    );
  }

  /// Returns a [WidgetButton] for removing the [User] from the blacklist.
  Widget _blockedField(BuildContext context, UserController c) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Theme(
      data: MessageFieldView.theme(context),
      child: SafeArea(
        child: Container(
          key: const Key('BlockedField'),
          decoration: BoxDecoration(
            borderRadius: style.cardRadius,
            boxShadow: [
              CustomBoxShadow(
                blurRadius: 8,
                color: style.colors.onBackgroundOpacity13,
              ),
            ],
          ),
          child: ConditionalBackdropFilter(
            condition: style.cardBlur > 0,
            filter: ImageFilter.blur(
              sigmaX: style.cardBlur,
              sigmaY: style.cardBlur,
            ),
            borderRadius: style.cardRadius,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              decoration: BoxDecoration(color: style.cardColor),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 5 + (PlatformUtils.isMobile ? 0 : 8),
                        bottom: 13,
                      ),
                      child: Transform.translate(
                        offset: Offset(0, PlatformUtils.isMobile ? 6 : 1),
                        child: WidgetButton(
                          onPressed: c.unblacklist,
                          child: IgnorePointer(
                            child: ReactiveTextField(
                              enabled: false,
                              key: const Key('MessageField'),
                              state: TextFieldState(text: 'btn_unblock'.l10n),
                              filled: false,
                              dense: true,
                              textAlign: TextAlign.center,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              style: style.boldBody.copyWith(
                                fontSize: 17,
                                color: style.colors.primary,
                              ),
                              type: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Opens a confirmation popup deleting the [User] from address book.
  Future<void> _removeFromContacts(
    UserController c,
    BuildContext context,
  ) async {
    final Style style = Theme.of(context).extension<Style>()!;

    final bool? result = await MessagePopup.alert(
      'label_delete_contact'.l10n,
      description: [
        TextSpan(text: 'alert_contact_will_be_removed1'.l10n),
        TextSpan(
          text: c.user?.user.value.name?.val ?? c.user?.user.value.num.val,
          style: TextStyle(color: style.colors.onBackground),
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
    final Style style = Theme.of(context).extension<Style>()!;

    final bool? result = await MessagePopup.alert(
      'label_hide_chat'.l10n,
      description: [
        TextSpan(text: 'alert_dialog_will_be_hidden1'.l10n),
        TextSpan(
          text: c.user?.user.value.name?.val ?? c.user?.user.value.num.val,
          style: TextStyle(color: style.colors.onBackground),
        ),
        TextSpan(text: 'alert_dialog_will_be_hidden2'.l10n),
      ],
    );

    if (result == true) {
      await c.hideChat();
    }
  }

  /// Opens a confirmation popup clearing the [Chat]-dialog with the [User].
  Future<void> _clearChat(UserController c, BuildContext context) async {
    final Style style = Theme.of(context).extension<Style>()!;

    final bool? result = await MessagePopup.alert(
      'label_clear_history'.l10n,
      description: [
        TextSpan(text: 'alert_dialog_will_be_cleared1'.l10n),
        TextSpan(
          text: c.user?.user.value.name?.val ?? c.user?.user.value.num.val,
          style: TextStyle(color: style.colors.onBackground),
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
    final Style style = Theme.of(context).extension<Style>()!;

    final bool? result = await MessagePopup.alert(
      'label_block'.l10n,
      description: [
        TextSpan(text: 'alert_user_will_be_blocked1'.l10n),
        TextSpan(
          text: c.user?.user.value.name?.val ?? c.user?.user.value.num.val,
          style: TextStyle(color: style.colors.onBackground),
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
