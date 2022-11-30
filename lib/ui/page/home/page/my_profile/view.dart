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

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';
import 'package:medea_flutter_webrtc/medea_flutter_webrtc.dart' as webrtc;
import 'package:messenger/domain/model/ongoing_call.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/download/view.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';
import 'package:messenger/ui/page/home/tab/menu/view.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/confirm_dialog.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/selector.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:messenger/util/web/web_utils.dart';

import '/api/backend/schema.dart';
import '/config.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/gallery.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/text_field.dart';
import 'add_email/view.dart';
import 'add_phone/view.dart';
import 'call_window_switch/view.dart';
import 'camera_switch/view.dart';
import 'change_password/view.dart';
import 'controller.dart';
import 'delete_account/view.dart';
import 'delete_email/view.dart';
import 'delete_phone/view.dart';
import 'language/view.dart';
import 'link_details/view.dart';
import 'microphone_switch/view.dart';
import 'output_switch/view.dart';
import 'widget/copyable.dart';
import 'widget/dropdown.dart';

/// View of the [Routes.me] page.
class MyProfileView extends StatelessWidget {
  const MyProfileView({Key? key}) : super(key: key);

  /// Displays an [MyProfileView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(
      context: context,
      desktopConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      modalConstraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
      mobileConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      mobilePadding: const EdgeInsets.all(0),
      child: const MyProfileView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    final Style style = Theme.of(context).extension<Style>()!;

    return GetBuilder(
      key: const Key('MyProfileView'),
      init: MyProfileController(
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
      builder: (MyProfileController c) {
        return GestureDetector(
          onTap: FocusManager.instance.primaryFocus?.unfocus,
          child: Scaffold(
            appBar: CustomAppBar(
              title: const Text('Profile'),
              padding: const EdgeInsets.only(left: 4, right: 20),
              leading: const [StyledBackButton()],
              actions: [
                WidgetButton(
                  onPressed: () {},
                  child: SvgLoader.asset(
                    'assets/icons/search.svg',
                    width: 17.77,
                  ),
                ),
              ],
            ),
            body: Obx(() {
              if (c.myUser.value == null) {
                return const CircularProgressIndicator();
              }

              Widget block({List<Widget> children = const []}) {
                return Center(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    decoration: BoxDecoration(
                      // color: Colors.white,
                      border: style.primaryBorder,
                      color: style.messageColor,
                      borderRadius: BorderRadius.circular(15),
                      // border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    // constraints: context.isNarrow
                    //     ? null
                    //     : const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: children,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return ListView(
                children: [
                  const SizedBox(height: 8),
                  // _label(context, 'Публичная информация'),
                  block(
                    children: [
                      _label(context, 'Публичная информация'),
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
                              quality: AvatarQuality.original,
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
                                          child: CircularProgressIndicator(),
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
                                    'Delete',
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
                  ),
                  // _label(context, 'Параметры входа'),
                  block(
                    children: [
                      _label(context, 'Параметры входа'),
                      _num(c),
                      // _link(context, c),
                      // const SizedBox(height: 20),
                      const SizedBox(height: 10),
                      _login(c, context),
                      const SizedBox(height: 10),
                      // const SizedBox(height: 10),
                      // // _emails(c, context),
                      // _password(context, c),
                      // const SizedBox(height: 10),
                      // _deleteAccount(c),
                      _emails(c, context),
                      _password(context, c),
                    ],
                  ),
                  block(
                    children: [
                      _label(context, 'Прямая ссылка на чат с Вами'),
                      _link(context, c),
                    ],
                  ),
                  block(children: [
                    _label(context, 'Бэкграунд'),
                    _personalization(context, c),
                  ]),
                  if (!PlatformUtils.isMobile)
                    block(children: [
                      _label(context, 'Звонки'),
                      _call(context, c),
                    ]),
                  if (!PlatformUtils.isMobile)
                    block(children: [
                      _label(context, 'Медиа'),
                      _media(context, c),
                    ]),
                  block(children: [
                    _label(context, 'Язык'),
                    _language(context, c),
                  ]),
                  block(children: [
                    _label(context, 'Скачать приложение'),
                    _downloads(context, c),
                  ]),
                  block(children: [
                    _label(context, 'Опасная зона'),
                    _deleteAccount(context, c),
                  ]),
                  const SizedBox(height: 8),
                ],
              );
            }),
          ),
        );

        if (context.isNarrow) {
          return const MenuTabView();
        }

        return Scaffold(appBar: AppBar());

        return Obx(() {
          if (c.myUser.value == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          return GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 0,
                right: 0,
                top: 16,
                bottom: 16,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      children: [
                        LayoutBuilder(builder: (context, constraints) {
                          return WidgetButton(
                            onPressed: () async {
                              if (c.myUser.value?.avatar == null) {
                                await c.uploadAvatar();
                              } else {
                                await ModalPopup.show(
                                  context: context,
                                  modalConstraints:
                                      const BoxConstraints(maxWidth: 300),
                                  child: Builder(builder: (context) {
                                    return ListView(
                                      shrinkWrap: true,
                                      children: [
                                        OutlinedRoundedButton(
                                          title: const Text(
                                            'Change',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          color: const Color(0xFF63B4FF),
                                          onPressed: () {
                                            c.uploadAvatar();
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        OutlinedRoundedButton(
                                          color: const Color(0xFF63B4FF),
                                          title: const Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          onPressed: () {
                                            c.deleteAvatar();
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  }),
                                );
                              }
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AvatarWidget.fromMyUser(
                                  c.myUser.value,
                                  radius: 30,
                                  showBadge: false,
                                ),
                                Positioned.fill(
                                  child: Obx(() {
                                    return AnimatedSwitcher(
                                      duration: 200.milliseconds,
                                      child: c.avatarUpload.value.isLoading
                                          ? Container(
                                              width: 60,
                                              height: 60,
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
                          );
                        }),
                        const SizedBox(height: 20),
                        _name(c),
                        const SizedBox(height: 10),
                        _num(c),
                        const SizedBox(height: 10),
                        _presence(c),
                        const SizedBox(height: 10),
                        _link(context, c),
                        const SizedBox(height: 15),
                        _login(c, context),
                        const SizedBox(height: 10),
                        _phones(c, context),
                        _emails(c, context),
                        _password(context, c),
                        _deleteAccount(context, c),
                        ListTile(
                          leading: const Icon(Icons.settings),
                          title: Text('Settings'.l10n),
                          onTap: () => router.settings(push: true),
                        ),
                        ListTile(
                          leading: const Icon(Icons.workspaces),
                          title: Text('Personalization'.l10n),
                          onTap: () => router.personalization(push: true),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedRoundedButton(
                            maxWidth: null,
                            title: Text(
                              'btn_logout'.l10n,
                              style: thin, //?.copyWith(color: Colors.white),
                            ),
                            onPressed: () async {
                              if (await c.confirmLogout()) {
                                router.go(await c.logout());
                                router.tab = HomeTab.chats;
                              }
                            },
                            color: const Color(0xFFEEEEEE),
                            // color: const Color(0xFF63B4FF),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedRoundedButton(
                            key: const Key('CloseButton'),
                            maxWidth: null,
                            title: Text('btn_close'.l10n, style: thin),
                            onPressed: Navigator.of(context).pop,
                            color: const Color(0xFFEEEEEE),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
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

/// Returns [CarouselGallery] of [MyUser.gallery].
Widget _gallery(MyProfileController c) {
  return DropTarget(
    onDragDone: (details) => c.dropFiles(details),
    onDragEntered: (_) => c.isDraggingFiles.value = true,
    onDragExited: (_) => c.isDraggingFiles.value = false,
    child: Obx(
      () => CarouselGallery(
        items: c.myUser.value?.gallery,
        index: c.galleryIndex.value,
        onChanged: (i) => c.galleryIndex.value = i,
        onCarouselController: (g) => c.galleryController = g,
        overlay: [
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6, right: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    key: const Key('AddGallery'),
                    mini: true,
                    onPressed: c.addGalleryStatus.value.isLoading
                        ? null
                        : c.pickGalleryItem,
                    child: ElasticAnimatedSwitcher(
                      child: c.addGalleryStatus.value.isLoading
                          ? const Icon(Icons.timer, key: ValueKey('Load'))
                          : c.addGalleryStatus.value.isSuccess
                              ? const Icon(
                                  Icons.check,
                                  key: ValueKey('Success'),
                                )
                              : const Icon(
                                  Icons.add,
                                  key: ValueKey('Empty'),
                                ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (c.myUser.value?.gallery?.isNotEmpty == true) ...[
                    FloatingActionButton(
                      key: const Key('DeleteGallery'),
                      mini: true,
                      onPressed: c.deleteGalleryStatus.value.isLoading
                          ? null
                          : c.deleteGalleryItem,
                      child: ElasticAnimatedSwitcher(
                        child: c.deleteGalleryStatus.value.isLoading
                            ? const Icon(Icons.timer, key: ValueKey('Load'))
                            : c.deleteGalleryStatus.value.isSuccess
                                ? const Icon(
                                    Icons.check,
                                    key: ValueKey('Success'),
                                  )
                                : const Icon(
                                    Icons.remove,
                                    key: ValueKey('Empty'),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FloatingActionButton(
                      key: const Key('AvatarStatus'),
                      mini: true,
                      onPressed: c.avatarStatus.value.isLoading
                          ? null
                          : c.isAvatar
                              ? c.deleteAvatar
                              : c.updateAvatar,
                      child: ElasticAnimatedSwitcher(
                        child: c.avatarStatus.value.isLoading
                            ? const Icon(Icons.timer, key: ValueKey('Load'))
                            : c.avatarStatus.value.isSuccess
                                ? const Icon(
                                    Icons.check,
                                    key: ValueKey('Success'),
                                  )
                                : c.isAvatar
                                    ? const Icon(
                                        Icons.cancel_outlined,
                                        key: ValueKey('Empty_delete'),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        key: ValueKey('Empty_apply'),
                                      ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: c.isDraggingFiles.value
                ? Container(
                    color: Colors.white.withOpacity(0.9),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.upload_file,
                            size: 30,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'label_drop_here'.l10n,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    ),
  );
}

/// Returns [MyUser.name] editable field.
Widget _name(MyProfileController c) {
  return _padding(
    ReactiveTextField(
      key: const Key('NameField'),
      state: c.name,
      // style: const TextStyle(fontSize: 20),
      // suffix: Icons.edit,
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

/// Returns [MyUser.bio] editable field.
Widget _bio(MyProfileController c) => _padding(
      ReactiveTextField(
        key: const Key('BioField'),
        state: c.bio,
        suffix: Icons.edit,
        label: 'label_biography'.l10n,
        hint: 'label_biography_hint'.l10n,
      ),
    );

/// Returns [MyUser.presence] dropdown.
Widget _presence(MyProfileController c) => _padding(
      ReactiveDropdown<Presence>(
        key: const Key('PresenceDropdown'),
        state: c.presence,
        label: 'label_presence'.l10n,
      ),
    );

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
          // const SizedBox(height: 4),
          // RichText(
          //   text: const TextSpan(
          //     style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
          //     children: [
          //       TextSpan(
          //         text: 'Ваш логин публичен. Для изменения этой настройки... ',
          //         style: TextStyle(color: Color(0xFF888888)),
          //       ),
          //       TextSpan(
          //         text: 'Ещё',
          //         style: TextStyle(color: Color(0xFF00A3FF)),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );

/// Returns [MyUser.chatDirectLink] editable field.
Widget _link(BuildContext context, MyProfileController c) {
  final TextStyle? thin =
      Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

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

                  // Clipboard.setData(
                  //   ClipboardData(
                  //     text:
                  //         '${Config.origin}${Routes.chatDirectLink}/${c.myUser.value?.chatDirectLink?.slug.val}',
                  //   ),
                  // );

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
                    const TextSpan(
                      text: 'Переходов: 0. ',
                      // style: TextStyle(color: Color(0xFF888888)),
                      style: TextStyle(color: Color(0xFF888888)),
                    ),
                    TextSpan(
                      text: 'Подробнее.',
                      style: const TextStyle(color: Color(0xFF00A3FF)),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          LinkDetailsView.show(context);
                        },
                    ),
                  ],
                ),
              ),
              // const Spacer(),
              // RichText(
              //   text: TextSpan(
              //     style: const TextStyle(
              //         fontSize: 11, fontWeight: FontWeight.normal),
              //     children: [
              //       TextSpan(
              //         text: 'Подробнее',
              //         style: const TextStyle(color: Color(0xFF00A3FF)),
              //         recognizer: TapGestureRecognizer()..onTap = () async {},
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
  });

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
                  title: Text('btn_delete_direct_chat_link'.l10n, style: thin),
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
          // Row(
          //   children: [
          //     Text(
          //       '${'label_transition_count'.l10n}: ${c.myUser.value?.chatDirectLink?.usageCount ?? 0}',
          //       textAlign: TextAlign.start,
          //     ),
          //     Expanded(
          //       child: Row(
          //         mainAxisAlignment: MainAxisAlignment.end,
          //         children: [
          //           if (c.myUser.value?.chatDirectLink != null &&
          //               !c.link.isEmpty.value)
          //             Flexible(
          //               child: _textButton(
          //                 context,
          //                 key: const Key('RemoveChatDirectLink'),
          //                 onPressed:
          //                     c.link.editable.value ? c.deleteLink : null,
          //                 label: 'btn_delete_direct_chat_link'.l10n,
          //               ),
          //             ),
          //           Flexible(
          //             child: _textButton(
          //               context,
          //               key: const Key('GenerateChatDirectLink'),
          //               onPressed: c.link.editable.value
          //                   ? c.link.isEmpty.value
          //                       ? c.generateLink
          //                       : c.link.submit
          //                   : null,
          //               label: c.link.isEmpty.value
          //                   ? 'btn_generate_direct_chat_link'.l10n
          //                   : 'btn_submit'.l10n,
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),
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
                            onPressed: ExpandableController.of(context)?.toggle,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // child ??
              //     Padding(
              //       padding: const EdgeInsets.symmetric(horizontal: 5),
              //       child: OutlinedRoundedButton(
              //         key: key,
              //         maxWidth: null,
              //         height: 50,
              //         title: Row(
              //           children: [
              //             const SizedBox(width: 10),
              //             Text(title, style: thin),
              //             const Spacer(),
              //             const Icon(
              //               Icons.expand_more,
              //               color: Color(0xFF888888),
              //             ),
              //             const SizedBox(width: 10),
              //           ],
              //         ),
              //         color: const Color(0xFFFFFFFF),
              //         onPressed: ExpandableController.of(context)?.toggle,
              //         border: Border.all(color: const Color(0xFF888888)),
              //         borderRadius: BorderRadius.circular(50),
              //       ),
              //     ),
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
                const TextSpan(
                  text: 'Ваш логин видят: ',
                  style: TextStyle(color: Color(0xFF888888)),
                ),
                TextSpan(
                  text: 'никто.',
                  style: const TextStyle(color: Color(0xFF00A3FF)),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      await ConfirmDialog.show(
                        context,
                        title: 'Логин'.l10n,
                        // description:
                        //     'Unique login is an additional unique identifier for your account. \n\nVisible to: ',
                        additional: const [
                          Center(
                            child: Text(
                              'Unique login is an additional unique identifier for your account.\n',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Visible to:',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                        proceedLabel: 'Confirm',
                        withCancel: false,
                        initial: 2,
                        variants: [
                          ConfirmDialogVariant(
                            onProceed: () {},
                            child: Text('Все'.l10n),
                          ),
                          ConfirmDialogVariant(
                            onProceed: () {},
                            child: Text('Мои контакты'.l10n),
                          ),
                          ConfirmDialogVariant(
                            onProceed: () {},
                            child: Text('Никто'.l10n),
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

/// Returns addable list of [MyUser.phones].
Widget _phones(MyProfileController c, BuildContext context) => ExpandablePanel(
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

Widget _label(BuildContext context, String text) {
  final Style style = Theme.of(context).extension<Style>()!;

  return Padding(
    padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          text,
          style: style.systemMessageStyle
              .copyWith(color: Colors.black, fontSize: 18),
        ),
      ),
    ),
  );

  return Padding(
    padding: const EdgeInsets.fromLTRB(0, 18, 0, 12),
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          // border: style.systemMessageBorder,
          // color: style.systemMessageColor,
          // border: Border.all(color: const Color(0xFFE0E0E0)),
          border: style.primaryBorder,
          color: style.messageColor,
          // color: const Color(0xFFF8F8F8),
        ),
        child: Text(text, style: style.systemMessageStyle),
      ),
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
                  // onPressed: () {
                  //   Clipboard.setData(ClipboardData(text: e.val));
                  //   MessagePopup.success('label_copied_to_clipboard'.l10n);
                  // },
                  child: IgnorePointer(
                    child: ReactiveTextField(
                      state: TextFieldState(text: e.val, editable: false),
                      label: 'E-mail',
                      trailing: Transform.translate(
                        offset: const Offset(0, -1),
                        child: Transform.scale(
                          scale: 1.15,
                          child: SvgLoader.asset('assets/icons/delete.svg',
                              height: 14),
                        ),
                      ),
                    ),
                  ),
                ),
                WidgetButton(
                  onPressed: () => DeleteEmailView.show(context, email: e),
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
                      text: 'Ваш E-mail видят: ',
                      style: TextStyle(color: Color(0xFF888888)),
                    ),
                    TextSpan(
                      text: 'никто.',
                      style: const TextStyle(color: Color(0xFF00A3FF)),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          await ConfirmDialog.show(
                            context,
                            title: 'E-mail'.l10n,
                            additional: const [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Visible to:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                            proceedLabel: 'Confirm',
                            withCancel: false,
                            initial: 2,
                            variants: [
                              ConfirmDialogVariant(
                                onProceed: () {},
                                child: Text('Все'.l10n),
                              ),
                              ConfirmDialogVariant(
                                onProceed: () {},
                                child: Text('Мои контакты'.l10n),
                              ),
                              ConfirmDialogVariant(
                                onProceed: () {},
                                child: Text('Никто'.l10n),
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
                  AddEmailView.show(
                    context,
                    email: c.myUser.value!.emails.unconfirmed!,
                  );
                },
                child: IgnorePointer(
                  child: ReactiveTextField(
                    state: TextFieldState(
                      text: c.myUser.value!.emails.unconfirmed!.val,
                      editable: false,
                    ),
                    label: 'Верифицировать E-mail',
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
                onPressed: () => DeleteEmailView.show(
                  context,
                  email: c.myUser.value!.emails.unconfirmed!,
                ),
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
          onPressed: () => AddEmailView.show(context),
          child: IgnorePointer(
            child: ReactiveTextField(
              state: TextFieldState(
                  text: c.myUser.value?.emails.confirmed.isNotEmpty == true
                      ? 'Добавить дополнительный E-mail'
                      : 'Добавить E-mail',
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
                      label: 'Phone number',
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
                  onPressed: () => DeletePhoneView.show(context, phone: e),
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
                      text: 'никто.',
                      style: const TextStyle(color: Color(0xFF00A3FF)),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          await ConfirmDialog.show(
                            context,
                            title: 'Phone'.l10n,
                            additional: const [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Visible to:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                            proceedLabel: 'Confirm',
                            withCancel: false,
                            initial: 2,
                            variants: [
                              ConfirmDialogVariant(
                                onProceed: () {},
                                child: Text('Все'.l10n),
                              ),
                              ConfirmDialogVariant(
                                onProceed: () {},
                                child: Text('Мои контакты'.l10n),
                              ),
                              ConfirmDialogVariant(
                                onProceed: () {},
                                child: Text('Никто'.l10n),
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
                  AddPhoneView.show(
                    context,
                    phone: c.myUser.value!.phones.unconfirmed!,
                  );
                },
                child: IgnorePointer(
                  child: ReactiveTextField(
                    state: TextFieldState(
                      text: c.myUser.value!.phones.unconfirmed!.val,
                      editable: false,
                    ),
                    label: 'Верифицировать номер телефона',
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
                onPressed: () => DeletePhoneView.show(
                  context,
                  phone: c.myUser.value!.phones.unconfirmed!,
                ),
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
          onPressed: () => AddPhoneView.show(context),
          child: IgnorePointer(
            child: ReactiveTextField(
              state: TextFieldState(
                text: c.myUser.value?.phones.confirmed.isNotEmpty == true
                    ? 'Добавить дополнительный телефон'
                    : 'Добавить номер телефона',
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

  // ExpandablePanel(
  //   key: const Key('EmailsExpandable'),
  //   header: ListTile(
  //     leading: const Icon(Icons.email),
  //     title: Text('label_emails'.l10n),
  //   ),
  //   collapsed: Container(),
  //   expanded: Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20),
  //     child: Obx(
  //       () => Column(
  //         children: [
  //           ...c.myUser.value!.emails.confirmed.map(
  //             (e) => ListTile(
  //               leading: const Icon(Icons.email),
  //               trailing: IconButton(
  //                 key: const Key('DeleteConfirmedEmail'),
  //                 onPressed: (!c.emailsOnDeletion.contains(e))
  //                     ? () => c.deleteUserEmail(e)
  //                     : null,
  //                 icon: const Icon(Icons.delete, color: Colors.red),
  //               ),
  //               title: Text(e.val),
  //               dense: true,
  //             ),
  //           ),
  //           if (c.myUser.value?.emails.unconfirmed != null)
  //             ListTile(
  //               leading: const Icon(Icons.email),
  //               trailing: IconButton(
  //                 onPressed: !c.emailsOnDeletion
  //                         .contains(c.myUser.value?.emails.unconfirmed)
  //                     ? () =>
  //                         c.deleteUserEmail(c.myUser.value!.emails.unconfirmed!)
  //                     : null,
  //                 icon: const Icon(Icons.delete, color: Colors.red),
  //               ),
  //               title: Text(c.myUser.value!.emails.unconfirmed!.val),
  //               subtitle: Text('label_unconfirmed'.l10n),
  //               dense: true,
  //             ),
  //           _dense(
  //             c.myUser.value?.emails.unconfirmed == null
  //                 ? ReactiveTextField(
  //                     key: const Key('EmailInput'),
  //                     state: c.email,
  //                     type: TextInputType.emailAddress,
  //                     dense: true,
  //                     label: 'label_add_email'.l10n,
  //                     hint: 'label_add_email_hint'.l10n,
  //                   )
  //                 : ReactiveTextField(
  //                     key: const Key('EmailCodeInput'),
  //                     state: c.emailCode,
  //                     type: TextInputType.number,
  //                     dense: true,
  //                     label: 'label_enter_confirmation_code'.l10n,
  //                     hint: 'label_enter_confirmation_code_hint'.l10n,
  //                     onChanged: () => c.showEmailCodeButton.value =
  //                         c.emailCode.text.isNotEmpty,
  //                   ),
  //           ),
  //           if (c.myUser.value?.emails.unconfirmed == null)
  //             Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 const Spacer(),
  //                 _textButton(
  //                   context,
  //                   key: const Key('addEmailButton'),
  //                   onPressed: c.email.submit,
  //                   label: 'btn_add'.l10n,
  //                 ),
  //                 const SizedBox(width: 12),
  //               ],
  //             ),
  //           if (c.myUser.value?.emails.unconfirmed != null)
  //             Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 const Spacer(),
  //                 c.showEmailCodeButton.value
  //                     ? _textButton(
  //                         context,
  //                         key: const Key('ConfirmEmailCode'),
  //                         onPressed: c.emailCode.submit,
  //                         label: 'btn_confirm'.l10n,
  //                       )
  //                     : _textButton(
  //                         context,
  //                         key: const Key('ResendEmailCode'),
  //                         onPressed: c.resendEmailTimeout.value == 0
  //                             ? c.resendEmail
  //                             : null,
  //                         label: c.resendEmailTimeout.value == 0
  //                             ? 'btn_resend_code'.l10n
  //                             : '${'btn_resend_code'.l10n} (${c.resendEmailTimeout.value})',
  //                       ),
  //                 const SizedBox(width: 12),
  //               ],
  //             )
  //         ],
  //       ),
  //     ),
  //   ),
  // );
}

/// Returns editable fields of [MyUser.password].
Widget _password(BuildContext context, MyProfileController c) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _dense(
        WidgetButton(
          onPressed: () => ChangePasswordView.show(context),
          child: IgnorePointer(
            child: ReactiveTextField(
              state: TextFieldState(
                text: c.myUser.value?.hasPassword == true
                    ? 'Изменить пароль'
                    : 'Задать пароль',
                editable: false,
              ),
              style: TextStyle(
                color: c.myUser.value?.hasPassword != true
                    ? Colors.red
                    : Theme.of(context).colorScheme.secondary,
              ),
              //      trailing: RotatedBox(
              //   quarterTurns: 2,
              //   child: Icon(
              //     Icons.arrow_back_ios_rounded,
              //     color: Theme.of(context).colorScheme.secondary,
              //     size: 14,
              //   ),
              // ),
            ),
          ),
        ),
      ),
      // if (c.myUser.value?.hasPassword != true)
      //   Padding(
      //     padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
      //     child: RichText(
      //       text: TextSpan(
      //         style:
      //             const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
      //         children: [
      //           const TextSpan(
      //             text: 'Пароль не задан. ',
      //             style: TextStyle(color: Colors.red),
      //           ),
      //           TextSpan(
      //             text: 'Подробнее.',
      //             style: const TextStyle(color: Color(0xFF00A3FF)),
      //             recognizer: TapGestureRecognizer()..onTap = () async {},
      //           ),
      //         ],
      //       ),
      //     ),
      //   ),
      const SizedBox(height: 10),
    ],
  );

  return Obx(
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
}

/// Returns button to go to monolog chat.
Widget _monolog(MyProfileController c) => ListTile(
      key: const Key('MonologButton'),
      leading: const Icon(Icons.message),
      title: Text('btn_saved_messages'.l10n),
      onTap: () => throw UnimplementedError(),
    );

/// Returns button to delete the account.
Widget _deleteAccount(BuildContext context, MyProfileController c) {
  return _dense(
    WidgetButton(
      onPressed: () => DeleteAccountView.show(context),
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
          // style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
      ),
    ),
  );

  return ListTile(
    key: const Key('DeleteAccountButton'),
    leading: const Icon(Icons.delete, color: Colors.red),
    title: Text(
      'btn_delete_account'.l10n,
      style: const TextStyle(color: Colors.red),
    ),
    onTap: c.deleteAccount,
  );
}

Widget _personalization(BuildContext context, MyProfileController c) {
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
              )
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
                                // color: Colors.grey,
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
                                text: 'Hello!',
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: message(
                                fromMe: true,
                                text: 'Yay, hello :)',
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Align(
                      //   alignment: Alignment.topLeft,
                      //   child: Container(
                      //     width: 50,
                      //     height: double.infinity,
                      //     color: Colors.white.withOpacity(0.4),
                      //   ),
                      // )
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
                'Delete',
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

Widget _call(BuildContext context, MyProfileController c) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _dense(
        WidgetButton(
          onPressed: () => CallWindowSwitchView.show(context),
          child: IgnorePointer(
            child: ReactiveTextField(
              state: TextFieldState(
                text: (c.settings.value?.enablePopups ?? true)
                    ? 'Отображать звонки в отдельном окне.'
                    : 'Отображать звонки в окне приложения.',
              ),
              maxLines: null,
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ),
      ),
      // _dense(
      //   WidgetButton(
      //     onPressed: () =>
      //         c.setPopupsEnabled(!(c.settings.value?.enablePopups ?? true)),
      //     child: IgnorePointer(
      //       child: ReactiveTextField(
      //         state: TextFieldState(
      //           text: 'Отображать звонки в новых окнах'.l10n,
      //         ),
      //         maxLines: null,
      //         style: TextStyle(color: Theme.of(context).colorScheme.secondary),
      //         trailingWidth: null,
      //         trailing: Switch(
      //           value: c.settings.value?.enablePopups ?? true,
      //           onChanged: (_) {},
      //         ),
      //       ),
      //     ),
      //   ),
      // ),
    ],
  );
}

Widget _media(BuildContext context, MyProfileController c) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _dense(
        WidgetButton(
          onPressed: () => CameraSwitchView.show(context, call: c.call),
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
          onPressed: () => MicrophoneSwitchView.show(context, call: c.call),
          // key: c.micKey,
          // onPressed: () async {
          //   await Selector.menu(
          //     context,
          //     key: c.micKey,
          //     width: 340,
          //     alignment: Alignment.bottomLeft,
          //     margin: const EdgeInsets.only(top: 30),
          //     actions: c.devices.audio().mapIndexed((i, e) {
          //       final bool selected = (c.mic.value == null && i == 0) ||
          //           c.mic.value == e.deviceId();

          //       return ContextMenuButton(
          //         label: e.label(),
          //         onPressed: () => c.setAudioDevice(e.deviceId()),
          //         style: const TextStyle(fontSize: 15),
          //         trailing: AnimatedSwitcher(
          //           duration: 200.milliseconds,
          //           child: selected
          //               ? const SizedBox(
          //                   width: 20,
          //                   height: 20,
          //                   child: CircleAvatar(
          //                     backgroundColor: Color(0xFF63B4FF),
          //                     radius: 12,
          //                     child: Icon(
          //                       Icons.check,
          //                       color: Colors.white,
          //                       size: 12,
          //                     ),
          //                   ),
          //                 )
          //               : const SizedBox(key: Key('0')),
          //         ),
          //       );
          //     }).toList(),
          //   );
          // },
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
              // trailing: RotatedBox(
              //   quarterTurns: 3,
              //   child: Icon(
              //     Icons.arrow_back_ios_rounded,
              //     color: Theme.of(context).colorScheme.secondary,
              //     size: 14,
              //   ),
              // ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      _dense(
        WidgetButton(
          onPressed: () => OutputSwitchView.show(context, call: c.call),
          // key: c.outputKey,
          // onPressed: () async {
          //   await Selector.menu(
          //     context,
          //     key: c.outputKey,
          //     width: 340,
          //     alignment: Alignment.bottomLeft,
          //     margin: const EdgeInsets.only(top: 30),
          //     actions: c.devices.output().mapIndexed((i, e) {
          //       final bool selected = (c.output.value == null && i == 0) ||
          //           c.output.value == e.deviceId();

          //       return ContextMenuButton(
          //         label: e.label(),
          //         onPressed: () => c.setOutputDevice(e.deviceId()),
          //         style: const TextStyle(fontSize: 15),
          //         trailing: AnimatedSwitcher(
          //           duration: 200.milliseconds,
          //           child: selected
          //               ? const SizedBox(
          //                   width: 20,
          //                   height: 20,
          //                   child: CircleAvatar(
          //                     backgroundColor: Color(0xFF63B4FF),
          //                     radius: 12,
          //                     child: Icon(
          //                       Icons.check,
          //                       color: Colors.white,
          //                       size: 12,
          //                     ),
          //                   ),
          //                 )
          //               : const SizedBox(key: Key('0')),
          //         ),
          //       );
          //     }).toList(),
          //   );
          // },
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
              // trailing: RotatedBox(
              //   quarterTurns: 3,
              //   child: Icon(
              //     Icons.arrow_back_ios_rounded,
              //     color: Theme.of(context).colorScheme.secondary,
              //     size: 14,
              //   ),
              // ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget row(Widget left, Widget right, [bool useFlexible = false]) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Expanded(flex: 9, child: left),
            useFlexible
                ? Flexible(flex: 31, child: right)
                : Expanded(flex: 31, child: right),
          ],
        ),
      );

  Widget dropdown({
    required MediaDeviceInfo? value,
    required Iterable<MediaDeviceInfo> devices,
    required ValueChanged<MediaDeviceInfo?> onChanged,
  }) =>
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(18),
        ),
        height: 36,
        child: DropdownButton<MediaDeviceInfo>(
          value: value,
          items: devices
              .map<DropdownMenuItem<MediaDeviceInfo>>(
                (MediaDeviceInfo e) =>
                    DropdownMenuItem(value: e, child: Text(e.label())),
              )
              .toList(),
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(18),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.black,
            size: 31,
          ),
          disabledHint: Text('label_media_no_device_available'.l10n),
          style: context.textTheme.subtitle1?.copyWith(color: Colors.black),
          underline: const SizedBox(),
        ),
      );

  return _dense(
    Column(
      children: [
        WidgetButton(
          onPressed: () async {},
          child: IgnorePointer(
            child: ReactiveTextField(
              label: 'label_media_camera'.l10n,
              state: TextFieldState(
                text: (c.devices.video().firstWhereOrNull(
                                (e) => e.deviceId() == c.camera.value) ??
                            c.devices.video().firstOrNull)
                        ?.label() ??
                    '',
                editable: false,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ),
        const SizedBox(height: 25),
        row(
          Text('label_media_camera'.l10n),
          dropdown(
            value: c.devices
                    .video()
                    .firstWhereOrNull((e) => e.deviceId() == c.camera.value) ??
                c.devices.video().firstOrNull,
            devices: c.devices.video(),
            onChanged: (d) => c.setVideoDevice(d!.deviceId()),
          ),
        ),
        const SizedBox(height: 25),
        StreamBuilder(
          stream: c.localTracks?.changes,
          builder: (context, snapshot) {
            RtcVideoRenderer? local = c.localTracks
                ?.firstWhereOrNull((t) =>
                    t.source == MediaSourceKind.Device &&
                    t.renderer.value is RtcVideoRenderer)
                ?.renderer
                .value as RtcVideoRenderer?;
            return row(
              Container(),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 250,
                    width: 370,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: local == null
                        ? const Center(
                            child: Icon(
                              Icons.videocam_off,
                              color: Colors.white,
                              size: 40,
                            ),
                          )
                        : webrtc.VideoView(
                            local.inner,
                            objectFit: webrtc.VideoViewObjectFit.cover,
                            mirror: true,
                          ),
                  ),
                ),
              ),
              true,
            );
          },
        ),
        const SizedBox(height: 25),
        row(
          Text('label_media_microphone'.l10n),
          dropdown(
            value: c.devices
                    .audio()
                    .firstWhereOrNull((e) => e.deviceId() == c.mic.value) ??
                c.devices.audio().firstOrNull,
            devices: c.devices.audio(),
            onChanged: (d) => c.setAudioDevice(d!.deviceId()),
          ),
        ),
        const SizedBox(height: 25),
        row(
          Text('label_media_output'.l10n),
          dropdown(
            value: c.devices
                    .output()
                    .firstWhereOrNull((e) => e.deviceId() == c.output.value) ??
                c.devices.output().firstOrNull,
            devices: c.devices.output(),
            onChanged: (d) => c.setOutputDevice(d!.deviceId()),
          ),
        ),
        const SizedBox(height: 25),
      ],
    ),
  );
}

Widget _downloads(BuildContext context, MyProfileController c) {
  Widget button({
    String? asset,
    double width = 1,
    double height = 1,
    String title = '...',
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
                text: '    $title',
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
          title: 'Windows',
          link: 'messenger-windows.zip',
        ),
        const SizedBox(height: 8),
        button(
          asset: 'apple',
          width: 23,
          height: 29,
          title: 'macOS',
          link: 'messenger-macos.zip',
        ),
        const SizedBox(height: 8),
        button(
          asset: 'linux',
          width: 18.85,
          height: 22,
          title: 'Linux',
          link: 'messenger-linux.zip',
        ),
        const SizedBox(height: 8),
        button(
          asset: 'apple',
          width: 23,
          height: 29,
          title: 'iOS',
        ),
        const SizedBox(height: 8),
        button(
          asset: 'google',
          width: 20.33,
          height: 22.02,
          title: 'Android (APK)',
          link: 'messenger-android.apk',
        ),
        const SizedBox(height: 8),
        button(
          asset: 'google',
          width: 20.33,
          height: 22.02,
          title: 'Android (App Bundle)',
          link: 'messenger-android.aab',
        ),
      ],
    ),
  );

  return _dense(const DownloadView(true));
}

Widget _language(BuildContext context, MyProfileController c) {
  return _dense(
    WidgetButton(
      key: c.languageKey,
      onPressed: () async => await LanguageSelectionView.show(context),
      child: IgnorePointer(
        child: ReactiveTextField(
          state: TextFieldState(
            text:
                '${L10n.chosen.value!.locale.countryCode}, ${L10n.chosen.value!.name}',
            editable: false,
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          // trailing: RotatedBox(
          //   quarterTurns: 2,
          //   child: Icon(
          //     Icons.arrow_back_ios_rounded,
          //     color: Theme.of(context).colorScheme.secondary,
          //     size: 14,
          //   ),
          // ),
        ),
      ),
    ),
  );
}
