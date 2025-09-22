import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../api/backend/schema.graphql.dart';
import '../../../../domain/model/my_user.dart';
import '../../../../l10n/l10n.dart';
import '../../../../themes.dart';

import '../../../widget/primary_button.dart';
import '../../../widget/svg/svg.dart';

import '../../../widget/text_field.dart';
import '../../auth/account_is_not_accessible/view.dart';
import '../../login/controller.dart';
import '../../login/view.dart';

import '../tab/chats/widget/unread_counter.dart';
import '../widget/avatar.dart';
import '../widget/contact_tile.dart';
import 'controller.dart';

class AccountSwitcherMenuWidget extends StatefulWidget {
  const AccountSwitcherMenuWidget({super.key, required this.child});

  /// widget that viewed in layout
  final Widget child;

  @override
  State<AccountSwitcherMenuWidget> createState() =>
      _AccountSwitcherMenuWidgetState();
}

class _AccountSwitcherMenuWidgetState extends State<AccountSwitcherMenuWidget>
    with SingleTickerProviderStateMixin {
  late final OverlayPortalController _overlayController;

  late final AnimationController _animationController;

  @override
  initState() {
    _overlayController = OverlayPortalController();
    _animationController = AnimationController(
      duration: 150.milliseconds,
      vsync: this,
    );

    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();

    super.dispose();
  }

  void _show() {
    _overlayController.show();
    _animationController
      ..forward()
      ..animateTo(1);
  }

  void _animationStatus(AnimationStatus status) {
    if (!status.isForwardOrCompleted) return;
    _overlayController.hide();

    _animationController.removeStatusListener(_animationStatus);
  }

  void _hide() {
    _animationController
      ..animateTo(0)
      ..addStatusListener(_animationStatus);
  }

  final GlobalKey _portalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      key: _portalKey,
      controller: _overlayController,
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

    final portalCenter = portalSize.center(portalOffset);

    print([portalOffset, portalSize]);
    print(widget.child);
    var style = Theme.of(context).style;
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _hide,
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _animationController,
                    child: child!,
                  );
                },
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.1,
                    ), // Semi-transparent overlay
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  var bottom = (constraints.maxHeight - portalOffset.dy + 12);
                  return Positioned(
                    bottom: bottom,
                    right:
                        constraints.maxWidth -
                        portalOffset.dx -
                        portalSize.width -
                        2,
                    left: math.max(
                      math.min(12, constraints.maxWidth - 500),
                      12,
                    ),
                    child: FadeTransition(
                      opacity: _animationController,
                      child: child!,
                    ),
                  );
                },

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
                        children: [AccountSwitcherMenuView()],
                      ),
                    ),
                  ),
                ),
              ),

              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Positioned.fromRect(
                    rect: Rect.fromCircle(
                      center: portalCenter,
                      radius: portalSize.width / 2 + 4,
                    ),
                    // left: portalOffset.dx - 5,
                    // top: portalOffset.dy - 5,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 1,
                        end: 1,
                      ).animate(_animationController),
                      alignment: Alignment.center,
                      child: FadeTransition(
                        opacity: Tween<double>(
                          begin: 0,
                          end: 1,
                        ).animate(_animationController),
                        child: child,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),

                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(1),
                    child: widget.child,
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

class AccountSwitcherMenuView extends StatelessWidget {
  const AccountSwitcherMenuView({super.key});

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
                            AvatarWidget.fromMyUser(
                              c.accounts
                                  .firstWhere((user) => user.value.id == c.me)
                                  .value,
                              radius: AvatarRadius.medium,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() {
                                  final Rx<MyUser> user = c.accounts.firstWhere(
                                    (user) => user.value.id == c.me,
                                  );
                                  return Text(
                                    user.value.name?.val ?? 'dot'.l10n,
                                    style:
                                        style.fonts.medium.regular.onBackground,
                                  );
                                }),
                                Obx(() {
                                  final presence = c.accounts
                                      .firstWhere(
                                        (user) => user.value.id == c.me,
                                      )
                                      .value
                                      .presence;

                                  return Text.rich(
                                    TextSpan(
                                      text: switch (presence) {
                                        Presence.present =>
                                          'label_presence_present'.l10n,
                                        Presence.away =>
                                          'label_presence_away'.l10n,
                                        (_) => '',
                                      },
                                      style:
                                          style.fonts.small.regular.secondary,
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
        );
      },
    );
  }
}
