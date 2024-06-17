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

import 'dart:math';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:collection/collection.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:messenger/domain/model/application_settings.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/main.dart';
import 'package:messenger/ui/page/auth/widget/cupertino_button.dart';
import 'package:messenger/ui/page/call/widget/fit_view.dart';
import 'package:messenger/ui/page/erase/view.dart';
import 'package:messenger/ui/page/home/page/chat/get_paid/controller.dart';
import 'package:messenger/ui/page/home/page/chat/get_paid/view.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_gallery.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';
import 'package:messenger/ui/page/home/page/user/widget/contact_info.dart';
import 'package:messenger/ui/page/home/page/user/widget/copy_or_share.dart';
import 'package:messenger/ui/page/home/page/user/widget/money_field.dart';
import 'package:messenger/ui/page/home/page/user/widget/prices.dart';
import 'package:messenger/ui/page/home/tab/menu/accounts/view.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';
import 'package:messenger/ui/page/home/widget/highlighted_container.dart';
import 'package:messenger/ui/page/home/widget/rectangle_button.dart';
import 'package:messenger/ui/page/login/controller.dart';
import 'package:messenger/ui/page/login/privacy_policy/view.dart';
import 'package:messenger/ui/page/login/qr_code/view.dart';
import 'package:messenger/ui/page/login/terms_of_use/view.dart';
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/widget/info_tile.dart';
import 'package:messenger/ui/widget/member_tile.dart';
import 'package:messenger/ui/widget/phone_field.dart';
import 'package:messenger/util/web/web_utils.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

import '../chat/message_field/view.dart';
import '/api/backend/schema.dart' show Presence;
import '/domain/model/cache_info.dart';
import '/domain/model/my_user.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/repository/settings.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/my_profile/widget/switch_field.dart';
import '/ui/page/home/tab/menu/status/view.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/big_avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/confirm_dialog.dart';
import '/ui/page/home/widget/direct_link.dart';
import '/ui/page/home/widget/field_button.dart';
import '/ui/page/home/widget/num.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/widget/download_button.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/ui/worker/cache.dart';
import '/util/media_utils.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'add_email/view.dart';
import 'add_phone/view.dart';
import 'blocklist/view.dart';
import 'call_window_switch/view.dart';
import 'camera_switch/view.dart';
import 'controller.dart';
import 'language/view.dart';
import 'call_buttons_switch/view.dart';
import 'microphone_switch/view.dart';
import 'output_switch/view.dart';
import 'paid_list/view.dart';
import 'password/view.dart';
import 'set_price/view.dart';
import 'welcome_message/view.dart';
import 'widget/background_preview.dart';
import 'widget/bio.dart';
import 'widget/line_divider.dart';
import 'widget/login.dart';
import 'widget/name.dart';
import 'widget/status.dart';
import 'widget/verification.dart';

/// View of the [Routes.me] page.
class MyProfileView extends StatelessWidget {
  const MyProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      key: const Key('MyProfileView'),
      init: MyProfileController(
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
      global: !Get.isRegistered<MyProfileController>(),
      builder: (MyProfileController c) {
        return GestureDetector(
          onTap: FocusManager.instance.primaryFocus?.unfocus,
          child: Scaffold(
            appBar: CustomAppBar(title: _bar(c, context)),
            body: Builder(builder: (context) {
              final Widget child = ScrollablePositionedList.builder(
                key: const Key('MyProfileScrollable'),
                initialScrollIndex: c.listInitIndex,
                scrollController: c.scrollController,
                itemScrollController: c.itemScrollController,
                itemPositionsListener: c.positionsListener,
                itemCount: ProfileTab.values.length,
                physics: const ClampingScrollPhysics(),
                itemBuilder: (context, i) {
                  // Builds a [Block] wrapped with [Obx] to highlight it.
                  Widget block({
                    String? title,
                    required List<Widget> children,
                    EdgeInsets? padding,
                    List<Widget> overlay = const [],
                  }) {
                    return Obx(() {
                      return Block(
                        title: title,
                        padding: padding ??
                            const EdgeInsets.fromLTRB(32, 16, 32, 16),
                        highlight: c.highlightIndex.value == i,
                        overlay: overlay,
                        children: children,
                      );
                    });
                  }

                  switch (ProfileTab.values[i]) {
                    case ProfileTab.public:
                      return Obx(() {
                        return HighlightedContainer(
                          highlight: c.highlightIndex.value == i,
                          child: Column(
                            children: [
                              block(
                                // title: 'label_avatar'.l10n,
                                title: 'Аватар',
                                children: [
                                  Obx(() {
                                    return BigAvatarWidget.myUser(
                                      c.myUser.value,
                                      loading: c.avatarUpload.value.isLoading,
                                      onUpload: c.uploadAvatar,
                                      onDelete: c.myUser.value?.avatar != null
                                          ? c.deleteAvatar
                                          : null,
                                    );
                                  }),
                                ],
                              ),
                              block(
                                title: 'label_about'.l10n,
                                children: [
                                  // const SizedBox(height: 24),
                                  Paddings.basic(
                                    Obx(() {
                                      return UserNameField(
                                        c.myUser.value?.name,
                                        onSubmit: c.updateUserName,
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 6),
                                  Paddings.basic(
                                    Obx(() {
                                      return UserBioField(
                                        c.myUser.value?.bio,
                                        onSubmit: c.updateUserBio,
                                      );
                                    }),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      });

                    case ProfileTab.signing:
                      return block(
                        title: 'label_login_options'.l10n,
                        children: [
                          Paddings.basic(
                            Obx(() {
                              return InfoTile(
                                title: 'label_num'.l10n,
                                content: c.myUser.value?.num.toString() ?? '',
                                trailing: CopyOrShareButton(
                                  c.myUser.value?.num.toString() ?? '',
                                ),
                              );
                            }),
                          ),
                          Obx(() {
                            if (c.myUser.value?.login == null) {
                              return const SizedBox();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: UserLoginField(
                                c.myUser.value?.login,
                                onSubmit: (s) async {
                                  if (s == null) {
                                    // TODO: Implement [UserLogin] deleting.
                                    c.myUser.value?.login = null;
                                    c.myUser.refresh();
                                  } else {
                                    await c.updateUserLogin(s);
                                  }
                                },
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          _emails(context, c),
                          _phones(context, c),
                          _providers(context, c),
                          _addInfo(context, c),
                        ],
                      );

                    case ProfileTab.link:
                      return block(
                        title: 'label_your_direct_link'.l10n,
                        // overlay: [
                        //   Positioned(
                        //     right: 0,
                        //     top: 0,
                        //     child: Center(
                        //       child: SelectionContainer.disabled(
                        //         child: AnimatedButton(
                        //           onPressed: c.linkEditing.toggle,
                        //           child: Padding(
                        //             padding:
                        //                 const EdgeInsets.fromLTRB(6, 6, 0, 6),
                        //             child: Obx(() {
                        //               return c.linkEditing.value
                        //                   ? const Padding(
                        //                       padding: EdgeInsets.all(2),
                        //                       child: SvgIcon(
                        //                         SvgIcons.closeSmallPrimary,
                        //                       ),
                        //                     )
                        //                   : const SvgIcon(SvgIcons.editSmall);
                        //             }),
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ],
                        children: [
                          Obx(() {
                            return DirectLinkField(
                              c.myUser.value?.chatDirectLink,
                              onSubmit: (s) async {
                                if (s == null) {
                                  await c.deleteChatDirectLink();
                                } else {
                                  await c.createChatDirectLink(s);
                                }

                                c.linkEditing.value = false;
                              },
                              background: c.background.value,
                              editing: c.linkEditing.value,
                              onEditing: (b) {
                                if (b) {
                                  c.itemScrollController.scrollTo(
                                    index: i,
                                    curve: Curves.ease,
                                    duration: const Duration(milliseconds: 600),
                                  );
                                }
                                c.highlight(ProfileTab.link);
                                c.linkEditing.value = b;
                              },
                            );
                          }),
                        ],
                      );

                    case ProfileTab.verification:
                      return block(children: [_verification2(context, c)]);

                    case ProfileTab.background:
                      return block(
                        title: 'label_background'.l10n,
                        children: [
                          Obx(() {
                            return BackgroundPreview(
                              c.background.value,
                              onPick: c.pickBackground,
                              onRemove: c.removeBackground,
                            );
                          }),
                        ],
                      );

                    case ProfileTab.chats:
                      return block(
                        title: 'label_chats'.l10n,
                        children: [_chats(context, c)],
                      );

                    case ProfileTab.calls:
                      if (!PlatformUtils.isWeb || !PlatformUtils.isDesktop) {
                        return const SizedBox();
                      }

                      return block(
                        title: 'label_open_calls_in'.l10n,
                        children: [_call(context, c)],
                      );

                    case ProfileTab.media:
                      if (PlatformUtils.isMobile) {
                        return const SizedBox();
                      }

                      return block(
                        title: 'label_media'.l10n,
                        children: [_media(context, c)],
                      );

                    case ProfileTab.welcome:
                      return block(
                        title: 'label_welcome_message'.l10n,
                        padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                        children: [_welcome(context, c)],
                      );

                    case ProfileTab.money:
                      return Stack(
                        children: [
                          block(
                            title: 'Монетизация (входящие)'.l10n,
                            padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                            children: [_money(context, c)],
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
                                              8, 4, 8, 4),
                                          constraints: context.isNarrow
                                              ? null
                                              : const BoxConstraints(
                                                  maxWidth: 400),
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
                      );

                    case ProfileTab.moneylist:
                      return Stack(
                        children: [
                          block(
                            title: 'Монетизация (входящие)'.l10n,
                            padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                            children: [_moneylist(context, c)],
                          ),
                        ],
                      );

                    case ProfileTab.donates:
                      return Stack(
                        children: [
                          block(
                            title: 'Монетизация (донаты)'.l10n,
                            children: [_donates(context, c)],
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
                      );

                    case ProfileTab.notifications:
                      return block(
                        title: 'label_audio_notifications'.l10n,
                        children: [
                          Paddings.dense(
                            Obx(() {
                              final bool isMuted =
                                  c.myUser.value?.muted == null;

                              return SwitchField(
                                text: isMuted
                                    ? 'label_enabled'.l10n
                                    : 'label_disabled'.l10n,
                                value: isMuted,
                                onChanged:
                                    c.isMuting.value ? null : c.toggleMute,
                              );
                            }),
                          ),
                        ],
                      );

                    case ProfileTab.storage:
                      if (PlatformUtils.isWeb) {
                        return const SizedBox();
                      }

                      return block(
                        title: 'label_storage'.l10n,
                        children: [_storage(context, c)],
                      );

                    case ProfileTab.language:
                      return block(
                        title: 'label_language'.l10n,
                        children: [_language(context, c)],
                      );

                    case ProfileTab.blocklist:
                      return block(
                        title: 'label_blocked_users'.l10n,
                        children: [_blockedUsers(context, c)],
                      );

                    case ProfileTab.devices:
                      return block(
                        title: 'label_linked_devices'.l10n,
                        children: [_devices(context, c)],
                      );

                    case ProfileTab.sections:
                      return block(
                        title: 'label_show_sections'.l10n,
                        children: [_sections(context, c)],
                      );

                    case ProfileTab.download:
                      if (!PlatformUtils.isWeb) {
                        return const SizedBox();
                      }

                      return block(
                        title: 'label_download_application'.l10n,
                        children: [_downloads(context, c)],
                      );

                    case ProfileTab.danger:
                      return block(
                        title: 'label_danger_zone'.l10n,
                        children: [_danger(context, c)],
                      );

                    case ProfileTab.legal:
                      return SafeArea(
                        top: false,
                        left: false,
                        right: false,
                        child: _legal(c, context),
                      );

                    case ProfileTab.styles:
                      return const SizedBox();

                    case ProfileTab.logout:
                      return const SafeArea(
                        top: false,
                        left: false,
                        right: false,
                        child: SizedBox(),
                      );
                  }
                },
              );

              if (PlatformUtils.isMobile) {
                return Scrollbar(controller: c.scrollController, child: child);
              }

              return child;
            }),
            floatingActionButton: Obx(() {
              if (c.myUser.value != null) {
                return const SizedBox();
              }

              return const CustomProgressIndicator();
            }),
          ),
        );
      },
    );
  }
}

/// Returns addable list of [MyUser.emails].
Widget _emails(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Obx(() {
    final List<Widget> widgets = [];

    for (UserEmail e in [
      ...c.myUser.value?.emails.confirmed ?? [],
      ...c.emails.where((e) => !e.val.startsWith('unverified')),
    ]) {
      widgets.add(
        InfoTile(
          content: e.val,
          title: 'E-mail',
          trailing: WidgetButton(
            onPressed: () => _deleteEmail(c, context, e),
            child: const SvgIcon(SvgIcons.delete),
          ),
        ),
      );

      widgets.add(const SizedBox(height: 8));
    }

    final unconfirmed = c.myUser.value?.emails.unconfirmed ??
        c.emails.firstWhereOrNull((e) => e.val.startsWith('unverified'));

    if (unconfirmed != null) {
      widgets.add(
        InfoTile(
          content: unconfirmed.val,
          trailing: WidgetButton(
            onPressed: () => _deleteEmail(c, context, unconfirmed),
            child: const SvgIcon(SvgIcons.delete),
          ),
          title: 'E-mail не верифицирован',
          subtitle: [
            const SizedBox(height: 4),
            WidgetButton(
              onPressed: () => AddEmailView.show(context, email: unconfirmed),
              child: Text(
                'Верифицировать',
                style: style.fonts.small.regular.primary,
              ),
            ),
          ],
          danger: true,
        ),
      );

      widgets.add(const SizedBox(height: 8));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets.map((e) => Paddings.dense(e)).toList(),
    );
  });
}

/// Returns addable list of [MyUser.phones].
Widget _phones(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Obx(() {
    final List<Widget> widgets = [];

    for (UserPhone e in [
      ...c.myUser.value?.phones.confirmed ?? [],
      ...c.phones.where((e) => !e.val.startsWith('+0')),
    ]) {
      widgets.add(
        InfoTile(
          content: e.val,
          title: 'label_phone'.l10n,
          trailing: WidgetButton(
            onPressed: () => _deletePhone(c, context, e),
            child: const SvgIcon(SvgIcons.delete),
          ),
        ),
      );

      widgets.add(const SizedBox(height: 8));
    }

    final unconfirmed = c.myUser.value?.phones.unconfirmed ??
        c.phones.firstWhereOrNull((e) => e.val.startsWith('+0'));

    if (unconfirmed != null) {
      widgets.add(
        InfoTile(
          content: unconfirmed.val,
          title: 'Телефон не верифицирован',
          trailing: WidgetButton(
            onPressed: () => _deletePhone(c, context, unconfirmed),
            child: const SvgIcon(SvgIcons.delete),
          ),
          subtitle: [
            const SizedBox(height: 4),
            WidgetButton(
              key: const Key('VerifyPhone'),
              onPressed: () => AddPhoneView.show(context, phone: unconfirmed),
              child: Text(
                'label_verify'.l10n,
                style: style.fonts.small.regular.primary,
              ),
            ),
          ],
          danger: true,
        ),
      );

      widgets.add(const SizedBox(height: 8));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets.map((e) => Paddings.dense(e)).toList(),
    );
  });
}

/// Returns addable list of [MyUser.emails].
Widget _providers(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Obx(() {
    final List<Widget> widgets = [];

    for (var e in c.providers) {
      widgets.add(
        InfoTile(
          content: e.$2.user?.email ?? 'Привязан',
          title: switch (e.$1) {
            OAuthProvider.apple => 'Apple ID',
            OAuthProvider.google => 'Google',
            OAuthProvider.github => 'GitHub',
          },
          trailing: WidgetButton(
            onPressed: () => c.providers.remove(e),
            child: const SvgIcon(SvgIcons.delete),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 8));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets.map((e) => Paddings.dense(e)).toList(),
    );
  });
}

Widget _addInfo(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              height: 0.5,
              color: Colors.black26,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Действия',
            style: style.fonts.small.regular.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              height: 0.5,
              color: Colors.black26,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),

      // const SizedBox(height: 4),
      Obx(() {
        if (c.myUser.value?.login != null) {
          return const SizedBox(height: 0);
        }

        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: UserLoginField(
            c.myUser.value?.login,
            editable: false,
            onSubmit: (s) async {
              if (s != null) {
                await c.updateUserLogin(s);
              }
            },
          ),
        );
      }),
      Obx(() {
        final emails = [
          ...c.myUser.value?.emails.confirmed ?? <UserEmail>[],
          c.myUser.value?.emails.unconfirmed,
          ...c.emails,
        ].whereNotNull();

        final phones = [
          ...c.myUser.value?.phones.confirmed ?? <UserPhone>[],
          c.myUser.value?.phones.unconfirmed,
          ...c.phones,
        ].whereNotNull();

        final phone =
            ReactivePhoneField(state: c.phone, label: 'Добавить телефон');
        final email = ReactiveTextField(
          state: c.email,
          label: 'Добавить E-mail',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hint: 'example@dummy.com',
        );

        Widget linkProvider(OAuthProvider provider) {
          return FieldButton(
            text: switch (provider) {
              OAuthProvider.apple => 'Привязать Apple ID',
              OAuthProvider.google => 'Привязать Google',
              OAuthProvider.github => 'Привязать GitHub',
            },
            onPressed: switch (provider) {
              OAuthProvider.apple => c.continueWithApple,
              OAuthProvider.google => c.continueWithGoogle,
              OAuthProvider.github => c.continueWithGitHub,
            },
            style: style.fonts.normal.regular.primary,
            trailing: SvgIcon(
              switch (provider) {
                OAuthProvider.apple => SvgIcons.apple,
                OAuthProvider.google => SvgIcons.google,
                OAuthProvider.github => SvgIcons.github,
              },
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emails.isEmpty) const SizedBox(height: 12),
            if (emails.isEmpty) email,
            if (emails.isEmpty) const SizedBox(height: 12),
            const SizedBox(height: 12),
            _password(context, c),
            const SizedBox(height: 6),
            if (true || emails.isNotEmpty) ...[
              const SizedBox(height: 12),
              WidgetButton(
                onPressed: c.expanded.toggle,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        height: 0.5,
                        color: style.colors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      c.expanded.value ? 'Скрыть' : 'Добавить',
                      style: style.fonts.small.regular.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        height: 0.5,
                        color: style.colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (c.expanded.value) ...[
                const SizedBox(height: 24),
                phone,
                if (emails.isNotEmpty) const SizedBox(height: 24),
                if (emails.isNotEmpty) email,
                if (c.providers.none((e) => e.$1 == OAuthProvider.apple)) ...[
                  const SizedBox(height: 24),
                  linkProvider(OAuthProvider.apple),
                ],
                if (c.providers.none((e) => e.$1 == OAuthProvider.google)) ...[
                  const SizedBox(height: 24),
                  linkProvider(OAuthProvider.google),
                ],
                if (c.providers.none((e) => e.$1 == OAuthProvider.github)) ...[
                  const SizedBox(height: 24),
                  linkProvider(OAuthProvider.github),
                ],
              ],
            ],
          ],
        );
      }),
    ],
  );
}

/// Returns the buttons changing or setting the password of the currently
/// authenticated [MyUser].
Widget _password(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Obx(() {
        return FieldButton(
          key: c.myUser.value?.hasPassword == true
              ? const Key('ChangePassword')
              : const Key('SetPassword'),
          text: c.myUser.value?.hasPassword == true
              ? 'btn_change_password'.l10n
              : 'btn_set_password'.l10n,
          onPressed: () => ChangePasswordView.show(context),
          warning: c.myUser.value?.hasPassword != true,
          style: style.fonts.normal.regular.primary,
          trailing: c.myUser.value?.hasPassword == true
              ? const SvgIcon(SvgIcons.password19)
              : const SvgIcon(SvgIcons.password19White),
        );
      }),
      const SizedBox(height: 10),
    ],
  );
}

/// Returns the contents of a [ProfileTab.danger] section.
Widget _danger(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Column(
    children: [
      Paddings.dense(
        FieldButton(
          key: const Key('DeleteAccount'),
          text: 'btn_delete_account'.l10n,
          onPressed: () => _deleteAccount(c, context),
          danger: true,
          style: style.fonts.normal.regular.danger,
        ),
      ),
    ],
  );
}

/// Returns the contents of a [ProfileTab.calls] section.
Widget _call(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Paddings.dense(
        Obx(() {
          return FieldButton(
            text: (c.settings.value?.enablePopups ?? true)
                ? 'label_open_calls_in_window'.l10n
                : 'label_open_calls_in_app'.l10n,
            maxLines: null,
            onPressed: () => CallWindowSwitchView.show(context),
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          );
        }),
      ),
    ],
  );
}

/// Returns the contents of a [ProfileTab.chats] section.
Widget _chats(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Paddings.dense(
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 21),
            child: Text(
              'label_display_audio_and_video_call_buttons'.l10n,
              style: style.fonts.normal.regular.secondary,
            ),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Paddings.dense(
        Obx(() {
          return FieldButton(
            text: switch (c.settings.value?.callButtonsPosition) {
              CallButtonsPosition.appBar ||
              null =>
                'label_media_buttons_in_app_bar'.l10n,
              CallButtonsPosition.contextMenu =>
                'label_media_buttons_in_context_menu'.l10n,
              CallButtonsPosition.top => 'label_media_buttons_in_top'.l10n,
              CallButtonsPosition.bottom =>
                'label_media_buttons_in_bottom'.l10n,
              CallButtonsPosition.more => 'label_media_buttons_in_more'.l10n,
            },
            maxLines: null,
            onPressed: () => CallButtonsSwitchView.show(context),
            style: style.fonts.normal.regular.primary,
          );
        }),
      ),
    ],
  );
}

/// Returns the contents of a [ProfileTab.media] section.
Widget _media(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Paddings.dense(
        Obx(() {
          final selected = c.devices.video().firstWhereOrNull(
                    (e) => e.deviceId() == c.media.value?.videoDevice,
                  ) ??
              c.devices.video().firstOrNull;

          return FieldButton(
            text: selected?.label() ?? 'label_media_no_device_available'.l10n,
            headline: Text('label_media_camera'.l10n),
            onPressed: () async {
              await CameraSwitchView.show(
                context,
                camera: c.media.value?.videoDevice,
              );

              if (c.devices.video().isEmpty) {
                c.devices.value = await MediaUtils.enumerateDevices();
              }
            },
            style: style.fonts.normal.regular.primary,
          );
        }),
      ),
      const SizedBox(height: 16),
      Paddings.dense(
        Obx(() {
          final selected = c.devices.audio().firstWhereOrNull(
                    (e) => e.id() == c.media.value?.audioDevice,
                  ) ??
              c.devices.audio().firstOrNull;

          return FieldButton(
            text: selected?.label() ?? 'label_media_no_device_available'.l10n,
            headline: Text('label_media_microphone'.l10n),
            onPressed: () async {
              await MicrophoneSwitchView.show(
                context,
                mic: c.media.value?.audioDevice,
              );

              if (c.devices.audio().isEmpty) {
                c.devices.value = await MediaUtils.enumerateDevices();
              }
            },
            style: style.fonts.normal.regular.primary,
          );
        }),
      ),

      // TODO: Remove, when Safari supports output devices without tweaking the
      //       developer options:
      //       https://bugs.webkit.org/show_bug.cgi?id=216641
      if (!WebUtils.isSafari || c.devices.output().isNotEmpty) ...[
        const SizedBox(height: 16),
        Paddings.dense(
          Obx(() {
            final selected = c.devices.output().firstWhereOrNull(
                      (e) => e.id() == c.media.value?.outputDevice,
                    ) ??
                c.devices.output().firstOrNull;

            return FieldButton(
              text: selected?.label() ?? 'label_media_no_device_available'.l10n,
              headline: Text('label_media_output'.l10n),
              onPressed: () async {
                await OutputSwitchView.show(
                  context,
                  output: c.media.value?.outputDevice,
                );

                if (c.devices.output().isEmpty) {
                  c.devices.value = await MediaUtils.enumerateDevices();
                }
              },
              style: style.fonts.normal.regular.primary,
            );
          }),
        ),
      ],
    ],
  );
}

/// Returns the contents of a `ProfileTab.verification` section.
Widget _verification2(BuildContext context, MyProfileController c) {
  return VerificationBlock(
    person: c.person.value,
    editing: c.verificationEditing.value,
    onChanged: (s) => c.person.value = s,
    onEditing: (e) {
      c.itemScrollController.scrollTo(
        index: ProfileTab.values.indexOf(ProfileTab.verification),
        curve: Curves.ease,
        duration: const Duration(milliseconds: 600),
      );

      c.highlight(ProfileTab.verification);

      c.verificationEditing.value = e;
      if (!e) {
        c.verify();
      }
    },
    myUser: c.myUser,
  );
}

Widget _welcome(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  final TextStyle? thin = Theme.of(context)
      .textTheme
      .bodyLarge
      ?.copyWith(color: style.colors.onBackground);

  Widget info({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: style.systemMessageBorder,
            color: style.systemMessageColor,
          ),
          child: DefaultTextStyle(
            style: style.systemMessageStyle,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget message({
    String text = '123',
    List<Attachment> attachments = const [],
    PreciseDateTime? at,
  }) {
    final List<Attachment> media = attachments.where((e) {
      return ((e is ImageAttachment) ||
          (e is FileAttachment && e.isVideo) ||
          (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
    }).toList();

    final Iterable<GalleryAttachment> galleries =
        media.map((e) => GalleryAttachment(e, null));

    final List<Attachment> files = attachments.where((e) {
      return ((e is FileAttachment && !e.isVideo) ||
          (e is LocalAttachment && !e.file.isImage && !e.file.isVideo));
    }).toList();

    final bool timeInBubble = attachments.isNotEmpty;

    Widget? timeline;
    if (at != null) {
      timeline = SelectionContainer.disabled(
        child: Text(
          DateFormat.Hm().format(at.val.toLocal()),
          style: style.systemMessageStyle.copyWith(fontSize: 11),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(5 * 2, 6, 5 * 2, 6),
      child: Stack(
        children: [
          IntrinsicWidth(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                color: style.readMessageColor,
                borderRadius: BorderRadius.circular(15),
                border: style.secondaryBorder,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: text),
                            if (timeline != null)
                              WidgetSpan(
                                child: Opacity(opacity: 0, child: timeline),
                              ),
                          ],
                        ),
                        style: style.fonts.medium.regular.onBackground,
                      ),
                    ),
                  if (files.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                      child: Column(
                        children: files
                            .map((e) => ChatItemWidget.fileAttachment(e))
                            .toList(),
                      ),
                    ),
                  if (media.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: text.isNotEmpty || files.isNotEmpty
                            ? Radius.zero
                            : files.isEmpty
                                ? const Radius.circular(15)
                                : Radius.zero,
                        topRight: text.isNotEmpty || files.isNotEmpty
                            ? Radius.zero
                            : files.isEmpty
                                ? const Radius.circular(15)
                                : Radius.zero,
                        bottomLeft: const Radius.circular(15),
                        bottomRight: const Radius.circular(15),
                      ),
                      child: media.length == 1
                          ? ChatItemWidget.mediaAttachment(
                              context,
                              media.first,
                              galleries,
                              filled: false,
                            )
                          : SizedBox(
                              width: media.length * 120,
                              height: max(media.length * 60, 300),
                              child: FitView(
                                dividerColor: Colors.transparent,
                                children: media
                                    .mapIndexed(
                                      (i, e) => ChatItemWidget.mediaAttachment(
                                        context,
                                        e,
                                        galleries,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ),
          if (timeline != null)
            Positioned(
              right: timeInBubble ? 4 : 8,
              bottom: 4,
              child: timeInBubble
                  ? Container(
                      padding: const EdgeInsets.only(
                        left: 5,
                        right: 5,
                        top: 2,
                        bottom: 2,
                      ),
                      decoration: BoxDecoration(
                        // color: Colors.white.withOpacity(0.9),
                        color: style.readMessageColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: timeline,
                    )
                  : timeline,
            )
        ],
      ),
    );
  }

  final Widget editOrDelete = info(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        WidgetButton(
          onPressed: () async {
            c.send.editing.value = true;
            c.send.field.unchecked = c.welcome.value?.text?.val;
            c.send.attachments.value = c.welcome.value?.attachments
                    .map((e) => MapEntry(GlobalKey(), e))
                    .toList() ??
                [];
          },
          child: Text('btn_edit'.l10n, style: style.systemMessagePrimary),
        ),
        Text('space_or_space'.l10n, style: style.systemMessageStyle),
        WidgetButton(
          key: const Key('DeleteAvatar'),
          onPressed: () => c.welcome.value = null,
          child: Text(
            'btn_delete'.l10n.toLowerCase(),
            style: style.systemMessagePrimary,
          ),
        ),
      ],
    ),
  );

  return Column(
    children: [
      Padding(
        padding: Block.defaultPadding
            .copyWith(top: 0, bottom: 0)
            .add(const EdgeInsets.fromLTRB(8, 0, 8, 0)),
        child: Text(
          'label_welcome_message_description'.l10n,
          style: style.fonts.small.regular.secondary,
        ),
      ),

      const SizedBox(height: 16),
      Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: style.primaryBorder,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Obx(() {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: c.background.value == null
                      ? const SvgImage.asset(
                          'assets/images/background_light.svg',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.memory(c.background.value!, fit: BoxFit.cover),
                );
              }),
            ),
          ),
          Obx(() {
            return Column(
              children: [
                const SizedBox(height: 16),
                if (c.welcome.value == null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    height: 60 * 1.5,
                    child: info(
                      child: Text(
                        'label_no_welcome_message'.l10n,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else ...[
                  info(
                    child: Text(c.welcome.value?.at.val.toRelative() ?? ''),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: IgnorePointer(
                        child: message(
                          text: c.welcome.value?.text?.val ?? '',
                          attachments: c.welcome.value?.attachments ?? [],
                          at: c.welcome.value?.at,
                        ),
                      ),
                    ),
                  ),
                  editOrDelete,
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  child: MessageFieldView(
                    key: c.welcomeFieldKey,
                    fieldKey: const Key('ForwardField'),
                    sendKey: const Key('SendForward'),
                    constraints: const BoxConstraints(),
                    controller: c.send,
                  ),
                ),
              ],
            );
          }),
        ],
      ),

      // const SizedBox(height: 10),
    ],
  );
}

Widget _verification(BuildContext context, MyProfileController c) {
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
                      // onPressed: () => c.verified.value = true,
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
                          style: TextStyle(color: style.colors.onBackground),
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

/// Returns the contents of a [ProfileTab.sections] section.
Widget _sections(BuildContext context, MyProfileController c) {
  return Column(
    children: [
      Paddings.dense(
        Obx(() {
          final enabled = c.settings.value?.balanceTabEnabled == true;

          return SwitchField(
            text: 'label_wallet'.l10n,
            value: enabled,
            onChanged: c.setBalanceTabEnabled,
          );
        }),
      ),
      Paddings.dense(
        Obx(() {
          return SwitchField(
            text: 'btn_work_with_us'.l10n,
            value: c.settings.value?.workWithUsTabEnabled == true,
            onChanged: c.setWorkWithUsTabEnabled,
          );
        }),
      ),
    ],
  );
}

Widget _money(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Obx(() {
    final List<Widget> children;

    if (c.moneyEditing.value) {
      children = [
        const LineDivider('От всех пользователей'),
        const SizedBox(height: 8 + 8 + 8),
        MoneyField(
          state: c.allMessageCost,
          label: 'Входящие сообщения, за 1 сообщение',
        ),
        const SizedBox(height: 24),
        MoneyField(
          state: c.allCallCost,
          label: 'Входящие звонки, за 1 минуту',
        ),
        const SizedBox(height: 8),
        Text(
          'Кроме Ваших контактов и индивидуальных пользователей.',
          style: style.fonts.small.regular.secondary,
        ),
        const SizedBox(height: 24),
        const LineDivider('От Ваших контактов'),
        const SizedBox(height: 8 + 8 + 8),
        MoneyField(
          state: c.contactMessageCost,
          label: 'Входящие сообщения, за 1 сообщение',
        ),
        const SizedBox(height: 24),
        MoneyField(
          state: c.contactCallCost,
          label: 'Входящие звонки, за 1 минуту',
        ),
        const SizedBox(height: 12),
        WidgetButton(
          onPressed: () {
            c.moneyEditing.value = false;
          },
          child: Text(
            'Готово',
            style: style.fonts.small.regular.primary,
          ),
        ),
      ];
    } else {
      children = [
        Text(
          'Пользователи платят Вам за отправку Вам сообщений и совершение звонков.',
          style: style.fonts.small.regular.secondary,
        ),
        const SizedBox(height: 24),
        const LineDivider('От всех пользователей'),
        const SizedBox(height: 8),
        Prices(
          calls: c.allCallPrice.value,
          messages: c.allMessagePrice.value,
          onMessagesPressed: () {
            c.moneyEditing.value = true;
            c.allMessageCost.focus.requestFocus();
          },
          onCallsPressed: () {
            c.moneyEditing.value = true;
            c.allCallCost.focus.requestFocus();
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Кроме Ваших контактов и индивидуальных пользователей.',
          style: style.fonts.small.regular.secondary,
        ),
        const SizedBox(height: 24),
        const LineDivider('От Ваших контактов'),
        const SizedBox(height: 8),
        Prices(
          calls: c.contactCallPrice.value,
          messages: c.contactMessagePrice.value,
          onMessagesPressed: () {
            c.moneyEditing.value = true;
            c.contactMessageCost.focus.requestFocus();
          },
          onCallsPressed: () {
            c.moneyEditing.value = true;
            c.contactCallCost.focus.requestFocus();
          },
        ),
        const SizedBox(height: 12),
        WidgetButton(
          onPressed: () {
            c.itemScrollController.scrollTo(
              index: ProfileTab.values.indexOf(ProfileTab.money),
              curve: Curves.ease,
              duration: const Duration(milliseconds: 600),
            );

            c.highlight(ProfileTab.money);
            c.moneyEditing.value = true;
          },
          child: Text(
            'Изменить',
            style: style.fonts.small.regular.primary,
          ),
        ),
      ];
    }

    return AnimatedSizeAndFade(
      sizeDuration: const Duration(milliseconds: 300),
      fadeDuration: const Duration(milliseconds: 300),
      child: Column(
        key: Key(c.moneyEditing.value.toString()),
        children: children,
      ),
    );
  });
}

Widget _moneylist(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return AnimatedSizeAndFade(
    sizeDuration: const Duration(milliseconds: 300),
    fadeDuration: const Duration(milliseconds: 300),
    child: Column(
      children: [
        // Text(
        //   'Пользователи платят Вам за отправку Вам сообщений и совершение звонков.',
        //   style: style.fonts.small.regular.secondary,
        // ),
        Text(
          'В профиле каждого пользователя Вы можете установить индивидуальные настройки оплаты входящих сообщений и звонков.'
              .l10n,
          style: style.fonts.small.regular.secondary,
        ),
        Obx(() {
          if (!c.blocklistStatus.value.isLoading && c.blocklist.isEmpty) {
            return const SizedBox();
          }

          return const SizedBox(height: 16);
        }),
        _blocklist(context, c),
      ],
    ),
  );
}

Widget _blocklist(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Obx(() {
    // Show only users with [User.isBlocked] for optimistic
    // deletion from blocklist.
    final Iterable<RxUser> blocklist = c.blocklist
        .where((e) => e.user.value.isBlocked != null)
        .map((e) => [e, e, e, e, e, e, e, e, e, e, e])
        .expand((e) => e);

    if (c.blocklistStatus.value.isLoading) {
      return SizedBox(
        height: (c.myUser.value?.blocklistCount ?? 0) * 95,
        child: const Center(
          child: CustomProgressIndicator.primary(),
        ),
      );
    } else if (blocklist.isEmpty) {
      return const SizedBox();
      return Text(
        'В профиле каждого пользователя Вы можете установить индивидуальные настройки оплаты входящих сообщений и звонков.'
            .l10n,
        style: style.fonts.small.regular.secondary,
      );
    } else {
      return Scrollbar(
        controller: c.paidScrollController,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.builder(
            // padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            controller: c.paidScrollController,
            shrinkWrap: true,
            itemBuilder: (context, i) {
              final RxUser e = blocklist.elementAt(i);

              return ContactTile(
                user: e,
                onTap: () => router.user(e.id, push: true, scrollToPaid: true),
                basement: Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Сообщение: ',
                            style: style.fonts.small.regular.secondary,
                          ),
                          TextSpan(
                            text: '¤123',
                            style: style.fonts.small.regular.primary.copyWith(
                              color: style.colors.acceptPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Звонок: ',
                            style: style.fonts.small.regular.secondary,
                          ),
                          TextSpan(
                            text: '¤123/мин',
                            style: style.fonts.small.regular.primary.copyWith(
                              color: style.colors.acceptPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                height: 36,
                trailing: [
                  AnimatedButton(
                    onPressed: () async {
                      final bool inContacts = false;

                      final name = TextSpan(
                        text: e.user.value.name?.val ??
                            e.user.value.num.toString(),
                        style: style.fonts.normal.regular.onBackground,
                      );

                      final bool? result = await MessagePopup.alert(
                        'Изменение тарификации',
                        description: [
                          const TextSpan(
                            text:
                                'Индивидуальные настройки оплаты входящих сообщений и звонков от ',
                          ),
                          name,
                          const TextSpan(
                              text: ' будут удалены.\n\nК пользователю '),
                          name,
                          const TextSpan(
                            text:
                                ' будут применены общие настройки тарификации входящих сообщений и звонков.',
                          ),
                        ],
                        additional: [
                          const SizedBox(height: 16),
                          const LineDivider('От Ваших контактов'),
                          const SizedBox(height: 8),
                          const Prices(messages: 0, calls: 0),
                        ],
                      );

                      if (result == true) {
                        await c.unblock(e);
                      }
                    },
                    child: const SvgIcon(
                      SvgIcons.delete,
                      key: Key('DeleteMemberButton'),
                    ),
                  ),
                ],
              );
            },
            itemCount: blocklist.length,
          ),
        ),
      );
    }
  });
}

Widget _donates(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Obx(() {
    final List<Widget> children;

    if (c.donateEditing.value) {
      children = [
        const SizedBox(height: 8),
        MoneyField(state: c.donateCost, label: 'Минимальная сумма'),
        const SizedBox(height: 12),
        WidgetButton(
          onPressed: () {
            c.donateEditing.value = false;
          },
          child: Text(
            'Готово',
            style: style.fonts.small.regular.primary,
          ),
        ),
      ];
    } else {
      children = [
        PriceEntry(
          amount: c.donatePrice.value,
          label: 'Минимальная сумма',
          // subtitle: 'Доната',
          onPressed: () {
            c.donateEditing.value = true;
            c.donateCost.focus.requestFocus();
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Пользователи не смогут отправить Вам донат на сумму менее указанной Вами.',
          style: style.fonts.small.regular.secondary,
        ),
        const SizedBox(height: 12),
        WidgetButton(
          onPressed: () {
            c.itemScrollController.scrollTo(
              index: ProfileTab.values.indexOf(ProfileTab.donates),
              curve: Curves.ease,
              alignment: 0.01,
              duration: const Duration(milliseconds: 600),
            );

            c.highlight(ProfileTab.donates);
            c.donateEditing.value = true;
          },
          child: Text(
            'Изменить',
            style: style.fonts.small.regular.primary,
          ),
        ),
      ];
    }

    return AnimatedSizeAndFade(
      sizeDuration: const Duration(milliseconds: 300),
      fadeDuration: const Duration(milliseconds: 300),
      child: Column(
        key: Key(c.donateEditing.value.toString()),
        children: children,
      ),
    );
  });
}

/// Returns the contents of a [ProfileTab.download] section.
Widget _downloads(BuildContext context, MyProfileController c) {
  return Paddings.dense(
    const Column(
      children: [
        DownloadButton.windows(),
        SizedBox(height: 8),
        DownloadButton.macos(),
        SizedBox(height: 8),
        DownloadButton.linux(),
        SizedBox(height: 8),
        DownloadButton.appStore(),
        SizedBox(height: 8),
        DownloadButton.googlePlay(),
      ],
    ),
  );
}

/// Returns the contents of a [ProfileTab.language] section.
Widget _language(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Paddings.dense(
    FieldButton(
      key: const Key('ChangeLanguage'),
      onPressed: () => LanguageSelectionView.show(
        context,
        Get.find<AbstractSettingsRepository>(),
      ),
      text: 'label_language_entry'.l10nfmt({
        'code': L10n.chosen.value!.locale.countryCode,
        'name': L10n.chosen.value!.name,
      }),
      style: TextStyle(color: style.colors.primary),
    ),
  );
}

/// Returns the contents of a [ProfileTab.blocklist] section.
Widget _blockedUsers(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Obx(() {
    // Show only users with [User.isBlocked] for optimistic
    // deletion from blocklist.
    final Iterable<RxUser> blocklist = c.blocklist
        .where((e) => e.user.value.isBlocked != null)
        .map((e) => [e, e, e, e, e, e, e, e, e, e, e])
        .expand((e) => e);

    if (c.blocklistStatus.value.isLoading) {
      return SizedBox(
        height: (c.myUser.value?.blocklistCount ?? 0) * 95,
        child: const Center(
          child: CustomProgressIndicator.primary(),
        ),
      );
    } else if (blocklist.isEmpty) {
      return Text(
        'Пользователей нет.'.l10n,
        style: style.fonts.small.regular.secondary,
      );
    } else {
      return Scrollbar(
        controller: c.blocklistScrollController,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.builder(
            controller: c.blocklistScrollController,
            shrinkWrap: true,
            itemBuilder: (context, i) {
              final RxUser e = blocklist.elementAt(i);

              return ContactTile(
                user: e,
                onTap: () => router.user(e.id, push: true),
                height: 52,
                radius: AvatarRadius.small,
                subtitle: [
                  Text(
                    e.user.value.isBlocked?.at.val.yyMd ?? '',
                    style: style.fonts.small.regular.secondary,
                  ),
                ],
                trailing: [
                  AnimatedButton(
                    onPressed: () async {
                      await c.unblock(e);
                    },
                    child: const SvgIcon(SvgIcons.block16),
                  ),
                ],
              );
            },
            itemCount: blocklist.length,
          ),
        ),
      );
    }
  });
}

/// Returns the contents of a [ProfileTab.storage] section.
Widget _storage(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  final List<double> values = [
    0.0,
    2.0,
    4.0,
    8.0,
    16.0,
    32.0,
    64.0,
  ];

  final gbs = (CacheWorker.instance.info.value.maxSize?.toDouble() ??
          (values.last * GB)) /
      GB;

  var index = values.indexWhere((e) => gbs <= e);
  if (index == -1) {
    index = values.length - 1;
  }

  final v = (index / (values.length - 1) * 100).round();

  return Paddings.dense(
    Column(
      children: [
        Obx(() {
          final int size = CacheWorker.instance.info.value.size;
          final int max = CacheWorker.instance.info.value.maxSize ??
              (values.last * GB).toInt();

          if (max >= 64 * GB) {
            return Text(
              'label_gb_occupied'
                  .l10nfmt({'count': (size / GB).toPrecision(2)}),
            );
          } else if (max <= 0) {
            return Text('label_gb_occupied'.l10nfmt({'count': 0}));
          }

          return Text(
            'label_gb_of_gb_occupied'.l10nfmt({
              'a': (size / GB).toPrecision(2),
              'b': max ~/ GB,
            }),
          );
        }),
        SizedBox(
          height: 100,
          child: FlutterSlider(
            handlerHeight: 24,
            values: [v.toDouble()],
            tooltip: FlutterSliderTooltip(disabled: true),
            fixedValues: values.mapIndexed(
              (i, e) {
                return FlutterSliderFixedValue(
                  percent: ((i / (values.length - 1)) * 100).round(),
                  value: e * GB,
                );
              },
            ).toList(),
            trackBar: FlutterSliderTrackBar(
              inactiveTrackBar: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: style.colors.onBackgroundOpacity13,
              ),
              activeTrackBar: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: style.colors.primaryHighlight,
              ),
            ),
            onDragging: (i, lower, upper) {
              if (lower is double) {
                if (lower == 64.0 * GB) {
                  CacheWorker.instance.setMaxSize(null);
                } else {
                  CacheWorker.instance.setMaxSize(lower.round());
                }
              }
            },
            onDragCompleted: (i, lower, upper) {
              if (lower is double) {
                if (lower == 64.0 * GB) {
                  CacheWorker.instance.setMaxSize(null);
                } else {
                  CacheWorker.instance.setMaxSize(lower.round());
                }
              }
            },
            hatchMark: FlutterSliderHatchMark(
              labelsDistanceFromTrackBar: -48,
              density: 0.5,
              labels: [
                FlutterSliderHatchMarkLabel(
                  percent: 0,
                  label: Text(
                    'label_off'.l10n,
                    style: style.fonts.smallest.regular.secondary,
                  ),
                ),
                FlutterSliderHatchMarkLabel(
                  percent: 16,
                  label: Text(
                    'label_count_gb'.l10nfmt({'count': 2}),
                    style: style.fonts.smallest.regular.secondary,
                  ),
                ),
                FlutterSliderHatchMarkLabel(
                  percent: 32,
                  label: Text(
                    'label_count_gb'.l10nfmt({'count': 4}),
                    style: style.fonts.smallest.regular.secondary,
                  ),
                ),
                FlutterSliderHatchMarkLabel(
                  percent: 49,
                  label: Text(
                    'label_count_gb'.l10nfmt({'count': 8}),
                    style: style.fonts.smallest.regular.secondary,
                  ),
                ),
                FlutterSliderHatchMarkLabel(
                  percent: 66,
                  label: Text(
                    'label_count_gb'.l10nfmt({'count': 16}),
                    style: style.fonts.smallest.regular.secondary,
                  ),
                ),
                FlutterSliderHatchMarkLabel(
                  percent: 83,
                  label: Text(
                    'label_count_gb'.l10nfmt({'count': 32}),
                    style: style.fonts.smallest.regular.secondary,
                  ),
                ),
                FlutterSliderHatchMarkLabel(
                  percent: 100,
                  label: Text(
                    'label_no_limit'.l10n,
                    style: style.fonts.smallest.regular.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        FieldButton(
          onPressed: c.clearCache,
          text: 'btn_clear_cache'.l10n,
          style: style.fonts.normal.regular.primary,
        ),
        const SizedBox(height: 8),
        FieldButton(
          text: 'Очистить все данные'.l10n,
          onPressed: () => _clearCache(c, context),
          danger: true,
          style: style.fonts.normal.regular.danger,
        ),
      ],
    ),
  );
}

Widget _devices(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  Widget device({
    required String name,
    required String location,
    required Widget icon,
    DateTime? activeAt,
    bool thisDevice = false,
  }) {
    // Удалить устройство
    //
    // Устройство такое-то.

    return Padding(
      padding: const EdgeInsets.only(bottom: 21),
      child: InfoTile(
        title:
            '${thisDevice ? 'Это устройство' : activeAt == null ? 'Онлайн' : activeAt.toRelative()}, $location',
        content: name,
        trailing: thisDevice
            ? null
            : WidgetButton(
                onPressed: () => _deleteSession(
                  context,
                  InfoTile(
                    title:
                        '${thisDevice ? 'Это устройство' : activeAt == null ? 'Онлайн' : activeAt.toRelative()}, $location',
                    content: name,
                  ),
                ),
                child: const SvgIcon(SvgIcons.delete),
              ),
      ),
    );
  }

  return Paddings.dense(
    Column(
      children: [
        device(
          name: 'iPhone 14 Pro Max',
          location: 'Florida, USA',
          icon: const Icon(Icons.phone_iphone, size: 24, color: Colors.blue),
          activeAt: null,
          thisDevice: true,
        ),
        const SizedBox(height: 8),
        device(
          name: 'MacBook Pro 16 M3 Max',
          location: 'Tokyo, Japan',
          icon: const Icon(Icons.laptop, size: 24, color: Colors.blue),
          activeAt: null,
        ),
        const SizedBox(height: 8),
        device(
          name: 'Xiaomi Redmi Note 12',
          location: 'Tokyo, Japan',
          icon: const Icon(Icons.laptop, size: 24, color: Colors.blue),
          activeAt: DateTime.now().copyWith(hour: DateTime.now().hour - 1),
        ),
        const SizedBox(height: 8),
        device(
          name: 'Chrome 120, Windows 11',
          location: 'Moon, Space',
          icon: const Icon(Icons.laptop, size: 24, color: Colors.blue),
          activeAt: DateTime.now().copyWith(hour: DateTime.now().day - 3),
        ),
        const SizedBox(height: 8),
        device(
          name: 'Windows 11',
          location: 'Irkutsk, Russia',
          icon: const Icon(Icons.monitor, size: 24, color: Colors.blue),
          activeAt: DateTime(2000, 12, 12),
        ),
        const SizedBox(height: 14),
        const LineDivider('Добавить устройство'),
        const SizedBox(height: 24),
        FieldButton(
          text: 'btn_scan_qr_code'.l10n,
          onPressed: () {
            QrCodeView.show(
              context,
              title: 'btn_scan_qr_code'.l10n,
              scanning: false,
              path: 'label_show_qr_code_to_sign_in3'.l10n,
            );
          },
        ),
        const SizedBox(height: 16),
        FieldButton(
          text: 'btn_show_qr_code'.l10n,
          onPressed: () {
            QrCodeView.show(
              context,
              title: 'btn_show_qr_code'.l10n,
              scanning: true,
              path: 'label_show_qr_code_to_sign_in3'.l10n,
            );
          },
        ),
      ],
    ),
  );
}

// Returns the buttons for legal related information displaying.
Widget _legal(MyProfileController c, BuildContext context) {
  final style = Theme.of(context).style;

  return Block(
    title: 'label_legal_info'.l10n,
    children: [
      Column(
        children: [
          Center(
            child: StyledCupertinoButton(
              label: 'btn_terms_and_conditions'.l10n,
              style: style.fonts.small.regular.primary,
              onPressed: () => TermsOfUseView.show(context),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: StyledCupertinoButton(
              label: 'btn_privacy_policy'.l10n,
              style: style.fonts.small.regular.primary,
              onPressed: () => PrivacyPolicy.show(context),
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _bar(MyProfileController c, BuildContext context) {
  final style = Theme.of(context).style;

  final searchButton = AnimatedButton(
    onPressed: () {},
    decorator: (child) => Padding(
      padding: const EdgeInsets.only(left: 31, right: 20),
      child: child,
    ),
    child: const SvgIcon(SvgIcons.search),
  );

  return Obx(() {
    final section = switch (router.profileSection.value) {
      null || ProfileTab.public => 'label_profile'.l10n,
      ProfileTab.signing => 'label_login_options'.l10n,
      ProfileTab.verification => 'Верификация аккаунта'.l10n,
      ProfileTab.link => 'label_link_to_chat'.l10n,
      ProfileTab.background => 'label_background'.l10n,
      ProfileTab.chats => 'label_chats'.l10n,
      ProfileTab.calls => 'label_calls'.l10n,
      ProfileTab.media => 'label_media'.l10n,
      ProfileTab.welcome => 'label_welcome_message'.l10n,
      ProfileTab.money => 'Монетизация (входящие)'.l10n,
      ProfileTab.moneylist => 'Монетизация (входящие)'.l10n,
      ProfileTab.donates => 'Монетизация (донаты)'.l10n,
      ProfileTab.notifications => 'label_notifications'.l10n,
      ProfileTab.storage => 'label_storage'.l10n,
      ProfileTab.language => 'label_language'.l10n,
      ProfileTab.blocklist => 'label_blocked_users'.l10n,
      ProfileTab.devices => 'label_linked_devices'.l10n,
      ProfileTab.sections => 'label_show_sections'.l10n,
      ProfileTab.download => 'label_download'.l10n,
      ProfileTab.danger => 'label_danger_zone'.l10n,
      ProfileTab.legal => 'label_legal_info'.l10n,
      ProfileTab.styles => 'Styles'.l10n,
      ProfileTab.logout => 'btn_logout'.l10n,
    };

    final Widget title;

    if (context.isNarrow) {
      title = Row(
        children: [
          const SizedBox(width: 4),
          const StyledBackButton(),
          Material(
            elevation: 6,
            type: MaterialType.circle,
            shadowColor: style.colors.onBackgroundOpacity27,
            color: style.colors.onPrimary,
            child: Center(
              child: Obx(() {
                return AvatarWidget.fromMyUser(
                  c.myUser.value,
                  radius: AvatarRadius.medium,
                );
              }),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DefaultTextStyle.merge(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: Obx(() {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.myUser.value?.name?.val ??
                          c.myUser.value?.num.toString() ??
                          'dot'.l10n * 3,
                      style: style.fonts.large.regular.onBackground,
                    ),
                    // Text(section, style: style.fonts.small.regular.secondary),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(width: 10),
          WidgetButton(
            behavior: HitTestBehavior.translucent,
            onPressed: () => AccountsView.show(context),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Obx(() {
                if (c.accounts.length <= 1) {
                  return WidgetButton(
                    child: Text(
                      'Добавить\nаккаунт',
                      style: style.fonts.small.regular.primary,
                      textAlign: TextAlign.center,
                    ),
                  );
                } else {
                  return WidgetButton(
                    child: Text(
                      'Сменить\nаккаунт',
                      style: style.fonts.small.regular.primary,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
              }),
            ),
          ),
        ],
      );
    } else {
      title = Row(
        key: const Key('Profile'),
        children: [
          const SizedBox(width: 4),
          const StyledBackButton(),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
              child: Center(child: Text(section)),
            ),
          ),
          const SizedBox(width: 54),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: title,
          ),
        ),
        // const SizedBox(width: 52),
        // AnimatedButton(
        //   onPressed: () {},
        //   decorator: (child) => Padding(
        //     padding: const EdgeInsets.only(left: 31, right: 20),
        //     child: child,
        //   ),
        //   child: Text(
        //     'Редактировать',
        //     style: style.fonts.small.regular.primary,
        //   ),
        // ),
        // AnimatedButton(
        //   onPressed: () {},
        //   decorator: (child) => Padding(
        //     padding: const EdgeInsets.only(left: 31, right: 20),
        //     child: child,
        //   ),
        //   child: const SvgIcon(SvgIcons.menuProfile),
        // ),
        // searchButton,
      ],
    );
  });
}

/// Opens a confirmation popup deleting the provided [email] from the
/// [MyUser.emails].
Future<void> _deleteEmail(
  MyProfileController c,
  BuildContext context,
  UserEmail email,
) async {
  final style = Theme.of(context).style;

  final bool? result = await MessagePopup.alert(
    'label_delete_email'.l10n,
    description: [
      TextSpan(text: 'alert_email_will_be_deleted1'.l10n),
      TextSpan(text: email.val, style: style.fonts.normal.regular.onBackground),
      TextSpan(text: 'alert_email_will_be_deleted2'.l10n),
    ],
  );

  if (result == true) {
    await c.deleteEmail(email);
  }
}

/// Opens a confirmation popup deleting the provided [phone] from the
/// [MyUser.phones].
Future<void> _deletePhone(
  MyProfileController c,
  BuildContext context,
  UserPhone phone,
) async {
  final style = Theme.of(context).style;

  final bool? result = await MessagePopup.alert(
    'label_delete_phone_number'.l10n,
    description: [
      TextSpan(text: 'alert_phone_will_be_deleted1'.l10n),
      TextSpan(text: phone.val, style: style.fonts.normal.regular.onBackground),
      TextSpan(text: 'alert_phone_will_be_deleted2'.l10n),
    ],
  );

  if (result == true) {
    await c.deletePhone(phone);
  }
}

/// Opens a confirmation popup deleting the [MyUser]'s account.
Future<void> _deleteAccount(MyProfileController c, BuildContext context) async {
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const EraseView()),
  );
}

Future<void> _clearCache(MyProfileController c, BuildContext context) async {
  final style = Theme.of(context).style;

  final bool? result = await MessagePopup.alert(
    'Очистить все данные?'.l10n,
    description: [
      TextSpan(
        text:
            'Весь кэш, включая любые данные авторизации, будут очищены. Продолжить?'
                .l10n,
      ),
    ],
  );

  if (result == true) {
    final Future<String> future = c.logout();
    await Hive.clean('hive');
    router.go(await future);
  }
}

Future<void> _deleteSession(BuildContext context, Widget child) async {
  final bool? result = await MessagePopup.alert(
    'Удалить устройство'.l10n,
    additional: [child],
    // description: [

    //   // TextSpan(
    //   //   text:
    //   //       'Сессия будет завершена. На устройстве потребуется произвести повторный вход.'
    //   //           .l10n,
    //   // ),
    // ],
  );

  if (result == true) {
    // onHide?.call();
  }
}
