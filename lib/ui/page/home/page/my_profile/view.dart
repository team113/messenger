// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '/config.dart';
import '/domain/model/application_settings.dart';
import '/domain/model/attachment.dart';
import '/domain/model/avatar.dart';
import '/domain/model/cache_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/my_user.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/domain/model/welcome_message.dart';
import '/domain/repository/session.dart';
import '/domain/repository/settings.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/auth/widget/cupertino_button.dart';
import '/ui/page/call/widget/fit_view.dart';
import '/ui/page/erase/view.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/page/my_profile/widget/switch_field.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/big_avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/copy_or_share.dart';
import '/ui/page/home/widget/direct_link.dart';
import '/ui/page/home/widget/field_button.dart';
import '/ui/page/home/widget/highlighted_container.dart';
import '/ui/page/home/widget/info_tile.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/page/login/privacy_policy/view.dart';
import '/ui/page/login/terms_of_use/view.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/download_button.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/safe_area/safe_area.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
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
import 'delete_email/view.dart';
import 'language/view.dart';
import 'microphone_switch/view.dart';
import 'output_switch/view.dart';
import 'password/view.dart';
import 'session/controller.dart';
import 'welcome_field/view.dart';
import 'widget/background_preview.dart';
import 'widget/bio.dart';
import 'widget/login.dart';
import 'widget/name.dart';

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
      ),
      global: !Get.isRegistered<MyProfileController>(),
      builder: (MyProfileController c) {
        return GestureDetector(
          onTap: FocusManager.instance.primaryFocus?.unfocus,
          child: Scaffold(
            appBar: CustomAppBar(title: _bar(c, context)),
            body: Builder(
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
  final ProfileTab tab = ProfileTab.values[i];

  // Builds a [Block] wrapped with [Obx] to highlight it.
  Widget block({String? title, required List<Widget> children}) {
    return Obx(() {
      return Block(
        title: title ?? tab.l10n,
        highlight: c.highlightIndex.value == i,
        children: children,
      );
    });
  }

  switch (tab) {
    case ProfileTab.public:
      return Obx(() {
        return HighlightedContainer(
          highlight: c.highlightIndex.value == i,
          child: Column(
            children: [
              block(
                children: [
                  Obx(() {
                    final UserAvatar? avatar = c.myUser.value?.avatar;

                    return BigAvatarWidget.myUser(
                      c.myUser.value,
                      loading: c.avatarUpload.value.isLoading,
                      onUpload: c.uploadAvatar,
                      onEdit: avatar != null ? c.editAvatar : null,
                      onDelete: avatar != null ? c.deleteAvatar : null,
                    );
                  }),
                ],
              ),
              block(
                title: 'label_about'.l10n,
                children: [
                  Paddings.basic(
                    Obx(() {
                      return UserNameField(
                        c.myUser.value?.name,
                        onSubmit: c.updateUserName,
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Paddings.basic(
                    Obx(() {
                      return UserBioField(
                        c.myUser.value?.bio,
                        onSubmit: c.updateUserBio,
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        );
      });

    case ProfileTab.signing:
      return block(
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

            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: UserLoginField(
                c.myUser.value?.login,
                onSubmit: (s) async {
                  await c.updateUserLogin(s);
                },
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
              onSubmit: (s) async {
                if (s == null) {
                  await c.deleteChatDirectLink();
                } else {
                  await c.createChatDirectLink(s);
                }
              },
              background: c.background.value,
              onEditing: (b) {
                if (b) {
                  final ItemPosition? first =
                      c.positionsListener.itemPositions.value.firstOrNull;

                  // If the [Block] containing this widget isn't fully visible,
                  // then animate to it's beginning.
                  if (first?.index == i && first!.itemLeadingEdge < 0) {
                    c.itemScrollController.scrollTo(
                      index: i,
                      curve: Curves.ease,
                      duration: const Duration(milliseconds: 600),
                    );
                    c.highlight(ProfileTab.link);
                  }
                }
              },
            );
          }),
        ],
      );

    case ProfileTab.background:
      return block(
        children: [
          Obx(() {
            return BackgroundPreview(
              c.background.value,
              onPick: c.pickBackground,
              onRemove: c.removeBackground,
            );
          }),
        ],
      );

    case ProfileTab.chats:
      return block(children: [_chats(context, c)]);

    case ProfileTab.calls:
      if (!PlatformUtils.isDesktop || !PlatformUtils.isWeb) {
        return const SizedBox();
      }

      return block(children: [_call(context, c)]);

    case ProfileTab.media:
      if (PlatformUtils.isMobile) {
        return const SizedBox();
      }

      return block(children: [_media(context, c)]);

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
        title: 'label_audio_notifications'.l10n,
        children: [
          Paddings.dense(
            Obx(() {
              final bool isMuted = c.myUser.value?.muted == null;

              return SwitchField(
                text: isMuted ? 'label_enabled'.l10n : 'label_disabled'.l10n,
                value: isMuted,
                onChanged: c.isMuting.value ? null : c.toggleMute,
              );
            }),
          ),
        ],
      );

    case ProfileTab.storage:
      if (PlatformUtils.isWeb) {
        return const SizedBox();
      }

      return block(children: [_storage(context, c)]);

    case ProfileTab.language:
      return block(children: [_language(context, c)]);

    case ProfileTab.blocklist:
      return block(children: [_blockedUsers(context, c)]);

    case ProfileTab.devices:
      return block(children: [_devices(context, c)]);

    case ProfileTab.download:
      if (!PlatformUtils.isWeb) {
        return const SizedBox();
      }

      return block(
        title: 'label_download_application'.l10n,
        children: [_downloads(context, c)],
      );

    case ProfileTab.danger:
      return block(children: [_danger(context, c)]);

    case ProfileTab.legal:
      return block(children: [_legal(context, c)]);

    case ProfileTab.support:
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

/// Returns list of [MyUser.emails].
Widget _emails(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Obx(() {
    final List<Widget> widgets = [];

    for (UserEmail e in c.myUser.value?.emails.confirmed ?? []) {
      widgets.add(
        InfoTile(
          key: const Key('ConfirmedEmail'),
          content: e.val,
          title: 'label_email'.l10n,
          trailing: WidgetButton(
            key: const Key('DeleteEmail'),
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
          key: const Key('UnconfirmedEmail'),
          content: unconfirmed.val,
          trailing: WidgetButton(
            onPressed:
                () => _deleteEmail(c, context, unconfirmed, confirmed: false),
            child: const SvgIcon(SvgIcons.delete),
          ),
          title: 'label_email_not_verified'.l10n,
          subtitle: [
            const SizedBox(height: 4),
            WidgetButton(
              key: const Key('VerifyEmail'),
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

/// Returns list of [MyUser.phones].
Widget _phones(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Obx(() {
    final List<Widget> widgets = [];

    for (UserPhone e in [...c.myUser.value?.phones.confirmed ?? []]) {
      widgets.add(
        InfoTile(
          key: const Key('ConfirmedPhone'),
          content: e.val,
          title: 'label_phone'.l10n,
          trailing: WidgetButton(
            key: const Key('DeletePhone'),
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
          key: const Key('UnconfirmedPhone'),
          content: unconfirmed.val,
          title: 'label_phone_not_verified'.l10n,
          trailing: WidgetButton(
            onPressed: () => _deletePhone(c, context, unconfirmed),
            child: const SvgIcon(SvgIcons.delete),
          ),
          subtitle: [
            const SizedBox(height: 4),
            WidgetButton(
              key: const Key('VerifyPhone'),
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

/// Returns the additional inputs of a [ProfileTab.signing] section.
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
              color: style.colors.onBackgroundOpacity27,
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
              color: style.colors.onBackgroundOpacity27,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Obx(() {
        if (c.myUser.value?.login != null) {
          return const SizedBox();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: UserLoginField(
            c.myUser.value?.login,
            onSubmit: (s) async {
              await c.updateUserLogin(s);
            },
          ),
        );
      }),
      Obx(() {
        final emails =
            [
              ...c.myUser.value?.emails.confirmed ?? <UserEmail>[],
              c.myUser.value?.emails.unconfirmed,
            ].nonNulls;

        final email = ReactiveTextField(
          key: const Key('Email'),
          state: c.email,
          label: 'label_add_email'.l10n,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hint: 'example@dummy.com',
          clearable: false,
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
            if (emails.isNotEmpty) ...[
              const SizedBox(height: 12),
              WidgetButton(
                key: const Key('ExpandSigning'),
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
              if (c.expanded.value) ...[const SizedBox(height: 24), email],
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
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Obx(() {
        return FieldButton(
          key:
              c.myUser.value?.hasPassword == true
                  ? const Key('ChangePassword')
                  : const Key('SetPassword'),
          text:
              c.myUser.value?.hasPassword == true
                  ? 'btn_change_password'.l10n
                  : 'btn_set_password'.l10n,
          onPressed: () => ChangePasswordView.show(context),
          warning: c.myUser.value?.hasPassword != true,
          trailing:
              c.myUser.value?.hasPassword == true
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
              null => 'label_media_buttons_in_app_bar'.l10n,
              CallButtonsPosition.contextMenu =>
                'label_media_buttons_in_context_menu'.l10n,
              CallButtonsPosition.top => 'label_media_buttons_in_top'.l10n,
              CallButtonsPosition.bottom =>
                'label_media_buttons_in_bottom'.l10n,
              CallButtonsPosition.more => 'label_media_buttons_in_more'.l10n,
            },
            maxLines: null,
            onPressed: () => CallButtonsSwitchView.show(context),
          );
        }),
      ),
    ],
  );
}

/// Returns the contents of a [ProfileTab.calls] section.
Widget _call(BuildContext context, MyProfileController c) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Paddings.dense(
        Obx(() {
          return FieldButton(
            text:
                (c.settings.value?.enablePopups ?? true)
                    ? 'label_open_calls_in_window'.l10n
                    : 'label_open_calls_in_app'.l10n,
            maxLines: null,
            onPressed: () => CallWindowSwitchView.show(context),
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
      Paddings.dense(
        Obx(() {
          final selected =
              c.devices.video().firstWhereOrNull(
                (e) => e.deviceId() == c.media.value?.videoDevice,
              ) ??
              c.devices.video().firstOrNull;

          return FieldButton(
            text: selected?.label() ?? 'label_media_no_device_available'.l10n,
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
          );
        }),
      ),
      const SizedBox(height: 16),
      Paddings.dense(
        Obx(() {
          final selected =
              c.devices.audio().firstWhereOrNull(
                (e) => e.id() == c.media.value?.audioDevice,
              ) ??
              c.devices.audio().firstOrNull;

          return FieldButton(
            text: selected?.label() ?? 'label_media_no_device_available'.l10n,
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
            final selected =
                c.devices.output().firstWhereOrNull(
                  (e) => e.id() == c.media.value?.outputDevice,
                ) ??
                c.devices.output().firstOrNull;

            return FieldButton(
              text: selected?.label() ?? 'label_media_no_device_available'.l10n,
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
            );
          }),
        ),
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
    final List<Attachment> media =
        attachments.where((e) {
          return ((e is ImageAttachment) ||
              (e is FileAttachment && e.isVideo) ||
              (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
        }).toList();

    final List<Attachment> files =
        attachments.where((e) {
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
                        bottomLeft:
                            text.isNotEmpty || files.isNotEmpty
                                ? Radius.zero
                                : files.isEmpty
                                ? const Radius.circular(15)
                                : Radius.zero,
                        bottomRight:
                            text.isNotEmpty || files.isNotEmpty
                                ? Radius.zero
                                : files.isEmpty
                                ? const Radius.circular(15)
                                : Radius.zero,
                      ),
                      child:
                          media.length == 1
                              ? ChatItemWidget.mediaAttachment(
                                context,
                                media.first,
                                media,
                                filled: false,
                              )
                              : SizedBox(
                                width: media.length * 120,
                                height: max(media.length * 60, 300),
                                child: FitView(
                                  dividerColor: Colors.transparent,
                                  children:
                                      media
                                          .mapIndexed(
                                            (i, e) =>
                                                ChatItemWidget.mediaAttachment(
                                                  context,
                                                  e,
                                                  media,
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
                        children:
                            files
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
              child:
                  timeInBubble
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
          onPressed:
              () => c.updateWelcomeMessage(
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
                  child:
                      c.background.value == null
                          ? const SvgImage.asset(
                            'assets/images/background_light.svg',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                          : Image.memory(
                            c.background.value!,
                            fit: BoxFit.cover,
                          ),
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

/// Returns the contents of a [ProfileTab.language] section.
Widget _language(BuildContext context, MyProfileController c) {
  return Paddings.dense(
    FieldButton(
      key: const Key('ChangeLanguage'),
      onPressed:
          () => LanguageSelectionView.show(
            context,
            Get.find<AbstractSettingsRepository>(),
          ),
      text: 'label_language_entry'.l10nfmt({
        'code': L10n.chosen.value!.locale.countryCode,
        'name': L10n.chosen.value!.name,
      }),
    ),
  );
}

/// Returns the contents of a [ProfileTab.blocklist] section.
Widget _blockedUsers(BuildContext context, MyProfileController c) {
  return Obx(() {
    final int count = c.blocklistCount.value;

    return Paddings.dense(
      FieldButton(
        key: const Key('ShowBlocklist'),
        text: 'label_users_count'.l10nfmt({'count': count}),
        onPressed: count == 0 ? null : () => BlocklistView.show(context),
      ),
    );
  });
}

/// Returns the contents of a [ProfileTab.devices] section.
Widget _devices(BuildContext context, MyProfileController c) {
  Widget device(RxSession rxSession) {
    return Obx(() {
      final Session session = rxSession.session.value;
      final IpGeoLocation? geo = rxSession.geo.value;

      final bool isCurrent = session.id == c.credentials.value?.sessionId;

      final String device =
          isCurrent
              ? 'label_this_device'.l10n
              : session.lastActivatedAt.val.yMdHm;

      final String title;
      if (geo == null) {
        title = device;
      } else {
        title = 'comma_separated_a_b_c'.l10nfmt({
          'a':
              isCurrent
                  ? 'label_this_device'.l10n
                  : session.lastActivatedAt.val.yMdHm,
          'b': geo.city,
          'c': geo.country,
        });
      }

      return Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: InfoTile(
          key: Key(isCurrent ? 'CurrentSession' : 'Session_${session.id}'),
          title: title,
          content: session.userAgent.localized,
          trailing:
              isCurrent
                  ? null
                  : WidgetButton(
                    key: const Key('DeleteSessionButton'),
                    onPressed: () => DeleteSessionView.show(context, session),
                    child: const SvgIcon(SvgIcons.delete),
                  ),
        ),
      );
    });
  }

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
              (e) => e.id == c.credentials.value?.sessionId,
            );

            if (current != null) {
              sessions.remove(current);
              sessions.insert(0, current);
            }

            return ListView.builder(
              controller: c.devicesScrollController,
              shrinkWrap: true,
              itemCount: sessions.length,
              itemBuilder: (_, i) {
                return Column(
                  children: [
                    device(sessions[i]),
                    if (i != sessions.length - 1) const SizedBox(height: 25),
                  ],
                );
              },
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
  return Paddings.dense(
    Column(
      children: [
        const DownloadButton.windows(),
        const SizedBox(height: 8),
        const DownloadButton.macos(),
        const SizedBox(height: 8),
        const DownloadButton.linux(),
        const SizedBox(height: 8),
        if (Config.appStoreUrl.isNotEmpty) ...[
          DownloadButton.appStore(),
          const SizedBox(height: 8),
        ],
        const DownloadButton.ios(),
        const SizedBox(height: 8),
        if (Config.googlePlayUrl.isNotEmpty) ...[
          DownloadButton.googlePlay(),
          const SizedBox(height: 8),
        ],
        const DownloadButton.android(),
      ],
    ),
  );
}

/// Returns the contents of a [ProfileTab.danger] section.
Widget _danger(BuildContext context, MyProfileController c) {
  return Column(
    children: [
      Paddings.dense(
        FieldButton(
          key: const Key('DeleteAccount'),
          text: 'btn_delete_account'.l10n,
          onPressed: () => _deleteAccount(c, context),
          danger: true,
        ),
      ),
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

  var index = values.indexWhere((e) => gbs <= e);
  if (index == -1) {
    index = values.length - 1;
  }

  final v = (index / (values.length - 1) * 100).round();

  return Paddings.dense(
    Column(
      children: [
        Obx(() {
          final int size = CacheWorker.instance.info.value.size;
          final int max =
              CacheWorker.instance.info.value.maxSize ??
              (values.last * GB).toInt();

          if (max >= 64 * GB) {
            return Text(
              'label_gb_occupied'.l10nfmt({
                'count': (size / GB).toPrecision(2),
              }),
            );
          } else if (max <= 0) {
            return Text('label_gb_occupied'.l10nfmt({'count': 0}));
          }

          return Text(
            'label_gb_of_gb_occupied'.l10nfmt({
              'a': (size / GB).toPrecision(2),
              'b': max ~/ GB,
            }),
          );
        }),
        SizedBox(
          height: 100,
          child: FlutterSlider(
            handlerHeight: 24,
            values: [v.toDouble()],
            tooltip: FlutterSliderTooltip(disabled: true),
            fixedValues:
                values.mapIndexed((i, e) {
                  return FlutterSliderFixedValue(
                    percent: ((i / (values.length - 1)) * 100).round(),
                    value: e * GB,
                  );
                }).toList(),
            trackBar: FlutterSliderTrackBar(
              inactiveTrackBar: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: style.colors.onBackgroundOpacity13,
              ),
              activeTrackBar: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: style.colors.primaryHighlight,
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
              density: 0.5,
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
                  percent: 49,
                  label: Text(
                    'label_count_gb'.l10nfmt({'count': 8}),
                    style: style.fonts.smallest.regular.secondary,
                  ),
                ),
                FlutterSliderHatchMarkLabel(
                  percent: 66,
                  label: Text(
                    'label_count_gb'.l10nfmt({'count': 16}),
                    style: style.fonts.smallest.regular.secondary,
                  ),
                ),
                FlutterSliderHatchMarkLabel(
                  percent: 83,
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
        FieldButton(onPressed: c.clearCache, text: 'btn_clear_cache'.l10n),
      ],
    ),
  );
}

/// Returns the buttons for legal related information displaying.
Widget _legal(BuildContext context, MyProfileController c) {
  final style = Theme.of(context).style;

  return Column(
    children: [
      Center(
        child: StyledCupertinoButton(
          label: 'btn_terms_and_conditions'.l10n,
          style: style.fonts.small.regular.primary,
          onPressed: () => TermsOfUseView.show(context),
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: StyledCupertinoButton(
          label: 'btn_privacy_policy'.l10n,
          style: style.fonts.small.regular.primary,
          onPressed: () => PrivacyPolicy.show(context),
        ),
      ),
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

  final bool? result = await MessagePopup.alert(
    'label_delete_email'.l10n,
    description: [
      TextSpan(text: 'alert_email_will_be_deleted1'.l10n),
      TextSpan(text: email.val, style: style.fonts.normal.regular.onBackground),
      TextSpan(text: 'alert_email_will_be_deleted2'.l10n),
    ],
  );

  if (result == true) {
    if (context.mounted) {
      if (confirmed) {
        if (c.myUser.value?.emails.confirmed.isNotEmpty == true ||
            c.myUser.value?.hasPassword == true) {
          await DeleteEmailView.show(context, email: email);
        } else {
          await c.deleteEmail(email);
        }
      } else {
        await c.deleteEmail(email);
      }
    }
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
  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const EraseView()));
}
