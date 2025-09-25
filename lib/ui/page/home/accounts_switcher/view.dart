// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../tab/menu/accounts/controller.dart';
import '../tab/menu/accounts/view.dart';
import '/api/backend/schema.graphql.dart';
import '/domain/model/my_user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/auth/account_is_not_accessible/view.dart';
import '/ui/page/home/widget/navigation_bar.dart';
import '/ui/page/home/tab/chats/widget/unread_counter.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/page/login/controller.dart';
import '/ui/page/login/view.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/global_key.dart';
import 'controller.dart';

/// View for switching between known [MyUser] profiles.
///
/// Intended to be displayed with the [show] method.
class AccountsSwitcherView extends StatelessWidget {
  const AccountsSwitcherView({super.key, required this.avatarKey});

  final GlobalKey avatarKey;

  /// Pushes an [AccountsSwitcherView] via router.
  static Future<T?> show<T>(
    BuildContext context, {
    required GlobalKey avatarKey,
  }) async {
    final style = Theme.of(context).style;

    final route = RawDialogRoute<T>(
      // TODO: может нужно вынести в тему ?
      barrierColor: style.barrierColor.withValues(alpha: .1),
      barrierDismissible: true,
      pageBuilder: (_, _, _) {
        final Widget body = AccountsSwitcherView(avatarKey: avatarKey);
        return body;
      },
      fullscreenDialog: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, Animation<double> animation, _, Widget child) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: animation.value * 10,
                sigmaY: animation.value * 10,
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: child,
        );
      },
    );

    router.obscuring.add(route);

    try {
      return await Navigator.of(context, rootNavigator: true).push<T>(route);
    } finally {
      router.obscuring.remove(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: AccountsSwitcherController(Get.find(), Get.find()),
      builder: (AccountsSwitcherController c) {
        return LayoutBuilder(
          builder: (context, constraints) {
            Rect bounds;
            // hack for preventing error when element inactive
            try {
              bounds = avatarKey.globalPaintBounds ?? Rect.zero;
            } catch (_) {
              bounds = Rect.zero;
            }

            return Stack(
              children: [
                WidgetButton(
                  onPressed: Navigator.of(context).pop,
                  child: SizedBox.expand(),
                ),
                Positioned(
                  bottom: CustomNavigationBar.height + 12,
                  right: constraints.maxWidth - bounds.right - 4,
                  left: 12,
                  child: _buildModal(context, c),
                ),
                Positioned(
                  left: bounds.left - 4,
                  top: bounds.top - 4,
                  width: bounds.width + 8,
                  height: bounds.height + 8,
                  child: Obx(() {
                    return GestureDetector(
                      onTap: Navigator.of(context).pop,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: AvatarWidget.fromMyUser(
                          c.myUser.value,
                          radius: AvatarRadius.normal,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Builds general modal widget.
  Widget _buildModal(BuildContext context, AccountsSwitcherController c) {
    final List<Widget> children = [];
    var style = Theme.of(context).style;

    for (final e in c.accounts) {
      // skip current account
      if (e.value.id == c.me) continue;

      children.add(
        Obx(() {
          final MyUser myUser = e.value;
          final bool expired = !c.sessions.containsKey(myUser.id);

          final bool active = c.me == myUser.id;

          return ContactTile(
            margin: EdgeInsets.zero,
            key: Key('Account_${e.value.id}'),
            myUser: myUser,
            height: 48,
            radius: AvatarRadius.normal,
            onTap: active
                ? null
                : () async {
                    if (expired) {
                      final hasPasswordOrEmail =
                          myUser.hasPassword ||
                          myUser.emails.confirmed.isNotEmpty ||
                          myUser.phones.confirmed.isNotEmpty;

                      if (hasPasswordOrEmail) {
                        await LoginView.show(
                          context,
                          initial: LoginViewStage.signIn,
                          myUser: myUser,
                        );
                      } else {
                        await AccountIsNotAccessibleView.show(context, myUser);
                      }
                    } else {
                      Navigator.of(context).pop();
                      await c.switchTo(myUser.id);
                    }
                  },
            avatarBuilder: (_) => AvatarWidget.fromMyUser(
              myUser,
              radius: AvatarRadius.normal,
              badge: active,
            ),
            trailing: [
              if (myUser.unreadChatsCount > 0)
                KeyedSubtree(
                  key: Key('AccountMuteIndicator_${myUser.id}'),
                  child: UnreadCounter(
                    key: const Key('UnreadMessages'),
                    myUser.unreadChatsCount,
                    dimmed: myUser.muted != null,
                  ),
                ),
            ],
            selected: active,
            subtitle: [
              if (expired)
                Text(
                  'label_sign_in_required'.l10n,
                  style: style.fonts.small.regular.danger,
                ),
            ],
          );
        }),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: style.colors.background,
        borderRadius: BorderRadius.circular(16),
        // TODO: need shadows
        boxShadow: [],
      ),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          PrimaryButton(
            onPressed: () async {
              await AccountsView.show(context, initial: AccountsViewStage.add);
            },
            leading: SvgIcon(SvgIcons.logoutWhite),
            title: 'btn_add_account'.l10n,
          ),
          ...children,
          SizedBox(height: 2),
          InputDecorator(
            decoration: InputDecoration(
              floatingLabelAlignment: FloatingLabelAlignment.center,
              label: Text(
                'label_current_account'.l10n,
                textAlign: TextAlign.center,
                style: style.fonts.medium.regular.secondary,
              ),
              contentPadding: EdgeInsets.all(12).copyWith(top: 14),
              filled: true,
              fillColor: Colors.white,
              // border: style.cardBorder,
            ),
            child: Column(
              children: [
                Row(
                  spacing: 12,
                  children: [
                    Obx(() {
                      return AvatarWidget.fromMyUser(
                        c.myUser.value,
                        radius: AvatarRadius.medium,
                      );
                    }),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() {
                          return Text(
                            c.myUser.value?.name?.val ?? 'dot'.l10n,
                            style: style.fonts.medium.regular.onBackground,
                          );
                        }),
                        Obx(() {
                          final presence = c.myUser.value?.presence;

                          return Text.rich(
                            TextSpan(
                              text: switch (presence) {
                                Presence.present =>
                                  'label_presence_present'.l10n,
                                Presence.away => 'label_presence_away'.l10n,
                                (_) => '',
                              },
                              style: style.fonts.small.regular.secondary,
                              children: [
                                TextSpan(text: 'space_vertical_space'.l10n),
                                WidgetSpan(
                                  alignment: ui.PlaceholderAlignment.middle,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: c.togglePresence,
                                    child: Ink(
                                      child: Text(
                                        'btn_change'.l10n,
                                        style:
                                            style.fonts.small.regular.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Divider(color: style.colors.secondaryHighlightDark, height: 1),
                SizedBox(height: 4),
                Theme(
                  data: _textStatusFieldTheme(context),
                  child: ReactiveTextField(
                    key: Key('TextStatusField'),
                    state: c.status,
                    hint: 'label_text_status_description_switcher'.l10n,
                    dense: true,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    maxLines: 1,
                    formatters: [LengthLimitingTextInputFormatter(25)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a [ThemeData] to decorate a [ReactiveTextField] with.
  ///
  /// Used for TextStatusField.
  ThemeData _textStatusFieldTheme(BuildContext context) {
    final style = Theme.of(context).style;

    final OutlineInputBorder border = OutlineInputBorder(
      borderSide: BorderSide.none,
    );

    return Theme.of(context).copyWith(
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
        border: border,
        errorBorder: border,
        enabledBorder: border,
        focusedBorder: border,
        disabledBorder: border,
        focusedErrorBorder: border,
        focusColor: style.colors.onPrimary,
        fillColor: style.colors.onPrimary,
        hoverColor: style.colors.transparent,
        filled: true,
        isDense: true,
        contentPadding: EdgeInsets.fromLTRB(0, 4, 0, 4),
      ),
    );
  }
}
