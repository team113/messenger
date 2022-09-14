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
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/page/my_profile/controller.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/gallery.dart';
import '/util/message_popup.dart';
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
              body: LayoutBuilder(builder: (context, constraints) {
                print(constraints);
                return CustomScrollView(
                  key: const Key('UserColumn'),
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // App bar with gallery.
                    SliverAppBar(
                      elevation: 0,
                      pinned: true,
                      stretch: true,
                      backgroundColor: context.theme.scaffoldBackgroundColor,
                      leading: IconButton(
                        onPressed: router.pop,
                        icon: const Icon(Icons.arrow_back),
                      ),
                      expandedHeight: MediaQuery.of(context).size.height * 0.6,
                      flexibleSpace: FlexibleSpaceBar(background: _gallery(c)),
                    ),

                    // Main content of this page.
                    // context.isNarrow
                    (constraints.maxWidth < 450 || context.isNarrow)
                        ? _mobile(context, c)
                        : _desktop(context, c),
                  ],
                );
              }),
            );
          } else if (c.status.value.isEmpty) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(child: Text('err_unknown_user'.l10n)),
            );
          } else {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
        });
      },
    );

    return GetBuilder(
      init: UserController(id, Get.find(), Get.find(), Get.find(), Get.find()),
      tag: id.val,
      builder: (UserController c) {
        return Obx(() {
          if (c.status.value.isSuccess) {
            return Scaffold(
              body: CustomScrollView(
                key: const Key('UserColumn'),
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App bar with gallery.
                  SliverAppBar(
                    elevation: 0,
                    pinned: true,
                    stretch: true,
                    backgroundColor: context.theme.scaffoldBackgroundColor,
                    leading: IconButton(
                      onPressed: router.pop,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    expandedHeight: MediaQuery.of(context).size.height * 0.6,
                    flexibleSpace: FlexibleSpaceBar(background: _gallery(c)),
                  ),

                  // Main content of this page.
                  SliverList(
                    delegate: SliverChildListDelegate.fixed(
                      [
                        Align(
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 450),
                            child: Column(
                              children: [
                                const SizedBox(height: 10),
                                _name(c, context),
                                if (c.user?.user.value.bio != null)
                                  _bio(c, context),
                                const Divider(thickness: 2),
                                _presence(c, context),
                                _num(c, context),
                                if (id != c.me) ...[
                                  const Divider(thickness: 2),
                                  _audioCall(c, context),
                                  _videoCall(c, context),
                                  const Divider(thickness: 2),
                                  _dialog(c, context),
                                  _contacts(c, context),
                                  const Divider(thickness: 2),
                                  _blacklist(c, context),
                                ],
                                const SizedBox(height: 20),
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
              appBar: AppBar(),
              body: Center(child: Text('err_unknown_user'.l10n)),
            );
          } else {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
        });
      },
    );
  }

  SliverList _mobile(BuildContext context, UserController c) {
    Style style = Theme.of(context).extension<Style>()!;
    return SliverList(
      delegate: SliverChildListDelegate.fixed(
        [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    ContactTile(
                      user: c.user,
                      darken: 0,
                      subtitle: [
                        const SizedBox(height: 5),
                        Obx(() {
                          final subtitle = c.user?.user.value.getStatus();
                          if (subtitle != null) {
                            return Text(
                              subtitle,
                              style: const TextStyle(
                                color: Color(0xFF888888),
                              ),
                            );
                          }

                          return Container();
                        }),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: style.cardRadius,
                        border: style.cardBorder,
                        color: style.cardColor,
                      ),
                      height: 55,
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(12 * 1.5, 8, 12 * 1.5, 8),
                        child: Row(
                          children: [
                            Center(
                              child: WidgetButton(
                                onPressed: () => c.call(false),
                                child: SvgLoader.asset(
                                  'assets/icons/chat_video_call.svg',
                                  height: 17,
                                ),
                              ),
                            ),
                            Center(
                              child: WidgetButton(
                                onPressed: () => c.call(true),
                                child: SvgLoader.asset(
                                  'assets/icons/chat_audio_call.svg',
                                  height: 19,
                                ),
                              ),
                            ),
                            Center(
                              child: WidgetButton(
                                onPressed: c.openChat,
                                child: SvgLoader.asset(
                                  'assets/icons/chat.svg',
                                  width: 21.13,
                                  height: 22.62,
                                ),
                              ),
                            ),
                            Center(
                              child: WidgetButton(
                                onPressed: c.inContacts.value
                                    ? c.removeFromContacts
                                    : c.addToContacts,
                                child: c.inContacts.value
                                    ? Transform.translate(
                                        offset: const Offset(0, 1),
                                        child: SvgLoader.asset(
                                          'assets/icons/contact_remove.svg',
                                          width: 25.4,
                                          height: 22.77,
                                        ),
                                      )
                                    : Transform.translate(
                                        offset: const Offset(0, 1),
                                        child: SvgLoader.asset(
                                          'assets/icons/contact_add.svg',
                                          width: 25.4,
                                          height: 22.77,
                                        ),
                                      ),
                              ),
                            ),
                          ].map((e) => Expanded(child: e)).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverList _desktop(BuildContext context, UserController c) {
    Style style = Theme.of(context).extension<Style>()!;
    return SliverList(
      delegate: SliverChildListDelegate.fixed(
        [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: style.cardRadius,
                    border: style.cardBorder,
                    color: style.cardColor,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        AvatarWidget.fromRxUser(c.user, radius: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                c.user?.user.value.name?.val ??
                                    c.user?.user.value.num.val ??
                                    '...',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: Theme.of(context).textTheme.headline5,
                              ),
                              const SizedBox(height: 3),
                              Obx(() {
                                final subtitle = c.user?.user.value.getStatus();
                                if (subtitle != null) {
                                  return Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF888888),
                                    ),
                                  );
                                }

                                return Container();
                              }),
                            ],
                          ),
                        ),
                        WidgetButton(
                          onPressed: () => c.call(true),
                          child: SvgLoader.asset(
                            'assets/icons/chat_video_call.svg',
                            height: 17,
                          ),
                        ),
                        const SizedBox(width: 28),
                        WidgetButton(
                          onPressed: () => c.call(false),
                          child: SvgLoader.asset(
                            'assets/icons/chat_audio_call.svg',
                            height: 19,
                          ),
                        ),
                        const SizedBox(width: 28),
                        WidgetButton(
                          onPressed: c.openChat,
                          child: SvgLoader.asset(
                            'assets/icons/chat.svg',
                            width: 21.13,
                            height: 22.62,
                          ),
                        ),
                        const SizedBox(width: 28),
                        WidgetButton(
                          onPressed: c.inContacts.value
                              ? c.removeFromContacts
                              : c.addToContacts,
                          child: c.inContacts.value
                              ? Transform.translate(
                                  offset: const Offset(0, 1),
                                  child: SvgLoader.asset(
                                    'assets/icons/contact_remove.svg',
                                    width: 25.4,
                                    height: 22.77,
                                  ),
                                )
                              : Transform.translate(
                                  offset: const Offset(0, 1),
                                  child: SvgLoader.asset(
                                    'assets/icons/contact_add.svg',
                                    width: 25.4,
                                    height: 22.77,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
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
  }

  /// Basic [Padding] wrapper.
  Widget _padding(Widget child) =>
      Padding(padding: const EdgeInsets.all(8), child: child);

  /// Returns a [CarouselGallery] of the [User.gallery].
  Widget _gallery(UserController c) => Obx(
        () => CarouselGallery(
          items: c.user?.user.value.gallery,
          index: c.galleryIndex.value,
          onChanged: (i) => c.galleryIndex.value = i,
        ),
      );

  /// Returns a [User.name] text widget with an [AvatarWidget].
  Widget _name(UserController c, BuildContext context) => _padding(
        Row(
          key: const Key('UserName'),
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarWidget.fromUser(c.user?.user.value, radius: 29),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SelectableText(
                    '${c.user?.user.value.name?.val ?? c.user?.user.value.num.val}',
                    style: const TextStyle(fontSize: 24),
                  ),
                  _onlineStatus(c),
                ],
              ),
            )
          ],
        ),
      );

  /// Returns an online status subtitle of the [User] this [UserView] is about.
  Widget _onlineStatus(UserController c) {
    final subtitle = c.user?.user.value.getStatus();
    if (subtitle != null) {
      return Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF888888)),
      );
    }
    return Container();
  }

  /// Returns a [User.bio] text.
  Widget _bio(UserController c, BuildContext context) => Obx(() {
        return ListTile(
          key: const Key('UserBio'),
          leading: _centered(const Icon(Icons.article)),
          title: SelectableText(
            '${c.user?.user.value.bio?.val}',
            style: const TextStyle(fontSize: 17),
          ),
          subtitle: Text(
            'label_biography'.l10n,
            style: const TextStyle(color: Color(0xFF888888)),
          ),
        );
      });

  /// Returns a [User.num] copyable field.
  Widget _num(UserController c, BuildContext context) => ListTile(
        key: const Key('UserNum'),
        leading: _centered(const Icon(Icons.fingerprint)),
        title: Text(
          c.user!.user.value.num.val.replaceAllMapped(
            RegExp(r'.{4}'),
            (match) => '${match.group(0)} ',
          ),
        ),
        subtitle: Text(
          'label_num'.l10n,
          style: const TextStyle(color: Color(0xFF888888)),
        ),
        trailing: _centered(const Icon(Icons.copy)),
        onTap: () => _copy(c.user!.user.value.num.val),
      );

  /// Returns a [User.presence] text.
  Widget _presence(UserController c, BuildContext context) => ListTile(
        key: const Key('UserPresence'),
        leading: _centered(const Icon(Icons.info)),
        title: Text(Presence.values
            .firstWhere((e) => e.index == c.user?.user.value.presenceIndex)
            .localizedString()
            .toString()),
        subtitle: Text(
          'label_presence'.l10n,
          style: const TextStyle(color: Color(0xFF888888)),
        ),
      );

  /// Returns a contact-related button adding or removing the [User] from the
  /// contacts list of the authenticated [MyUser].
  Widget _contacts(UserController c, BuildContext context) => Obx(
        () => ListTile(
          key: c.inContacts.value
              ? const Key('DeleteFromContactsButton')
              : const Key('AddToContactsButton'),
          leading: _centered(c.inContacts.value
              ? const Icon(Icons.delete)
              : const Icon(Icons.person_add)),
          title: Text(c.inContacts.value
              ? 'btn_delete_from_contacts'.l10n
              : 'btn_add_to_contacts'.l10n),
          onTap: c.status.value.isLoadingMore
              ? null
              : c.inContacts.value
                  ? c.removeFromContacts
                  : c.addToContacts,
        ),
      );

  /// Returns a [Chat]-dialog button opening the [User.dialog].
  Widget _dialog(UserController c, BuildContext context) => ListTile(
        leading: _centered(const Icon(Icons.chat)),
        title: Text('btn_write_message'.l10n),
        onTap: c.openChat,
      );

  /// Returns a button making an audio call with the [User].
  Widget _audioCall(UserController c, BuildContext context) => ListTile(
        leading: _centered(const Icon(Icons.call)),
        title: Text('btn_audio_call'.l10n),
        onTap: () => c.call(false),
      );

  /// Returns a button making a video call with the [User].
  Widget _videoCall(UserController c, BuildContext context) => ListTile(
        leading: _centered(const Icon(Icons.video_call)),
        title: Text('btn_video_call'.l10n),
        onTap: () => c.call(true),
      );

  /// Returns a button blacklisting the [User] .
  Widget _blacklist(UserController c, BuildContext context) => ListTile(
        leading: _centered(const Icon(Icons.block)),
        title: Text('btn_blacklist'.l10n),
        onTap: () => throw UnimplementedError(),
      );

  /// Puts a [copy] of data into the clipboard and shows a snackbar.
  void _copy(String copy) {
    Clipboard.setData(ClipboardData(text: copy));
    MessagePopup.success('label_copied_to_clipboard'.l10n);
  }

  /// Returns the vertically centered [widget].
  Widget _centered(Widget widget) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [widget],
      );
}
