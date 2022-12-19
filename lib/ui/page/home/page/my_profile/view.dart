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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:collection/collection.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/ongoing_call.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/tab/menu/status/view.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/confirm_dialog.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
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
                    margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    decoration: BoxDecoration(
                      // color: Colors.white,
                      border: style.primaryBorder,
                      color: style.messageColor,
                      borderRadius: BorderRadius.circular(15),
                      // border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    constraints: context.isNarrow
                        ? null
                        : const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: children,
                    ),
                  ),
                );
              }

              return FlutterListView(
                controller: c.listController,
                delegate: FlutterListViewDelegate(
                  (context, i) {
                    switch (ProfileTab.values[i]) {
                      case ProfileTab.public:
                        return block(
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
                            // _bio(c),
                            _presence(c, context),
                            _status(c),
                          ],
                        );

                      case ProfileTab.signing:
                        return block(
                          children: [
                            _label(context, 'Параметры входа'),
                            _num(c),
                            _login(c, context),
                            const SizedBox(height: 10),
                            _emails(c, context),
                            _password(context, c),
                          ],
                        );

                      // case ProfileTab.privacy:
                      //   return block(
                      //     children: [
                      //       _label(context, 'Приватность'),
                      //       _privacy(context, c),
                      //     ],
                      //   );

                      case ProfileTab.link:
                        return block(
                          children: [
                            _label(context, 'Прямая ссылка на чат с Вами'),
                            _link(context, c),
                          ],
                        );

                      case ProfileTab.background:
                        return block(children: [
                          _label(context, 'Бэкграунд'),
                          _personalization(context, c),
                        ]);

                      case ProfileTab.calls:
                        if (!PlatformUtils.isMobile) {
                          return block(
                            children: [
                              _label(context, 'Звонки'),
                              _call(context, c),
                            ],
                          );
                        }
                        return const SizedBox();

                      case ProfileTab.media:
                        if (!PlatformUtils.isMobile) {
                          return block(
                            children: [
                              _label(context, 'Медиа'),
                              _media(context, c),
                            ],
                          );
                        }
                        return const SizedBox();

                      case ProfileTab.notifications:
                        return block(
                          children: [
                            _label(context, 'Звуковые уведомления'),
                            _notifications(context, c),
                          ],
                        );

                      case ProfileTab.language:
                        return block(
                          children: [
                            _label(context, 'Язык'),
                            _language(context, c),
                          ],
                        );

                      case ProfileTab.download:
                        return block(
                          children: [
                            _label(context, 'Скачать приложение'),
                            _downloads(context, c),
                          ],
                        );

                      case ProfileTab.danger:
                        return block(
                          children: [
                            _label(context, 'Опасная зона'),
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

/// Returns [MyUser.name] editable field.
Widget _bio(MyProfileController c) {
  return _padding(
    ReactiveTextField(
      key: const Key('BioField'),
      state: c.bio,
      label: 'About'.l10n,
      filled: true,
      type: TextInputType.multiline,
      maxLines: null,
      textInputAction: TextInputAction.newline,
      onSuffixPressed: c.bio.text.isEmpty
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

/// Returns [MyUser.name] editable field.
Widget _status(MyProfileController c) {
  return _padding(
    ReactiveTextField(
      key: const Key('StatusField'),
      state: c.status,
      label: 'Status'.l10n,
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

/// Returns [MyUser.presence] dropdown.
Widget _presence(MyProfileController c, BuildContext context) {
  return Obx(() {
    Presence? presence = c.myUser.value?.presence;
    Color? color;

    switch (presence) {
      case Presence.present:
        color = Colors.green;
        break;

      case Presence.away:
        color = Colors.orange;
        break;

      case Presence.hidden:
        color = Colors.grey;
        break;

      case Presence.artemisUnknown:
        break;

      default:
        break;
    }

    return _padding(
      WidgetButton(
        onPressed: () => StatusView.show(context, presenceOnly: true),
        child: IgnorePointer(
          child: ReactiveTextField(
            label: 'label_presence'.l10n,
            state: TextFieldState(
              text: presence?.localizedString(),
              editable: false,
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            trailing: CircleAvatar(
              backgroundColor: color,
              radius: 7,
            ),
          ),
        ),
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
                              style:
                                  TextStyle(fontSize: 18, color: Colors.black),
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
        ),
      ),
    ),
  );
}

/// Returns button to delete the account.
Widget _privacy(BuildContext context, MyProfileController c) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // _dense(
      //   WidgetButton(
      //     onPressed: () async {
      //       await ConfirmDialog.show(
      //         context,
      //         title: 'Логин'.l10n,
      //         // description:
      //         //     'Unique login is an additional unique identifier for your account. \n\nVisible to: ',
      //         additional: const [
      //           Center(
      //             child: Text(
      //               'Unique login is an additional unique identifier for your account.\n',
      //               style: TextStyle(
      //                 fontSize: 15,
      //                 color: Color(0xFF888888),
      //               ),
      //             ),
      //           ),
      //           Align(
      //             alignment: Alignment.centerLeft,
      //             child: Text(
      //               'Visible to:',
      //               style: TextStyle(fontSize: 18, color: Colors.black),
      //             ),
      //           ),
      //         ],
      //         proceedLabel: 'Confirm',
      //         withCancel: false,
      //         initial: 2,
      //         variants: [
      //           ConfirmDialogVariant(
      //             onProceed: () {},
      //             child: Text('Все'.l10n),
      //           ),
      //           ConfirmDialogVariant(
      //             onProceed: () {},
      //             child: Text('Мои контакты'.l10n),
      //           ),
      //           ConfirmDialogVariant(
      //             onProceed: () {},
      //             child: Text('Никто'.l10n),
      //           ),
      //         ],
      //       );
      //     },
      //     child: IgnorePointer(
      //       child: ReactiveTextField(
      //         state: TextFieldState(
      //           text: 'Ваш логин видят: все'.l10n,
      //           editable: false,
      //         ),
      //         style: TextStyle(color: Theme.of(context).colorScheme.secondary),
      //       ),
      //     ),
      //   ),
      // ),
      // const SizedBox(height: 12),
      Column(
        children: [
          Obx(() {
            return _dense(
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  IgnorePointer(
                    child: ReactiveTextField(
                      state: TextFieldState(
                        text: 'Отметки о прочтении',
                        editable: false,
                      ),
                      trailing: const SizedBox(),
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
                            activeColor:
                                Theme.of(context).colorScheme.secondary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            value: c.showReadLabels.value,
                            onChanged: (m) => c.showReadLabels.toggle(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Obx(() {
            final Widget child;

            if (!c.showReadLabels.value) {
              child = const Padding(
                padding: EdgeInsets.fromLTRB(24, 6, 24, 6),
                child: Text(
                  'Вы также не сможете видеть отметки о прочтении других пользователей.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF888888),
                  ),
                ),
              );
            } else {
              child = const SizedBox(width: double.infinity);
            }

            return AnimatedSizeAndFade(
              fadeDuration: 200.milliseconds,
              sizeDuration: 200.milliseconds,
              child: child,
            );
          }),
        ],
      ),
      const SizedBox(height: 12),
      // _dense(
      //   WidgetButton(
      //     onPressed: () async {
      //       await ConfirmDialog.show(
      //         context,
      //         title: 'Время последнего входа'.l10n,
      //         additional: const [
      //           Align(
      //             alignment: Alignment.centerLeft,
      //             child: Text(
      //               'Visible to:',
      //               style: TextStyle(fontSize: 18, color: Colors.black),
      //             ),
      //           ),
      //         ],
      //         proceedLabel: 'Confirm',
      //         withCancel: false,
      //         variants: [
      //           ConfirmDialogVariant(
      //             onProceed: () {},
      //             child: Text('Все'.l10n),
      //           ),
      //           ConfirmDialogVariant(
      //             onProceed: () {},
      //             child: Text('Мои контакты'.l10n),
      //           ),
      //           ConfirmDialogVariant(
      //             onProceed: () {},
      //             child: Text('Никто'.l10n),
      //           ),
      //         ],
      //       );
      //     },
      //     child: IgnorePointer(
      //       child: ReactiveTextField(
      //         maxLines: null,
      //         state: TextFieldState(
      //           text: 'Время последнего входа: все',
      //           editable: false,
      //         ),
      //         style: TextStyle(color: Theme.of(context).colorScheme.secondary),
      //         trailing: const SizedBox(),
      //       ),
      //     ),
      //   ),
      // ),
      Column(
        children: [
          Obx(() {
            return _dense(
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  IgnorePointer(
                    child: ReactiveTextField(
                      state: TextFieldState(
                        text: 'Время последнего входа',
                        editable: false,
                      ),
                      trailing: const SizedBox(),
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
                          data: ThemeData(platform: TargetPlatform.macOS),
                          child: Switch.adaptive(
                            activeColor:
                                Theme.of(context).colorScheme.secondary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            value: c.showSeenAt.value,
                            onChanged: (m) => c.showSeenAt.toggle(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Obx(() {
            final Widget child;

            if (!c.showSeenAt.value) {
              child = const Padding(
                padding: EdgeInsets.fromLTRB(24, 6, 24, 6),
                child: Text(
                  'Вы также не сможете видеть время последнего входа других пользователей.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF888888),
                  ),
                ),
              );
            } else {
              child = const SizedBox(width: double.infinity);
            }

            return AnimatedSizeAndFade(
              fadeDuration: 200.milliseconds,
              sizeDuration: 200.milliseconds,
              child: child,
            );
          }),
        ],
      ),
    ],
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
          onPressed: () => OutputSwitchView.show(context, call: c.call),
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

Widget _notifications(BuildContext context, MyProfileController c) {
  return Obx(() {
    return _dense(
      Stack(
        alignment: Alignment.centerRight,
        children: [
          IgnorePointer(
            child: ReactiveTextField(
              state: TextFieldState(
                text: c.muted.value ? 'Отключены' : 'Включены',
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
                    value: !c.muted.value,
                    onChanged: (m) => c.muted.toggle(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return _dense(Material(
      borderRadius: BorderRadius.circular(10),
      color: Colors.white.darken(0.05),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        height: 52,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.muted.value ? 'Отключены' : 'Включены',
                          maxLines: 1,
                          style: const TextStyle(fontSize: 17),
                        ),
                      ),
                      Theme(
                        data: ThemeData(
                          platform: TargetPlatform.macOS,
                        ),
                        child: Transform.scale(
                          scale: 0.7,
                          child: SizedBox(
                            width: 30,
                            height: 20,
                            child: Switch.adaptive(
                              activeColor:
                                  Theme.of(context).colorScheme.secondary,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              value: !c.muted.value,
                              onChanged: (m) => c.muted.toggle(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  });
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
          title: 'Android',
          link: 'messenger-android.apk',
        ),
      ],
    ),
  );
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
        ),
      ),
    ),
  );
}
