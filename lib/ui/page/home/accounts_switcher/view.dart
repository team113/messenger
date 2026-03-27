// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import '/api/backend/schema.graphql.dart';
import '/domain/model/my_user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/auth/account_is_not_accessible/view.dart';
import '/ui/page/home/tab/chats/widget/unread_counter.dart';
import '/ui/page/home/tab/menu/accounts/controller.dart';
import '/ui/page/home/tab/menu/accounts/view.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/page/login/controller.dart';
import '/ui/page/login/view.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/global_key.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View for switching between known [MyUser] profiles.
///
/// Intended to be displayed with the [show] method.
class AccountsSwitcherView extends StatelessWidget {
  const AccountsSwitcherView({
    super.key,
    required this.avatarKey,
    required this.panelKey,
  });

  /// [GlobalKey] to position an [AvatarWidget.fromMyUser] around.
  final GlobalKey avatarKey;

  /// [GlobalKey] to position modal interface above.
  final GlobalKey panelKey;

  /// Displays an [AccountsSwitcherView] via separate [RawDialogRoute].
  static Future<T?> show<T>(
    BuildContext context, {
    required GlobalKey avatarKey,
    required GlobalKey panelKey,
  }) async {
    final style = Theme.of(context).style;

    final route = RawDialogRoute<T>(
      barrierColor: style.barrierColor.withValues(alpha: .1),
      barrierDismissible: true,
      pageBuilder: (_, _, _) =>
          AccountsSwitcherView(avatarKey: avatarKey, panelKey: panelKey),
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
    final style = Theme.of(context).style;

    return GetBuilder(
      init: AccountsSwitcherController(Get.find(), Get.find()),
      builder: (AccountsSwitcherController c) {
        return LayoutBuilder(
          builder: (context, constraints) {
            Rect avatar;
            Rect panel;

            try {
              avatar = avatarKey.globalPaintBounds ?? Rect.zero;
            } catch (_) {
              // Might happen when [avatarKey] isn't in the tree.
              avatar = Rect.zero;
            }

            try {
              panel = panelKey.globalPaintBounds ?? Rect.zero;
            } catch (_) {
              // Might happen when [panelKey] isn't in the tree.
              panel = Rect.zero;
            }

            return Stack(
              children: [
                GestureDetector(
                  onTap: Navigator.of(context).pop,
                  child: SizedBox.expand(),
                ),
                Positioned(
                  top: panel.top - 8,
                  width: panel.width - 16,
                  left: panel.left + 8,
                  height: constraints.maxHeight - panel.height - 16,
                  child: FractionalTranslation(
                    translation: Offset(0, -1),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _modal(context, c),
                    ),
                  ),
                ),
                Positioned(
                  left: avatar.left - 4,
                  top: avatar.top - 4,
                  width: avatar.width + 8,
                  height: avatar.height + 8,
                  child: Obx(() {
                    return GestureDetector(
                      onTap: Navigator.of(context).pop,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: style.colors.onPrimary,
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

  /// Builds general modal widget with accounts list and status changing.
  Widget _modal(BuildContext context, AccountsSwitcherController c) {
    final style = Theme.of(context).style;

    final List<Widget> children = [];

    for (final e in c.accounts) {
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

    final OutlineInputBorder border = OutlineInputBorder(
      borderSide: BorderSide.none,
    );

    final OutlineInputBorder outline = OutlineInputBorder(
      borderRadius: style.cardRadius,
      borderSide: BorderSide(
        color: style.colors.secondaryHighlightDarkest,
        width: 0.5,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: style.colors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          CustomBoxShadow(
            color: style.colors.onBackgroundOpacity20,
            blurRadius: 8,
            blurStyle: BlurStyle.outer,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Flexible(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              shrinkWrap: true,
              separatorBuilder: (context, i) => SizedBox(height: 8),
              itemCount: children.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return PrimaryButton(
                    onPressed: () async {
                      await AccountsView.show(
                        context,
                        initial: AccountsViewStage.add,
                      );
                    },
                    leading: SvgIcon(SvgIcons.logoutWhite),
                    title: 'btn_add_account'.l10n,
                  );
                }

                return children[i - 1];
              },
            ),
          ),
          SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: InputDecorator(
              decoration: InputDecoration(
                floatingLabelAlignment: FloatingLabelAlignment.center,
                label: Text(
                  'label_current_account'.l10n,
                  textAlign: TextAlign.center,
                  style: style.fonts.medium.regular.secondary,
                ),
                contentPadding: EdgeInsets.fromLTRB(
                  12,
                  14,
                  12,
                  PlatformUtils.isMobile ? 6 : 12,
                ),
                filled: true,
                fillColor: style.colors.onPrimary,
                border: outline,
                errorBorder: outline,
                enabledBorder: outline,
                focusedBorder: outline,
                disabledBorder: outline,
                focusedErrorBorder: outline,
              ),
              child: Column(
                children: [
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Obx(() {
                        return AvatarWidget.fromMyUser(
                          c.myUser.value,
                          radius: AvatarRadius.normal,
                        );
                      }),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() {
                            return Text(
                              c.myUser.value?.title ?? ('dot'.l10n * 3),
                              style: style.fonts.normal.regular.onBackground,
                            );
                          }),

                          Obx(() {
                            final presence = c.myUser.value?.presence;

                            return Text.rich(
                              TextSpan(
                                text: switch (presence) {
                                  UserPresence.present =>
                                    'label_presence_present'.l10n,
                                  UserPresence.away =>
                                    'label_presence_away'.l10n,
                                  (_) => 'label_offline'.l10n.capitalized,
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
                                          'btn_change_status'.l10n,
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
                  Divider(
                    color: style.colors.secondaryHighlightDark,
                    height: 1,
                  ),
                  SizedBox(height: 8),
                  Theme(
                    data: Theme.of(context).copyWith(
                      inputDecorationTheme: Theme.of(context)
                          .inputDecorationTheme
                          .copyWith(
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
                          ),
                    ),
                    child: ReactiveTextField(
                      key: Key('TextStatusField'),
                      state: c.status,
                      padding: PlatformUtils.isAndroid
                          ? EdgeInsets.fromLTRB(0, 8, 0, 0) // Android.
                          : PlatformUtils.isIOS
                          ? EdgeInsets.fromLTRB(0, 8, 0, 0) // iOS.
                          : EdgeInsets.fromLTRB(
                              0,
                              8,
                              0,
                              4,
                            ), // macOS, Linux, Windows.
                      hint: 'label_text_status_hint'.l10n,
                      dense: true,
                      style: style.fonts.small.regular.onBackground,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      maxLines: 1,
                      formatters: [LengthLimitingTextInputFormatter(33)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
