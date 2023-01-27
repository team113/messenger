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

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' show Presence;
import '/config.dart';
import '/domain/model/my_user.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/repository/settings.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/my_profile/widget/field_button.dart';
import '/ui/page/home/tab/menu/status/view.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/confirm_dialog.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'add_email/view.dart';
import 'add_phone/view.dart';
import 'blacklist/view.dart';
import 'call_window_switch/view.dart';
import 'camera_switch/view.dart';
import 'controller.dart';
import 'language/view.dart';
import 'link_details/view.dart';
import 'microphone_switch/view.dart';
import 'output_switch/view.dart';
import 'password/view.dart';
import 'widget/copyable.dart';
import 'widget/download_button.dart';

/// View of the [Routes.me] page.
class MyProfileView extends StatelessWidget {
  const MyProfileView({super.key});

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

              return Scrollbar(
                controller: c.listController,
                child: FlutterListView(
                  controller: c.listController,
                  delegate: FlutterListViewDelegate(
                    (context, i) {
                      switch (ProfileTab.values[i]) {
                        case ProfileTab.public:
                          return Block(
                            title: 'label_public_information'.l10n,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  WidgetButton(
                                    onPressed: c.uploadAvatar,
                                    child: AvatarWidget.fromMyUser(
                                      c.myUser.value,
                                      radius: 100,
                                      badge: false,
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
                              Obx(() {
                                if (c.myUser.value?.avatar == null) {
                                  return const SizedBox();
                                }

                                return Center(
                                  child: WidgetButton(
                                    key: const Key('DeleteAvatar'),
                                    onPressed: c.deleteAvatar,
                                    child: SizedBox(
                                      height: 20,
                                      child: Text(
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
                                );
                              }),
                              const SizedBox(height: 10),
                              _name(c),
                              _presence(c, context),
                              _status(c),
                            ],
                          );

                        case ProfileTab.signing:
                          return Block(
                            title: 'label_login_options'.l10n,
                            children: [
                              _num(c),
                              _login(c, context),
                              const SizedBox(height: 10),
                              _emails(c, context),
                              _phones(c, context),
                              _password(context, c),
                            ],
                          );

                        case ProfileTab.link:
                          return Block(
                            title: 'label_your_direct_link'.l10n,
                            children: [_link(context, c)],
                          );

                        case ProfileTab.background:
                          return Block(
                            title: 'label_background'.l10n,
                            children: [_background(context, c)],
                          );

                        case ProfileTab.calls:
                          if (PlatformUtils.isDesktop && PlatformUtils.isWeb) {
                            return Block(
                              title: 'label_calls'.l10n,
                              children: [_call(context, c)],
                            );
                          }

                          return const SizedBox();

                        case ProfileTab.media:
                          if (!PlatformUtils.isMobile) {
                            return Block(
                              title: 'label_media'.l10n,
                              children: [_media(context, c)],
                            );
                          }

                          return const SizedBox();

                        case ProfileTab.notifications:
                          return Block(
                            title: 'label_audio_notifications'.l10n,
                            children: [_notifications(context, c)],
                          );

                        case ProfileTab.language:
                          return Block(
                            title: 'label_language'.l10n,
                            children: [_language(context, c)],
                          );

                        case ProfileTab.blacklist:
                          return Block(
                            title: 'label_blocked_users'.l10n,
                            children: [_blockedUsers(context, c)],
                          );

                        case ProfileTab.download:
                          if (PlatformUtils.isWeb) {
                            return Block(
                              title: 'label_download_application'.l10n,
                              children: [_downloads(context, c)],
                            );
                          }

                          return const SizedBox();

                        case ProfileTab.danger:
                          return Block(
                            title: 'label_danger_zone'.l10n,
                            children: [_danger(context, c)],
                          );

                        case ProfileTab.logout:
                          return const SizedBox();
                      }
                    },
                    initIndex: c.listInitIndex,
                    childCount: ProfileTab.values.length,
                  ),
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
                child: SvgLoader.asset('assets/icons/copy.svg', height: 15),
              ),
            ),
    ),
  );
}

/// Returns [MyUser.status] editable field.
Widget _status(MyProfileController c) {
  return _padding(
    ReactiveTextField(
      key: const Key('StatusField'),
      state: c.status,
      label: 'label_status'.l10n,
      filled: true,
      maxLength: 25,
      onSuffixPressed: c.status.text.isEmpty
          ? null
          : () {
              Clipboard.setData(ClipboardData(text: c.status.text));
              MessagePopup.success('label_copied_to_clipboard'.l10n);
            },
      trailing: c.status.text.isEmpty
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

/// Returns [WidgetButton] displaying the [MyUser.presence].
Widget _presence(MyProfileController c, BuildContext context) {
  return Obx(() {
    final Presence? presence = c.myUser.value?.presence;

    return _padding(
      FieldButton(
        onPressed: () => StatusView.show(context, expanded: false),
        hint: 'label_presence'.l10n,
        text: presence?.localizedString(),
        trailing:
            CircleAvatar(backgroundColor: presence?.getColor(), radius: 7),
        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
      ),
    );
  });
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
                    child: SvgLoader.asset('assets/icons/copy.svg', height: 15),
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
                      text: 'label_transition_count'.l10nfmt({
                            'count':
                                c.myUser.value?.chatDirectLink?.usageCount ?? 0
                          }) +
                          'dot_space'.l10n,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    TextSpan(
                      text: 'label_details'.l10n,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          await LinkDetailsView.show(context);
                        },
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
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                TextSpan(
                  text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      await ConfirmDialog.show(
                        context,
                        title: 'label_login'.l10n,
                        additional: [
                          Center(
                            child: Text(
                              'label_login_visibility_hint'.l10n,
                              style: TextStyle(
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
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
                        label: 'label_confirm'.l10n,
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

    for (UserEmail e in c.myUser.value?.emails.confirmed ?? []) {
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FieldButton(
              key: const Key('ConfirmedEmail'),
              text: e.val,
              hint: 'label_email'.l10n,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: e.val));
                MessagePopup.success('label_copied_to_clipboard'.l10n);
              },
              onTrailingPressed: () => _deleteEmail(c, context, e),
              trailing: Transform.translate(
                key: const Key('DeleteEmail'),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                  children: [
                    TextSpan(
                      text: 'label_email_visible'.l10n,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    TextSpan(
                      text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
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
                            label: 'label_confirm'.l10n,
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
          child: FieldButton(
            key: const Key('UnconfirmedEmail'),
            text: c.myUser.value!.emails.unconfirmed!.val,
            hint: 'label_verify_email'.l10n,
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
            onPressed: () => AddEmailView.show(
              context,
              email: c.myUser.value!.emails.unconfirmed!,
            ),
            onTrailingPressed: () => _deleteEmail(
              c,
              context,
              c.myUser.value!.emails.unconfirmed!,
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ]);
      widgets.add(const SizedBox(height: 10));
    }

    if (c.myUser.value?.emails.unconfirmed == null) {
      widgets.add(
        FieldButton(
          key: c.myUser.value?.emails.confirmed.isNotEmpty == true
              ? const Key('AddAdditionalEmail')
              : const Key('AddEmail'),
          text: c.myUser.value?.emails.confirmed.isNotEmpty == true
              ? 'label_add_additional_email'.l10n
              : 'label_add_email'.l10n,
          onPressed: () => AddEmailView.show(context),
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
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

/// Returns addable list of [MyUser.emails].
Widget _phones(MyProfileController c, BuildContext context) {
  return Obx(() {
    final List<Widget> widgets = [];

    for (UserPhone e in [...c.myUser.value?.phones.confirmed ?? []]) {
      widgets.add(
        Column(
          key: const Key('ConfirmedPhone'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FieldButton(
              text: e.val,
              hint: 'label_phone_number'.l10n,
              trailing: Transform.translate(
                key: const Key('DeletePhone'),
                offset: const Offset(0, -1),
                child: Transform.scale(
                  scale: 1.15,
                  child: SvgLoader.asset(
                    'assets/icons/delete.svg',
                    height: 14,
                  ),
                ),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: e.val));
                MessagePopup.success('label_copied_to_clipboard'.l10n);
              },
              onTrailingPressed: () => _deletePhone(c, context, e),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                  children: [
                    TextSpan(
                      text: 'label_phone_visible'.l10n,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    TextSpan(
                      text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
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
                            label: 'label_confirm'.l10n,
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
          child: FieldButton(
            key: const Key('UnconfirmedPhone'),
            text: c.myUser.value!.phones.unconfirmed!.val,
            hint: 'label_verify_number'.l10n,
            trailing: Transform.translate(
              offset: const Offset(0, -1),
              child: Transform.scale(
                scale: 1.15,
                child: SvgLoader.asset('assets/icons/delete.svg', height: 14),
              ),
            ),
            onPressed: () => AddPhoneView.show(
              context,
              phone: c.myUser.value!.phones.unconfirmed!,
            ),
            onTrailingPressed: () => _deletePhone(
              c,
              context,
              c.myUser.value!.phones.unconfirmed!,
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ]);
      widgets.add(const SizedBox(height: 10));
    }

    if (c.myUser.value?.phones.unconfirmed == null) {
      widgets.add(
        FieldButton(
          key: c.myUser.value?.phones.confirmed.isNotEmpty == true
              ? const Key('AddAdditionalPhone')
              : const Key('AddPhone'),
          onPressed: () => AddPhoneView.show(context),
          text: c.myUser.value?.phones.confirmed.isNotEmpty == true
              ? 'label_add_additional_number'.l10n
              : 'label_add_number'.l10n,
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
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

/// Returns the buttons changing or setting the password of the currently
/// authenticated [MyUser].
Widget _password(BuildContext context, MyProfileController c) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _dense(
        FieldButton(
          key: c.myUser.value?.hasPassword == true
              ? const Key('ChangePassword')
              : const Key('SetPassword'),
          text: c.myUser.value?.hasPassword == true
              ? 'btn_change_password'.l10n
              : 'btn_set_password'.l10n,
          onPressed: () => ChangePasswordView.show(context),
          style: TextStyle(
            color: c.myUser.value?.hasPassword != true
                ? Colors.red
                : Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
      const SizedBox(height: 10),
    ],
  );
}

/// Returns the contents of a [ProfileTab.danger] section.
Widget _danger(BuildContext context, MyProfileController c) {
  return Column(
    children: [
      _dense(
        FieldButton(
          text: 'btn_delete_account'.l10n,
          trailing: Transform.translate(
            offset: const Offset(0, -1),
            child: Transform.scale(
              scale: 1.15,
              child: SvgLoader.asset('assets/icons/delete.svg', height: 14),
            ),
          ),
          onPressed: () => _deleteAccount(c, context),
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
      ),
    ],
  );
}

/// Returns the contents of a [ProfileTab.background] section.
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
        Obx(() {
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WidgetButton(
                    onPressed: c.background.value == null
                        ? c.pickBackground
                        : c.removeBackground,
                    child: Text(
                      c.background.value == null
                          ? 'btn_upload'.l10n
                          : 'btn_delete'.l10n,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    ),
  );
}

/// Returns the contents of a [ProfileTab.calls] section.
Widget _call(BuildContext context, MyProfileController c) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _dense(
        Obx(() {
          return FieldButton(
            text: (c.settings.value?.enablePopups ?? true)
                ? 'label_open_calls_in_window'.l10n
                : 'label_open_calls_in_app'.l10n,
            maxLines: null,
            onPressed: () => CallWindowSwitchView.show(context),
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          );
        }),
      ),
    ],
  );
}

/// Returns the contents of a [ProfileTab.media] section.
Widget _media(BuildContext context, MyProfileController c) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _dense(
        Obx(() {
          return FieldButton(
            text: (c.devices.video().firstWhereOrNull((e) =>
                            e.deviceId() == c.media.value?.videoDevice) ??
                        c.devices.video().firstOrNull)
                    ?.label() ??
                'label_media_no_device_available'.l10n,
            hint: 'label_media_camera'.l10n,
            onPressed: () async {
              await CameraSwitchView.show(
                context,
                camera: c.media.value?.videoDevice,
              );

              if (c.devices.video().isEmpty) {
                c.enumerateDevices();
              }
            },
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          );
        }),
      ),
      const SizedBox(height: 16),
      _dense(
        Obx(() {
          return FieldButton(
            text: (c.devices.audio().firstWhereOrNull((e) =>
                            e.deviceId() == c.media.value?.audioDevice) ??
                        c.devices.audio().firstOrNull)
                    ?.label() ??
                'label_media_no_device_available'.l10n,
            hint: 'label_media_microphone'.l10n,
            onPressed: () async {
              await MicrophoneSwitchView.show(
                context,
                mic: c.media.value?.audioDevice,
              );

              if (c.devices.audio().isEmpty) {
                c.enumerateDevices();
              }
            },
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          );
        }),
      ),
      const SizedBox(height: 16),
      _dense(
        Obx(() {
          return FieldButton(
            text: (c.devices.output().firstWhereOrNull((e) =>
                            e.deviceId() == c.media.value?.outputDevice) ??
                        c.devices.output().firstOrNull)
                    ?.label() ??
                'label_media_no_device_available'.l10n,
            hint: 'label_media_output'.l10n,
            onPressed: () async {
              await OutputSwitchView.show(
                context,
                output: c.media.value?.outputDevice,
              );

              if (c.devices.output().isEmpty) {
                c.enumerateDevices();
              }
            },
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          );
        }),
      ),
    ],
  );
}

/// Returns the contents of a [ProfileTab.notifications] section.
Widget _notifications(BuildContext context, MyProfileController c) {
  return Obx(() {
    return _dense(
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
                    activeColor: Theme.of(context).colorScheme.secondary,
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
  return _dense(
    Column(
      children: const [
        DownloadButton(
          asset: 'windows',
          width: 21.93,
          height: 22,
          title: 'Windows',
          link: 'messenger-windows.zip',
        ),
        SizedBox(height: 8),
        DownloadButton(
          asset: 'apple',
          width: 23,
          height: 29,
          title: 'macOS',
          link: 'messenger-macos.zip',
        ),
        SizedBox(height: 8),
        DownloadButton(
          asset: 'linux',
          width: 18.85,
          height: 22,
          title: 'Linux',
          link: 'messenger-linux.zip',
        ),
        SizedBox(height: 8),
        DownloadButton(
          asset: 'apple',
          width: 23,
          height: 29,
          title: 'iOS',
          link: 'messenger-ios.zip',
        ),
        SizedBox(height: 8),
        DownloadButton(
          asset: 'google',
          width: 20.33,
          height: 22.02,
          title: 'Android',
          link: 'messenger-android.apk',
        ),
      ],
    ),
  );
}

/// Returns the contents of a [ProfileTab.language] section.
Widget _language(BuildContext context, MyProfileController c) {
  return _dense(
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
      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
    ),
  );
}

/// Returns the contents of a [ProfileTab.blacklist] section.
Widget _blockedUsers(BuildContext context, MyProfileController c) {
  return Column(
    children: [
      _dense(
        FieldButton(
          text: 'label_blocked_count'.l10nfmt({'count': c.blacklist.length}),
          onPressed:
              c.blacklist.isEmpty ? null : () => BlacklistView.show(context),
          style: TextStyle(
              color: c.blacklist.isEmpty
                  ? Colors.black
                  : Theme.of(context).colorScheme.secondary),
        ),
      ),
    ],
  );
}

/// Opens a confirmation popup deleting the provided [email] from the
/// [MyUser.emails].
Future<void> _deleteEmail(
  MyProfileController c,
  BuildContext context,
  UserEmail email,
) async {
  final bool? result = await MessagePopup.alert(
    'label_delete_email'.l10n,
    description: [
      TextSpan(text: 'alert_email_will_be_deleted1'.l10n),
      TextSpan(
        text: email.val,
        style: const TextStyle(color: Colors.black),
      ),
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
  final bool? result = await MessagePopup.alert(
    'label_delete_phone_number'.l10n,
    description: [
      TextSpan(text: 'alert_phone_will_be_deleted1'.l10n),
      TextSpan(
        text: phone.val,
        style: const TextStyle(color: Colors.black),
      ),
      TextSpan(text: 'alert_phone_will_be_deleted2'.l10n),
    ],
  );

  if (result == true) {
    await c.deletePhone(phone);
  }
}

/// Opens a confirmation popup deleting the [MyUser]'s account.
Future<void> _deleteAccount(MyProfileController c, BuildContext context) async {
  final bool? result = await MessagePopup.alert(
    'label_delete_account'.l10n,
    description: [
      TextSpan(text: 'alert_account_will_be_deleted1'.l10n),
      TextSpan(
        text: c.myUser.value?.name?.val ??
            c.myUser.value?.login?.val ??
            c.myUser.value?.num.val ??
            'dot'.l10n * 3,
        style: const TextStyle(color: Colors.black),
      ),
      TextSpan(text: 'alert_account_will_be_deleted2'.l10n),
    ],
  );

  if (result == true) {
    await c.deleteAccount();
  }
}
