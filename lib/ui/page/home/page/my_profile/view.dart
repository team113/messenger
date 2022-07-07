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

import 'package:desktop_drop/desktop_drop.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  @override
  Widget build(BuildContext context) => GetBuilder(
        key: const Key('MyProfileView'),
        init: MyProfileController(Get.find()),
        builder: (MyProfileController c) {
          return Obx(
            () => c.myUser.value != null
                ? GestureDetector(
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                    child: Scaffold(
                      body: CustomScrollView(
                        key: const Key('MyProfileScrollable'),
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          /// App bar with gallery.
                          SliverAppBar(
                            elevation: 0,
                            pinned: true,
                            stretch: true,
                            backgroundColor:
                                context.theme.scaffoldBackgroundColor,
                            leading: IconButton(
                              onPressed: router.pop,
                              icon: const Icon(Icons.arrow_back),
                            ),
                            expandedHeight:
                                MediaQuery.of(context).size.height * 0.6,
                            flexibleSpace:
                                FlexibleSpaceBar(background: _gallery(c)),
                          ),

                          /// Main content of this page.
                          SliverList(
                            delegate: SliverChildListDelegate.fixed(
                              [
                                Align(
                                  alignment: Alignment.center,
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 450),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 10),
                                        _name(c),
                                        _bio(c),
                                        const Divider(thickness: 2),
                                        _presence(c),
                                        _num(c),
                                        _link(context, c),
                                        const Divider(thickness: 2),
                                        _login(c),
                                        _phones(c, context),
                                        _emails(c, context),
                                        _password(context, c),
                                        const Divider(thickness: 2),
                                        _monolog(c),
                                        const Divider(thickness: 2),
                                        _deleteAccount(c),
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
                    ),
                  )
                : Scaffold(
                    appBar: AppBar(),
                    body: const Center(child: CircularProgressIndicator()),
                  ),
          );
        },
      );
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
                            'label_drop_here'.td,
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
Widget _name(MyProfileController c) => Obx(
      () => _padding(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarWidget.fromMyUser(c.myUser.value, radius: 29),
            const SizedBox(width: 10),
            Expanded(
              child: ReactiveTextField(
                key: const Key('NameField'),
                state: c.name,
                style: const TextStyle(fontSize: 20),
                suffix: Icons.edit,
                label: 'label_name'.td,
                hint: 'label_name_hint'.td,
              ),
            )
          ],
        ),
      ),
    );

/// Returns [MyUser.bio] editable field.
Widget _bio(MyProfileController c) => _padding(
      ReactiveTextField(
        key: const Key('BioField'),
        state: c.bio,
        suffix: Icons.edit,
        label: 'label_biography'.td,
        hint: 'label_biography_hint'.td,
      ),
    );

/// Returns [MyUser.presence] dropdown.
Widget _presence(MyProfileController c) => _padding(
      ReactiveDropdown<Presence>(
        key: const Key('PresenceDropdown'),
        icon: Icons.info,
        state: c.presence,
        label: 'label_presence'.td,
      ),
    );

/// Returns [MyUser.num] copyable field.
Widget _num(MyProfileController c) => _padding(
      CopyableTextField(
        key: const Key('NumCopyable'),
        state: c.num,
        icon: Icons.person,
        label: 'label_num'.td,
        copy: c.myUser.value?.num.val,
      ),
    );

/// Returns [MyUser.chatDirectLink] editable field.
Widget _link(BuildContext context, MyProfileController c) => Obx(
      () => ExpandablePanel(
        key: const Key('ChatDirectLinkExpandable'),
        header: ListTile(
          leading: const Icon(Icons.link),
          title: Text('label_direct_chat_link'.td),
        ),
        collapsed: Container(),
        expanded: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('label_direct_chat_link_description'.td),
              const SizedBox(height: 10),
              _padding(
                ReactiveTextField(
                  key: const Key('DirectChatLinkTextField'),
                  state: c.link,
                  prefixText: '${Config.origin}${Routes.chatDirectLink}/',
                  label: 'label_direct_chat_link'.td,
                  suffix: Icons.copy,
                  onSuffixPressed: c.myUser.value?.chatDirectLink == null
                      ? null
                      : c.copyLink,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${'label_transition_count'.td}: ${c.myUser.value?.chatDirectLink?.usageCount ?? 0}',
                    textAlign: TextAlign.start,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (c.myUser.value?.chatDirectLink != null &&
                            !c.link.isEmpty.value)
                          Flexible(
                            child: _textButton(
                              context,
                              key: const Key('RemoveChatDirectLink'),
                              onPressed:
                                  c.link.editable.value ? c.deleteLink : null,
                              label: 'btn_delete_direct_chat_link'.td,
                            ),
                          ),
                        Flexible(
                          child: _textButton(
                            context,
                            key: const Key('GenerateChatDirectLink'),
                            onPressed: c.link.editable.value
                                ? c.link.isEmpty.value
                                    ? c.generateLink
                                    : c.link.submit
                                : null,
                            label: c.link.isEmpty.value
                                ? 'btn_generate_direct_chat_link'.td
                                : 'btn_submit'.td,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

/// Returns [MyUser.login] editable field.
Widget _login(MyProfileController c) => _padding(
      ReactiveTextField(
        key: const Key('LoginField'),
        icon: Icons.person,
        state: c.login,
        suffix: Icons.edit,
        label: 'label_login'.td,
        hint: 'label_login_hint'.td,
      ),
    );

/// Returns addable list of [MyUser.phones].
Widget _phones(MyProfileController c, BuildContext context) => ExpandablePanel(
      key: const Key('PhonesExpandable'),
      header: ListTile(
        leading: const Icon(Icons.phone),
        title: Text('label_phones'.td),
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
                  subtitle: Text('label_unconfirmed'.td),
                  dense: true,
                ),
              _dense(
                c.myUser.value?.phones.unconfirmed == null
                    ? ReactiveTextField(
                        key: const Key('PhoneInput'),
                        icon: Icons.add,
                        state: c.phone,
                        type: TextInputType.phone,
                        dense: true,
                        label: 'label_add_number'.td,
                        hint: 'label_add_number_hint'.td,
                      )
                    : ReactiveTextField(
                        key: const Key('PhoneCodeInput'),
                        icon: Icons.add,
                        state: c.phoneCode,
                        type: TextInputType.number,
                        dense: true,
                        label: 'label_enter_confirmation_code'.td,
                        hint: 'label_enter_confirmation_code_hint'.td,
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
                      label: 'btn_add'.td,
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
                            label: 'btn_confirm'.td,
                          )
                        : _textButton(
                            context,
                            key: const Key('ResendPhoneCode'),
                            onPressed: c.resendPhoneTimeout.value == 0
                                ? c.resendPhone
                                : null,
                            label: c.resendPhoneTimeout.value == 0
                                ? 'btn_resend_code'.td
                                : '${'btn_resend_code'.td} (${c.resendPhoneTimeout.value})',
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
        title: Text('label_emails'.td),
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
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
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
                  subtitle: Text('label_unconfirmed'.td),
                  dense: true,
                ),
              _dense(
                c.myUser.value?.emails.unconfirmed == null
                    ? ReactiveTextField(
                        key: const Key('EmailInput'),
                        icon: Icons.add,
                        state: c.email,
                        type: TextInputType.emailAddress,
                        dense: true,
                        label: 'label_add_email'.td,
                        hint: 'label_add_email_hint'.td,
                      )
                    : ReactiveTextField(
                        key: const Key('EmailCodeInput'),
                        icon: Icons.add,
                        state: c.emailCode,
                        type: TextInputType.number,
                        dense: true,
                        label: 'label_enter_confirmation_code'.td,
                        hint: 'label_enter_confirmation_code_hint'.td,
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
                      label: 'btn_add'.td,
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
                            label: 'btn_confirm'.td,
                          )
                        : _textButton(
                            context,
                            key: const Key('ResendEmailCode'),
                            onPressed: c.resendEmailTimeout.value == 0
                                ? c.resendEmail
                                : null,
                            label: c.resendEmailTimeout.value == 0
                                ? 'btn_resend_code'.td
                                : '${'btn_resend_code'.td} (${c.resendEmailTimeout.value})',
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
          title: Text('label_password'.td),
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
                    label: 'label_current_password'.td,
                    obscure: true,
                  ),
                ),
              _dense(
                ReactiveTextField(
                  key: const Key('NewPasswordField'),
                  state: c.newPassword,
                  label: 'label_new_password'.td,
                  obscure: true,
                ),
              ),
              _dense(
                ReactiveTextField(
                  key: const Key('RepeatPasswordField'),
                  state: c.repeatPassword,
                  label: 'label_repeat_password'.td,
                  obscure: true,
                ),
              ),
              ListTile(
                title: ElevatedButton(
                  key: const Key('ChangePasswordButton'),
                  onPressed: c.changePassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    primary: context.theme.colorScheme.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'btn_change_password'.td,
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
      title: Text('btn_saved_messages'.td),
      onTap: () => throw UnimplementedError(),
    );

/// Returns button to delete the account.
Widget _deleteAccount(MyProfileController c) => ListTile(
      key: const Key('DeleteAccountButton'),
      leading: const Icon(Icons.delete, color: Colors.red),
      title: Text(
        'btn_delete_account'.td,
        style: const TextStyle(color: Colors.red),
      ),
      onTap: c.deleteAccount,
    );
