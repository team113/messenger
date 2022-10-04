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

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/api/backend/schema.dart' show Presence;
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/my_profile/view.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/copyable.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/dropdown.dart';
import 'package:messenger/ui/page/home/page/user/view.dart';
import 'package:messenger/ui/page/home/tab/menu/more/view.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';

import '/l10n/l10n.dart';
import '/routes.dart';
import 'controller.dart';

/// View of the `HomeTab.menu` tab.
class MenuTabView extends StatelessWidget {
  const MenuTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      key: const Key('MenuTab'),
      init: MenuTabController(Get.find(), Get.find(), Get.find()),
      builder: (MenuTabController c) {
        if (context.isNarrow) {
          return UserView(c.me!);
        }

        Widget button({
          Key? key,
          Widget? leading,
          required Widget title,
          void Function()? onTap,
        }) {
          Style style = Theme.of(context).extension<Style>()!;
          return Padding(
            key: key,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              height: 55,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: style.cardRadius,
                  border: style.cardBorder,
                  color: Colors.transparent,
                ),
                child: Material(
                  type: MaterialType.card,
                  borderRadius: style.cardRadius,
                  color: style.cardColor,
                  child: InkWell(
                    borderRadius: style.cardRadius,
                    onTap: onTap,
                    hoverColor: const Color.fromARGB(255, 244, 249, 255),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 9 + 3, 12, 9 + 3),
                      child: Row(
                        children: [
                          if (leading != null) ...[
                            const SizedBox(width: 12),
                            leading,
                            const SizedBox(width: 18),
                          ],
                          Expanded(
                            child: DefaultTextStyle(
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.headline5!,
                              child: title,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          // appBar: CustomAppBar.from(
          //   context: context,
          //   title: Text(
          //     'Your accounts'.l10n,
          //     style: Theme.of(context).textTheme.caption?.copyWith(
          //           color: Colors.black,
          //           fontWeight: FontWeight.w300,
          //           fontSize: 18,
          //         ),
          //   ),
          //   // leading: const [SizedBox(width: 30)],
          //   // actions: [
          //   //   WidgetButton(
          //   //     onPressed: () => MoreView.show(context),
          //   //     child: const Padding(
          //   //       padding: EdgeInsets.only(right: 16),
          //   //       child: Icon(Icons.settings, color: Color(0xFF63B4FF)),
          //   //     ),
          //   //   ),
          //   // ],
          // ),
          body: Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: Obx(() {
                  return ListView(
                    controller: ScrollController(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ContactTile(
                          darken: 0,
                          myUser: c.myUser.value,
                          onTap: () {
                            if (router.routes.length != 1) {
                              router.user(c.me!);
                            }
                          },
                          onBadgeTap: () => _displayPresence(context, c),
                          radius: 26 + 7,
                          subtitle: [
                            WidgetButton(
                              onPressed: () => _displayPresence(context, c),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  SizedBox(height: 5),
                                  Text(
                                    'В сети',
                                    style: TextStyle(color: Color(0xFF888888)),
                                  ),
                                ],
                              ),
                            )
                          ],
                          // trailing: [
                          //   Padding(
                          //     padding: const EdgeInsets.only(right: 8),
                          //     child: WidgetButton(
                          //       onPressed: () async {
                          //         if (await c.confirmLogout()) {
                          //           router.go(await c.logout());
                          //           router.tab = HomeTab.chats;
                          //         }
                          //       },
                          //       child: const Icon(
                          //         Icons.logout,
                          //         color: Color(0xFF63B4FF),
                          //         size: 28,
                          //       ),
                          //     ),
                          //   ),
                          // ],
                        ),
                      ),
                      // const SizedBox(height: 8),
                      // button(
                      //   key: const Key('AddAccountButton'),
                      //   leading: const Icon(
                      //     Icons.manage_accounts,
                      //     color: Color(0xFF63B4FF),
                      //   ),
                      //   title: Text('Add account'.l10n),
                      //   onTap: () {},
                      // ),

                      _name(c),
                      const SizedBox(height: 8),
                      _num(c),
                      const SizedBox(height: 8),
                      _presence(c),
                      const SizedBox(height: 8),
                      _link(context, c),
                      const SizedBox(height: 8),
                      _login(c),
                      const SizedBox(height: 8),
                      _phones(c, context),
                      const SizedBox(height: 8),
                      _emails(c, context),
                      const SizedBox(height: 8),
                      _password(context, c),
                      const SizedBox(height: 8),
                      _deleteAccount(c),
                      const SizedBox(height: 8),
                      button(
                        leading: const Icon(Icons.settings),
                        title: Text('Settings'.l10n),
                        onTap: () => router.settings(push: true),
                      ),
                      const SizedBox(height: 8),
                      button(
                        leading: const Icon(Icons.workspaces),
                        title: Text('Personalization'.l10n),
                        onTap: () => router.personalization(push: true),
                      ),
                      const SizedBox(height: 8),
                      button(
                        key: const Key('DownloadButton'),
                        leading: const Icon(
                          Icons.download,
                          color: Color(0xFF63B4FF),
                        ),
                        title: Text('Download application'.l10n),
                        onTap: router.download,
                      ),
                      const SizedBox(height: 8),
                      button(
                        title: Text('btn_logout'.l10n),
                        onTap: () async {
                          if (await c.confirmLogout()) {
                            router.go(await c.logout());
                            router.tab = HomeTab.chats;
                          }
                        },
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _displayPresence(BuildContext context, MenuTabController c) {
    ModalPopup.show(
      context: context,
      child: Builder(
        builder: (context) {
          return ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                tileColor: const Color(0xFFEEEEEE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: const CircleAvatar(backgroundColor: Colors.green),
                title: const Text('Online'),
                onTap: () {
                  c.setPresence(Presence.present);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                tileColor: const Color(0xFFEEEEEE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: const CircleAvatar(backgroundColor: Colors.orange),
                title: const Text('Away'),
                onTap: () {
                  c.setPresence(Presence.away);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                tileColor: const Color(0xFFEEEEEE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: const CircleAvatar(backgroundColor: Colors.grey),
                title: const Text('Hidden'),
                onTap: () {
                  c.setPresence(Presence.hidden);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
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

  /// Returns [MyUser.name] editable field.
  Widget _name(MenuTabController c) {
    return _padding(
      ReactiveTextField(
        key: const Key('NameField'),
        state: c.name,
        suffix: Icons.edit,
        label: 'label_name'.l10n,
        hint: 'label_name_hint'.l10n,
      ),
    );
  }

  /// Returns [MyUser.presence] dropdown.
  Widget _presence(MenuTabController c) => _padding(
        ReactiveDropdown<Presence>(
          key: const Key('PresenceDropdown'),
          state: c.presence,
          label: 'label_presence'.l10n,
        ),
      );

  /// Returns [MyUser.num] copyable field.
  Widget _num(MenuTabController c) => _padding(
        CopyableTextField(
          key: const Key('NumCopyable'),
          state: c.num,
          label: 'label_num'.l10n,
          copy: c.myUser.value?.num.val,
        ),
      );

  /// Returns [MyUser.chatDirectLink] editable field.
  Widget _link(BuildContext context, MenuTabController c) {
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
                    title:
                        Text('btn_delete_direct_chat_link'.l10n, style: thin),
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
                              onPressed:
                                  ExpandableController.of(context)?.toggle,
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
  Widget _login(MenuTabController c) => _padding(
        ReactiveTextField(
          key: const Key('LoginField'),
          state: c.login,
          suffix: Icons.edit,
          label: 'label_login'.l10n,
          hint: 'label_login_hint'.l10n,
        ),
      );

  /// Returns addable list of [MyUser.phones].
  Widget _phones(MenuTabController c, BuildContext context) => ExpandablePanel(
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
  Widget _emails(MenuTabController c, BuildContext context) => ExpandablePanel(
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
  Widget _password(BuildContext context, MenuTabController c) => Obx(
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

  /// Returns button to delete the account.
  Widget _deleteAccount(MenuTabController c) => ListTile(
        key: const Key('DeleteAccountButton'),
        leading: const Icon(Icons.delete, color: Colors.red),
        title: Text(
          'btn_delete_account'.l10n,
          style: const TextStyle(color: Colors.red),
        ),
        onTap: c.deleteAccount,
      );
}
