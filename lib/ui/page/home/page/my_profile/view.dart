// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import '/ui/page/home/widget/copy_or_share.dart';
import '/ui/page/home/widget/info_tile.dart';
import '/ui/widget/text_field.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '/domain/model/application_settings.dart';
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
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/big_avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/direct_link.dart';
import '/ui/page/home/widget/field_button.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/widget/download_button.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/ui/worker/cache.dart';
import '/util/media_utils.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'add_email/view.dart';
import 'add_phone/view.dart';
import 'blocklist/view.dart';
import 'call_buttons_switch/controller.dart';
import 'call_window_switch/view.dart';
import 'camera_switch/view.dart';
import 'controller.dart';
import 'language/view.dart';
import 'microphone_switch/view.dart';
import 'output_switch/view.dart';
import 'password/view.dart';
import 'timeline_switch/view.dart';
import 'widget/background_preview.dart';
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
              title: Text('label_account'.l10n),
              padding: const EdgeInsets.only(left: 4, right: 20),
              leading: const [StyledBackButton()],
            ),
            body: Builder(builder: (context) {
              final Widget child = ScrollablePositionedList.builder(
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
                    required String title,
                    required List<Widget> children,
                  }) {
                    return Obx(() {
                      return Block(
                        title: title,
                        highlight: c.highlightIndex.value == i,
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
                          )
                        ],
                      );

                    case ProfileTab.signing:
                      return block(
                        title: 'label_login_options'.l10n,
                        children: [
                          Paddings.basic(
                            Obx(() {
                              return InfoTile(
                                title: 'label_num'.l10n,
                                content: c.myUser.value?.num.toString() ?? '',
                                trailing: CopyOrShareButton(
                                  c.myUser.value?.num.toString() ?? '',
                                ),
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
                                child: InfoTile(
                                  title: 'label_login'.l10n,
                                  content: c.myUser.value!.login.toString(),
                                  trailing: WidgetButton(
                                    onPressed: () =>
                                        c.updateUserLogin(UserLogin('')),
                                    child: const SvgIcon(SvgIcons.delete),
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          _emails(context, c),
                          _phones(context, c),
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
                              onSubmit: c.createChatDirectLink,
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
                      if (!PlatformUtils.isDesktop || !PlatformUtils.isWeb) {
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
                      if (PlatformUtils.isWeb) {
                        return const SizedBox();
                      }

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

                    case ProfileTab.logout:
                      return const SizedBox();
                  }
                },
              );

              if (PlatformUtils.isMobile) {
                return Scrollbar(controller: c.scrollController, child: child);
              }

              return child;
            }),
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
        InfoTile(
          content: e.val,
          title: 'label_email'.l10n,
          trailing: WidgetButton(
            onPressed: () => _deleteEmail(c, context, e),
            child: const SvgIcon(SvgIcons.delete),
          ),
        ),
      );

      widgets.add(const SizedBox(height: 8));
    }

    final unconfirmed = c.myUser.value?.emails.unconfirmed;

    if (unconfirmed != null) {
      widgets.add(
        InfoTile(
          content: unconfirmed.val,
          trailing: WidgetButton(
            onPressed: () => _deleteEmail(c, context, unconfirmed),
            child: const SvgIcon(SvgIcons.delete),
          ),
          title: 'label_email_not_verified'.l10n,
          subtitle: [
            const SizedBox(height: 4),
            WidgetButton(
              onPressed: () => AddEmailView.show(context, email: unconfirmed),
              child: Text(
                'label_verify'.l10n,
                style: style.fonts.small.regular.primary,
              ),
            ),
          ],
          danger: true,
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
        InfoTile(
          content: e.val,
          title: 'label_phone'.l10n,
          trailing: WidgetButton(
            onPressed: () => _deletePhone(c, context, e),
            child: const SvgIcon(SvgIcons.delete),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 8));
    }

    final unconfirmed = c.myUser.value?.phones.unconfirmed;

    if (unconfirmed != null) {
      widgets.add(
        InfoTile(
          content: unconfirmed.val,
          title: 'label_phone_not_verified'.l10n,
          trailing: WidgetButton(
            onPressed: () => _deletePhone(c, context, unconfirmed),
            child: const SvgIcon(SvgIcons.delete),
          ),
          subtitle: [
            const SizedBox(height: 4),
            WidgetButton(
              onPressed: () => AddPhoneView.show(context, phone: unconfirmed),
              child: Text(
                'label_verify'.l10n,
                style: style.fonts.small.regular.primary,
              ),
            ),
          ],
          danger: true,
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

/// Returns the add options content of a [ProfileTab.signing] section.
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
            'label_actions'.l10n,
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
        ].whereNotNull();

        final phone = ReactiveTextField(
          state: c.phone,
          label: 'label_add_phone'.l10n,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hint: '+34 123 123 53 53',
          formatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d+ ]')),
          ],
        );
        final email = ReactiveTextField(
          state: c.email,
          label: 'label_add_email'.l10n,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hint: 'example@dummy.com',
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emails.isEmpty) const SizedBox(height: 12),
            if (emails.isEmpty) email,
            if (emails.isEmpty) const SizedBox(height: 12),
            const SizedBox(height: 12),
            _password(context, c),
            const SizedBox(height: 6),
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
                    c.expanded.value ? 'btn_hide'.l10n : 'btn_add'.l10n,
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
            ],
          ],
        );
      }),
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
              ? const SvgIcon(SvgIcons.passwordSmall)
              : const SvgIcon(SvgIcons.passwordSmallWhite),
        );
      }),
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
              style: style.fonts.normal.regular.secondary,
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
            style: style.fonts.normal.regular.primary,
          );
        }),
      ),
      const SizedBox(height: 16),
      Paddings.dense(
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 21),
            child: Text(
              'label_display_audio_and_video_call_buttons'.l10n,
              style: style.fonts.normal.regular.secondary,
            ),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Paddings.dense(
        Obx(() {
          return FieldButton(
            text: switch (c.settings.value?.callButtonsPosition) {
              CallButtonsPosition.appBar ||
              null =>
                'label_media_buttons_in_app_bar'.l10n,
              CallButtonsPosition.contextMenu =>
                'label_media_buttons_in_context_menu'.l10n,
              CallButtonsPosition.top => 'label_media_buttons_in_top'.l10n,
              CallButtonsPosition.bottom =>
                'label_media_buttons_in_bottom'.l10n,
              CallButtonsPosition.more => 'label_media_buttons_in_more'.l10n,
            },
            maxLines: null,
            onPressed: () => CallButtonsSwitchView.show(context),
            style: style.fonts.normal.regular.primary,
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
      style: style.fonts.normal.regular.primary,
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

/// Returns the contents of a [ProfileTab.danger] section.
Widget _danger(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Column(
    children: [
      Paddings.dense(
        FieldButton(
          key: const Key('DeleteAccount'),
          text: 'btn_delete_account'.l10n,
          onPressed: () => _deleteAccount(c, context),
          style: style.fonts.normal.regular.danger,
        ),
      ),
    ],
  );
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

  final gbs =
      CacheWorker.instance.info.value.maxSize?.toDouble() ?? 64 * GB / GB;
  var index = values.indexWhere((e) => gbs <= e);
  if (index == -1) {
    index = values.length - 1;
  }

  final v = (index / (values.length - 1) * 100).round();

  return Paddings.dense(
    Column(
      children: [
        Column(
          children: [
            Obx(() {
              final int size = CacheWorker.instance.info.value.size;
              final int max =
                  CacheWorker.instance.info.value.maxSize ?? 64 * GB;

              if (max >= 64 * GB) {
                return Text(
                  'label_takes_gb'
                      .l10nfmt({'count': (size / GB).toPrecision(2)}),
                );
              } else if (max <= 0) {
                return Text('label_takes_gb'.l10nfmt({'count': 0}));
              }

              return Text(
                'label_takes_gb_of_gb'.l10nfmt({'a': (size / GB).toPrecision(2), 'b': max ~/ GB}),
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
                  ),
                  activeTrackBar: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.blue.withOpacity(1),
                  ),
                ),
                onDragging: (i, lower, upper) {
                  if (lower is double) {
                    if (lower == 64.0 * GB) {
                      CacheWorker.instance.setMaxSize(null);
                    } else {
                      CacheWorker.instance.setMaxSize(lower.round());
                    }
                  }
                },
                onDragCompleted: (i, lower, upper) {
                  if (lower is double) {
                    if (lower == 64.0 * GB) {
                      CacheWorker.instance.setMaxSize(null);
                    } else {
                      CacheWorker.instance.setMaxSize(lower.round());
                    }
                  }
                },
                hatchMark: FlutterSliderHatchMark(
                  labelsDistanceFromTrackBar: -48,
                  linesAlignment: FlutterSliderHatchMarkAlignment.right,
                  density: 0.5, // means 50 lines, from 0 to 100 percent
                  labels: [
                    FlutterSliderHatchMarkLabel(
                      percent: 0,
                      label: Text(
                        'label_off'.l10n,
                        style: style.fonts.smallest.regular.secondary,
                      ),
                    ),
                    FlutterSliderHatchMarkLabel(
                      percent: 16,
                      label: Text(
                        'label_count_gb'.l10nfmt({'count': 2}),
                        style: style.fonts.smallest.regular.secondary,
                      ),
                    ),
                    FlutterSliderHatchMarkLabel(
                      percent: 32,
                      label: Text(
                        'label_count_gb'.l10nfmt({'count': 4}),
                        style: style.fonts.smallest.regular.secondary,
                      ),
                    ),
                    FlutterSliderHatchMarkLabel(
                      percent: 48,
                      label: Text(
                        'label_count_gb'.l10nfmt({'count': 8}),
                        style: style.fonts.smallest.regular.secondary,
                      ),
                    ),
                    FlutterSliderHatchMarkLabel(
                      percent: 64,
                      label: Text(
                        'label_count_gb'.l10nfmt({'count': 16}),
                        style: style.fonts.smallest.regular.secondary,
                      ),
                    ),
                    FlutterSliderHatchMarkLabel(
                      percent: 80,
                      label: Text(
                        'label_count_gb'.l10nfmt({'count': 32}),
                        style: style.fonts.smallest.regular.secondary,
                      ),
                    ),
                    FlutterSliderHatchMarkLabel(
                      percent: 100,
                      label: Text(
                        'label_no_limit'.l10n,
                        style: style.fonts.smallest.regular.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            FieldButton(
              onPressed: c.clearCache,
              text: 'btn_clear_cache'.l10n,
              style: style.fonts.normal.regular.primary,
            ),
          ],
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
