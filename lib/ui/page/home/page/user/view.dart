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
import 'package:get/get.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui//widget/svg/svg.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/my_profile/widget/copyable.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View of the [Routes.user] page.
class UserView extends StatelessWidget {
  const UserView(this.id, {Key? key}) : super(key: key);

  /// ID of the [User] this [UserView] represents.
  final UserId id;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: UserController(id, Get.find(), Get.find(), Get.find(), Get.find()),
      tag: id.val,
      builder: (UserController c) {
        return Obx(() {
          if (c.status.value.isSuccess) {
            return Scaffold(
              appBar: CustomAppBar(
                title: Row(
                  children: [
                    Material(
                      elevation: 6,
                      type: MaterialType.circle,
                      shadowColor: const Color(0x55000000),
                      color: Colors.white,
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
                          final subtitle = c.user?.user.value.getStatus();
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${c.user?.user.value.name?.val ?? c.user?.user.value.num.val}'),
                              if (subtitle != null)
                                Text(
                                  subtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
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
                      child: SvgLoader.asset(
                        'assets/icons/chat.svg',
                        width: 20.12,
                        height: 21.62,
                      ),
                    ),
                  ),
                  if (!context.isNarrow) ...[
                    const SizedBox(width: 28),
                    WidgetButton(
                      onPressed: () => c.call(true),
                      child: SvgLoader.asset(
                        'assets/icons/chat_video_call.svg',
                        height: 17,
                      ),
                    ),
                  ],
                  const SizedBox(width: 28),
                  WidgetButton(
                    onPressed: () => c.call(false),
                    child: SvgLoader.asset(
                      'assets/icons/chat_audio_call.svg',
                      height: 19,
                    ),
                  ),
                ],
              ),
              body: Obx(() {
                return ListView(
                  key: const Key('UserColumn'),
                  children: [
                    const SizedBox(height: 8),
                    Block(
                      title: 'label_public_information'.l10n,
                      children: [
                        AvatarWidget.fromRxUser(
                          c.user,
                          radius: 100,
                          showBadge: false,
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
                  ],
                );
              }),
            );
          }

          return Scaffold(
            appBar: const CustomAppBar(
              padding: EdgeInsets.only(left: 4, right: 20),
              leading: [StyledBackButton()],
            ),
            body: Center(
              child: c.status.value.isEmpty
                  ? Text('err_unknown_user'.l10n)
                  : const CircularProgressIndicator(),
            ),
          );
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
          WidgetButton(
            key: key,
            onPressed: onPressed,
            child: IgnorePointer(
              child: ReactiveTextField(
                state: TextFieldState(text: text ?? '', editable: false),
                trailing: trailing != null
                    ? Transform.translate(
                        offset: const Offset(0, -1),
                        child: Transform.scale(scale: 1.15, child: trailing),
                      )
                    : null,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          ),
        ),
      );
    }

    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          action(
            key: Key(c.inContacts.value
                ? 'DeleteFromContactsButton'
                : 'AddToContactsButton'),
            text: c.inContacts.value
                ? 'btn_delete_from_contacts'.l10n
                : 'btn_add_to_contacts'.l10n,
            onPressed: c.status.value.isLoadingMore
                ? null
                : c.inContacts.value
                    ? c.removeFromContacts
                    : c.addToContacts,
          ),
          action(
            text: c.inFavorites.value
                ? 'btn_delete_from_favorites'.l10n
                : 'btn_add_to_favorites'.l10n,
            onPressed: c.inFavorites,
          ),
          action(
            text:
                c.isMuted.value ? 'btn_unmute_chat'.l10n : 'btn_mute_chat'.l10n,
            trailing: c.isMuted.value
                ? SvgLoader.asset(
                    'assets/icons/btn_mute.svg',
                    width: 18.68,
                    height: 15,
                  )
                : SvgLoader.asset(
                    'assets/icons/btn_unmute.svg',
                    width: 17.86,
                    height: 15,
                  ),
            onPressed: c.isMuted.toggle,
          ),
          action(
            text: 'btn_hide_chat'.l10n,
            trailing: SvgLoader.asset('assets/icons/delete.svg', height: 14),
            onPressed: () {},
          ),
          action(
            text: 'btn_clear_chat'.l10n,
            trailing: SvgLoader.asset('assets/icons/delete.svg', height: 14),
            onPressed: () {},
          ),
          action(
            key: Key(c.isBlacklisted! ? 'Unblock' : 'Block'),
            text:
                c.isBlacklisted == true ? 'btn_unblock'.l10n : 'btn_block'.l10n,
            onPressed: c.isBlacklisted == true ? c.unblock : c.block,
          ),
          action(text: 'btn_report'.l10n, onPressed: () {}),
        ],
      );
    });
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

      if (presence == null || presence == Presence.hidden) {
        return Container();
      }

      final subtitle = c.user?.user.value.getStatus();

      final Color? color;

      switch (presence) {
        case Presence.present:
          color = Colors.green;
          break;

        case Presence.away:
          color = Colors.orange;
          break;

        case Presence.hidden:
          color = Colors.grey;
          break;

        case Presence.artemisUnknown:
          color = null;
          break;
      }

      return _padding(
        ReactiveTextField(
          key: const Key('Presence'),
          state: TextFieldState(text: subtitle),
          label: 'label_presence'.l10n,
          enabled: false,
          trailing: CircleAvatar(
            key: Key(presence.name.capitalizeFirst!),
            backgroundColor: color,
            radius: 7,
          ),
        ),
      );
    });
  }
}
