// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:pwa_install/pwa_install.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '/api/backend/schema.dart' show UserPresence;
import '/config.dart';
import '/domain/model/attachment.dart';
import '/domain/model/cache_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/my_user.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/model/welcome_message.dart';
import '/domain/repository/session.dart';
import '/domain/repository/settings.dart';
import '/l10n/l10n.dart';
import '/pubspec.g.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/fit_view.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/page/my_profile/widget/switch_field.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/big_avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/direct_link.dart';
import '/ui/page/home/widget/field_button.dart';
import '/ui/page/home/widget/scroll_keyboard_handler.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/download_button.dart';
import '/ui/widget/line_divider.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/safe_area/safe_area.dart';
import '/ui/widget/styled_slider.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/upgrade_popup/view.dart';
import '/ui/widget/widget_button.dart';
import '/ui/worker/cache.dart';
import '/ui/worker/call.dart';
import '/util/media_utils.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'add_email/view.dart';
import 'blocklist/view.dart';
import 'call_window_switch/view.dart';
import 'camera_switch/view.dart';
import 'controller.dart';
import 'delete_email/view.dart';
import 'language/view.dart';
import 'microphone_switch/view.dart';
import 'muted_chats/view.dart';
import 'output_switch/view.dart';
import 'password/view.dart';
import 'presence_switch/view.dart';
import 'session/controller.dart';
import 'welcome_field/view.dart';
import 'widget/background_preview.dart';
import 'widget/session_tile.dart';

/// View of the [Routes.me] page.
class MyProfileView extends StatelessWidget {
  const MyProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      key: const Key('MyProfileView'),
      init: MyProfileController(
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
      global: !Get.isRegistered<MyProfileController>(),
      builder: (MyProfileController c) {
        return GestureDetector(
          onTap: FocusManager.instance.primaryFocus?.unfocus,
          child: Scaffold(
            appBar: CustomAppBar(title: _bar(c, context)),
            body: ScrollKeyboardHandler(
              scrollController: c.scrollController,
              child: Builder(
                builder: (context) {
                  final Widget child = ScrollablePositionedList.builder(
                    key: const Key('MyProfileScrollable'),
                    initialScrollIndex: c.listInitIndex,
                    scrollController: c.scrollController,
                    itemScrollController: c.itemScrollController,
                    itemPositionsListener: c.positionsListener,
                    itemCount: ProfileTab.values.length,
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (context, i) => _block(context, c, i),
                  );

                  if (PlatformUtils.isMobile) {
                    return Scrollbar(
                      controller: c.scrollController,
                      child: child,
                    );
                  }

                  return child;
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

/// Builds the [ProfileTab] at the specified [i] index.
Widget _block(BuildContext context, MyProfileController c, int i) {
  final style = Theme.of(context).style;

  final ProfileTab tab = ProfileTab.values[i];

  // Builds a [Block] wrapped with [Obx] to highlight it.
  Widget block({
    String? title,
    required List<Widget> children,
    bool clipHeight = false,
  }) {
    return Obx(() {
      return Block(
        title: title ?? tab.l10n,
        highlight: c.highlightIndex.value == i,
        clipHeight: clipHeight,
        children: children,
      );
    });
  }

  switch (tab) {
    case ProfileTab.public:
      return _profile(context, c);

    case ProfileTab.signing:
      return Obx(() {
        final Widget animated;

        bool hasPassword = c.myUser.value?.hasPassword == true;
        bool hasEmail = c.myUser.value?.emails.confirmed.isNotEmpty == true;

        if (!hasPassword || !hasEmail) {
          final InputBorder border = OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: style.colors.secondary, width: 0.5),
          );

          animated = Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 16.0),
            child: InputDecorator(
              decoration: InputDecoration(
                border: border,
                errorBorder: border,
                enabledBorder: border,
                focusedBorder: border,
                disabledBorder: border,
                focusedErrorBorder: border,
                focusColor: style.colors.onPrimary,
                fillColor: style.colors.onPrimary,
                hoverColor: style.colors.transparent,
                floatingLabelAlignment: FloatingLabelAlignment.center,
                contentPadding: EdgeInsets.fromLTRB(24, 26, 24, 26),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: style.colors.danger,
                      ),
                      child: Center(
                        child: Text(
                          'exclamation_mark'.l10n,
                          style: style.fonts.smallest.regular.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'label_warning'.l10n,
                      style: style.fonts.medium.regular.secondary,
                    ),
                  ],
                ),
              ),
              child: Text(
                hasPassword
                    ? 'label_introduction_description_email'.l10n
                    : 'label_introduction_description'.l10n,
                style: style.fonts.small.regular.secondary,
              ),
            ),
          );
        } else {
          animated = const SizedBox(key: Key('None'), width: double.infinity);
        }

        return block(
          children: [
            AnimatedSizeAndFade(
              fadeDuration: const Duration(milliseconds: 300),
              sizeDuration: const Duration(milliseconds: 300),
              child: animated,
            ),
            _addInfo(context, c),
            const SizedBox(height: 20),
            LineDivider('label_password'.l10n),
            const SizedBox(height: 16),
            _password(context, c),
          ],
        );
      });

    case ProfileTab.link:
      return block(
        title: 'label_your_direct_link'.l10n,
        children: [
          Obx(() {
            return DirectLinkField(
              c.myUser.value?.chatDirectLink,
              onSubmit: (s) async {
                if (s == null) {
                  await c.deleteChatDirectLink();
                } else {
                  await c.createChatDirectLink(s);
                }
              },
              background: c.background.value,
            );
          }),
        ],
      );

    case ProfileTab.interface:
      return block(
        children: [
          LineDivider('label_language'.l10n),
          const SizedBox(height: 16),
          FieldButton(
            key: const Key('ChangeLanguage'),
            onPressed: () => LanguageSelectionView.show(
              context,
              Get.find<AbstractSettingsRepository>(),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Text(L10n.chosen.value!.locale.languageCode.toUpperCase()),
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 14,
                  color: style.colors.secondaryHighlightDarkest,
                ),
                const SizedBox(width: 12),
                Text(L10n.chosen.value!.name),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LineDivider('label_background'.l10n),
          const SizedBox(height: 16),
          Obx(() {
            return BackgroundPreview(
              c.background.value,
              onPick: c.pickBackground,
              onRemove: c.removeBackground,
            );
          }),
          if (PlatformUtils.isWeb && !PlatformUtils.isMobile) ...[
            const SizedBox(height: 20),
            LineDivider('label_call_window'.l10n),
            const SizedBox(height: 16),
            _call(context, c),
          ],
        ],
      );

    case ProfileTab.media:
      if (PlatformUtils.isMobile) {
        return const SizedBox();
      }

      return block(clipHeight: true, children: [_media(context, c)]);

    case ProfileTab.welcome:
      return Obx(() {
        return Block(
          title: tab.l10n,
          highlight: c.highlightIndex.value == i,
          padding: Block.defaultPadding.copyWith(right: 0, left: 0),
          children: [_welcome(context, c)],
        );
      });

    case ProfileTab.notifications:
      return block(
        children: [
          LineDivider('label_all_chats_and_groups'.l10n),
          const SizedBox(height: 16),
          Obx(() {
            final bool isMuted = c.myUser.value?.muted == null;

            return SwitchField(
              text: isMuted ? 'label_unmuted'.l10n : 'label_muted'.l10n,
              value: isMuted,
              onChanged: c.isMuting.value ? null : c.toggleMute,
            );
          }),
          const SizedBox(height: 20),
          LineDivider('label_always_muted'.l10n),
          const SizedBox(height: 16),
          Obx(() {
            return FieldButton(
              text: 'label_chats_and_groups'.l10nfmt({
                'count': c.mutedChatsCount,
              }),
              onPressed: () async => MutedChatsView.show(context),
            );
          }),
          const SizedBox(height: 8),
        ],
      );

    case ProfileTab.storage:
      if (PlatformUtils.isWeb) {
        return const SizedBox();
      }

      return block(children: [_storage(context, c)]);

    case ProfileTab.confidential:
      return block(children: [_confidential(context, c)]);

    case ProfileTab.devices:
      return block(children: [_devices(context, c)]);

    case ProfileTab.download:
      return block(
        title: 'label_download_and_update'.l10n,
        children: [_downloads(context, c)],
      );

    case ProfileTab.danger:
      return const SizedBox();

    case ProfileTab.legal:
      return const SizedBox();

    case ProfileTab.logout:
      return const CustomSafeArea(
        top: false,
        right: false,
        left: false,
        child: SizedBox(),
      );
  }
}

/// Builds a [Widget] representing the publicly visible information of [MyUser].
Widget _profile(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Block(
    title: 'label_profile'.l10n,
    children: [
      SelectionContainer.disabled(
        child: Obx(() {
          return BigAvatarWidget.myUser(
            c.myUser.value,
            loading: c.avatarUpload.value.isLoading,
            error: c.avatarUpload.value.errorMessage,
            onUpload: c.uploadAvatar,
            onEdit: c.myUser.value?.avatar != null ? c.editAvatar : null,
            onDelete: c.myUser.value?.avatar != null ? c.deleteAvatar : null,
          );
        }),
      ),
      const SizedBox(height: 16),
      const SizedBox(height: 8),
      Obx(() {
        return ReactiveTextField(
          key: Key('NameField'),
          state: c.name,
          label: 'label_your_name'.l10n,
          hint: '${c.myUser.value?.num}',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          formatters: [LengthLimitingTextInputFormatter(100)],
        );
      }),
      const SizedBox(height: 21),
      Obx(() {
        final UserPresence presence =
            c.myUser.value?.presence ?? UserPresence.present;

        return FieldButton(
          key: Key('StatusButton'),
          headline: Text('label_your_status'.l10n),
          onPressed: () async => await PresenceSwitchView.show(context),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: switch (presence) {
                    UserPresence.present => style.colors.acceptAuxiliary,
                    UserPresence.away => style.colors.warning,
                    (_) => style.colors.secondary,
                  },
                ),
                width: 8,
                height: 8,
              ),
              SizedBox(width: 5),
              Expanded(
                child: Text(switch (presence) {
                  UserPresence.present => 'label_presence_present'.l10n,
                  UserPresence.away => 'label_presence_away'.l10n,
                  (_) => '',
                }, textAlign: TextAlign.left),
              ),
              Text(
                'btn_change'.l10n,
                style: style.fonts.medium.regular.primary,
              ),
              SizedBox(width: 5),
            ],
          ),
        );
      }),
      const SizedBox(height: 21),
      ReactiveTextField(
        key: Key('TextStatusField'),
        state: c.status,
        label: 'label_text_status'.l10n,
        hint: 'label_text_status_description'.l10n,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        maxLines: 1,
        formatters: [LengthLimitingTextInputFormatter(4096)],
      ),
      const SizedBox(height: 21),
      ReactiveTextField(
        key: Key('BioField'),
        state: c.about,
        label: 'label_about_you'.l10n,
        hint: 'label_about_you_description'.l10n,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        maxLines: null,
        formatters: [LengthLimitingTextInputFormatter(4096)],
        type: TextInputType.multiline,
      ),
      const SizedBox(height: 8),
    ],
  );
}

/// Returns the additional inputs of a [ProfileTab.signing] section.
Widget _addInfo(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Obx(() {
    final List<Widget> widgets = [];

    final List<UserEmail> emails = [...c.myUser.value?.emails.confirmed ?? []];

    for (var i = 0; i < emails.length; ++i) {
      final UserEmail e = emails[i];

      widgets.add(
        ReactiveTextField(
          key: Key('ConfirmedEmail_$i'),
          state: TextFieldState(text: e.val, editable: false),
          label: 'label_email'.l10n,
          trailing: WidgetButton(
            key: Key('DeleteEmail_$i'),
            onPressed: () => _deleteEmail(c, context, e),
            child: Center(child: SvgIcon(SvgIcons.delete)),
          ),
          spellCheck: false,
        ),
      );

      widgets.add(const SizedBox(height: 21));
    }

    final unconfirmed = c.myUser.value?.emails.unconfirmed;

    if (unconfirmed != null) {
      widgets.add(
        ReactiveTextField(
          key: const Key('UnconfirmedEmail'),
          state: TextFieldState(text: unconfirmed.val, editable: false),
          label: 'label_email'.l10n,
          style: style.fonts.medium.regular.onBackground.copyWith(
            color: style.colors.danger,
          ),
          trailing: WidgetButton(
            onPressed: () =>
                _deleteEmail(c, context, unconfirmed, confirmed: false),
            child: Center(child: SvgIcon(SvgIcons.delete)),
          ),
          spellCheck: false,
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        LineDivider('label_identifiers'.l10n),
        const SizedBox(height: 20),
        Obx(() {
          return ReactiveTextField(
            key: Key('LoginField'),
            state: c.login,
            label: 'label_login'.l10n,
            hint: 'label_login_example'.l10n,
            prefixText: '@',
            prefixStyle: c.login.isEmpty.value
                ? style.fonts.medium.regular.secondary.copyWith(
                    color: style.colors.secondaryHighlightDarkest,
                  )
                : style.fonts.medium.regular.onBackground,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            formatters: [LengthLimitingTextInputFormatter(100)],
            spellCheck: false,
            trailing: c.myUser.value?.login == null
                ? null
                : WidgetButton(
                    onPressed: () {},
                    onPressedWithDetails: (u) {
                      PlatformUtils.copy(text: '${c.myUser.value?.login}');
                      MessagePopup.success(
                        'label_copied'.l10n,
                        at: u.globalPosition,
                      );
                    },
                    child: Center(child: SvgIcon(SvgIcons.copy)),
                  ),
          );
        }),
        const SizedBox(height: 21),
        ReactiveTextField.copyable(
          text: '${c.myUser.value?.num}',
          label: 'label_num'.l10n,
        ),
        const SizedBox(height: 21),
        ...widgets,
        // Don't display the button when there's already 2 added emails.
        if (unconfirmed != null || emails.length < 2)
          FieldButton(
            key: Key(
              unconfirmed == null ? 'AddEmailButton' : 'VerifyEmailButton',
            ),
            text: unconfirmed == null
                ? 'label_add_email'.l10n
                : 'btn_confirm_email'.l10n,
            onPressed: unconfirmed == null && emails.length >= 2
                ? null
                : () => AddEmailView.show(context, email: unconfirmed),

            maxLines: 2,
            trailing: unconfirmed == null && emails.length >= 2
                ? const SvgIcon(SvgIcons.emailGrey)
                : const SvgIcon(SvgIcons.emailWhite),
            warning: true,
          ),
        const SizedBox(height: 6),
      ],
    );
  });
}

/// Returns the buttons changing or setting the password of the currently
/// authenticated [MyUser].
Widget _password(BuildContext context, MyProfileController c) {
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
          warning: true,
          trailing: c.myUser.value?.hasPassword == true
              ? const SvgIcon(SvgIcons.password)
              : const SvgIcon(SvgIcons.passwordWhite),
        );
      }),
      const SizedBox(height: 10),
    ],
  );
}

/// Returns the contents of a [ProfileTab.calls] section.
Widget _call(BuildContext context, MyProfileController c) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Obx(() {
        return FieldButton(
          text: (c.settings.value?.enablePopups ?? true)
              ? 'label_open_calls_in_window'.l10n
              : 'label_open_calls_in_app'.l10n,
          maxLines: null,
          onPressed: () => CallWindowSwitchView.show(context),
        );
      }),
    ],
  );
}

/// Returns the contents of a [ProfileTab.media] section.
Widget _media(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Obx(() {
        final selected =
            c.devices.audio().firstWhereOrNull(
              (e) => e.id() == c.media.value?.audioDevice,
            ) ??
            c.devices.audio().firstOrNull;

        return FieldButton(
          text: selected?.label() ?? 'label_media_no_device_available'.l10n,
          trailing: Transform.translate(
            offset: Offset(5, 0),
            child: SvgIcon(SvgIcons.mediaDevicesMicrophone),
          ),
          onPressed: () async {
            await MicrophoneSwitchView.show(
              context,
              mic: c.media.value?.audioDevice,
            );

            if (c.devices.audio().isEmpty) {
              c.devices.value = await MediaUtils.enumerateDevices();
            }
          },
        );
      }),

      // TODO: Remove, when Safari supports output devices without tweaking the
      //       developer options:
      //       https://bugs.webkit.org/show_bug.cgi?id=216641
      if (!WebUtils.isSafari || c.devices.output().isNotEmpty) ...[
        const SizedBox(height: 12),
        Obx(() {
          final selected =
              c.devices.output().firstWhereOrNull(
                (e) => e.id() == c.media.value?.outputDevice,
              ) ??
              c.devices.output().firstOrNull;

          return FieldButton(
            text: selected?.label() ?? 'label_media_no_device_available'.l10n,
            trailing: Transform.translate(
              offset: Offset(5, 0),
              child: SvgIcon(SvgIcons.mediaDevicesSpeaker),
            ),
            onPressed: () async {
              await OutputSwitchView.show(
                context,
                output: c.media.value?.outputDevice,
              );

              if (c.devices.output().isEmpty) {
                c.devices.value = await MediaUtils.enumerateDevices();
              }
            },
          );
        }),
      ],
      const SizedBox(height: 12),
      Obx(() {
        final selected =
            c.devices.video().firstWhereOrNull(
              (e) => e.deviceId() == c.media.value?.videoDevice,
            ) ??
            c.devices.video().firstOrNull;

        return FieldButton(
          text: selected?.label() ?? 'label_media_no_device_available'.l10n,
          trailing: Transform.translate(
            offset: Offset(5, 0),
            child: SvgIcon(SvgIcons.mediaDevicesCamera),
          ),
          onPressed: () async {
            await CameraSwitchView.show(
              context,
              camera: c.media.value?.videoDevice,
            );

            if (c.devices.video().isEmpty) {
              c.devices.value = await MediaUtils.enumerateDevices();
            }
          },
        );
      }),

      SizedBox(height: 20),
      LineDivider('label_hotkey'.l10n),
      SizedBox(height: 16),
      Obx(() {
        final HotKey key =
            c.settings.value?.muteHotKey ?? MuteHotKeyExtension.defaultHotKey;

        final Iterable<String> modifiers = (key.modifiers ?? [])
            .map(
              (e) => e.physicalKeys.map((e) {
                return KeyboardKeyToStringExtension.labels[e] ??
                    e.debugName ??
                    'question_mark'.l10n;
              }),
            )
            .expand((e) => e)
            .toSet();

        final String keys =
            KeyboardKeyToStringExtension.labels[key.physicalKey] ??
            key.physicalKey.debugName ??
            'label_unknown'.l10n;

        return FieldButton(
          headline: Text(
            'label_mute_slash_unmute_microphone'.l10n,
            style: c.hotKeyRecording.value
                ? style.fonts.normal.regular.primary
                : style.fonts.normal.regular.secondary,
          ),
          onPressed: c.toggleHotKey,
          border: c.hotKeyRecording.value
              ? BorderSide(color: style.colors.primary, width: 1)
              : null,
          child: Row(
            children: [
              if (c.hotKeyRecording.value)
                Expanded(
                  child: Text(
                    'label_key_plus_key_by_default'.l10nfmt({
                      'modifier': PlatformUtils.isMacOS ? '⌥' : 'Alt',
                      'key': 'M',
                    }),
                    textAlign: TextAlign.left,
                    style: style.fonts.normal.regular.secondary,
                  ),
                )
              else
                Expanded(
                  child: Text(
                    [...modifiers, keys].join('space_plus_space'.l10n),
                    textAlign: TextAlign.left,
                  ),
                ),
              Text(
                c.hotKeyRecording.value ? 'btn_cancel'.l10n : 'btn_change'.l10n,
                style: style.fonts.medium.regular.primary,
              ),
            ],
          ),
        );
      }),

      // Voice processing is unavailable for mobile platforms.
      if (!PlatformUtils.isMobile) ...[
        const SizedBox(height: 20),
        LineDivider('label_voice_processing'.l10n),
        const SizedBox(height: 16),
        Obx(() {
          return SwitchField(
            text: 'label_echo_cancellation'.l10n,
            value: c.media.value?.echoCancellation ?? false,
            onChanged: c.setEchoCancellation,
          );
        }),
        const SizedBox(height: 16),
        Obx(() {
          return SwitchField(
            text: 'label_auto_gain_control'.l10n,
            value: c.media.value?.autoGainControl ?? false,
            onChanged: c.setAutoGainControl,
          );
        }),

        // High pass filter and noise suppression level are only available under
        // desktops.
        if (PlatformUtils.isWeb) ...[
          const SizedBox(height: 16),
          Obx(() {
            final bool enabled = c.media.value?.noiseSuppression ?? true;

            return SwitchField(
              text: 'label_noise_suppression'.l10n,
              value: enabled,
              onChanged: (e) => c.setNoiseSuppression(
                e
                    ? NoiseSuppressionLevelWithOff.veryHigh
                    : NoiseSuppressionLevelWithOff.off,
              ),
            );
          }),
          const SizedBox(height: 8),
        ] else ...[
          const SizedBox(height: 16),
          Obx(() {
            return SwitchField(
              text: 'label_high_pass_filter'.l10n,
              value: c.media.value?.highPassFilter ?? false,
              onChanged: c.setHighPassFilter,
            );
          }),
          const SizedBox(height: 20),
          LineDivider('label_noise_suppression'.l10n),
          SizedBox(height: 8),
          Obx(() {
            NoiseSuppressionLevelWithOff? level =
                c.media.value?.noiseSuppression != true
                ? NoiseSuppressionLevelWithOff.off
                : NoiseSuppressionLevelWithOff.values
                      .whereNot((e) => e == NoiseSuppressionLevelWithOff.off)
                      .firstWhereOrNull(
                        (e) =>
                            e.toLevel() == c.media.value?.noiseSuppressionLevel,
                      );
            level ??= NoiseSuppressionLevelWithOff.off;

            return StyledSlider(
              value: level,
              values: NoiseSuppressionLevelWithOff.values,
              labelBuilder: (_, value) {
                return Text(
                  textAlign: TextAlign.center,
                  switch (value) {
                    NoiseSuppressionLevelWithOff.off =>
                      'label_noise_suppression_disabled'.l10n,
                    NoiseSuppressionLevelWithOff.low =>
                      'label_noise_suppression_low'.l10n,
                    NoiseSuppressionLevelWithOff.moderate =>
                      'label_noise_suppression_medium'.l10n,
                    NoiseSuppressionLevelWithOff.high =>
                      'label_noise_suppression_high'.l10n,
                    NoiseSuppressionLevelWithOff.veryHigh =>
                      'label_noise_suppression_very_high'.l10n,
                  },
                  style: style.fonts.smaller.regular.secondary,
                );
              },
              onCompleted: c.setNoiseSuppression,
            );
          }),
        ],
      ],
    ],
  );
}

/// Returns the contents of a [ProfileTab.welcome] section.
Widget _welcome(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  Widget info({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: style.systemMessageBorder,
            color: style.systemMessageColor,
          ),
          child: DefaultTextStyle(
            style: style.systemMessageStyle,
            child: child,
          ),
        ),
      ),
    );
  }

  // Builds the provided [text] and [attachments] as a [ChatMessage] widget.
  Widget message({
    String text = '123',
    List<Attachment> attachments = const [],
    PreciseDateTime? at,
  }) {
    final List<Attachment> media = attachments.where((e) {
      return ((e is ImageAttachment) ||
          (e is FileAttachment && e.isVideo) ||
          (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
    }).toList();

    final List<Attachment> files = attachments.where((e) {
      return ((e is FileAttachment && !e.isVideo) ||
          (e is LocalAttachment && !e.file.isImage && !e.file.isVideo));
    }).toList();

    final bool timeInBubble = attachments.isNotEmpty;

    Widget? timeline;
    if (at != null) {
      timeline = SelectionContainer.disabled(
        child: Text(
          at.val.toLocal().hm,
          style: style.systemMessageStyle.copyWith(fontSize: 11),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(5 * 2, 6, 5 * 2, 6),
      child: Stack(
        children: [
          IntrinsicWidth(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                color: style.readMessageColor,
                borderRadius: BorderRadius.circular(15),
                border: style.secondaryBorder,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (media.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: text.isNotEmpty || files.isNotEmpty
                            ? Radius.zero
                            : files.isEmpty
                            ? const Radius.circular(15)
                            : Radius.zero,
                        bottomRight: text.isNotEmpty || files.isNotEmpty
                            ? Radius.zero
                            : files.isEmpty
                            ? const Radius.circular(15)
                            : Radius.zero,
                      ),
                      child: media.length == 1
                          ? ChatItemWidget.mediaAttachment(
                              context,
                              attachment: media.first,
                              filled: false,
                            )
                          : SizedBox(
                              width: media.length * 120,
                              height: max(media.length * 60, 300),
                              child: FitView(
                                dividerColor: Colors.transparent,
                                children: media
                                    .mapIndexed(
                                      (i, e) => ChatItemWidget.mediaAttachment(
                                        context,
                                        attachment: e,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                    ),
                  if (files.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 6, 0, 4),
                      child: Column(
                        children: files
                            .map((e) => ChatItemWidget.fileAttachment(e))
                            .toList(),
                      ),
                    ),
                  if (text.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        files.isEmpty ? 6 : 0,
                        12,
                        6,
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: text),
                            if (timeline != null)
                              WidgetSpan(
                                child: Opacity(opacity: 0, child: timeline),
                              ),
                          ],
                        ),
                        style: style.fonts.medium.regular.onBackground,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (timeline != null)
            Positioned(
              right: timeInBubble ? 4 : 8,
              bottom: 4,
              child: timeInBubble
                  ? Container(
                      padding: const EdgeInsets.only(
                        left: 5,
                        right: 5,
                        top: 2,
                        bottom: 2,
                      ),
                      decoration: BoxDecoration(
                        color: style.readMessageColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: timeline,
                    )
                  : timeline,
            ),
        ],
      ),
    );
  }

  final Widget editOrDelete = info(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        WidgetButton(
          key: const Key('EditWelcomeMessage'),
          onPressed: () async {
            final WelcomeMessage? message = c.myUser.value?.welcomeMessage;

            c.welcome.edited.value = message;
            c.welcome.field.unchecked = message?.text?.val;
            c.welcome.attachments.value =
                message?.attachments
                    .map((e) => MapEntry(GlobalKey(), e))
                    .toList() ??
                [];
            c.welcome.field.unsubmit();
          },
          child: Text('btn_edit'.l10n, style: style.systemMessagePrimary),
        ),
        Text('space_or_space'.l10n, style: style.systemMessageStyle),
        WidgetButton(
          key: const Key('DeleteWelcomeMessage'),
          onPressed: () => c.updateWelcomeMessage(
            text: const ChatMessageText(''),
            attachments: [],
          ),
          child: Text(
            'btn_delete'.l10n.toLowerCase(),
            style: style.systemMessagePrimary,
          ),
        ),
      ],
    ),
  );

  return Column(
    children: [
      Padding(
        padding: Block.defaultPadding
            .copyWith(top: 0, bottom: 0)
            .add(const EdgeInsets.fromLTRB(8, 0, 8, 0)),
        child: Text(
          'label_welcome_message_description'.l10n,
          style: style.fonts.small.regular.secondary,
        ),
      ),
      const SizedBox(height: 16),
      Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: style.primaryBorder,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Obx(() {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: c.background.value == null
                      ? const SvgImage.asset(
                          'assets/images/background_light.svg',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.memory(c.background.value!, fit: BoxFit.cover),
                );
              }),
            ),
          ),
          Obx(() {
            return Column(
              children: [
                const SizedBox(height: 16),
                if (c.myUser.value?.welcomeMessage == null)
                  Padding(
                    key: const Key('NoWelcomeMessage'),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: SizedBox(
                      height: 60 * 1.5,
                      child: info(
                        child: Text(
                          'label_no_welcome_message'.l10n,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else ...[
                  info(
                    child: Text(
                      c.myUser.value?.welcomeMessage?.at?.val.toRelative() ??
                          '',
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: IgnorePointer(
                        child: message(
                          text: c.myUser.value?.welcomeMessage?.text?.val ?? '',
                          attachments:
                              c.myUser.value?.welcomeMessage?.attachments ?? [],
                          at: c.myUser.value?.welcomeMessage?.at,
                        ),
                      ),
                    ),
                  ),
                  editOrDelete,
                ],
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(13),
                    bottomRight: Radius.circular(13),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(1),
                    child: WelcomeFieldView(
                      key: c.welcomeFieldKey,
                      fieldKey: const Key('WelcomeMessageField'),
                      sendKey: const Key('PostWelcomeMessage'),
                      controller: c.welcome,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    ],
  );
}

/// Returns the contents of a [ProfileTab.confidential] section.
Widget _confidential(BuildContext context, MyProfileController c) {
  return Obx(() {
    final int count = c.blocklistCount.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldButton(
          key: const Key('ShowBlocklist'),
          text: 'label_blocked_users_count'.l10nfmt({'count': count}),
          onPressed: count == 0 ? null : () => BlocklistView.show(context),
        ),
        const SizedBox(height: 8),
      ],
    );
  });
}

/// Returns the contents of a [ProfileTab.devices] section.
Widget _devices(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Scrollbar(
          controller: c.devicesScrollController,
          child: Obx(() {
            final List<RxSession> sessions = c.sessions.toList();

            final RxSession? current = sessions.firstWhereOrNull(
              (e) => e.id == c.credentials.value?.session.id,
            );

            if (current != null) {
              sessions.remove(current);
            }

            return ListView(
              controller: c.devicesScrollController,
              shrinkWrap: true,
              children: [
                if (current != null) ...[
                  LineDivider('label_this_device'.l10n),
                  SizedBox(height: 12),
                  SessionTileWidget(current, isCurrent: true),
                  if (sessions.isNotEmpty) ...[
                    SizedBox(height: 6),
                    Center(
                      child: WidgetButton(
                        onPressed: () async {
                          await DeleteSessionView.show(
                            context,
                            sessions,
                            exceptCurrent: true,
                          );
                        },
                        child: Text(
                          key: Key('TerminateAllSessions'),
                          'btn_terminate_all_other_sessions'.l10n,
                          style: style.fonts.small.regular.danger,
                        ),
                      ),
                    ),
                  ],
                ],
                if (sessions.isNotEmpty) ...[
                  if (current != null) SizedBox(height: 20),
                  LineDivider('label_active_devices'.l10n),
                  SizedBox(height: 12),
                  ...sessions.mapIndexed((i, e) {
                    return Column(
                      children: [
                        SessionTileWidget(e),
                        SizedBox(height: 6),
                        Center(
                          child: WidgetButton(
                            key: Key('TerminateSession_$i'),
                            onPressed: () async {
                              await DeleteSessionView.show(context, [e]);
                            },
                            child: Text(
                              'btn_terminate_this_session'.l10n,
                              style: style.fonts.small.regular.danger,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    );
                  }),
                ],
              ],
            );
          }),
        ),
      ),
      Obx(() {
        if (c.sessions.isNotEmpty) {
          return const SizedBox();
        } else {
          return const Padding(
            padding: EdgeInsets.only(top: 10),
            child: SizedBox.square(
              dimension: 17,
              child: CustomProgressIndicator(),
            ),
          );
        }
      }),
    ],
  );
}

/// Returns the contents of a [ProfileTab.download] section.
Widget _downloads(BuildContext context, MyProfileController c) {
  final Widget latestButton = Obx(() {
    final latest =
        c.latestRelease.value == null ||
        c.latestRelease.value?.name == Pubspec.ref;

    return PrimaryButton(
      title: latest
          ? 'label_latest_version_is_installed'.l10n
          : 'btn_download_version'.l10nfmt({
              'version': '${c.latestRelease.value?.name}',
            }),
      onPressed: latest
          ? null
          : () async {
              await UpgradePopupView.show(
                context,
                release: c.latestRelease.value!,
              );
            },
    );
  });

  return Column(
    children: [
      WidgetButton(
        onPressed: () {},
        onPressedWithDetails: (u) {
          PlatformUtils.copy(text: Pubspec.ref);
          MessagePopup.success('label_copied'.l10n, at: u.globalPosition);
        },
        child: LineDivider(
          'label_version_semicolon'.l10nfmt({'version': Pubspec.ref}),
        ),
      ),
      SizedBox(height: 16),
      if (!PlatformUtils.isWeb)
        latestButton
      else
        FieldButton(
          text: 'btn_install_web_app'.l10n,
          onPressed: () async {
            if (PWAInstall().installPromptEnabled) {
              PWAInstall().promptInstall_();
            } else {
              MessagePopup.error(
                'label_installation_error_description'.l10n,
                title: 'label_installation_error'.l10n,
              );
            }
          },
          trailing: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: SvgIcon(SvgIcons.logo, height: 21),
          ),
        ),
      if (Config.appStoreUrl.isNotEmpty || Config.googlePlayUrl.isNotEmpty) ...[
        SizedBox(height: 20),
        LineDivider('label_mobile_apps'.l10n),
        SizedBox(height: 16),
      ],
      if (Config.appStoreUrl.isNotEmpty) ...[
        DownloadButton.appStore(),
        const SizedBox(height: 8),
      ],
      // TODO: Uncomment when ready to ship the provided platforms.
      // const DownloadButton.ios(),
      // const SizedBox(height: 8),
      if (Config.googlePlayUrl.isNotEmpty) ...[
        DownloadButton.googlePlay(),
        const SizedBox(height: 8),
      ],
      // const DownloadButton.android(),
      // SizedBox(height: 20),
      // LineDivider('label_desktop_apps'.l10n),
      // SizedBox(height: 16),
      // const DownloadButton.windows(),
      // const SizedBox(height: 8),
      // const DownloadButton.macos(),
      // const SizedBox(height: 8),
      // const DownloadButton.linux(),
      // const SizedBox(height: 8),
    ],
  );
}

/// Returns the contents of a [ProfileTab.storage] section.
Widget _storage(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  final List<double> values = [0.0, 2.0, 4.0, 8.0, 16.0, 32.0, 64.0];

  final gbs =
      (CacheWorker.instance.info.value.maxSize?.toDouble() ??
          (values.last * GB)) /
      GB;

  /// One megabyte in bytes.
  // ignore: constant_identifier_names
  const int MB = 1024 * 1024;

  return Column(
    children: [
      LineDivider('label_cache'.l10n),
      const SizedBox(height: 16),
      Obx(() {
        final int size = CacheWorker.instance.info.value.size;

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'label_occupied_space'.l10n,
                    style: style.fonts.normal.regular.onBackground,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'label_mb'.l10nfmt({
                      'amount': '${(size / MB).toPrecision(2)}',
                    }),
                    style: style.fonts.small.regular.secondary,
                  ),
                ],
              ),
            ),
            WidgetButton(
              onPressed: c.clearCache,
              child: Text(
                'btn_clear_cache'.l10n,
                style: style.fonts.medium.regular.primary,
              ),
            ),
          ],
        );
      }),
      const SizedBox(height: 16),
      Obx(() {
        final int max =
            CacheWorker.instance.info.value.maxSize ??
            (values.last * GB).toInt();

        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'label_cache_limit_gb'.l10nfmt({
              'gb': '${max ~/ GB == 64 ? 'label_no_limit'.l10n : max ~/ GB}',
            }),
          ),
        );
      }),
      StyledSlider(
        value: values[values.indexWhere((e) => gbs <= e)],
        values: values,
        labelBuilder: (_, value) {
          return Text(
            textAlign: TextAlign.center,
            switch (value) {
              64 => 'label_no_limit'.l10n,
              (_) => 'label_count_gb'.l10nfmt({'count': value}),
            },
            style: style.fonts.smaller.regular.secondary,
          );
        },
        onCompleted: (value) {
          if (value == 64) {
            CacheWorker.instance.setMaxSize(null);
          } else {
            CacheWorker.instance.setMaxSize((value * GB).round());
          }
        },
      ),
      Obx(() {
        if (c.downloadsDirectory.value == null) {
          return SizedBox();
        }
        return Column(
          children: [
            const SizedBox(height: 12),
            LineDivider('label_saved_files'.l10n),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'label_download_path'.l10n,
                        style: style.fonts.normal.regular.onBackground,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${c.downloadsDirectory.value?.path}',
                        style: style.fonts.small.regular.secondary,
                      ),
                    ],
                  ),
                ),

                // TODO: Uncomment when implemented.
                // WidgetButton(
                //   onPressed: () {},
                //   child: Text(
                //     'btn_change'.l10n,
                //     style: style.fonts.medium.regular.primary,
                //   ),
                // ),
              ],
            ),
          ],
        );
      }),
      SizedBox(height: 8),
    ],
  );
}

/// Returns information about the [MyUser].
Widget _bar(MyProfileController c, BuildContext context) {
  final style = Theme.of(context).style;

  final Widget title;

  if (context.isNarrow) {
    title = Row(
      children: [
        const SizedBox(width: 4),
        const StyledBackButton(),
        Center(
          child: Obx(() {
            return AvatarWidget.fromMyUser(
              c.myUser.value,
              radius: AvatarRadius.medium,
            );
          }),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: DefaultTextStyle.merge(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: Obx(() {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.myUser.value?.name?.val ??
                        c.myUser.value?.num.toString() ??
                        'dot'.l10n * 3,
                    style: style.fonts.big.regular.onBackground,
                  ),
                  Text(
                    'label_online'.l10n,
                    style: style.fonts.small.regular.secondary,
                  ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  } else {
    title = Row(
      key: const Key('Profile'),
      children: [
        const SizedBox(width: 4),
        const StyledBackButton(),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
            child: Center(
              child: Text(
                router.profileSection.value?.l10n ?? 'label_profile'.l10n,
              ),
            ),
          ),
        ),
      ],
    );
  }

  return Row(
    children: [
      Expanded(
        child: SafeAnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: title,
        ),
      ),
      const SizedBox(width: 52),
    ],
  );
}

/// Opens a confirmation popup deleting the provided [email] from the
/// [MyUser.emails].
Future<void> _deleteEmail(
  MyProfileController c,
  BuildContext context,
  UserEmail email, {
  bool confirmed = true,
}) async {
  final style = Theme.of(context).style;

  final bool hasPasswordOrEmail =
      c.myUser.value?.emails.confirmed.isNotEmpty == true ||
      c.myUser.value?.hasPassword == true;

  if (confirmed && hasPasswordOrEmail) {
    await DeleteEmailView.show(context, email: email);
  }

  final bool? result = await MessagePopup.alert(
    'label_delete_email'.l10n,
    description: [
      TextSpan(
        text: 'alert_email_will_be_deleted1'.l10n,
        style: style.fonts.small.regular.secondary,
      ),
      TextSpan(text: email.val, style: style.fonts.small.regular.onBackground),
      TextSpan(
        text: 'alert_email_will_be_deleted2'.l10n,
        style: style.fonts.small.regular.secondary,
      ),
    ],
    button: MessagePopup.deleteButton,
  );

  if (result == true) {
    await c.deleteEmail(email);
  }
}
