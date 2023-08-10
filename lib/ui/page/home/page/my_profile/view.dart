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
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '/api/backend/schema.dart' show Presence;
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
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/media_utils.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'add_email/view.dart';
import 'add_phone/view.dart';
import 'blacklist/view.dart';
import 'call_window_switch/view.dart';
import 'camera_switch/view.dart';
import 'controller.dart';
import 'language/view.dart';
import 'microphone_switch/view.dart';
import 'output_switch/view.dart';
import 'password/view.dart';
import 'timeline_switch/view.dart';
import 'widget/background_preview.dart';
import 'widget/download_button.dart';
import 'widget/login.dart';
import 'widget/name.dart';
import 'widget/status.dart';

/// View of the [Routes.me] page.
class MyProfileView extends StatelessWidget {
  const MyProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      key: const Key('MyProfileView'),
      init: MyProfileController(Get.find(), Get.find()),
      global: !Get.isRegistered<MyProfileController>(),
      builder: (MyProfileController c) {
        return GestureDetector(
          onTap: FocusManager.instance.primaryFocus?.unfocus,
          child: Scaffold(
            appBar: CustomAppBar(
              title: Text('label_profile'.l10n),
              padding: const EdgeInsets.only(left: 4, right: 20),
              leading: const [StyledBackButton()],
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
                itemBuilder: (context, i) {
                  switch (ProfileTab.values[i]) {
                    case ProfileTab.public:
                      return Block(
                        title: 'label_public_information'.l10n,
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
                          _presence(context, c),
                          Paddings.basic(
                            Obx(() {
                              return UserTextStatusField(
                                c.myUser.value?.status,
                                onSubmit: c.updateUserStatus,
                              );
                            }),
                          )
                        ],
                      );

                    case ProfileTab.signing:
                      return Block(
                        title: 'label_login_options'.l10n,
                        children: [
                          Paddings.basic(
                            Obx(() {
                              return UserNumCopyable(c.myUser.value?.num);
                            }),
                          ),
                          Paddings.basic(
                            Obx(() {
                              return UserLoginField(
                                c.myUser.value?.login,
                                onSubmit: c.updateUserLogin,
                              );
                            }),
                          ),
                          _emails(context, c),
                          _phones(context, c),
                          _password(context, c),
                        ],
                      );

                    case ProfileTab.link:
                      return Block(
                        title: 'label_your_direct_link'.l10n,
                        children: [
                          Obx(() {
                            return DirectLinkField(
                              c.myUser.value?.chatDirectLink,
                              onSubmit: c.createChatDirectLink,
                            );
                          }),
                        ],
                      );

                    case ProfileTab.background:
                      return Block(
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
                      return Block(
                        title: 'label_chats'.l10n,
                        children: [_chats(context, c)],
                      );

                    case ProfileTab.calls:
                      if (!PlatformUtils.isDesktop || !PlatformUtils.isWeb) {
                        return const SizedBox();
                      }

                      return Block(
                        title: 'label_calls'.l10n,
                        children: [_call(context, c)],
                      );

                    case ProfileTab.media:
                      if (PlatformUtils.isMobile) {
                        return const SizedBox();
                      }

                      return Block(
                        title: 'label_media'.l10n,
                        children: [_media(context, c)],
                      );

                    case ProfileTab.notifications:
                      return Block(
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
                          )
                        ],
                      );

                    case ProfileTab.storage:
                      return Block(
                        title: 'label_storage'.l10n,
                        children: [
                          Paddings.dense(
                            Obx(() {
                              return SwitchField(
                                text: 'label_load_images'.l10n,
                                value: c.settings.value?.loadImages == true,
                                onChanged: c.settings.value == null
                                    ? null
                                    : c.setLoadImages,
                              );
                            }),
                          ),
                        ],
                      );

                    case ProfileTab.language:
                      return Block(
                        title: 'label_language'.l10n,
                        children: [_language(context, c)],
                      );

                    case ProfileTab.blocklist:
                      return Block(
                        title: 'label_blocked_users'.l10n,
                        children: [_blockedUsers(context, c)],
                      );

                    case ProfileTab.download:
                      if (!PlatformUtils.isWeb) {
                        return const SizedBox();
                      }

                      return Block(
                        title: 'label_download_application'.l10n,
                        children: [_downloads(context, c)],
                      );

                    case ProfileTab.danger:
                      return Block(
                        title: 'label_danger_zone'.l10n,
                        children: [_danger(context, c)],
                      );

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
                PlatformUtils.copy(text: e.val);
                MessagePopup.success('label_copied'.l10n);
              },
              onTrailingPressed: () => _deleteEmail(c, context, e),
              trailing: Transform.translate(
                key: const Key('DeleteEmail'),
                offset: const Offset(0, -5),
                child: Transform.scale(
                  scale: 1.15,
                  child: const SvgImage.asset('assets/icons/delete.svg', height: 14),
                ),
              ),
              subtitle: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'label_email_visible'.l10n,
                      style: style.fonts.labelMediumSecondary,
                    ),
                    TextSpan(
                      text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
                      style: style.fonts.labelMediumPrimary,
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
                                  style: style.fonts.headlineMedium,
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
      widgets.add(const SizedBox(height: 8));
    }

    if (c.myUser.value?.emails.unconfirmed != null) {
      widgets.addAll([
        FieldButton(
          key: const Key('UnconfirmedEmail'),
          text: c.myUser.value!.emails.unconfirmed!.val,
          hint: 'label_verify_email'.l10n,
          trailing: Transform.translate(
            offset: const Offset(0, -5),
            child: Transform.scale(
              scale: 1.15,
              child: const SvgImage.asset('assets/icons/delete.svg', height: 14),
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
          style: style.fonts.titleMediumSecondary,
        ),
      ]);
      widgets.add(const SizedBox(height: 8));
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
          style: style.fonts.titleMediumPrimary,
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
                offset: const Offset(0, -5),
                child: Transform.scale(
                  scale: 1.15,
                  child: const SvgImage.asset('assets/icons/delete.svg', height: 14),
                ),
              ),
              onPressed: () {
                PlatformUtils.copy(text: e.val);
                MessagePopup.success('label_copied'.l10n);
              },
              onTrailingPressed: () => _deletePhone(c, context, e),
              subtitle: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'label_phone_visible'.l10n,
                      style: style.fonts.labelMediumSecondary,
                    ),
                    TextSpan(
                      text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
                      style: style.fonts.labelMediumPrimary,
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
                                  style: style.fonts.headlineMedium,
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
      widgets.add(const SizedBox(height: 8));
    }

    if (c.myUser.value?.phones.unconfirmed != null) {
      widgets.addAll([
        FieldButton(
          key: const Key('UnconfirmedPhone'),
          text: c.myUser.value!.phones.unconfirmed!.val,
          hint: 'label_verify_number'.l10n,
          trailing: Transform.translate(
            offset: const Offset(0, -5),
            child: Transform.scale(
              scale: 1.15,
              child: const SvgImage.asset('assets/icons/delete.svg', height: 14),
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
          style: style.fonts.titleMediumSecondary,
        ),
      ]);
      widgets.add(const SizedBox(height: 8));
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
          style: style.fonts.titleMediumPrimary,
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
        style: style.fonts.titleMediumPrimary,
      ),
    );
  });
}

/// Returns the buttons changing or setting the password of the currently
/// authenticated [MyUser].
Widget _password(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Paddings.dense(
        Obx(() {
          return FieldButton(
            key: c.myUser.value?.hasPassword == true
                ? const Key('ChangePassword')
                : const Key('SetPassword'),
            text: c.myUser.value?.hasPassword == true
                ? 'btn_change_password'.l10n
                : 'btn_set_password'.l10n,
            onPressed: () => ChangePasswordView.show(context),
            style: c.myUser.value?.hasPassword != true
                ? style.fonts.titleMediumDanger
                : style.fonts.titleMediumPrimary,
          );
        }),
      ),
      const SizedBox(height: 10),
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
            padding: const EdgeInsets.only(left: 21.0),
            child: Text(
              'label_display_timestamps'.l10n,
              style: style.fonts.titleMediumSecondary,
            ),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Paddings.dense(
        Obx(() {
          return FieldButton(
            text: (c.settings.value?.timelineEnabled ?? true)
                ? 'label_as_timeline'.l10n
                : 'label_in_message'.l10n,
            maxLines: null,
            onPressed: () => TimelineSwitchView.show(context),
            style: style.fonts.titleMediumPrimary,
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
      Paddings.dense(
        Obx(() {
          return FieldButton(
            text: (c.settings.value?.enablePopups ?? true)
                ? 'label_open_calls_in_window'.l10n
                : 'label_open_calls_in_app'.l10n,
            maxLines: null,
            onPressed: () => CallWindowSwitchView.show(context),
            style: style.fonts.titleMediumPrimary,
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
            onPressed: () async {
              await CameraSwitchView.show(
                context,
                camera: c.media.value?.videoDevice,
              );

              if (c.devices.video().isEmpty) {
                c.devices.value = await MediaUtils.enumerateDevices();
              }
            },
            style: style.fonts.titleMediumPrimary,
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
            onPressed: () async {
              await MicrophoneSwitchView.show(
                context,
                mic: c.media.value?.audioDevice,
              );

              if (c.devices.audio().isEmpty) {
                c.devices.value = await MediaUtils.enumerateDevices();
              }
            },
            style: style.fonts.titleMediumPrimary,
          );
        }),
      ),
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
            onPressed: () async {
              await OutputSwitchView.show(
                context,
                output: c.media.value?.outputDevice,
              );

              if (c.devices.output().isEmpty) {
                c.devices.value = await MediaUtils.enumerateDevices();
              }
            },
            style: style.fonts.titleMediumPrimary,
          );
        }),
      ),
    ],
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
      style: style.fonts.titleMediumPrimary,
    ),
  );
}

/// Returns the contents of a [ProfileTab.blacklist] section.
Widget _blockedUsers(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Column(
    children: [
      Paddings.dense(
        FieldButton(
          text: 'label_users_count'.l10nfmt({'count': c.blacklist.length}),
          onPressed:
              c.blacklist.isEmpty ? null : () => BlacklistView.show(context),
          style: c.blacklist.isEmpty
              ? style.fonts.titleMedium
              : style.fonts.titleMediumPrimary,
        ),
      ),
    ],
  );
}

/// Returns the contents of a [ProfileTab.download] section.
Widget _downloads(BuildContext context, MyProfileController c) {
  return Paddings.dense(
    const Column(
      children: [
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

/// Returns the contents of a [ProfileTab.danger] section.
Widget _danger(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Column(
    children: [
      Paddings.dense(
        FieldButton(
          key: const Key('DeleteAccount'),
          text: 'btn_delete_account'.l10n,
          trailing: Transform.translate(
            offset: const Offset(0, -1),
            child: Transform.scale(
              scale: 1.15,
              child: const SvgImage.asset('assets/icons/delete.svg', height: 14),
            ),
          ),
          onPressed: () => _deleteAccount(c, context),
          style: style.fonts.titleMediumPrimary,
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
  final style = Theme.of(context).style;

  final bool? result = await MessagePopup.alert(
    'label_delete_email'.l10n,
    description: [
      TextSpan(text: 'alert_email_will_be_deleted1'.l10n),
      TextSpan(text: email.val, style: style.fonts.labelLarge),
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
      TextSpan(text: phone.val, style: style.fonts.labelLarge),
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
            c.myUser.value?.num.val ??
            'dot'.l10n * 3,
        style: style.fonts.labelLarge,
      ),
      TextSpan(text: 'alert_account_will_be_deleted2'.l10n),
    ],
  );

  if (result == true) {
    await c.deleteAccount();
  }
}
