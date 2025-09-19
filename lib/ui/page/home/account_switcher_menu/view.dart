import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../api/backend/schema.graphql.dart';
import '../../../../domain/model/my_user.dart';
import '../../../../l10n/l10n.dart';
import '../../../../themes.dart';
import '../../../widget/animated_button.dart';
import '../../../widget/primary_button.dart';
import '../../../widget/svg/svg.dart';

import '../../../widget/text_field.dart';
import '../../auth/account_is_not_accessible/view.dart';
import '../../login/controller.dart';
import '../../login/view.dart';
import '../page/my_profile/presence_switch/view.dart';

import '../tab/chats/widget/unread_counter.dart';
import '../widget/avatar.dart';
import '../widget/contact_tile.dart';
import 'controller.dart';

class AccountSwithcerMenuView extends StatefulWidget {
  const AccountSwithcerMenuView({super.key, required this.child});

  /// widget that viewed in layout
  final Widget child;

  @override
  State<AccountSwithcerMenuView> createState() =>
      _AccountSwithcerMenuViewState();
}

class _AccountSwithcerMenuViewState extends State<AccountSwithcerMenuView> {
  late final OverlayPortalController _controller;

  @override
  initState() {
    _controller = OverlayPortalController();
    super.initState();
  }

  void _show() {
    _controller.show();
  }

  final GlobalKey _portalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    print(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final render =
            _portalKey.currentContext?.findRenderObject() as RenderBox;

        final portalOffset = render.localToGlobal(Offset.zero);

        final portalSize = render.size;

        print([portalSize, portalOffset]);
      });
    }());
    return OverlayPortal(
      key: _portalKey,
      controller: _controller,
      overlayChildBuilder: _buildOverlay,
      child: GestureDetector(
        onLongPress: _show,
        onSecondaryTap: _show,
        child: widget.child,
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final render = _portalKey.currentContext?.findRenderObject() as RenderBox;

    final portalOffset = render.localToGlobal(Offset.zero);

    final portalSize = render.size;

    var style = Theme.of(context).style;
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _controller.hide();
          },
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withValues(
                    alpha: 0.1,
                  ), // Semi-transparent overlay
                ),
              ),

              Positioned(
                // TODO: so bad
                left:
                    portalOffset.dx -
                    (AnimatedButton.scale - 1) *
                        AvatarRadius.large.toDouble() *
                        2,
                top:
                    portalOffset.dy -
                    (AnimatedButton.scale - 1) *
                        AvatarRadius.large.toDouble() *
                        2,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: widget.child,
                ),
              ),
              Positioned(
                bottom: constraints.maxHeight - portalOffset.dy + 12,
                right:
                    constraints.maxWidth -
                    portalOffset.dx -
                    portalSize.width -
                    2,
                left: math.max(math.min(12, constraints.maxWidth - 500), 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: math.min(MediaQuery.sizeOf(context).width, 320),
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.deferToChild,
                    // must be empty for cancel propagation click event
                    onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        color: style.colors.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [AccountSwitcherMenuWidget()],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AccountSwitcherMenuWidget extends StatelessWidget {
  const AccountSwitcherMenuWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: AccountSwitcherMenuController(Get.find(), Get.find()),
      builder: (AccountSwitcherMenuController c) {
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
                key: Key('Account_${e.value.id}'),
                myUser: myUser,
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
                            await AccountIsNotAccessibleView.show(
                              context,
                              myUser,
                            );
                          }
                        } else {
                          Navigator.of(context).pop();
                          await c.switchTo(myUser.id);
                        }
                      },

                // TODO: Remove, when [MyUser]s will receive their
                //       updates in real-time.
                avatarBuilder: (_) => AvatarWidget.fromMyUser(
                  myUser,
                  radius: AvatarRadius.large,
                  badge: active,
                ),

                trailing: [
                  if (myUser.unreadChatsCount > 0)
                    KeyedSubtree(
                      key: myUser.muted != null
                          ? Key('AccountMuteIndicator_${myUser.id}')
                          : null,
                      child: UnreadCounter(
                        key: const Key('UnreadMessages'),
                        myUser.unreadChatsCount + 99,
                        dimmed: myUser.muted != null,
                      ),
                    ),
                  // AnimatedButton(
                  //   key: const Key('RemoveAccount'),
                  //   decorator: (child) => Padding(
                  //     padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
                  //     child: child,
                  //   ),
                  //   onPressed: () async {
                  //     final bool hasPassword = myUser.hasPassword;
                  //     final bool canRecover =
                  //         myUser.emails.confirmed.isNotEmpty ||
                  //         myUser.phones.confirmed.isNotEmpty;

                  //     final bool? result = await MessagePopup.alert(
                  //       'btn_remove_account'.l10n,
                  //       additional: [
                  //         Center(
                  //           child: Text(
                  //             '${myUser.name ?? myUser.num}',
                  //             style: style.fonts.normal.regular.onBackground,
                  //           ),
                  //         ),

                  //         if (!hasPassword || !canRecover)
                  //           const SizedBox(height: 16),

                  //         if (!hasPassword)
                  //           RichText(
                  //             text: TextSpan(
                  //               style: style.fonts.small.regular.secondary,
                  //               children: [
                  //                 TextSpan(
                  //                   text: 'label_password_not_set1'.l10n,
                  //                   style:
                  //                       style.fonts.small.regular.onBackground,
                  //                 ),
                  //                 TextSpan(
                  //                   text: 'label_password_not_set2'.l10n,
                  //                 ),
                  //               ],
                  //             ),
                  //           ),

                  //         if (!hasPassword && !canRecover)
                  //           const SizedBox(height: 16),

                  //         if (!canRecover) ...[
                  //           RichText(
                  //             text: TextSpan(
                  //               style: style.fonts.small.regular.secondary,
                  //               children: [
                  //                 TextSpan(
                  //                   text: 'label_email_or_phone_not_set1'.l10n,
                  //                 ),
                  //                 TextSpan(
                  //                   text: 'label_email_or_phone_not_set2'.l10n,
                  //                   style:
                  //                       style.fonts.small.regular.onBackground,
                  //                 ),
                  //               ],
                  //             ),
                  //           ),
                  //         ],
                  //       ],
                  //       button: (context) => MessagePopup.deleteButton(
                  //         context,
                  //         label: 'btn_remove_account'.l10n,
                  //         icon: SvgIcons.removeFromCallWhite,
                  //       ),
                  //     );

                  //     if (result == true) {
                  //       await c.deleteAccount(myUser.id);
                  //     }
                  //   },
                  //   child: active
                  //       ? const SvgIcon(SvgIcons.logoutWhite)
                  //       : const SvgIcon(SvgIcons.logout),
                  // ),
                ],
                selected: active,
                subtitle: [
                  const SizedBox(height: 5),
                  if (expired)
                    Text(
                      'label_sign_in_required'.l10n,
                      style: style.fonts.small.regular.danger,
                    )
                  else
                    Text(
                      'label_signed_in'.l10n,
                      style: style.fonts.small.regular.secondary,
                    ),
                ],
              );
            }),
          );
        }
        return Column(
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
            SizedBox.shrink(),
            Container(
              decoration: BoxDecoration(
                border: style.cardBorder,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  Text('Current Account'),
                  ContactTile(
                    avatarBuilder: (context) => AvatarWidget.fromMyUser(
                      c.accounts
                          .firstWhere((user) => user.value.id == c.me)
                          .value,
                    ),
                    myUser: c.accounts
                        .firstWhere((user) => user.value.id == c.me)
                        .value,
                    subtitle: [
                      Row(
                        children: [
                          Text(switch (c.accounts
                              .firstWhere((user) => user.value.id == c.me)
                              .value
                              .presence) {
                            Presence.present => 'label_presence_present'.l10n,
                            Presence.away => 'label_presence_away'.l10n,
                            (_) => '',
                          }, style: style.fonts.small.regular.secondary),
                          Text(
                            ' |',
                            style: style.fonts.small.regular.secondary,
                          ),
                          TextButton(
                            onPressed: () async {
                              await PresenceSwitchView.show(context);
                            },
                            child: Text(
                              'btn_change'.l10n,
                              style: style.fonts.small.regular.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ReactiveTextField(
                    key: Key('TextStatusField'),
                    state: c.status,
                    label: 'label_text_status'.l10n,
                    hint: 'label_text_status_description'.l10n,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    maxLines: 1,
                    formatters: [LengthLimitingTextInputFormatter(4096)],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
