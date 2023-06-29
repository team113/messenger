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
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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
import 'widget/profile_tab/background.dart';
import 'widget/profile_tab/blacklist.dart';
import 'widget/profile_tab/calls.dart';
import 'widget/profile_tab/chats.dart';
import 'widget/profile_tab/danger.dart';
import 'widget/profile_tab/download.dart';
import 'widget/profile_tab/language.dart';
import 'widget/profile_tab/link.dart';
import 'widget/profile_tab/media.dart';
import 'widget/profile_tab/notifications.dart';
import 'widget/profile_tab/public.dart';
import 'widget/profile_tab/singing.dart';
import 'widget/profile_tab/storage.dart';

/// View of the [Routes.me] page.
class MyProfileView extends StatelessWidget {
  const MyProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

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
                                      ? () => c.uploadAvatar()
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
                            ProfileName(
                              c.name,
                              isHide: c.login.text.isEmpty,
                            ),
                            ProfilePresence(
                              text: c.myUser.value?.presence.localizedString(),
                              backgroundColor:
                                  c.myUser.value?.presence.getColor(),
                            ),
                            ProfileStatus(c.status),
                          ],
                        );

                      case ProfileTab.signing:
                        return Block(
                          title: 'label_login_options'.l10n,
                          children: [
                            ProfileNum(c.num, copy: c.myUser.value?.num.val),
                            ProfileLogin(
                              c.login,
                              hint: c.myUser.value?.login == null
                                  ? 'label_login_hint'.l10n
                                  : c.myUser.value?.login?.val,
                            ),
                            const SizedBox(height: 10),
                            ProfileEmails(
                              confirmedEmails: c.myUser.value?.emails.confirmed,
                              text: c.myUser.value?.emails.unconfirmed?.val,
                              hasUnconfirmed:
                                  c.myUser.value?.emails.unconfirmed != null,
                              onTrailingPressed: () => _deleteEmail(
                                c,
                                context,
                                c.myUser.value!.emails.unconfirmed!,
                              ),
                              onPressed: () => AddEmailView.show(
                                context,
                                email: c.myUser.value?.emails.unconfirmed!,
                              ),
                            ),
                            ProfilePhones(
                              confirmedPhones: c.myUser.value?.phones.confirmed,
                              text: c.myUser.value?.phones.unconfirmed?.val,
                              hasUnconfirmed:
                                  c.myUser.value?.phones.unconfirmed != null,
                              onPressed: () => AddPhoneView.show(
                                context,
                                phone: c.myUser.value?.phones.unconfirmed!,
                              ),
                              onTrailingPressed: () => _deletePhone(
                                c,
                                context,
                                c.myUser.value!.phones.unconfirmed!,
                              ),
                            ),
                            ProfilePassword(
                              hasPassword: c.myUser.value!.hasPassword,
                            ),
                          ],
                        );

                      case ProfileTab.link:
                        return Block(
                          title: 'label_your_direct_link'.l10n,
                          children: [
                            ProfileLink(
                              c.link,
                              transitionCount:
                                  c.myUser.value?.chatDirectLink?.usageCount,
                            )
                          ],
                        );

                      case ProfileTab.background:
                        return Block(
                          title: 'label_background'.l10n,
                          children: [
                            Obx(
                              () => ProfileBackground(
                                c.background.value,
                                () => c.pickBackground(),
                                () => c.removeBackground(),
                              ),
                            )
                          ],
                        );

                      case ProfileTab.chats:
                        return Block(
                          title: 'label_chats'.l10n,
                          children: [
                            Obx(
                              () => ProfileChats(
                                isTimeline: c.settings.value!.timelineEnabled,
                              ),
                            ),
                          ],
                        );

                      case ProfileTab.calls:
                        if (PlatformUtils.isDesktop && PlatformUtils.isWeb) {
                          return Block(
                            title: 'label_calls'.l10n,
                            children: [
                              Obx(
                                () => ProfileCall(
                                  enablePopups: c.settings.value?.enablePopups,
                                ),
                              )
                            ],
                          );
                        }

                        return const SizedBox();

                      case ProfileTab.media:
                        if (!PlatformUtils.isMobile) {
                          return Block(
                            title: 'label_media'.l10n,
                            children: [
                              Obx(
                                () => ProfileMedia(
                                  videoText: (c.devices
                                                  .video()
                                                  .firstWhereOrNull((e) =>
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
                                  audioText: (c.devices
                                                  .audio()
                                                  .firstWhereOrNull((e) =>
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
                                ),
                              )
                            ],
                          );
                        }

                        return const SizedBox();

                      case ProfileTab.notifications:
                        return Block(
                          title: 'label_audio_notifications'.l10n,
                          children: [
                            Obx(
                              () => ProfileNotifications(
                                isMuted: c.myUser.value?.muted == null,
                                onChanged: c.isMuting.value
                                    ? null
                                    : (enabled) => c.toggleMute(enabled),
                              ),
                            )
                          ],
                        );

                      case ProfileTab.storage:
                        return Block(
                          title: 'label_storage'.l10n,
                          children: [
                            Obx(
                              () => ProfileStorage(
                                value: c.settings.value?.loadImages == true,
                                onChanged: c.settings.value == null
                                    ? null
                                    : (enabled) => c.setLoadImages(enabled),
                              ),
                            )
                          ],
                        );

                      case ProfileTab.language:
                        return Block(
                          title: 'label_language'.l10n,
                          children: const [ProfileLanguage()],
                        );

                      case ProfileTab.blacklist:
                        return Block(
                          title: 'label_blocked_users'.l10n,
                          children: [ProfileBlockedUsers(c.blacklist)],
                        );

                      case ProfileTab.download:
                        if (PlatformUtils.isWeb) {
                          return Block(
                            title: 'label_download_application'.l10n,
                            children: const [ProfileDownloads()],
                          );
                        }

                        return const SizedBox();

                      case ProfileTab.danger:
                        return Block(
                          title: 'label_danger_zone'.l10n,
                          children: [
                            ProfileDanger(() => _deleteAccount(c, context)),
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
