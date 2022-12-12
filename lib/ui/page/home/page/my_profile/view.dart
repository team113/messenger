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

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';

import '/config.dart';
import '/domain/model/my_user.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/my_profile/widget/bloc.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/confirm_dialog.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'controller.dart';
import 'widget/copyable.dart';

/// View of the [Routes.profile] page.
class MyProfileView extends StatelessWidget {
  const MyProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      key: const Key('MyProfileView'),
      init: MyProfileController(Get.find(), Get.find()),
      builder: (MyProfileController c) {
        return GestureDetector(
          onTap: FocusManager.instance.primaryFocus?.unfocus,
          child: Scaffold(
            appBar: CustomAppBar(
              title: Text('label_profile'.l10n),
              padding: const EdgeInsets.only(left: 4, right: 20),
              leading: const [StyledBackButton()],
            ),
            body: Obx(() {
              if (c.myUser.value == null) {
                return const CircularProgressIndicator();
              }

              return FlutterListView(
                controller: c.listController,
                delegate: FlutterListViewDelegate(
                  (context, i) {
                    switch (ProfileTab.values[i]) {
                      case ProfileTab.public:
                        return Bloc(
                          title: 'label_public_information'.l10n,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                WidgetButton(
                                  onPressed: () async {
                                    await c.uploadAvatar();
                                  },
                                  child: AvatarWidget.fromMyUser(
                                    c.myUser.value,
                                    radius: 100,
                                    showBadge: false,
                                  ),
                                ),
                                Positioned.fill(
                                  child: Obx(() {
                                    return AnimatedSwitcher(
                                      duration: 200.milliseconds,
                                      child: c.avatarUpload.value.isLoading
                                          ? Container(
                                              width: 200,
                                              height: 200,
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
                            const SizedBox(height: 5),
                            Center(
                              child: WidgetButton(
                                onPressed: c.myUser.value?.avatar == null
                                    ? null
                                    : c.deleteAvatar,
                                child: SizedBox(
                                  height: 20,
                                  child: c.myUser.value?.avatar == null
                                      ? null
                                      : Text(
                                          'btn_delete'.l10n,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _name(c),
                          ],
                        );

                      case ProfileTab.signing:
                        return Bloc(
                          title: 'label_login_options'.l10n,
                          children: [
                            _num(c),
                            _login(c, context),
                            const SizedBox(height: 10),
                            _emails(c, context),
                            _password(context, c),
                          ],
                        );

                      case ProfileTab.link:
                        return Bloc(
                          title: 'label_your_direct_link'.l10n,
                          children: [
                            _link(context, c),
                          ],
                        );

                      case ProfileTab.background:
                        return Bloc(
                          title: 'label_background'.l10n,
                          children: [
                            _background(context, c),
                          ],
                        );

                      case ProfileTab.calls:
                        if (!PlatformUtils.isMobile) {
                          return Bloc(
                            title: 'label_calls'.l10n,
                            children: [
                              _call(context, c),
                            ],
                          );
                        }

                        return const SizedBox();

                      case ProfileTab.media:
                        if (!PlatformUtils.isMobile) {
                          return Bloc(
                            title: 'label_media'.l10n,
                            children: [
                              _media(context, c),
                            ],
                          );
                        }

                        return const SizedBox();

                      case ProfileTab.language:
                        return Bloc(
                          title: 'label_language'.l10n,
                          children: [
                            _language(context, c),
                          ],
                        );

                      case ProfileTab.download:
                        if (PlatformUtils.isWeb) {
                          return Bloc(
                            title: 'label_download_app'.l10n,
                            children: [
                              _downloads(context, c),
                            ],
                          );
                        }

                        return const SizedBox();

                      case ProfileTab.danger:
                        return Bloc(
                          title: 'label_danger_zone'.l10n,
                          children: [
                            _deleteAccount(context, c),
                          ],
                        );

                      case ProfileTab.logout:
                        return const SizedBox();
                    }
                  },
                  initIndex: c.listInitIndex,
                  childCount: ProfileTab.values.length,
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// Basic [Padding] wrapper.
Widget _padding(Widget child) =>
    Padding(padding: const EdgeInsets.all(8), child: child);

/// Dense [Padding] wrapper.
Widget _dense(Widget child) =>
    Padding(padding: const EdgeInsets.fromLTRB(8, 4, 8, 4), child: child);

/// Returns [MyUser.name] editable field.
Widget _name(MyProfileController c) {
  return _padding(
    ReactiveTextField(
      key: const Key('NameField'),
      state: c.name,
      label: 'label_name'.l10n,
      hint: 'label_name_hint'.l10n,
      filled: true,
      onSuffixPressed: c.login.text.isEmpty
          ? null
          : () {
              Clipboard.setData(ClipboardData(text: c.name.text));
              MessagePopup.success('label_copied_to_clipboard'.l10n);
            },
      trailing: c.login.text.isEmpty
          ? null
          : Transform.translate(
              offset: const Offset(0, -1),
              child: Transform.scale(
                scale: 1.15,
                child: SvgLoader.asset(
                  'assets/icons/copy.svg',
                  height: 15,
                ),
              ),
            ),
    ),
  );
}

/// Returns [MyUser.num] copyable field.
Widget _num(MyProfileController c) => _padding(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CopyableTextField(
            key: const Key('NumCopyable'),
            state: c.num,
            label: 'label_num'.l10n,
            copy: c.myUser.value?.num.val,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );

/// Returns [MyUser.chatDirectLink] editable field.
Widget _link(BuildContext context, MyProfileController c) {
  return Obx(() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ReactiveTextField(
          key: const Key('LinkField'),
          state: c.link,
          onSuffixPressed: c.link.isEmpty.value
              ? null
              : () {
                  Clipboard.setData(
                    ClipboardData(
                      text:
                          '${Config.origin}${Routes.chatDirectLink}/${c.link.text}',
                    ),
                  );

                  MessagePopup.success('label_copied_to_clipboard'.l10n);
                },
          trailing: c.link.isEmpty.value
              ? null
              : Transform.translate(
                  offset: const Offset(0, -1),
                  child: Transform.scale(
                    scale: 1.15,
                    child: SvgLoader.asset(
                      'assets/icons/copy.svg',
                      height: 15,
                    ),
                  ),
                ),
          label: '${Config.origin}/',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
          child: Row(
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                  children: [
                    TextSpan(
                      text: 'label_transition_count'.l10nfmt({'count': 0}) +
                          'dot_space'.l10n,
                      style: const TextStyle(color: Color(0xFF888888)),
                    ),
                    TextSpan(
                      text: 'label_details'.l10n + 'dot'.l10n,
                      style: const TextStyle(color: Color(0xFF00A3FF)),
                      recognizer: TapGestureRecognizer(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  });
}

/// Returns [MyUser.login] editable field.
Widget _login(MyProfileController c, BuildContext context) {
  return _padding(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ReactiveTextField(
          key: const Key('LoginField'),
          state: c.login,
          onSuffixPressed: c.login.text.isEmpty
              ? null
              : () {
                  Clipboard.setData(ClipboardData(text: c.login.text));
                  MessagePopup.success('label_copied_to_clipboard'.l10n);
                },
          trailing: c.login.text.isEmpty
              ? null
              : Transform.translate(
                  offset: const Offset(0, -1),
                  child: Transform.scale(
                    scale: 1.15,
                    child: SvgLoader.asset(
                      'assets/icons/copy.svg',
                      height: 15,
                    ),
                  ),
                ),
          label: 'label_login'.l10n,
          hint: c.myUser.value?.login == null
              ? 'label_login_hint'.l10n
              : c.myUser.value!.login!.val,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
          child: RichText(
            text: TextSpan(
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
              children: [
                TextSpan(
                  text: 'label_login_visible'.l10n,
                  style: const TextStyle(color: Color(0xFF888888)),
                ),
                TextSpan(
                  text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
                  style: const TextStyle(color: Color(0xFF00A3FF)),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      await ConfirmDialog.show(
                        context,
                        title: 'label_login'.l10n,
                        additional: [
                          Center(
                            child: Text(
                              'label_login_visibility_hint'.l10n,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'label_visible_to'.l10n,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                        proceedLabel: 'label_confirm'.l10n,
                        withCancel: false,
                        initial: 2,
                        variants: [
                          ConfirmDialogVariant(
                            onProceed: () {},
                            child: Text('label_all'.l10n),
                          ),
                          ConfirmDialogVariant(
                            onProceed: () {},
                            child: Text('label_my_contacts'.l10n),
                          ),
                          ConfirmDialogVariant(
                            onProceed: () {},
                            child: Text('label_nobody'.l10n),
                          ),
                        ],
                      );
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Returns addable list of [MyUser.emails].
Widget _emails(MyProfileController c, BuildContext context) {
  return Obx(() {
    final List<Widget> widgets = [];

    for (UserEmail e in [...c.myUser.value?.emails.confirmed ?? []]) {
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.centerRight,
              children: [
                WidgetButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: e.val));
                    MessagePopup.success('label_copied_to_clipboard'.l10n);
                  },
                  child: IgnorePointer(
                    child: ReactiveTextField(
                      state: TextFieldState(text: e.val, editable: false),
                      label: 'label_email'.l10n,
                      trailing: Transform.translate(
                        offset: const Offset(0, -1),
                        child: Transform.scale(
                          scale: 1.15,
                          child: SvgLoader.asset(
                            'assets/icons/delete.svg',
                            height: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                WidgetButton(
                  onPressed: () {
                    // TODO: show a delete email popup.
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 30,
                    height: 30,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                  children: [
                    TextSpan(
                      text: 'label_email_visible'.l10n,
                      style: const TextStyle(color: Color(0xFF888888)),
                    ),
                    TextSpan(
                      text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
                      style: const TextStyle(color: Color(0xFF00A3FF)),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          await ConfirmDialog.show(
                            context,
                            title: 'label_email'.l10n,
                            additional: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'label_visible_to'.l10n,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                            proceedLabel: 'label_confirm',
                            withCancel: false,
                            initial: 2,
                            variants: [
                              ConfirmDialogVariant(
                                onProceed: () {},
                                child: Text('label_all'.l10n),
                              ),
                              ConfirmDialogVariant(
                                onProceed: () {},
                                child: Text('label_my_contacts'.l10n),
                              ),
                              ConfirmDialogVariant(
                                onProceed: () {},
                                child: Text('label_nobody'.l10n),
                              ),
                            ],
                          );
                        },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }

    if (c.myUser.value?.emails.unconfirmed != null) {
      widgets.addAll([
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: Theme.of(context)
                .inputDecorationTheme
                .copyWith(
                  floatingLabelStyle:
                      TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
          ),
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              WidgetButton(
                behavior: HitTestBehavior.deferToChild,
                onPressed: () {
                  // TODO: show an add email popup.
                },
                child: IgnorePointer(
                  child: ReactiveTextField(
                    state: TextFieldState(
                      text: c.myUser.value!.emails.unconfirmed!.val,
                      editable: false,
                    ),
                    label: 'label_verify_email'.l10n,
                    trailing: Transform.translate(
                      offset: const Offset(0, -1),
                      child: Transform.scale(
                        scale: 1.15,
                        child: SvgLoader.asset(
                          'assets/icons/delete.svg',
                          height: 14,
                        ),
                      ),
                    ),
                    style: const TextStyle(color: Color(0xFF888888)),
                  ),
                ),
              ),
              WidgetButton(
                onPressed: () {
                  // TODO: show a delete email popup.
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 30,
                  height: 30,
                ),
              ),
            ],
          ),
        ),
      ]);
      widgets.add(const SizedBox(height: 10));
    }

    if (c.myUser.value?.emails.unconfirmed == null) {
      widgets.add(
        WidgetButton(
          onPressed: () {
            // TODO: show an add email popup.
          },
          child: IgnorePointer(
            child: ReactiveTextField(
              state: TextFieldState(
                  text: c.myUser.value?.emails.confirmed.isNotEmpty == true
                      ? 'label_add_additional_email'.l10n
                      : 'label_add_email'.l10n,
                  editable: false),
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }

    for (UserPhone e in [...c.myUser.value?.phones.confirmed ?? []]) {
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.centerRight,
              children: [
                WidgetButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: e.val));
                    MessagePopup.success('label_copied_to_clipboard'.l10n);
                  },
                  child: IgnorePointer(
                    child: ReactiveTextField(
                      state: TextFieldState(text: e.val, editable: false),
                      label: 'label_phone_number'.l10n,
                      trailing: Transform.translate(
                        offset: const Offset(0, -1),
                        child: Transform.scale(
                          scale: 1.15,
                          child: SvgLoader.asset(
                            'assets/icons/delete.svg',
                            height: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                WidgetButton(
                  onPressed: () {
                    // TODO: show a delete phone popup.
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 30,
                    height: 30,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Ваш номер телефона видят: ',
                      style: TextStyle(color: Color(0xFF888888)),
                    ),
                    TextSpan(
                      text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
                      style: const TextStyle(color: Color(0xFF00A3FF)),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          await ConfirmDialog.show(
                            context,
                            title: 'label_phone'.l10n,
                            additional: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'label_visible_to'.l10n,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                            proceedLabel: 'label_confirm'.l10n,
                            withCancel: false,
                            initial: 2,
                            variants: [
                              ConfirmDialogVariant(
                                onProceed: () {},
                                child: Text('label_all'.l10n),
                              ),
                              ConfirmDialogVariant(
                                onProceed: () {},
                                child: Text('label_my_contacts'.l10n),
                              ),
                              ConfirmDialogVariant(
                                onProceed: () {},
                                child: Text('label_nobody'.l10n),
                              ),
                            ],
                          );
                        },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }

    if (c.myUser.value?.phones.unconfirmed != null) {
      widgets.addAll([
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: Theme.of(context)
                .inputDecorationTheme
                .copyWith(
                  floatingLabelStyle:
                      TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
          ),
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              WidgetButton(
                behavior: HitTestBehavior.deferToChild,
                onPressed: () {
                  // TODO: show a add phone popup.
                },
                child: IgnorePointer(
                  child: ReactiveTextField(
                    state: TextFieldState(
                      text: c.myUser.value!.phones.unconfirmed!.val,
                      editable: false,
                    ),
                    label: 'label_verify_number'.l10n,
                    trailing: Transform.translate(
                      offset: const Offset(0, -1),
                      child: Transform.scale(
                        scale: 1.15,
                        child: SvgLoader.asset(
                          'assets/icons/delete.svg',
                          height: 14,
                        ),
                      ),
                    ),
                    style: const TextStyle(color: Color(0xFF888888)),
                  ),
                ),
              ),
              WidgetButton(
                onPressed: () {
                  // TODO: show a delete phone popup.
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 30,
                  height: 30,
                ),
              ),
            ],
          ),
        ),
      ]);
      widgets.add(const SizedBox(height: 10));
    }

    if (c.myUser.value?.phones.unconfirmed == null) {
      widgets.add(
        WidgetButton(
          onPressed: () {
            // TODO: show a add phone popup.
          },
          child: IgnorePointer(
            child: ReactiveTextField(
              state: TextFieldState(
                text: c.myUser.value?.phones.confirmed.isNotEmpty == true
                    ? 'label_add_additional_number'.l10n
                    : 'label_add_number'.l10n,
                editable: false,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets.map((e) => _dense(e)).toList(),
    );
  });
}

/// Returns button for changing [MyUser.password].
Widget _password(BuildContext context, MyProfileController c) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _dense(
        WidgetButton(
          onPressed: () {
            // TODO: show a change password popup.
          },
          child: IgnorePointer(
            child: ReactiveTextField(
              state: TextFieldState(
                text: c.myUser.value?.hasPassword == true
                    ? 'btn_change_password'.l10n
                    : 'btn_set_password'.l10n,
                editable: false,
              ),
              style: TextStyle(
                color: c.myUser.value?.hasPassword != true
                    ? Colors.red
                    : Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
    ],
  );
}

/// Returns button to delete the account.
Widget _deleteAccount(BuildContext context, MyProfileController c) {
  return _dense(
    WidgetButton(
      onPressed: () {
        // TODO: show a delete account popup.
      },
      child: IgnorePointer(
        child: ReactiveTextField(
          state:
              TextFieldState(text: 'btn_delete_account'.l10n, editable: false),
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          trailing: Transform.translate(
            offset: const Offset(0, -1),
            child: Transform.scale(
              scale: 1.15,
              child: SvgLoader.asset('assets/icons/delete.svg', height: 14),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Returns [Widget] for changing background image.
Widget _background(BuildContext context, MyProfileController c) {
  final Style style = Theme.of(context).extension<Style>()!;

  Widget message({
    bool fromMe = true,
    bool isRead = true,
    String text = '123',
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5 * 2, 6, 5 * 2, 6),
      child: IntrinsicWidth(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            color: fromMe
                ? isRead
                    ? style.readMessageColor
                    : style.unreadMessageColor
                : style.messageColor,
            borderRadius: BorderRadius.circular(15),
            border: fromMe
                ? isRead
                    ? style.secondaryBorder
                    : Border.all(color: const Color(0xFFDAEDFF), width: 0.5)
                : style.primaryBorder,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: Text(text, style: style.boldBody),
              ),
            ],
          ),
        ),
      ),
    );
  }

  return _dense(
    Column(
      children: [
        WidgetButton(
          onPressed: c.pickBackground,
          child: Container(
            decoration: BoxDecoration(
              border: style.primaryBorder,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Obx(() {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: double.infinity,
                  height: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: c.background.value == null
                            ? Container(
                                child: SvgLoader.asset(
                                  'assets/images/background_light.svg',
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.memory(
                                c.background.value!,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: message(
                                fromMe: false,
                                text: 'label_hello'.l10n,
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: message(
                                fromMe: true,
                                text: 'label_hello_reply'.l10n,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        if (c.background.value != null) ...[
          const SizedBox(height: 10),
          Center(
            child: WidgetButton(
              onPressed: c.background.value == null ? null : c.removeBackground,
              child: Text(
                'btn_delete'.l10n,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

/// Returns button for changing calls opening.
Widget _call(BuildContext context, MyProfileController c) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _dense(
        WidgetButton(
          onPressed: () {
            // TODO: show a call window switch popup.
          },
          child: IgnorePointer(
            child: ReactiveTextField(
              state: TextFieldState(
                text: (c.settings.value?.enablePopups ?? true)
                    ? 'label_open_calls_in_window'.l10n
                    : 'label_open_calls_in_app'.l10n,
              ),
              maxLines: null,
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ),
      ),
    ],
  );
}

/// Returns buttons for changing media settings.
Widget _media(BuildContext context, MyProfileController c) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _dense(
        WidgetButton(
          onPressed: () {
            // TODO: show a camera switch popup.
          },
          child: IgnorePointer(
            child: ReactiveTextField(
              label: 'label_media_camera'.l10n,
              state: TextFieldState(
                text: (c.devices.video().firstWhereOrNull(
                                (e) => e.deviceId() == c.camera.value) ??
                            c.devices.video().firstOrNull)
                        ?.label() ??
                    'label_media_no_device_available'.l10n,
                editable: false,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      _dense(
        WidgetButton(
          onPressed: () {
            // TODO: show a microphone switch popup.
          },
          child: IgnorePointer(
            child: ReactiveTextField(
              label: 'label_media_microphone'.l10n,
              state: TextFieldState(
                text: (c.devices.audio().firstWhereOrNull(
                                (e) => e.deviceId() == c.mic.value) ??
                            c.devices.audio().firstOrNull)
                        ?.label() ??
                    'label_media_no_device_available'.l10n,
                editable: false,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      _dense(
        WidgetButton(
          onPressed: () {
            // TODO: show a output switch popup.
          },
          child: IgnorePointer(
            child: ReactiveTextField(
              label: 'label_media_output'.l10n,
              state: TextFieldState(
                text: (c.devices.output().firstWhereOrNull(
                                (e) => e.deviceId() == c.output.value) ??
                            c.devices.output().firstOrNull)
                        ?.label() ??
                    'label_media_no_device_available'.l10n,
                editable: false,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ),
      ),
    ],
  );
}

/// Returns buttons for downloading application.
Widget _downloads(BuildContext context, MyProfileController c) {
  Widget button({
    required String asset,
    required double width,
    required double height,
    required String title,
    String? link,
  }) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        WidgetButton(
          onPressed: link == null
              ? null
              : () {
                  WebUtils.download('${Config.origin}/artifacts/$link', link);
                },
          child: IgnorePointer(
            child: ReactiveTextField(
              textAlign: TextAlign.center,
              prefix: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Transform.scale(
                  scale: 2,
                  child: SvgLoader.asset(
                    'assets/icons/$asset.svg',
                    width: width / 2,
                    height: height / 2,
                  ),
                ),
              ),
              trailing: Transform.translate(
                offset: const Offset(0, -1),
                child: Transform.scale(
                  scale: 1.15,
                  child: SvgLoader.asset(
                    'assets/icons/copy.svg',
                    height: 15,
                  ),
                ),
              ),
              state: TextFieldState(
                text: 'space'.l10n * 4 + title,
                editable: false,
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ),
        WidgetButton(
          onPressed: () {
            if (link != null) {
              Clipboard.setData(
                ClipboardData(text: '${Config.origin}/artifacts/$link'),
              );
              MessagePopup.success('label_copied_to_clipboard'.l10n);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            width: 30,
            height: 30,
          ),
        ),
      ],
    );
  }

  return _dense(
    Column(
      children: [
        button(
          asset: 'windows',
          width: 21.93,
          height: 22,
          title: 'label_windows'.l10n,
          link: 'messenger-windows.zip',
        ),
        const SizedBox(height: 8),
        button(
          asset: 'apple',
          width: 23,
          height: 29,
          title: 'label_macos'.l10n,
          link: 'messenger-macos.zip',
        ),
        const SizedBox(height: 8),
        button(
          asset: 'linux',
          width: 18.85,
          height: 22,
          title: 'label_linux'.l10n,
          link: 'messenger-linux.zip',
        ),
        const SizedBox(height: 8),
        button(
          asset: 'apple',
          width: 23,
          height: 29,
          title: 'label_ios'.l10n,
        ),
        const SizedBox(height: 8),
        button(
          asset: 'google',
          width: 20.33,
          height: 22.02,
          title: 'label_android'.l10n,
          link: 'messenger-android.apk',
        ),
      ],
    ),
  );
}

/// Returns button for changing language.
Widget _language(BuildContext context, MyProfileController c) {
  return _dense(
    WidgetButton(
      onPressed: () async {
        // TODO: show a language selector popup.
      },
      child: IgnorePointer(
        child: ReactiveTextField(
          state: TextFieldState(
            text:
                '${L10n.chosen.value!.locale.countryCode}, ${L10n.chosen.value!.name}',
            editable: false,
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
      ),
    ),
  );
}
