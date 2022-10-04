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

import 'dart:math';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '/api/backend/schema.dart';
import '/config.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/gallery.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';
import 'widget/copyable.dart';
import 'widget/dropdown.dart';

/// View of the [Routes.me] page.
class MyProfileView extends StatelessWidget {
  const MyProfileView({Key? key}) : super(key: key);

  /// Displays an [MyProfileView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(
      context: context,
      desktopConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      modalConstraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
      mobileConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      mobilePadding: const EdgeInsets.all(0),
      child: const MyProfileView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      key: const Key('MyProfileView'),
      init: MyProfileController(Get.find(), Get.find(), Get.find()),
      builder: (MyProfileController c) {
        return Obx(() {
          if (c.myUser.value == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          return GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 0,
                right: 0,
                top: 16,
                bottom: 16,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      children: [
                        LayoutBuilder(builder: (context, constraints) {
                          return WidgetButton(
                            onPressed: () async {
                              if (c.myUser.value?.avatar == null) {
                                await c.uploadAvatar();
                              } else {
                                await ModalPopup.show(
                                  context: context,
                                  modalConstraints:
                                      const BoxConstraints(maxWidth: 300),
                                  child: Builder(builder: (context) {
                                    return ListView(
                                      shrinkWrap: true,
                                      children: [
                                        OutlinedRoundedButton(
                                          title: const Text(
                                            'Change',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          color: const Color(0xFF63B4FF),
                                          onPressed: () {
                                            c.uploadAvatar();
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        OutlinedRoundedButton(
                                          color: const Color(0xFF63B4FF),
                                          title: const Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          onPressed: () {
                                            c.deleteAvatar();
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  }),
                                );
                              }
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AvatarWidget.fromMyUser(
                                  c.myUser.value,
                                  radius: 30,
                                  showBadge: false,
                                ),
                                Positioned.fill(
                                  child: Obx(() {
                                    return AnimatedSwitcher(
                                      duration: 200.milliseconds,
                                      child: c.avatarUpload.value.isLoading
                                          ? Container(
                                              width: 60,
                                              height: 60,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Color(0x22000000),
                                              ),
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                        _name(c),
                        const SizedBox(height: 10),
                        _num(c),
                        const SizedBox(height: 10),
                        _presence(c),
                        const SizedBox(height: 10),
                        _link(context, c),
                        const SizedBox(height: 15),
                        _login(c),
                        const SizedBox(height: 10),
                        _phones(c, context),
                        _emails(c, context),
                        _password(context, c),
                        _deleteAccount(c),
                        ListTile(
                          leading: const Icon(Icons.settings),
                          title: Text('Settings'.l10n),
                          onTap: () => router.settings(push: true),
                        ),
                        ListTile(
                          leading: const Icon(Icons.workspaces),
                          title: Text('Personalization'.l10n),
                          onTap: () => router.personalization(push: true),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedRoundedButton(
                            maxWidth: null,
                            title: Text(
                              'btn_logout'.l10n,
                              style: thin, //?.copyWith(color: Colors.white),
                            ),
                            onPressed: () async {
                              if (await c.confirmLogout()) {
                                router.go(await c.logout());
                                router.tab = HomeTab.chats;
                              }
                            },
                            color: const Color(0xFFEEEEEE),
                            // color: const Color(0xFF63B4FF),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedRoundedButton(
                            key: const Key('CloseButton'),
                            maxWidth: null,
                            title: Text('btn_close'.l10n, style: thin),
                            onPressed: Navigator.of(context).pop,
                            color: const Color(0xFFEEEEEE),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

/// Stylized wrapper around [TextButton].
Widget _textButton(
  BuildContext context, {
  Key? key,
  required String label,
  VoidCallback? onPressed,
}) =>
    TextButton(
      key: key,
      onPressed: onPressed,
      child: Text(
        label,
        style: context.textTheme.bodyText1!.copyWith(
          color: Colors.grey,
          fontSize: 16,
        ),
      ),
    );

/// Basic [Padding] wrapper.
Widget _padding(Widget child) =>
    Padding(padding: const EdgeInsets.all(8), child: child);

/// Dense [Padding] wrapper.
Widget _dense(Widget child) =>
    Padding(padding: const EdgeInsets.fromLTRB(8, 4, 8, 4), child: child);

/// Returns [CarouselGallery] of [MyUser.gallery].
Widget _gallery(MyProfileController c) {
  return DropTarget(
    onDragDone: (details) => c.dropFiles(details),
    onDragEntered: (_) => c.isDraggingFiles.value = true,
    onDragExited: (_) => c.isDraggingFiles.value = false,
    child: Obx(
      () => CarouselGallery(
        items: c.myUser.value?.gallery,
        index: c.galleryIndex.value,
        onChanged: (i) => c.galleryIndex.value = i,
        onCarouselController: (g) => c.galleryController = g,
        overlay: [
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6, right: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    key: const Key('AddGallery'),
                    mini: true,
                    onPressed: c.addGalleryStatus.value.isLoading
                        ? null
                        : c.pickGalleryItem,
                    child: ElasticAnimatedSwitcher(
                      child: c.addGalleryStatus.value.isLoading
                          ? const Icon(Icons.timer, key: ValueKey('Load'))
                          : c.addGalleryStatus.value.isSuccess
                              ? const Icon(
                                  Icons.check,
                                  key: ValueKey('Success'),
                                )
                              : const Icon(
                                  Icons.add,
                                  key: ValueKey('Empty'),
                                ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (c.myUser.value?.gallery?.isNotEmpty == true) ...[
                    FloatingActionButton(
                      key: const Key('DeleteGallery'),
                      mini: true,
                      onPressed: c.deleteGalleryStatus.value.isLoading
                          ? null
                          : c.deleteGalleryItem,
                      child: ElasticAnimatedSwitcher(
                        child: c.deleteGalleryStatus.value.isLoading
                            ? const Icon(Icons.timer, key: ValueKey('Load'))
                            : c.deleteGalleryStatus.value.isSuccess
                                ? const Icon(
                                    Icons.check,
                                    key: ValueKey('Success'),
                                  )
                                : const Icon(
                                    Icons.remove,
                                    key: ValueKey('Empty'),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FloatingActionButton(
                      key: const Key('AvatarStatus'),
                      mini: true,
                      onPressed: c.avatarStatus.value.isLoading
                          ? null
                          : c.isAvatar
                              ? c.deleteAvatar
                              : c.updateAvatar,
                      child: ElasticAnimatedSwitcher(
                        child: c.avatarStatus.value.isLoading
                            ? const Icon(Icons.timer, key: ValueKey('Load'))
                            : c.avatarStatus.value.isSuccess
                                ? const Icon(
                                    Icons.check,
                                    key: ValueKey('Success'),
                                  )
                                : c.isAvatar
                                    ? const Icon(
                                        Icons.cancel_outlined,
                                        key: ValueKey('Empty_delete'),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        key: ValueKey('Empty_apply'),
                                      ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: c.isDraggingFiles.value
                ? Container(
                    color: Colors.white.withOpacity(0.9),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.upload_file,
                            size: 30,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'label_drop_here'.l10n,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    ),
  );
}

/// Returns [MyUser.name] editable field.
Widget _name(MyProfileController c) {
  return _padding(
    ReactiveTextField(
      key: const Key('NameField'),
      state: c.name,
      // style: const TextStyle(fontSize: 20),
      suffix: Icons.edit,
      label: 'label_name'.l10n,
      hint: 'label_name_hint'.l10n,
    ),
  );
}

/// Returns [MyUser.bio] editable field.
Widget _bio(MyProfileController c) => _padding(
      ReactiveTextField(
        key: const Key('BioField'),
        state: c.bio,
        suffix: Icons.edit,
        label: 'label_biography'.l10n,
        hint: 'label_biography_hint'.l10n,
      ),
    );

/// Returns [MyUser.presence] dropdown.
Widget _presence(MyProfileController c) => _padding(
      ReactiveDropdown<Presence>(
        key: const Key('PresenceDropdown'),
        state: c.presence,
        label: 'label_presence'.l10n,
      ),
    );

/// Returns [MyUser.num] copyable field.
Widget _num(MyProfileController c) => _padding(
      CopyableTextField(
        key: const Key('NumCopyable'),
        state: c.num,
        label: 'label_num'.l10n,
        copy: c.myUser.value?.num.val,
      ),
    );

/// Returns [MyUser.chatDirectLink] editable field.
Widget _link(BuildContext context, MyProfileController c) {
  final TextStyle? thin =
      Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

  return _expanded(
    context,
    title: 'label_direct_chat_link'.l10n,
    child: WidgetButton(
      onPressed: c.myUser.value?.chatDirectLink == null ? null : c.copyLink,
      child: IgnorePointer(
        child: ReactiveTextField(
          key: const Key('DirectChatLinkTextField'),
          state: c.link,
          label: 'label_direct_chat_link'.l10n,
          suffix: Icons.expand_more,
          suffixColor: const Color(0xFF888888),
        ),
      ),
    ),
    expanded: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text('label_direct_chat_link_description'.l10n),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedRoundedButton(
                  maxWidth: null,
                  title: Text('btn_delete_direct_chat_link'.l10n, style: thin),
                  onPressed: c.link.editable.value ? c.deleteLink : null,
                  color: const Color(0xFFEEEEEE),
                  // color: const Color(0xFF63B4FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedRoundedButton(
                  key: const Key('CloseButton'),
                  maxWidth: null,
                  onPressed: c.link.editable.value
                      ? c.link.isEmpty.value
                          ? c.generateLink
                          : c.link.submit
                      : null,
                  title: Text(
                    c.link.isEmpty.value
                        ? 'btn_generate_direct_chat_link'.l10n
                        : 'btn_submit'.l10n,
                    style: thin,
                  ),
                  color: const Color(0xFFEEEEEE),
                ),
              )
            ],
          ),
          // Row(
          //   children: [
          //     Text(
          //       '${'label_transition_count'.l10n}: ${c.myUser.value?.chatDirectLink?.usageCount ?? 0}',
          //       textAlign: TextAlign.start,
          //     ),
          //     Expanded(
          //       child: Row(
          //         mainAxisAlignment: MainAxisAlignment.end,
          //         children: [
          //           if (c.myUser.value?.chatDirectLink != null &&
          //               !c.link.isEmpty.value)
          //             Flexible(
          //               child: _textButton(
          //                 context,
          //                 key: const Key('RemoveChatDirectLink'),
          //                 onPressed:
          //                     c.link.editable.value ? c.deleteLink : null,
          //                 label: 'btn_delete_direct_chat_link'.l10n,
          //               ),
          //             ),
          //           Flexible(
          //             child: _textButton(
          //               context,
          //               key: const Key('GenerateChatDirectLink'),
          //               onPressed: c.link.editable.value
          //                   ? c.link.isEmpty.value
          //                       ? c.generateLink
          //                       : c.link.submit
          //                   : null,
          //               label: c.link.isEmpty.value
          //                   ? 'btn_generate_direct_chat_link'.l10n
          //                   : 'btn_submit'.l10n,
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    ),
  );
}

Widget _expanded(
  BuildContext context, {
  Key? key,
  Widget? child,
  required Widget expanded,
  required String title,
}) {
  final TextStyle? thin =
      Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

  return _padding(
    ExpandableNotifier(
      child: Builder(
        builder: (context) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  child ?? Container(),
                  Positioned.fill(
                    child: Row(
                      children: [
                        const Expanded(flex: 4, child: SizedBox.shrink()),
                        Expanded(
                          flex: 1,
                          child: WidgetButton(
                            onPressed: ExpandableController.of(context)?.toggle,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // child ??
              //     Padding(
              //       padding: const EdgeInsets.symmetric(horizontal: 5),
              //       child: OutlinedRoundedButton(
              //         key: key,
              //         maxWidth: null,
              //         height: 50,
              //         title: Row(
              //           children: [
              //             const SizedBox(width: 10),
              //             Text(title, style: thin),
              //             const Spacer(),
              //             const Icon(
              //               Icons.expand_more,
              //               color: Color(0xFF888888),
              //             ),
              //             const SizedBox(width: 10),
              //           ],
              //         ),
              //         color: const Color(0xFFFFFFFF),
              //         onPressed: ExpandableController.of(context)?.toggle,
              //         border: Border.all(color: const Color(0xFF888888)),
              //         borderRadius: BorderRadius.circular(50),
              //       ),
              //     ),
              Expandable(
                controller:
                    ExpandableController.of(context, rebuildOnChange: false),
                collapsed: Container(),
                expanded: expanded,
              ),
            ],
          );
        },
      ),
    ),
  );
}

/// Returns [MyUser.login] editable field.
Widget _login(MyProfileController c) => _padding(
      ReactiveTextField(
        key: const Key('LoginField'),
        state: c.login,
        suffix: Icons.edit,
        label: 'label_login'.l10n,
        hint: 'label_login_hint'.l10n,
      ),
    );

/// Returns addable list of [MyUser.phones].
Widget _phones(MyProfileController c, BuildContext context) => ExpandablePanel(
      key: const Key('PhonesExpandable'),
      header: ListTile(
        leading: const Icon(Icons.phone),
        title: Text('label_phones'.l10n),
      ),
      collapsed: Container(),
      expanded: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Obx(
          () => Column(
            children: [
              ...c.myUser.value!.phones.confirmed.map(
                (e) => ListTile(
                  leading: const Icon(Icons.phone),
                  trailing: IconButton(
                    key: const Key('DeleteConfirmedPhone'),
                    onPressed: !c.phonesOnDeletion.contains(e)
                        ? () => c.deleteUserPhone(e)
                        : null,
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: Text(e.val),
                  dense: true,
                ),
              ),
              if (c.myUser.value?.phones.unconfirmed != null)
                ListTile(
                  leading: const Icon(Icons.phone),
                  trailing: IconButton(
                    onPressed: !c.phonesOnDeletion
                            .contains(c.myUser.value?.phones.unconfirmed)
                        ? () => c.deleteUserPhone(
                            c.myUser.value!.phones.unconfirmed!)
                        : null,
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: Text(c.myUser.value!.phones.unconfirmed!.val),
                  subtitle: Text('label_unconfirmed'.l10n),
                  dense: true,
                ),
              _dense(
                c.myUser.value?.phones.unconfirmed == null
                    ? ReactiveTextField(
                        key: const Key('PhoneInput'),
                        state: c.phone,
                        type: TextInputType.phone,
                        dense: true,
                        label: 'label_add_number'.l10n,
                        hint: 'label_add_number_hint'.l10n,
                      )
                    : ReactiveTextField(
                        key: const Key('PhoneCodeInput'),
                        state: c.phoneCode,
                        type: TextInputType.number,
                        dense: true,
                        label: 'label_enter_confirmation_code'.l10n,
                        hint: 'label_enter_confirmation_code_hint'.l10n,
                        onChanged: () => c.showPhoneCodeButton.value =
                            c.phoneCode.text.isNotEmpty,
                      ),
              ),
              if (c.myUser.value?.phones.unconfirmed == null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Spacer(),
                    _textButton(
                      context,
                      key: const Key('AddPhoneButton'),
                      onPressed: c.phone.submit,
                      label: 'btn_add'.l10n,
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              if (c.myUser.value?.phones.unconfirmed != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Spacer(),
                    c.showPhoneCodeButton.value
                        ? _textButton(
                            context,
                            key: const Key('ConfirmPhoneCodeButton'),
                            onPressed: c.phoneCode.submit,
                            label: 'btn_confirm'.l10n,
                          )
                        : _textButton(
                            context,
                            key: const Key('ResendPhoneCode'),
                            onPressed: c.resendPhoneTimeout.value == 0
                                ? c.resendPhone
                                : null,
                            label: c.resendPhoneTimeout.value == 0
                                ? 'btn_resend_code'.l10n
                                : '${'btn_resend_code'.l10n} (${c.resendPhoneTimeout.value})',
                          ),
                    const SizedBox(width: 12),
                  ],
                ),
            ],
          ),
        ),
      ),
    );

/// Returns addable list of [MyUser.emails].
Widget _emails(MyProfileController c, BuildContext context) => ExpandablePanel(
      key: const Key('EmailsExpandable'),
      header: ListTile(
        leading: const Icon(Icons.email),
        title: Text('label_emails'.l10n),
      ),
      collapsed: Container(),
      expanded: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Obx(
          () => Column(
            children: [
              ...c.myUser.value!.emails.confirmed.map(
                (e) => ListTile(
                  leading: const Icon(Icons.email),
                  trailing: IconButton(
                    key: const Key('DeleteConfirmedEmail'),
                    onPressed: (!c.emailsOnDeletion.contains(e))
                        ? () => c.deleteUserEmail(e)
                        : null,
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: Text(e.val),
                  dense: true,
                ),
              ),
              if (c.myUser.value?.emails.unconfirmed != null)
                ListTile(
                  leading: const Icon(Icons.email),
                  trailing: IconButton(
                    onPressed: !c.emailsOnDeletion
                            .contains(c.myUser.value?.emails.unconfirmed)
                        ? () => c.deleteUserEmail(
                            c.myUser.value!.emails.unconfirmed!)
                        : null,
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: Text(c.myUser.value!.emails.unconfirmed!.val),
                  subtitle: Text('label_unconfirmed'.l10n),
                  dense: true,
                ),
              _dense(
                c.myUser.value?.emails.unconfirmed == null
                    ? ReactiveTextField(
                        key: const Key('EmailInput'),
                        state: c.email,
                        type: TextInputType.emailAddress,
                        dense: true,
                        label: 'label_add_email'.l10n,
                        hint: 'label_add_email_hint'.l10n,
                      )
                    : ReactiveTextField(
                        key: const Key('EmailCodeInput'),
                        state: c.emailCode,
                        type: TextInputType.number,
                        dense: true,
                        label: 'label_enter_confirmation_code'.l10n,
                        hint: 'label_enter_confirmation_code_hint'.l10n,
                        onChanged: () => c.showEmailCodeButton.value =
                            c.emailCode.text.isNotEmpty,
                      ),
              ),
              if (c.myUser.value?.emails.unconfirmed == null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Spacer(),
                    _textButton(
                      context,
                      key: const Key('addEmailButton'),
                      onPressed: c.email.submit,
                      label: 'btn_add'.l10n,
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              if (c.myUser.value?.emails.unconfirmed != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Spacer(),
                    c.showEmailCodeButton.value
                        ? _textButton(
                            context,
                            key: const Key('ConfirmEmailCode'),
                            onPressed: c.emailCode.submit,
                            label: 'btn_confirm'.l10n,
                          )
                        : _textButton(
                            context,
                            key: const Key('ResendEmailCode'),
                            onPressed: c.resendEmailTimeout.value == 0
                                ? c.resendEmail
                                : null,
                            label: c.resendEmailTimeout.value == 0
                                ? 'btn_resend_code'.l10n
                                : '${'btn_resend_code'.l10n} (${c.resendEmailTimeout.value})',
                          ),
                    const SizedBox(width: 12),
                  ],
                )
            ],
          ),
        ),
      ),
    );

/// Returns editable fields of [MyUser.password].
Widget _password(BuildContext context, MyProfileController c) => Obx(
      () => ExpandablePanel(
        key: const Key('PasswordExpandable'),
        header: ListTile(
          leading: const Icon(Icons.password),
          title: Text('label_password'.l10n),
        ),
        collapsed: Container(),
        expanded: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              if (c.myUser.value!.hasPassword)
                _dense(
                  ReactiveTextField(
                    key: const Key('CurrentPasswordField'),
                    state: c.oldPassword,
                    label: 'label_current_password'.l10n,
                    obscure: true,
                  ),
                ),
              _dense(
                ReactiveTextField(
                  key: const Key('NewPasswordField'),
                  state: c.newPassword,
                  label: 'label_new_password'.l10n,
                  obscure: true,
                ),
              ),
              _dense(
                ReactiveTextField(
                  key: const Key('RepeatPasswordField'),
                  state: c.repeatPassword,
                  label: 'label_repeat_password'.l10n,
                  obscure: true,
                ),
              ),
              ListTile(
                title: ElevatedButton(
                  key: const Key('ChangePasswordButton'),
                  onPressed: c.changePassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: context.theme.colorScheme.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'btn_change_password'.l10n,
                    style: TextStyle(
                      fontSize: 20,
                      color: context.theme.colorScheme.background,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

/// Returns button to go to monolog chat.
Widget _monolog(MyProfileController c) => ListTile(
      key: const Key('MonologButton'),
      leading: const Icon(Icons.message),
      title: Text('btn_saved_messages'.l10n),
      onTap: () => throw UnimplementedError(),
    );

/// Returns button to delete the account.
Widget _deleteAccount(MyProfileController c) => ListTile(
      key: const Key('DeleteAccountButton'),
      leading: const Icon(Icons.delete, color: Colors.red),
      title: Text(
        'btn_delete_account'.l10n,
        style: const TextStyle(color: Colors.red),
      ),
      onTap: c.deleteAccount,
    );
