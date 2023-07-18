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
import 'package:messenger/ui/page/home/page/my_profile/widget/switch_field.dart';
import 'package:messenger/ui/page/home/widget/paddings.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../widget/svg/svg.dart';
import '../../widget/confirm_dialog.dart';
import '../../widget/field_button.dart';
import '/domain/model/my_user.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/widget_button.dart';
import '/util/media_utils.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'add_email/view.dart';
import 'add_phone/view.dart';
import 'camera_switch/view.dart';
import 'controller.dart';
import 'microphone_switch/view.dart';
import 'output_switch/view.dart';
import 'widget/background_preview.dart';
import 'tab/blacklist.dart';
import 'tab/calls.dart';
import 'tab/chats.dart';
import 'tab/danger.dart';
import 'tab/download.dart';
import 'tab/language.dart';
import 'tab/media.dart';
import 'tab/public.dart';
import 'tab/singing.dart';
import 'widget/direct_link.dart';

/// View of the [Routes.me] page.
class MyProfileView extends StatelessWidget {
  const MyProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

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
            body: Obx(() {
              if (c.myUser.value == null) {
                return const Center(child: CustomProgressIndicator());
              }

              return Scrollbar(
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
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                WidgetButton(
                                  onPressed: c.myUser.value?.avatar == null
                                      ? c.uploadAvatar
                                      : () async {
                                          await GalleryPopup.show(
                                            context: context,
                                            gallery: GalleryPopup(
                                              initialKey: c.avatarKey,
                                              children: [
                                                GalleryItem.image(
                                                  c.myUser.value!.avatar!
                                                      .original.url,
                                                  c.myUser.value!.num.val,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                  child: AvatarWidget.fromMyUser(
                                    c.myUser.value,
                                    key: c.avatarKey,
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
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: style.colors
                                                    .onBackgroundOpacity13,
                                              ),
                                              child: const Center(
                                                child:
                                                    CustomProgressIndicator(),
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
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  WidgetButton(
                                    key: const Key('UploadAvatar'),
                                    onPressed: () => c.uploadAvatar(),
                                    child: Text(
                                      'btn_upload'.l10n,
                                      style: fonts.labelSmall!.copyWith(
                                        color: style.colors.primary,
                                      ),
                                    ),
                                  ),
                                  if (c.myUser.value?.avatar != null) ...[
                                    Text(
                                      'space_or_space'.l10n,
                                      style: fonts.bodySmall,
                                    ),
                                    WidgetButton(
                                      key: const Key('DeleteAvatar'),
                                      onPressed: () => c.deleteAvatar(),
                                      child: Text(
                                        'btn_delete'.l10n.toLowerCase(),
                                        style: fonts.bodySmall!.copyWith(
                                          color: style.colors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            }),
                            const SizedBox(height: 10),
                            NameField(
                              c.myUser.value?.name,
                              onCreate: c.updateUserName,
                            ),
                            PresenceFieldButton(
                              text: c.myUser.value?.presence.localizedString(),
                              backgroundColor:
                                  c.myUser.value?.presence.getColor(),
                            ),
                            StatusFieldButton(
                              c.myUser.value?.status,
                              onCreate: c.updateUserStatus,
                            ),
                          ],
                        );

                      case ProfileTab.signing:
                        return Block(
                          title: 'label_login_options'.l10n,
                          children: [
                            CopyableNumField(c.myUser.value?.num),
                            ReactiveLoginField(
                              c.myUser.value?.login,
                              onCreate: c.updateUserLogin,
                            ),
                            const SizedBox(height: 10),
                            _emails(c, context),
                            _phones(c, context),
                            PasswordField(
                              hasPassword: c.myUser.value!.hasPassword,
                            ),
                          ],
                        );

                      case ProfileTab.link:
                        return Block(
                          title: 'label_your_direct_link'.l10n,
                          children: [
                            Obx(() {
                              return DirectLinkField(
                                c.myUser.value?.chatDirectLink,
                                onCreate: c.createChatDirectLink,
                              );
                            }),
                          ],
                        );

                      case ProfileTab.background:
                        return Block(
                          title: 'label_background'.l10n,
                          children: [
                            Obx(() {
                              return BackgroundPreview(
                                c.background.value,
                                onPick: c.pickBackground,
                                onRemove: c.removeBackground,
                              );
                            })
                          ],
                        );

                      case ProfileTab.chats:
                        return Block(
                          title: 'label_chats'.l10n,
                          children: [
                            Obx(() {
                              return ChatsFieldButton(
                                isTimeline: c.settings.value!.timelineEnabled,
                              );
                            }),
                          ],
                        );

                      case ProfileTab.calls:
                        if (!PlatformUtils.isDesktop || !PlatformUtils.isWeb) {
                          return const SizedBox();
                        }

                        return Block(
                          title: 'label_calls'.l10n,
                          children: [
                            Obx(
                              () => CallsFieldButton(
                                enablePopups: c.settings.value?.enablePopups,
                              ),
                            )
                          ],
                        );

                      case ProfileTab.media:
                        if (PlatformUtils.isMobile) {
                          return const SizedBox();
                        }

                        return Block(
                          title: 'label_media'.l10n,
                          children: [
                            Obx(() {
                              return MediaFieldButtons(
                                videoText: (c.devices.video().firstWhereOrNull(
                                                (e) =>
                                                    e.deviceId() ==
                                                    c.media.value
                                                        ?.videoDevice) ??
                                            c.devices.video().firstOrNull)
                                        ?.label() ??
                                    'label_media_no_device_available'.l10n,
                                videoSwitch: () async {
                                  await CameraSwitchView.show(
                                    context,
                                    camera: c.media.value?.videoDevice,
                                  );

                                  if (c.devices.video().isEmpty) {
                                    c.devices.value =
                                        await MediaUtils.enumerateDevices();
                                  }
                                },
                                audioText: (c.devices.audio().firstWhereOrNull(
                                                (e) =>
                                                    e.deviceId() ==
                                                    c.media.value
                                                        ?.audioDevice) ??
                                            c.devices.audio().firstOrNull)
                                        ?.label() ??
                                    'label_media_no_device_available'.l10n,
                                microphoneSwitch: () async {
                                  await MicrophoneSwitchView.show(
                                    context,
                                    mic: c.media.value?.audioDevice,
                                  );

                                  if (c.devices.audio().isEmpty) {
                                    c.devices.value =
                                        await MediaUtils.enumerateDevices();
                                  }
                                },
                                outputText: (c.devices
                                                .output()
                                                .firstWhereOrNull((e) =>
                                                    e.deviceId() ==
                                                    c.media.value
                                                        ?.outputDevice) ??
                                            c.devices.output().firstOrNull)
                                        ?.label() ??
                                    'label_media_no_device_available'.l10n,
                                outputSwitch: () async {
                                  await OutputSwitchView.show(
                                    context,
                                    output: c.media.value?.outputDevice,
                                  );

                                  if (c.devices.output().isEmpty) {
                                    c.devices.value =
                                        await MediaUtils.enumerateDevices();
                                  }
                                },
                              );
                            })
                          ],
                        );

                      case ProfileTab.notifications:
                        return Block(
                          title: 'label_audio_notifications'.l10n,
                          children: [
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
                            })
                          ],
                        );

                      case ProfileTab.storage:
                        return Block(
                          title: 'label_storage'.l10n,
                          children: [
                            Obx(() {
                              return SwitchField(
                                text: 'label_load_images'.l10n,
                                value: c.settings.value?.loadImages == true,
                                onChanged: c.settings.value == null
                                    ? null
                                    : (enabled) => c.setLoadImages(enabled),
                              );
                            })
                          ],
                        );

                      case ProfileTab.language:
                        return Block(
                          title: 'label_language'.l10n,
                          children: const [LanguageFieldButton()],
                        );

                      case ProfileTab.blocklist:
                        return Block(
                          title: 'label_blocked_users'.l10n,
                          children: [BlacklistField(c.blacklist)],
                        );

                      case ProfileTab.download:
                        if (!PlatformUtils.isWeb) {
                          return const SizedBox();
                        }

                        return Block(
                          title: 'label_download_application'.l10n,
                          children: const [DownloadColumn()],
                        );

                      case ProfileTab.danger:
                        return Block(
                          title: 'label_danger_zone'.l10n,
                          children: [
                            DangerFieldButton(() => _deleteAccount(c, context)),
                          ],
                        );

                      case ProfileTab.logout:
                        return const SizedBox();
                    }
                  },
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// Returns addable list of [MyUser.emails].
Widget _emails(MyProfileController c, BuildContext context) {
  final (style, fonts) = Theme.of(context).styles;

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
                offset: const Offset(0, -1),
                child: Transform.scale(
                  scale: 1.15,
                  child: SvgImage.asset('assets/icons/delete.svg', height: 14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'label_email_visible'.l10n,
                      style: fonts.bodySmall!.copyWith(
                        color: style.colors.secondary,
                      ),
                    ),
                    TextSpan(
                      text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
                      style: fonts.bodySmall!.copyWith(
                        color: style.colors.primary,
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
                                  style: fonts.headlineMedium,
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
            inputDecorationTheme:
                Theme.of(context).inputDecorationTheme.copyWith(
                      floatingLabelStyle: fonts.bodyMedium!.copyWith(
                        color: style.colors.primary,
                      ),
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
                child: SvgImage.asset('assets/icons/delete.svg', height: 14),
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
            style: fonts.titleMedium!.copyWith(color: style.colors.secondary),
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
          style: fonts.titleMedium!.copyWith(color: style.colors.primary),
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets.map((e) => Paddings.dense(e)).toList(),
    );
  });
}

/// Returns addable list of [MyUser.phones].
Widget _phones(MyProfileController c, BuildContext context) {
  final (style, fonts) = Theme.of(context).styles;

  return Obx(() {
    final List<Widget> widgets = [];

    for (UserPhone e in c.myUser.value?.phones.confirmed ?? []) {
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
                  child: SvgImage.asset('assets/icons/delete.svg', height: 14),
                ),
              ),
              onPressed: () {
                PlatformUtils.copy(text: e.val);
                MessagePopup.success('label_copied'.l10n);
              },
              onTrailingPressed: () => _deletePhone(c, context, e),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'label_phone_visible'.l10n,
                      style: fonts.bodySmall!.copyWith(
                        color: style.colors.secondary,
                      ),
                    ),
                    TextSpan(
                      text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
                      style: fonts.bodySmall!.copyWith(
                        color: style.colors.primary,
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
                                  style: fonts.headlineMedium,
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
            inputDecorationTheme:
                Theme.of(context).inputDecorationTheme.copyWith(
                      floatingLabelStyle: fonts.bodyMedium!.copyWith(
                        color: style.colors.primary,
                      ),
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
                child: SvgImage.asset('assets/icons/delete.svg', height: 14),
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
            style: fonts.titleMedium!.copyWith(color: style.colors.secondary),
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
          style: fonts.titleMedium!.copyWith(color: style.colors.primary),
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets.map((e) => Paddings.dense(e)).toList(),
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
  final fonts = Theme.of(context).fonts;

  final bool? result = await MessagePopup.alert(
    'label_delete_email'.l10n,
    description: [
      TextSpan(text: 'alert_email_will_be_deleted1'.l10n),
      TextSpan(text: email.val, style: fonts.labelLarge),
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
  final fonts = Theme.of(context).fonts;

  final bool? result = await MessagePopup.alert(
    'label_delete_phone_number'.l10n,
    description: [
      TextSpan(text: 'alert_phone_will_be_deleted1'.l10n),
      TextSpan(text: phone.val, style: fonts.labelLarge),
      TextSpan(text: 'alert_phone_will_be_deleted2'.l10n),
    ],
  );

  if (result == true) {
    await c.deletePhone(phone);
  }
}

/// Opens a confirmation popup deleting the [MyUser]'s account.
Future<void> _deleteAccount(MyProfileController c, BuildContext context) async {
  final fonts = Theme.of(context).fonts;

  final bool? result = await MessagePopup.alert(
    'label_delete_account'.l10n,
    description: [
      TextSpan(text: 'alert_account_will_be_deleted1'.l10n),
      TextSpan(
        text: c.myUser.value?.name?.val ??
            c.myUser.value?.login?.val ??
            c.myUser.value?.num.val ??
            'dot'.l10n * 3,
        style: fonts.labelLarge,
      ),
      TextSpan(text: 'alert_account_will_be_deleted2'.l10n),
    ],
  );

  if (result == true) {
    await c.deleteAccount();
  }
}
