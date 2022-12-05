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
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';
import 'package:messenger/api/backend/schema.dart' show Presence;
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/page/my_profile/view.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/copyable.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/dropdown.dart';
import 'package:messenger/ui/page/home/page/user/view.dart';
import 'package:messenger/ui/page/home/tab/menu/more/view.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/selector.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';

import '/l10n/l10n.dart';
import '/routes.dart';
import 'accounts/view.dart';
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
        final Style style = Theme.of(context).extension<Style>()!;

        Widget bigButton({
          Key? key,
          Widget? leading,
          required Widget title,
          required Widget subtitle,
          void Function()? onTap,
        }) {
          return Padding(
            key: key,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              height: 73,
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
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Row(
                        children: [
                          if (leading != null) ...[
                            const SizedBox(width: 12),
                            leading,
                            const SizedBox(width: 18),
                          ],
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DefaultTextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.headline5!,
                                  child: title,
                                ),
                                const SizedBox(height: 6),
                                DefaultTextStyle.merge(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  child: subtitle,
                                ),
                              ],
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

        void Function()? onBack =
            context.isNarrow && ModalRoute.of(context)?.canPop == true
                ? Navigator.of(context).pop
                : null;

        return Scaffold(
          appBar: CustomAppBar(
            title: (true || context.isNarrow)
                ? Row(
                    children: [
                      Material(
                        elevation: 6,
                        type: MaterialType.circle,
                        shadowColor: const Color(0x55000000),
                        color: Colors.white,
                        child: InkWell(
                          onTap: onBack,
                          customBorder: const CircleBorder(),
                          child: Center(
                            child: Obx(() {
                              return Stack(
                                children: [
                                  AvatarWidget.fromMyUser(
                                    onAvatarTap: c.uploadAvatar,
                                    c.myUser.value,
                                    radius: 17,
                                    showBadge: false,
                                  ),
                                  Positioned.fill(
                                    child: Obx(() {
                                      final Widget child;

                                      if (c.avatarUpload.value.isLoading) {
                                        child = Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                Colors.black.withOpacity(0.3),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      } else {
                                        child = const SizedBox();
                                      }

                                      return AnimatedSwitcher(
                                        duration: 200.milliseconds,
                                        child: child,
                                      );
                                    }),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: WidgetButton(
                          onPressed: () async {
                            await Selector.menu(
                              context,
                              actions: [
                                ContextMenuButton(
                                  label: 'Online',
                                  onPressed: () =>
                                      c.setPresence(Presence.present),
                                  leading: const CircleAvatar(
                                    radius: 8,
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                                ContextMenuButton(
                                  label: 'Away',
                                  onPressed: () => c.setPresence(Presence.away),
                                  leading: const CircleAvatar(
                                    radius: 8,
                                    backgroundColor: Colors.orange,
                                  ),
                                ),
                                ContextMenuButton(
                                  label: 'Hidden',
                                  onPressed: () =>
                                      c.setPresence(Presence.hidden),
                                  leading: const CircleAvatar(
                                    radius: 8,
                                    backgroundColor: Colors.grey,
                                  ),
                                ),
                              ],
                            );
                          },
                          child: DefaultTextStyle.merge(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.myUser.value?.name?.val ??
                                      c.myUser.value?.num.val ??
                                      '...',
                                  style: const TextStyle(color: Colors.black),
                                ),
                                Row(
                                  key: c.profileKey,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Obx(() {
                                      final String status;

                                      switch (c.myUser.value?.presence) {
                                        case Presence.hidden:
                                          status = 'Hidden';
                                          break;

                                        case Presence.away:
                                          status = 'Away';
                                          break;

                                        case Presence.present:
                                          status = 'Online';
                                          break;

                                        default:
                                          status = '...';
                                          break;
                                      }

                                      return Text(
                                        status,
                                        style:
                                            Theme.of(context).textTheme.caption,
                                      );
                                    }),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.expand_more,
                                      size: 18,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  )
                : const Text('Accounts'),
            leading: context.isNarrow
                ? const [StyledBackButton()]
                : [
                    const SizedBox(width: 30),
                    // Padding(
                    //   padding: const EdgeInsets.only(left: 16),
                    //   child: WidgetButton(
                    //     onPressed: () => AccountsView.show(context),
                    //     child: const Icon(
                    //       Icons.help,
                    //       color: Color(0xFF63B4FF),
                    //     ),
                    //   ),
                    // ),
                  ],
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: WidgetButton(
                  onPressed: () => AccountsView.show(context),
                  child: SvgLoader.asset(
                    'assets/icons/switch_account.svg',
                    width: 28.81,
                    height: 25.35,
                  ),
                ),
              ),
            ],
            automaticallyImplyLeading: false,
          ),
          body: FlutterListView(
            delegate: FlutterListViewDelegate(
              (context, i) {
                final Widget child;

                switch (ProfileTab.values[i]) {
                  case ProfileTab.public:
                    child = bigButton(
                      leading: const Icon(
                        Icons.person,
                        color: Color(0xFF63B4FF),
                      ),
                      title: Text('Публичная информация'.l10n),
                      subtitle: Text('Аватар и имя'.l10n),
                      onTap: () => router.profile(push: context.isNarrow),
                    );
                    break;

                  case ProfileTab.signing:
                    child = bigButton(
                      leading: const Icon(
                        Icons.lock,
                        color: Color(0xFF63B4FF),
                      ),
                      title: Text('Параметры входа'.l10n),
                      subtitle: Text('Логин, e-mail, телефон, пароль'.l10n),
                      onTap: () {},
                    );
                    break;

                  case ProfileTab.link:
                    child = bigButton(
                      leading: const Icon(
                        Icons.link,
                        color: Color(0xFF63B4FF),
                      ),
                      title: Text('Ссылка на чат'.l10n),
                      subtitle: Text('Прямая ссылка на чат с Вами'.l10n),
                      onTap: () {},
                    );
                    break;

                  case ProfileTab.background:
                    child = bigButton(
                      leading: const Icon(
                        Icons.image,
                        color: Color(0xFF63B4FF),
                      ),
                      title: Text('Бэкграунд'.l10n),
                      subtitle: Text('Фон приложения'.l10n),
                      onTap: () {},
                    );
                    break;

                  case ProfileTab.calls:
                    child = bigButton(
                      leading: const Icon(
                        Icons.call,
                        color: Color(0xFF63B4FF),
                      ),
                      title: Text('Звонки'.l10n),
                      subtitle: Text('Отображение звонков'.l10n),
                      onTap: () {},
                    );
                    break;

                  case ProfileTab.media:
                    child = bigButton(
                      leading: const Icon(
                        Icons.video_call,
                        color: Color(0xFF63B4FF),
                      ),
                      title: Text('Медиа'.l10n),
                      subtitle: Text('Аудио и видео устройства'.l10n),
                      onTap: () {},
                    );
                    break;

                  case ProfileTab.language:
                    child = bigButton(
                      leading: const Icon(
                        Icons.language,
                        color: Color(0xFF63B4FF),
                      ),
                      title: Text('Язык'.l10n),
                      subtitle: Text(L10n.chosen.value?.name ?? 'Текущий язык'),
                      onTap: () {},
                    );
                    break;

                  case ProfileTab.download:
                    child = bigButton(
                      leading: const Icon(
                        Icons.download,
                        color: Color(0xFF63B4FF),
                      ),
                      title: Text('Скачать'.l10n),
                      subtitle: Text('Приложение'.l10n),
                      onTap: () {},
                    );
                    break;

                  case ProfileTab.danger:
                    child = bigButton(
                      leading: const Icon(
                        Icons.dangerous,
                        color: Color(0xFF63B4FF),
                      ),
                      title: Text('Опасная зона'.l10n),
                      subtitle: Text('Удалить аккаунт'.l10n),
                      onTap: () {},
                    );
                    break;

                  case ProfileTab.logout:
                    child = bigButton(
                      title: Text('btn_logout'.l10n),
                      leading: const Icon(
                        Icons.logout,
                        color: Color(0xFF63B4FF),
                      ),
                      subtitle: Text('Завершить сессию'.l10n),
                      onTap: () async {
                        if (await c.confirmLogout()) {
                          router.go(await c.logout());
                          router.tab = HomeTab.chats;
                        }
                      },
                    );
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: child,
                );
              },
              childCount: ProfileTab.values.length,
            ),
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
            const SizedBox(height: 8),
            Text('label_direct_chat_link_description'.l10n),
            const SizedBox(height: 8),
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
