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

import 'dart:math';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:collection/collection.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:messenger/domain/model/application_settings.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/ui/page/call/widget/fit_view.dart';
import 'package:messenger/ui/page/home/page/chat/get_paid/controller.dart';
import 'package:messenger/ui/page/home/page/chat/get_paid/view.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_gallery.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';
import 'package:messenger/ui/page/home/page/user/widget/contact_info.dart';
import 'package:messenger/ui/page/home/page/user/widget/copy_or_share.dart';
import 'package:messenger/ui/page/home/widget/rectangle_button.dart';
import 'package:messenger/ui/page/login/controller.dart';
import 'package:messenger/ui/page/login/qr_code/view.dart';
import 'package:messenger/ui/widget/animated_button.dart';
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
import 'media_buttons_switch/view.dart';
import 'microphone_switch/view.dart';
import 'output_switch/view.dart';
import 'paid_list/view.dart';
import 'password/view.dart';
import 'timeline_switch/view.dart';
import 'welcome_message/view.dart';
import 'widget/background_preview.dart';
import 'widget/login.dart';
import 'widget/name.dart';
import 'widget/status.dart';

/// View of the [Routes.me] page.
class MyProfileView extends StatelessWidget {
  const MyProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      key: const Key('MyProfileView'),
      init: MyProfileController(Get.find(), Get.find(), Get.find()),
      global: !Get.isRegistered<MyProfileController>(),
      builder: (MyProfileController c) {
        return GestureDetector(
          onTap: FocusManager.instance.primaryFocus?.unfocus,
          child: Scaffold(
            appBar: CustomAppBar(
              title: Text('label_account'.l10n),
              padding: const EdgeInsets.only(left: 4, right: 20),
              leading: const [StyledBackButton()],
              actions: [
                AnimatedButton(
                  onPressed: () {},
                  child: const SvgIcon(SvgIcons.search),
                ),
              ],
            ),
            body: Scrollbar(
              controller: c.scrollController,
              child: ScrollablePositionedList.builder(
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
                      return block(
                        title: 'label_profile'.l10n,
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
                          const SizedBox(height: 12),
                          Paddings.basic(
                            Obx(() {
                              return UserNameField(
                                c.myUser.value?.name,
                                onSubmit: c.updateUserName,
                              );
                            }),
                          ),
                          Paddings.basic(
                            Obx(() {
                              return UserTextStatusField(
                                c.myUser.value?.status,
                                onSubmit: c.updateUserStatus,
                              );
                            }),
                          ),
                          // _presence(context, c),
                        ],
                      );

                    case ProfileTab.signing:
                      return block(
                        title: 'label_login_options'.l10n,
                        children: [
                          // Paddings.basic(
                          //   Obx(() {
                          //     return UserNumCopyable(c.myUser.value?.num);
                          //   }),
                          // ),
                          Paddings.basic(
                            Obx(() {
                              return ContactInfoContents(
                                padding: EdgeInsets.zero,
                                title: 'Gapopa ID',
                                content: c.myUser.value?.num.toString() ?? '',
                                trailing: CopyOrShareButton(
                                  c.myUser.value?.num.toString() ?? '',
                                ),
                                // trailing: WidgetButton(
                                //   onPressed: () {},
                                //   child: const SvgIcon(SvgIcons.copy),
                                // ),
                              );
                            }),
                          ),

                          Obx(() {
                            if (c.myUser.value?.login == null) {
                              return const SizedBox();
                            }

                            return Paddings.basic(
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: ContactInfoContents(
                                  padding: EdgeInsets.zero,
                                  title: 'Login',
                                  content: c.myUser.value!.login.toString(),
                                  trailing: WidgetButton(
                                    onPressed: () {},
                                    child: const SvgIcon(SvgIcons.delete),
                                  ),
                                  // subtitle: [
                                  //   const SizedBox(height: 4),
                                  //   RichText(
                                  //     text: TextSpan(
                                  //       children: [
                                  //         TextSpan(
                                  //           text: 'label_login_visible'.l10n,
                                  //           style: style
                                  //               .fonts.small.regular.secondary,
                                  //         ),
                                  //         TextSpan(
                                  //           text: 'label_nobody'
                                  //                   .l10n
                                  //                   .toLowerCase() +
                                  //               'dot'.l10n,
                                  //           style: style
                                  //               .fonts.small.regular.primary,
                                  //           recognizer: TapGestureRecognizer()
                                  //             ..onTap = () async {
                                  //               await ConfirmDialog.show(
                                  //                 context,
                                  //                 title: 'label_login'.l10n,
                                  //                 additional: [
                                  //                   Center(
                                  //                     child: Text(
                                  //                       'label_login_visibility_hint'
                                  //                           .l10n,
                                  //                       style: style
                                  //                           .fonts
                                  //                           .normal
                                  //                           .regular
                                  //                           .secondary,
                                  //                     ),
                                  //                   ),
                                  //                   const SizedBox(height: 20),
                                  //                   Align(
                                  //                     alignment:
                                  //                         Alignment.centerLeft,
                                  //                     child: Text(
                                  //                       'label_visible_to'.l10n,
                                  //                       style: style
                                  //                           .fonts
                                  //                           .big
                                  //                           .regular
                                  //                           .onBackground,
                                  //                     ),
                                  //                   ),
                                  //                 ],
                                  //                 label: 'label_confirm'.l10n,
                                  //                 initial: 2,
                                  //                 variants: [
                                  //                   ConfirmDialogVariant(
                                  //                     onProceed: () {},
                                  //                     label: 'label_all'.l10n,
                                  //                   ),
                                  //                   ConfirmDialogVariant(
                                  //                     onProceed: () {},
                                  //                     label: 'label_my_contacts'
                                  //                         .l10n,
                                  //                   ),
                                  //                   ConfirmDialogVariant(
                                  //                     onProceed: () {},
                                  //                     label:
                                  //                         'label_nobody'.l10n,
                                  //                   ),
                                  //                 ],
                                  //               );
                                  //             },
                                  //         ),
                                  //       ],
                                  //     ),
                                  //   ),
                                  // ],
                                ),
                              ),
                            );
                          }),

                          // const SizedBox(height: 8),
                          // const SizedBox(height: 8),
                          const SizedBox(height: 8),
                          // Paddings.basic(
                          //   Obx(() {
                          //     return UserLoginField(
                          //       c.myUser.value?.login,
                          //       onSubmit: c.updateUserLogin,
                          //     );
                          //   }),
                          // ),
                          // const SizedBox(height: 8),
                          // const SizedBox(height: 8),
                          // Paddings.basic(
                          //   Obx(() {
                          //     return UserNumCopyable(c.myUser.value?.num);
                          //   }),
                          // ),

                          // const SizedBox(height: 12),

                          _emails(context, c),
                          // Obx(() {
                          //   final hasEmails = [
                          //     ...c.myUser.value?.emails.confirmed ?? [],
                          //     c.myUser.value?.emails.unconfirmed,
                          //     ...c.emails,
                          //   ].whereNotNull().isNotEmpty;

                          //   final hasPhones = [
                          //     ...c.myUser.value?.phones.confirmed ?? [],
                          //     c.myUser.value?.phones.unconfirmed,
                          //     ...c.phones,
                          //   ].whereNotNull().isNotEmpty;

                          //   return SizedBox(
                          //     height: hasPhones || hasEmails ? 54 : 0,
                          //   );
                          // }),
                          _phones(context, c),
                          _providers(context, c),
                          // _password(context, c),
                          _addInfo(context, c),
                        ],
                      );

                    case ProfileTab.link:
                      return block(
                        title: 'label_your_direct_link'.l10n,
                        children: [
                          Obx(() {
                            return DirectLinkField(
                              c.myUser.value?.chatDirectLink,
                              onSubmit: (s) => s == null
                                  ? c.deleteChatDirectLink()
                                  : c.createChatDirectLink(s),
                              background: c.background.value,
                            );
                          }),
                        ],
                      );

                    case ProfileTab.background:
                      return block(
                        title: 'label_background'.l10n,
                        children: [
                          Paddings.dense(
                            Obx(() {
                              return BackgroundPreview(
                                c.background.value,
                                onPick: c.pickBackground,
                                onRemove: c.removeBackground,
                              );
                            }),
                          )
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
                        title: 'label_calls'.l10n,
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

                    case ProfileTab.getPaid:
                      return Stack(
                        children: [
                          block(
                            title: 'label_get_paid_for_incoming'.l10n,
                            children: [_getPaid(context, c)],
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

                    case ProfileTab.donates:
                      return Stack(
                        children: [
                          block(
                            title: 'label_donates'.l10n,
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

                    case ProfileTab.vacancies:
                      return block(
                        title: 'label_show_sections'.l10n,
                        children: [_workWithUs(context, c)],
                      );

                    case ProfileTab.styles:
                      return const SizedBox();

                    case ProfileTab.logout:
                      return const SizedBox();
                  }
                },
              ),
            ),
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
        ContactInfoContents(
          padding: EdgeInsets.zero,
          content: e.val,
          title: 'E-mail',
          trailing: WidgetButton(
            onPressed: () => _deleteEmail(c, context, e),
            child: const SvgIcon(SvgIcons.delete),
          ),
          // subtitle: [
          //   const SizedBox(height: 4),
          //   RichText(
          //     text: TextSpan(
          //       children: [
          //         TextSpan(
          //           text: 'label_email_visible'.l10n,
          //           style: style.fonts.small.regular.secondary,
          //         ),
          //         TextSpan(
          //           text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
          //           style: style.fonts.small.regular.primary,
          //           recognizer: TapGestureRecognizer()
          //             ..onTap = () async {
          //               await ConfirmDialog.show(
          //                 context,
          //                 title: 'label_email'.l10n,
          //                 label: 'label_confirm'.l10n,
          //                 initial: 2,
          //                 variants: [
          //                   ConfirmDialogVariant(
          //                     onProceed: () {},
          //                     label: 'label_all'.l10n,
          //                   ),
          //                   ConfirmDialogVariant(
          //                     onProceed: () {},
          //                     label: 'label_my_contacts'.l10n,
          //                   ),
          //                   ConfirmDialogVariant(
          //                     onProceed: () {},
          //                     label: 'label_nobody'.l10n,
          //                   ),
          //                 ],
          //               );
          //             },
          //         ),
          //       ],
          //     ),
          //   ),
          // ],
        ),

        // ReactiveTextField(
        //   state: TextFieldState(text: e.val),
        //   readOnly: true,
        //   label: 'E-mail',
        //   trailing: AnimatedButton(
        //     key: const Key('DeleteEmail'),
        //     onPressed: () => _deleteEmail(c, context, e),
        //     child: const SvgIcon(SvgIcons.delete),
        //   ),
        //   subtitle: RichText(
        //     text: TextSpan(
        //       children: [
        //         TextSpan(
        //           text: 'label_email_visible'.l10n,
        //           style: style.fonts.small.regular.secondary,
        //         ),
        //         TextSpan(
        //           text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
        //           style: style.fonts.small.regular.primary,
        //           recognizer: TapGestureRecognizer()
        //             ..onTap = () async {
        //               await ConfirmDialog.show(
        //                 context,
        //                 title: 'label_login'.l10n,
        //                 additional: [
        //                   Center(
        //                     child: Text(
        //                       'label_login_visibility_hint'.l10n,
        //                       style: style.fonts.normal.regular.secondary,
        //                     ),
        //                   ),
        //                   const SizedBox(height: 20),
        //                   Align(
        //                     alignment: Alignment.centerLeft,
        //                     child: Text(
        //                       'label_visible_to'.l10n,
        //                       style: style.fonts.big.regular.onBackground,
        //                     ),
        //                   ),
        //                 ],
        //                 label: 'label_confirm'.l10n,
        //                 initial: 2,
        //                 variants: [
        //                   ConfirmDialogVariant(
        //                     onProceed: () {},
        //                     label: 'label_all'.l10n,
        //                   ),
        //                   ConfirmDialogVariant(
        //                     onProceed: () {},
        //                     label: 'label_my_contacts'.l10n,
        //                   ),
        //                   ConfirmDialogVariant(
        //                     onProceed: () {},
        //                     label: 'label_nobody'.l10n,
        //                   ),
        //                 ],
        //               );
        //             },
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
      );

      widgets.add(const SizedBox(height: 8));
    }

    final unconfirmed = c.myUser.value?.emails.unconfirmed ??
        c.emails.firstWhereOrNull((e) => e.val.startsWith('unverified'));
    //??  UserEmail('unconfirmed@example.com');

    if (unconfirmed != null) {
      widgets.add(
        ContactInfoContents(
          padding: EdgeInsets.zero,
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
      // widgets.addAll([
      //   Theme(
      //     data: Theme.of(context).copyWith(
      //       inputDecorationTheme:
      //           Theme.of(context).inputDecorationTheme.copyWith(
      //                 floatingLabelStyle:
      //                     style.fonts.big.regular.onBackground.copyWith(
      //                   color: style.colors.danger,
      //                 ),
      //               ),
      //     ),
      //     child: ReactiveTextField(
      //       state: TextFieldState(text: unconfirmed.val),
      //       readOnly: true,
      //       label: 'E-mail не верифицирован',
      //       trailing: AnimatedButton(
      //         key: const Key('DeleteEmail'),
      //         onPressed: () => _deleteEmail(c, context, unconfirmed),
      //         child: const SvgIcon(SvgIcons.delete),
      //       ),
      //       subtitle: WidgetButton(
      //         onPressed: () => AddEmailView.show(context, email: unconfirmed),
      //         child: Text(
      //           'Верифицировать.',
      //           style: style.fonts.small.regular.primary,
      //         ),
      //       ),
      //     ),
      //   ),
      // ]);
      widgets.add(const SizedBox(height: 8));
    }

    // if (unconfirmed == null) {
    //   widgets.add(
    //     ReactiveTextField(
    //       state: c.email,
    //       label: 'Добавить E-mail',
    //       floatingLabelBehavior: FloatingLabelBehavior.always,
    //       hint: 'example@dummy.com',
    //     ),
    //   );
    //   widgets.add(const SizedBox(height: 8));
    // }

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
        ContactInfoContents(
          padding: EdgeInsets.zero,
          content: e.val,
          title: 'label_phone'.l10n,
          trailing: WidgetButton(
            onPressed: () => _deletePhone(c, context, e),
            child: const SvgIcon(SvgIcons.delete),
          ),
          // subtitle: [
          //   const SizedBox(height: 4),
          //   RichText(
          //     text: TextSpan(
          //       children: [
          //         TextSpan(
          //           text: 'label_phone_visible'.l10n,
          //           style: style.fonts.small.regular.secondary,
          //         ),
          //         TextSpan(
          //           text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
          //           style: style.fonts.small.regular.primary,
          //           recognizer: TapGestureRecognizer()
          //             ..onTap = () async {
          //               await ConfirmDialog.show(
          //                 context,
          //                 title: 'label_phone'.l10n,
          //                 label: 'label_confirm'.l10n,
          //                 initial: 2,
          //                 variants: [
          //                   ConfirmDialogVariant(
          //                     onProceed: () {},
          //                     label: 'label_all'.l10n,
          //                   ),
          //                   ConfirmDialogVariant(
          //                     onProceed: () {},
          //                     label: 'label_my_contacts'.l10n,
          //                   ),
          //                   ConfirmDialogVariant(
          //                     onProceed: () {},
          //                     label: 'label_nobody'.l10n,
          //                   ),
          //                 ],
          //               );
          //             },
          //         ),
          //       ],
          //     ),
          //   ),
          // ],
        ),
      );
      // widgets.add(
      //   ReactiveTextField(
      //     state: TextFieldState(text: e.val),
      //     readOnly: true,
      //     label: 'Phone',
      //     trailing: AnimatedButton(
      //       key: const Key('DeleteEmail'),
      //       onPressed: () => _deletePhone(c, context, e),
      //       child: const SvgIcon(SvgIcons.delete),
      //     ),
      //     subtitle: RichText(
      //       text: TextSpan(
      //         children: [
      //           TextSpan(
      //             text: 'label_login_visible'.l10n,
      //             style: style.fonts.small.regular.secondary,
      //           ),
      //           TextSpan(
      //             text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
      //             style: style.fonts.small.regular.primary,
      //             recognizer: TapGestureRecognizer()
      //               ..onTap = () async {
      //                 await ConfirmDialog.show(
      //                   context,
      //                   title: 'label_login'.l10n,
      //                   additional: [
      //                     Center(
      //                       child: Text(
      //                         'label_login_visibility_hint'.l10n,
      //                         style: style.fonts.normal.regular.secondary,
      //                       ),
      //                     ),
      //                     const SizedBox(height: 20),
      //                     Align(
      //                       alignment: Alignment.centerLeft,
      //                       child: Text(
      //                         'label_visible_to'.l10n,
      //                         style: style.fonts.big.regular.onBackground,
      //                       ),
      //                     ),
      //                   ],
      //                   label: 'label_confirm'.l10n,
      //                   initial: 2,
      //                   variants: [
      //                     ConfirmDialogVariant(
      //                       onProceed: () {},
      //                       label: 'label_all'.l10n,
      //                     ),
      //                     ConfirmDialogVariant(
      //                       onProceed: () {},
      //                       label: 'label_my_contacts'.l10n,
      //                     ),
      //                     ConfirmDialogVariant(
      //                       onProceed: () {},
      //                       label: 'label_nobody'.l10n,
      //                     ),
      //                   ],
      //                 );
      //               },
      //           ),
      //         ],
      //       ),
      //     ),
      //   ),
      // );
      widgets.add(const SizedBox(height: 8));
    }

    final unconfirmed = c.myUser.value?.phones.unconfirmed ??
        c.phones.firstWhereOrNull((e) => e.val.startsWith('+0'));

    if (unconfirmed != null) {
      widgets.add(
        ContactInfoContents(
          padding: EdgeInsets.zero,
          content: unconfirmed.val,
          title: 'Телефон не верифицирован',
          trailing: WidgetButton(
            onPressed: () => _deletePhone(c, context, unconfirmed),
            child: const SvgIcon(SvgIcons.delete),
          ),
          subtitle: [
            const SizedBox(height: 4),
            WidgetButton(
              onPressed: () => AddPhoneView.show(context, phone: unconfirmed),
              child: Text(
                'Верифицировать',
                style: style.fonts.small.regular.primary,
              ),
            ),
          ],
          danger: true,
        ),
      );
      // widgets.addAll([
      //   Theme(
      //     data: Theme.of(context).copyWith(
      //       inputDecorationTheme:
      //           Theme.of(context).inputDecorationTheme.copyWith(
      //                 floatingLabelStyle:
      //                     style.fonts.big.regular.onBackground.copyWith(
      //                   color: style.colors.danger,
      //                 ),
      //               ),
      //     ),
      //     child: ReactiveTextField(
      //       state: TextFieldState(text: unconfirmed.val),
      //       readOnly: true,
      //       label: 'Телефон не верифицирован',
      //       trailing: AnimatedButton(
      //         key: const Key('DeleteEmail'),
      //         onPressed: () => _deletePhone(c, context, unconfirmed),
      //         child: const SvgIcon(SvgIcons.delete),
      //       ),
      //       subtitle: AnimatedButton(
      //         onPressed: () => AddPhoneView.show(context, phone: unconfirmed),
      //         child: Text(
      //           'Верифицировать',
      //           style: style.fonts.small.regular.primary,
      //         ),
      //       ),
      //     ),
      //   ),
      // ]);
      widgets.add(const SizedBox(height: 8));
    }

    // if (unconfirmed == null) {
    //   widgets.add(
    //     ReactivePhoneField(
    //       state: c.phone,
    //       label: 'Добавить телефон',
    //       // floatingLabelBehavior: FloatingLabelBehavior.always,
    //       // hint: '+1 234 567 89 90',
    //     ),
    //     // ReactiveTextField(
    //     //   state: c.phone,
    //     //   label: 'Добавить телефон',
    //     //   floatingLabelBehavior: FloatingLabelBehavior.always,
    //     //   hint: '+1 234 567 89 90',
    //     // ),
    //   );
    //   widgets.add(const SizedBox(height: 8));
    // }

    // if (widgets.length <= 1) {
    //   widgets.add(const SizedBox(height: 0));
    // } else {
    //   // widgets.insert(0, const SizedBox(height: 24));
    //   widgets.add(const SizedBox(height: 48));
    // }

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
        ContactInfoContents(
          padding: EdgeInsets.zero,
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

/// Returns [WidgetButton] displaying the [MyUser.presence].
Widget _presence(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Obx(() {
    final Presence? presence = c.myUser.value?.presence;

    return Paddings.basic(
      FieldButton(
        onPressed: () => StatusView.show(context, expanded: false),
        hint: 'label_presence'.l10n,
        text: presence?.localizedString(),
        trailing:
            CircleAvatar(backgroundColor: presence?.getColor(), radius: 7),
        style: style.fonts.normal.regular.primary,
      ),
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
            onSubmit: c.updateUserLogin,
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
            // WidgetButton(
            //   onPressed: c.expanded.toggle,
            //   child: Text(
            //     c.expanded.value ? 'Скрыть' : 'Ещё',
            //     style: style.fonts.small.regular.primary,
            //   ),
            // ),
          ],
        );
      }),

      // ReactivePhoneField(
      //   state: c.phone,
      //   label: 'Добавить телефон',
      // ),
      // const SizedBox(height: 24),
      // ReactiveTextField(
      //   state: c.email,
      //   label: 'Добавить E-mail',
      //   floatingLabelBehavior: FloatingLabelBehavior.always,
      //   hint: 'example@dummy.com',
      // ),

      // Paddings.dense(
      //   FieldButton(
      //     text: 'Добавить E-mail, телефон, Google, Apple или GitHub',
      //     maxLines: 3,
      //     onPressed: () => ChangePasswordView.show(context),
      //     style: style.fonts.normal.regular.primary,
      //     trailing: const SvgIcon(SvgIcons.addMember),
      //   ),
      // ),
      // const SizedBox(height: 10),
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
          // trailing: Transform.translate(
          //   offset: const Offset(0, -1),
          //   child: const SvgIcon(SvgIcons.delete),
          // ),
          onPressed: () => _deleteAccount(c, context),
          danger: true,
          style: style.fonts.normal.regular.danger,
        ),
      ),
    ],
  );
}

/// Returns the contents of a [ProfileTab.danger] section.
Widget _workWithUs(BuildContext context, MyProfileController c) {
  // final style = Theme.of(context).style;

  return Column(
    children: [
      Paddings.dense(
        Obx(() {
          final enabled = c.settings.value?.balanceTabEnabled == true;

          return SwitchField(
            text: 'label_balance'.l10n,
            value: enabled,
            onChanged: c.setBalanceTabEnabled,
          );
        }),
      ),
      Paddings.dense(
        Obx(() {
          final enabled = c.settings.value?.partnerTabEnabled == true;

          return SwitchField(
            text: 'btn_work_with_us'.l10n,
            value: enabled,
            onChanged: c.setPartnerTabEnabled,
          );
        }),
      ),
      Paddings.dense(
        Obx(() {
          final enabled = c.settings.value?.publicsTabEnabled == true;

          return SwitchField(
            text: 'label_publics'.l10n,
            value: enabled,
            onChanged: c.setPublicsTabEnabled,
          );
        }),
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
      if (PlatformUtils.isDesktop && PlatformUtils.isWeb) ...[
        Paddings.dense(
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 21.0),
              child: Text(
                'label_open_calls_in'.l10n,
                style: style.systemMessageStyle.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
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
        const SizedBox(height: 16),
      ],
      // Paddings.dense(
      //   Stack(
      //     alignment: Alignment.centerRight,
      //     children: [
      //       IgnorePointer(
      //         child: ReactiveTextField(
      //           maxLines: null,
      //           state: TextFieldState(
      //             text: 'label_leave_group_call_when_alone'.l10n,
      //             editable: false,
      //           ),
      //           trailing: const SizedBox(width: 40),
      //           trailingWidth: 40,
      //         ),
      //       ),
      //       Align(
      //         alignment: Alignment.centerRight,
      //         child: Padding(
      //           padding: const EdgeInsets.only(right: 5),
      //           child: Transform.scale(
      //             scale: 0.7,
      //             transformHitTests: false,
      //             child: Theme(
      //               data: ThemeData(platform: TargetPlatform.macOS),
      //               child: Obx(
      //                 () => Switch.adaptive(
      //                   activeColor: Theme.of(context).colorScheme.primary,
      //                   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      //                   value: c.settings.value?.leaveWhenAlone == true,
      //                   onChanged: c.setLeaveWhenAlone,
      //                 ),
      //               ),
      //             ),
      //           ),
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    ],
  );
}

/// Returns the contents of a [ProfileTab.chats] section.
Widget _chats(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Paddings.dense(
      //   Align(
      //     alignment: Alignment.centerLeft,
      //     child: Padding(
      //       padding: const EdgeInsets.only(left: 21.0),
      //       child: Text(
      //         'label_display_timestamps'.l10n,
      //         style: style.systemMessageStyle.copyWith(
      //           color: style.colors.secondary,
      //           fontSize: 15,
      //           fontWeight: FontWeight.w400,
      //         ),
      //       ),
      //     ),
      //   ),
      // ),
      // const SizedBox(height: 4),
      // Paddings.dense(
      //   Obx(() {
      //     return FieldButton(
      //       text: (c.settings.value?.timelineEnabled ?? true)
      //           ? 'label_as_timeline'.l10n
      //           : 'label_in_message'.l10n,
      //       maxLines: null,
      //       onPressed: () => TimelineSwitchView.show(context),
      //       style: style.fonts.normal.regular.primary,
      //     );
      //   }),
      // ),
      // const SizedBox(height: 16),
      Paddings.dense(
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 21.0),
            child: Text(
              'Отображать кнопки аудио и видео звонка'.l10n,
              style: style.systemMessageStyle.copyWith(
                color: style.colors.secondary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Paddings.dense(
        Obx(() {
          return FieldButton(
            text: switch (c.settings.value?.mediaButtonsPosition) {
              MediaButtonsPosition.appBar =>
                'label_media_buttons_in_app_bar'.l10n,
              MediaButtonsPosition.contextMenu =>
                'label_media_buttons_in_context_menu'.l10n,
              MediaButtonsPosition.top => 'label_media_buttons_in_top'.l10n,
              MediaButtonsPosition.bottom =>
                'label_media_buttons_in_bottom'.l10n,
              MediaButtonsPosition.more => 'label_media_buttons_in_more'.l10n,
              null => 'В верхней панели',
            },
            maxLines: null,
            onPressed: () => MediaButtonsSwitchView.show(context),
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
          return FieldButton(
            text: (c.devices.video().firstWhereOrNull((e) =>
                            e.deviceId() == c.media.value?.videoDevice) ??
                        c.devices.video().firstOrNull)
                    ?.label() ??
                'label_media_no_device_available'.l10n,
            hint: 'label_media_camera'.l10n,
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
          return FieldButton(
            text: (c.devices.audio().firstWhereOrNull((e) =>
                            e.deviceId() == c.media.value?.audioDevice) ??
                        c.devices.audio().firstOrNull)
                    ?.label() ??
                'label_media_no_device_available'.l10n,
            hint: 'label_media_microphone'.l10n,
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
            return FieldButton(
              text: (c.devices.output().firstWhereOrNull((e) =>
                              e.deviceId() == c.media.value?.outputDevice) ??
                          c.devices.output().firstOrNull)
                      ?.label() ??
                  'label_media_no_device_available'.l10n,
              hint: 'label_media_output'.l10n,
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
          // expandText: 'label_show_more'.l10n,
          // collapseText: 'label_show_less'.l10n,
          // maxLines: 2,
          style: style.fonts.small.regular.secondary,
        ),
      ),
      // Text(
      //   'label_welcome_message_description'.l10n,
      //   style: style.fonts.small.regular.secondary,
      // ),

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

          // Positioned.fill(
          //   child: Container(
          //     width: double.infinity,
          //     height: double.infinity,
          //     decoration: BoxDecoration(
          //       color: style.unreadMessageColor,
          //       borderRadius: style.cardRadius,
          //       // borderRadius: BorderRadius.only(
          //       //   bottomRight: style.cardRadius.bottomRight,
          //       //   bottomLeft: style.cardRadius.bottomLeft,
          //       // ),
          //     ),
          //   ),
          // ),
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

Widget _title(BuildContext context, String label, [bool enabled = true]) {
  final style = Theme.of(context).style;

  return Padding(
    padding: Insets.dense.copyWith(left: 0, right: 0),
    child: Row(
      children: [
        const SizedBox(width: 0),
        Expanded(
          child: Container(
            width: double.infinity,
            height: 1,
            color: Colors.transparent,
          ),
        ),
        // const SizedBox(width: 8),
        // Text(
        //   label,
        //   textAlign: TextAlign.center,
        //   style: style.systemMessageStyle.copyWith(
        //     // color: Theme.of(context).colorScheme.secondary,
        //     color: enabled ? style.colors.onBackground : style.colors.secondary,
        //     fontSize: 15,

        //     fontWeight: FontWeight.w400,
        //   ),
        // ),
        // const SizedBox(width: 8),
        Expanded(
          child: Container(
            width: double.infinity,
            height: 1,
            color: Colors.transparent,
          ),
        ),
        const SizedBox(width: 0),
      ],
    ),
  );
}

Widget _getPaid(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  Widget title(String label) {
    final style = Theme.of(context).style;

    return Paddings.dense(
      Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.only(left: 0.0),
          child: Text(
            label,
            style: style.systemMessageStyle.copyWith(
              color: style.colors.secondary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  return Column(
    children: [
      title(
        'От всех пользователей (кроме Ваших контактов и индивидуальных пользователей)',
      ),
      const SizedBox(height: 8),
      Paddings.basic(
        ReactiveTextField(
          state: c.allMessageCost,
          style: style.fonts.medium.regular.onBackground,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          formatters: [FilteringTextInputFormatter.digitsOnly],
          hint: '0',
          prefix: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 1, 0),
            child: Transform.translate(
              offset: PlatformUtils.isWeb
                  ? const Offset(0, -0)
                  : const Offset(0, -0.5),
              child: Text(
                '¤',
                style: style.fonts.medium.regular.onBackground,
              ),
            ),
          ),
          label: 'Входящие сообщения, за 1 сообщение',
        ),
      ),
      Paddings.basic(
        ReactiveTextField(
          state: c.allCallCost,
          style: style.fonts.medium.regular.onBackground,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          formatters: [FilteringTextInputFormatter.digitsOnly],
          hint: '0',
          prefix: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 1, 0),
            child: Transform.translate(
              offset: PlatformUtils.isWeb
                  ? const Offset(0, -0)
                  : const Offset(0, -0.5),
              child: Text(
                '¤',
                style: style.fonts.medium.regular.onBackground,
              ),
            ),
          ),
          label: 'Входящие звонки, за 1 минуту',
        ),
      ),
      const SizedBox(height: 24),
      title('От Ваших контактов'),
      const SizedBox(height: 8),
      Paddings.basic(
        ReactiveTextField(
          state: c.contactMessageCost,
          style: style.fonts.medium.regular.onBackground,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          formatters: [FilteringTextInputFormatter.digitsOnly],
          hint: '0',
          prefix: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 1, 0),
            child: Transform.translate(
              offset: PlatformUtils.isWeb
                  ? const Offset(0, -0)
                  : const Offset(0, -0.5),
              child: Text(
                '¤',
                style: style.fonts.medium.regular.onBackground,
              ),
            ),
          ),
          label: 'Входящие сообщения, за 1 сообщение',
        ),
      ),
      Paddings.basic(
        ReactiveTextField(
          state: c.contactCallCost,
          style: style.fonts.medium.regular.onBackground,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          formatters: [FilteringTextInputFormatter.digitsOnly],
          hint: '0',
          prefix: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 1, 0),
            child: Transform.translate(
              offset: PlatformUtils.isWeb
                  ? const Offset(0, -0)
                  : const Offset(0, -0.5),
              child: Text(
                '¤',
                style: style.fonts.medium.regular.onBackground,
              ),
            ),
          ),
          label: 'Входящие звонки, за 1 минуту',
        ),
      ),
      const SizedBox(height: 24),
      title('От индивидуальных пользователей'),
      const SizedBox(height: 8),
      Paddings.dense(
        FieldButton(
          text: 'label_users_of'.l10n,
          onPressed:
              !c.verified.value ? null : () => PaidListView.show(context),
          trailing: Text(
            '0',
            style: style.fonts.medium.regular.onBackground.copyWith(
              fontSize: 15,
              color: !c.verified.value
                  ? style.colors.secondary
                  : style.colors.onBackground,
            ),
          ),
          style: TextStyle(
            color: !c.verified.value
                ? style.colors.secondary
                : style.colors.onBackground,
          ),
        ),
      ),
      Opacity(opacity: 0, child: _verification(context, c)),
    ],
  );

  Widget field({
    required TextFieldState state,
    required String label,
    bool contacts = false,
    bool enabled = true,
  }) {
    return Paddings.basic(
      Stack(
        alignment: Alignment.centerLeft,
        children: [
          FieldButton(
            text: state.text,
            prefixText: '    ',
            prefixStyle: const TextStyle(fontSize: 13),
            label: label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            onPressed: () async {
              await GetPaidView.show(
                context,
                mode: contacts ? GetPaidMode.contacts : GetPaidMode.users,
              );
            },
            style: TextStyle(
              color: enabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 21, bottom: 3),
            child: Text(
              ' ¤',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: enabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  return Obx(() {
    return Column(
      children: [
        if (!c.verified.value) ...[],
        _title(
          context,
          'От всех пользователей (кроме Ваших контактов и индивидуальных пользователей)',
          c.verified.value,
        ),
        const SizedBox(height: 6),
        field(
          label: 'label_fee_per_incoming_message'.l10n,
          state: c.allMessageCost,
          enabled: c.verified.value,
          contacts: false,
        ),
        field(
          label: 'label_fee_per_incoming_call_minute'.l10n,
          state: c.allCallCost,
          enabled: c.verified.value,
          contacts: false,
        ),
        const SizedBox(height: 12 * 2),
        _title(context, 'От Ваших контактов', c.verified.value),
        const SizedBox(height: 6),
        field(
          label: 'label_fee_per_incoming_message'.l10n,
          state: c.contactMessageCost,
          enabled: c.verified.value,
          contacts: true,
        ),
        field(
          label: 'label_fee_per_incoming_call_minute'.l10n,
          state: c.contactCallCost,
          enabled: c.verified.value,
          contacts: true,
        ),
        const SizedBox(height: 12 * 2),
        _title(context, 'От индивидуальных пользователей', c.verified.value),
        const SizedBox(height: 6),
        Paddings.dense(
          FieldButton(
            text: 'label_users_of'.l10n,
            onPressed:
                !c.verified.value ? null : () => PaidListView.show(context),
            trailing: Text(
              '0',
              style: style.fonts.medium.regular.onBackground.copyWith(
                fontSize: 15,
                color: !c.verified.value
                    ? style.colors.secondary
                    : style.colors.onBackground,
              ),
            ),
            style: TextStyle(
              color: !c.verified.value
                  ? style.colors.secondary
                  : style.colors.onBackground,
            ),
          ),
        ),
        Opacity(opacity: 0, child: _verification(context, c)),
      ],
    );
  });
}

Widget _donates(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  // Widget title(String label, [bool enabled = true]) {
  //   return Paddings.dense(
  //     Align(
  //       alignment: Alignment.center,
  //       child: Padding(
  //         padding: const EdgeInsets.only(left: 0.0),
  //         child: Text(
  //           label,
  //           textAlign: TextAlign.center,
  //           style: style.systemMessageStyle.copyWith(
  //             // color: Theme.of(context).colorScheme.secondary,
  //             color:
  //                 enabled ? style.colors.onBackground : style.colors.secondary,
  //             fontSize: 15,

  //             fontWeight: FontWeight.w400,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget field({
    required TextFieldState state,
    required String label,
    bool contacts = false,
    bool enabled = true,
  }) {
    return Paddings.basic(
      Stack(
        alignment: Alignment.centerLeft,
        children: [
          ReactiveTextField(
            state: state,
            prefixText: '    ',
            prefixStyle: const TextStyle(fontSize: 13),
            label: label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            style: TextStyle(
              color: enabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 21, bottom: 3),
            child: Text(
              ' ¤',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color:
                    enabled ? style.colors.onBackground : style.colors.primary,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  return Obx(() {
    return Column(
      children: [
        // title(
        //   'От всех пользователей (кроме Ваших контактов и индивидуальных пользователей)',
        //   c.verified.value,
        // ),
        // field(
        //   label: 'Минимальная сумма подарка'.l10n,
        //   state: c.contactMessageCost,
        //   enabled: c.verified.value,
        //   contacts: true,
        // ),
        Paddings.basic(
          ReactiveTextField(
            state: c.donateCost,
            style: style.fonts.medium.regular.onBackground,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            hint: '0',
            prefix: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 1, 0),
              child: Transform.translate(
                offset: PlatformUtils.isWeb
                    ? const Offset(0, -0)
                    : const Offset(0, -0.5),
                child: Text(
                  '¤',
                  style: style.fonts.medium.regular.onBackground,
                ),
              ),
            ),
            label: 'Минимальная сумма подарка',
          ),
        ),
        Paddings.basic(
          ReactiveTextField(
            key: const Key('StatusField'),
            state: TextFieldState(text: '0'),
            formatters: [FilteringTextInputFormatter.digitsOnly],
            label: 'Максимальная длина сообщения'.l10n,
            filled: true,
            style: TextStyle(
              color: c.verified.value
                  ? style.colors.onBackground
                  : style.colors.primary,
            ),
          ),
        ),

        Opacity(opacity: 0, child: _verification(context, c)),
      ],
    );
  });
}

/// Returns the contents of a [ProfileTab.notifications] section.
Widget _notifications(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Obx(() {
    return Paddings.dense(
      Stack(
        alignment: Alignment.centerRight,
        children: [
          IgnorePointer(
            child: ReactiveTextField(
              state: TextFieldState(
                text: (c.myUser.value?.muted == null
                        ? 'label_enabled'
                        : 'label_disabled')
                    .l10n,
                editable: false,
              ),
              style: style.fonts.normal.regular.onBackground
                  .copyWith(color: style.colors.secondary),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Transform.scale(
                scale: 0.7,
                transformHitTests: false,
                child: Theme(
                  data: ThemeData(
                    platform: TargetPlatform.macOS,
                  ),
                  child: Switch.adaptive(
                    activeColor: style.colors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: c.myUser.value?.muted == null,
                    onChanged: c.isMuting.value ? null : c.toggleMute,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}

/// Returns the contents of a [ProfileTab.download] section.
Widget _downloads(BuildContext context, MyProfileController c) {
  return Paddings.dense(
    const Column(
      children: [
        DownloadButton(
          asset: SvgIcons.windows,
          title: 'Windows',
          link: 'messenger-windows.zip',
        ),
        SizedBox(height: 8),
        DownloadButton(
          asset: SvgIcons.apple,
          title: 'macOS',
          link: 'messenger-macos.zip',
        ),
        SizedBox(height: 8),
        DownloadButton(
          asset: SvgIcons.linux,
          title: 'Linux',
          link: 'messenger-linux.zip',
        ),
        SizedBox(height: 8),
        DownloadButton(
          asset: SvgIcons.apple,
          title: 'iOS',
          link: 'messenger-ios.zip',
        ),
        SizedBox(height: 8),
        DownloadButton(
          asset: SvgIcons.googlePlay,
          title: 'Android',
          link: 'messenger-android.apk',
        ),
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
    final int count = c.myUser.value?.blocklistCount ?? 0;

    return Paddings.dense(
      FieldButton(
        key: const Key('ShowBlocklist'),
        text: 'label_users_count'.l10nfmt({'count': count}),
        onPressed: count == 0 ? null : () => BlocklistView.show(context),
        style: count == 0
            ? style.fonts.normal.regular.onBackground
            : style.fonts.normal.regular.primary,
      ),
    );
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

  final gbs = CacheWorker.instance.info.value.maxSize.toDouble() / GB;
  var index = values.indexWhere((e) => gbs < e);
  if (index == -1) {
    index = values.length - 1;
  }

  final v = (index / (values.length - 1) * 100).round();
  print('$gbs $index $v');

  return Paddings.dense(
    Column(
      children: [
        if (true || !PlatformUtils.isWeb) ...[
          Column(
            children: [
              Obx(() {
                final int size = CacheWorker.instance.info.value.size;
                final int max = CacheWorker.instance.info.value.maxSize;

                if (max >= 64 * GB) {
                  return Text(
                    'Занято ${(size / GB).toPrecision(2)} ГБ',
                  );
                } else if (max <= 0) {
                  return const Text('Занято 0 ГБ');
                }

                return Text(
                  'Занято ${(size / GB).toPrecision(2)} из ${max ~/ GB} ГБ',
                );
              }),

              Container(
                color: Colors.transparent,
                height: 100,
                child: FlutterSlider(
                  handlerHeight: 24,
                  handler: FlutterSliderHandler(),
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
                      color: Colors.black12,
                      // border: Border.all(width: 3, color: Colors.blue),
                    ),
                    activeTrackBar: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.blue.withOpacity(1),
                    ),
                  ),
                  onDragging: (i, lower, upper) {
                    if (lower is double) {
                      if (lower == 64.0 * GB) {
                        // TODO:  CacheWorker.instance.setMaxSize(null);
                        CacheWorker.instance.setMaxSize(lower.round());
                      } else {
                        CacheWorker.instance.setMaxSize(lower.round());
                      }
                    }
                  },
                  onDragCompleted: (i, lower, upper) {
                    if (lower is double) {
                      if (lower == 64.0 * GB) {
                        // TODO:  CacheWorker.instance.setMaxSize(null);
                        CacheWorker.instance.setMaxSize(lower.round());
                      } else {
                        CacheWorker.instance.setMaxSize(lower.round());
                      }
                    }
                  },
                  hatchMark: FlutterSliderHatchMark(
                    labelsDistanceFromTrackBar: -48,
                    // displayLines: true,

                    linesAlignment: FlutterSliderHatchMarkAlignment.right,
                    density: 0.5, // means 50 lines, from 0 to 100 percent
                    labels: [
                      FlutterSliderHatchMarkLabel(
                        percent: 0,
                        label: Text(
                          'Выкл',
                          style: style.fonts.smallest.regular.secondary,
                        ),
                      ),
                      FlutterSliderHatchMarkLabel(
                        percent: 16,
                        label: Text(
                          '2 ГБ',
                          style: style.fonts.smallest.regular.secondary,
                        ),
                      ),
                      FlutterSliderHatchMarkLabel(
                        percent: 32,
                        label: Text(
                          '4 ГБ',
                          style: style.fonts.smallest.regular.secondary,
                        ),
                      ),
                      FlutterSliderHatchMarkLabel(
                        percent: 48,
                        label: Text(
                          '8 ГБ',
                          style: style.fonts.smallest.regular.secondary,
                        ),
                      ),
                      FlutterSliderHatchMarkLabel(
                        percent: 64,
                        label: Text(
                          '16 ГБ',
                          style: style.fonts.smallest.regular.secondary,
                        ),
                      ),
                      FlutterSliderHatchMarkLabel(
                        percent: 80,
                        label: Text(
                          '32 ГБ',
                          style: style.fonts.smallest.regular.secondary,
                        ),
                      ),
                      FlutterSliderHatchMarkLabel(
                        percent: 100,
                        label: Text(
                          'No Limit',
                          style: style.fonts.smallest.regular.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // SizedBox(
              //   height: 120,
              //   width: 300,
              //   child: SfSlider(
              //     min: 0.0,
              //     max: 128 * GB,
              //     value: max,
              //     labelFormatterCallback: (i, s) {
              //       if (i == 128 * GB) {
              //         return 'No Limit';
              //       }

              //       return '${i / GB} ГБ';
              //     },
              //     interval: 20,
              //     showTicks: true,
              //     showLabels: true,
              //     enableTooltip: true,
              //     minorTicksPerInterval: 1,
              //     onChanged: (v) => CacheWorker.instance.setMaxSize(v),
              //   ),
              // ),
              // Stack(
              //   alignment: Alignment.center,
              //   children: [
              //     LinearProgressIndicator(
              //       value: size / max,
              //       minHeight: 32,
              //       color: style.colors.primary,
              //       backgroundColor: style.colors.background,
              //     ),
              //     Text(
              //       'label_gb_slash_gb'.l10nfmt({
              //         'a': (size / GB).toPrecision(2),
              //         'b': max ~/ GB,
              //       }),
              //       style: style.fonts.smaller.regular.onBackground,
              //     ),
              //   ],
              // ),
              const SizedBox(height: 8),
              FieldButton(
                onPressed: c.clearCache,
                text: 'btn_clear_cache'.l10n,
                style: style.fonts.normal.regular.primary,
              ),
            ],
          ),
        ],
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
      child: ContactInfoContents(
        padding: EdgeInsets.zero,
        title:
            '${thisDevice ? 'Это устройство' : activeAt == null ? 'Онлайн' : activeAt.toRelative()}, $location',
        content: name,
        trailing: thisDevice
            ? null
            : WidgetButton(
                onPressed: () => _deleteSession(
                  context,
                  ContactInfoContents(
                    padding: EdgeInsets.zero,
                    title:
                        '${thisDevice ? 'Это устройство' : activeAt == null ? 'Онлайн' : activeAt.toRelative()}, $location',
                    content: name,
                  ),
                ),
                child: const SvgIcon(SvgIcons.delete),
              ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: style.cardBorder,
        borderRadius: style.cardRadius,
      ),
      child: Row(
        children: [
          // Container(
          //   width: 32,
          //   height: 32,
          //   decoration: BoxDecoration(
          //     borderRadius: BorderRadius.circular(8),
          //     // color: Colors.blue,
          //   ),
          //   child: Center(child: icon),
          // ),
          // const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: style.fonts.medium.regular.onBackground),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(location, style: style.fonts.small.regular.secondary),
                    const Spacer(),
                    const SizedBox(width: 4),
                    Text(
                      activeAt == null ? 'Active' : activeAt.toRelative(),
                      style: style.fonts.small.regular.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
              'Добавить устройство',
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
        const SizedBox(height: 24),
        // const SizedBox(height: 8),
        // Paddings.dense(
        //   Align(
        //     alignment: Alignment.center,
        //     child: Padding(
        //       padding: const EdgeInsets.only(left: 21.0),
        //       child: Text(
        //         'Добавить устройство'.l10n,
        //         style: style.fonts.big.regular.onBackground,
        //       ),
        //     ),
        //   ),
        // ),
        // const SizedBox(height: 12),
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
  final style = Theme.of(context).style;

  final bool? result = await MessagePopup.alert(
    'label_delete_account'.l10n,
    description: [
      TextSpan(text: 'alert_account_will_be_deleted1'.l10n),
      TextSpan(
        text: c.myUser.value?.name?.val ??
            c.myUser.value?.login?.val ??
            c.myUser.value?.num.toString() ??
            'dot'.l10n * 3,
        style: style.fonts.normal.regular.onBackground,
      ),
      TextSpan(text: 'alert_account_will_be_deleted2'.l10n),
    ],
  );

  if (result == true) {
    await c.deleteAccount();
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
