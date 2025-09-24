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
      barrierColor: style.barrierColor,
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
                sigmaX: animation.value * 7,
                sigmaY: animation.value * 7,
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
                  child: _buildModalWidget(context, c),
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

  // Builds general modal widget
  Widget _buildModalWidget(BuildContext context, AccountsSwitcherController c) {
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
            dense: true,
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
              radius: AvatarRadius.medium,
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
              const SizedBox(height: 5),
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
      ),
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          PrimaryButton(
            onPressed: () async {
              await LoginView.show(
                context,
                initial: LoginViewStage.signUpOrSignIn,
              );
            },
            leading: SvgIcon(SvgIcons.logoutWhite),
            title: 'btn_add_account'.l10n,
          ),
          ...children,
          SizedBox(height: 2),
          Container(
            decoration: BoxDecoration(
              border: style.cardBorder,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top:
                      -(style.fonts.small.regular.secondary.height ?? 1.3) *
                      (style.fonts.small.regular.secondary.fontSize ?? 11) /
                      2,
                  child: Align(
                    alignment: Alignment.center,
                    child: Stack(
                      fit: StackFit.loose,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Align(
                            widthFactor: 1,
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(color: Colors.white),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'current_account'.l10n,
                            textAlign: TextAlign.center,
                            style: style.fonts.small.regular.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      SizedBox(height: 2),
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
                                  style:
                                      style.fonts.medium.regular.onBackground,
                                );
                              }),
                              Obx(() {
                                final presence = c.myUser.value?.presence;

                                return Text.rich(
                                  TextSpan(
                                    text: switch (presence) {
                                      Presence.present =>
                                        'label_presence_present'.l10n,
                                      Presence.away =>
                                        'label_presence_away'.l10n,
                                      (_) => '',
                                    },
                                    style: style.fonts.small.regular.secondary,
                                    children: [
                                      TextSpan(text: ' | '),
                                      WidgetSpan(
                                        alignment:
                                            ui.PlaceholderAlignment.middle,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          onTap: c.togglePresence,
                                          child: Ink(
                                            child: Text(
                                              'btn_change'.l10n,
                                              style: style
                                                  .fonts
                                                  .small
                                                  .regular
                                                  .primary,
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
                      SizedBox(height: 4),
                      ReactiveTextField(
                        key: Key('TextStatusField'),
                        state: c.status,
                        hint: 'label_text_status_description_switcher'.l10n,
                        decoration: InputDecoration(
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        dense: true,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        maxLines: 1,
                        formatters: [LengthLimitingTextInputFormatter(25)],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
