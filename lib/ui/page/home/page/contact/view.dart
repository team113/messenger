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

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/copyable.dart';
import 'package:messenger/ui/page/home/page/user/delete_email/view.dart';
import 'package:messenger/ui/page/home/page/user/delete_phone/view.dart';
import 'package:messenger/ui/page/home/tab/chats/mute_chat_popup/view.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/platform_utils.dart';

import '../../../../../domain/model/user.dart';
import '../../widget/avatar.dart';
import '/domain/model/contact.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/user/controller.dart';
import 'controller.dart';

// TODO: Implement [Routes.contact] page.
/// View of the [Routes.contact] page.
class ContactView extends StatelessWidget {
  const ContactView(this.id, {Key? key}) : super(key: key);

  /// ID of a [ChatContact] this [ContactView] represents.
  final ChatContactId id;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return GetBuilder<ContactController>(
      init: ContactController(id, Get.find(), Get.find(), Get.find()),
      tag: 'Contact_$id',
      builder: (c) => Scaffold(
        appBar: CustomAppBar(
          title: Row(
            children: [
              Material(
                elevation: 6,
                type: MaterialType.circle,
                shadowColor: const Color(0x55000000),
                color: Colors.white,
                child: Center(
                  child: AvatarWidget.fromRxContact(
                    c.contact,
                    radius: 17,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: DefaultTextStyle.merge(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.contact.contact.value.name.val,
                      ),
                      Obx(() {
                        final subtitle =
                            c.contact.user.value?.user.value.getStatus();
                        if (subtitle != null) {
                          return Text(
                            subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .caption
                                ?.copyWith(color: const Color(0xFF888888)),
                          );
                        }

                        return Container();
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
          padding: const EdgeInsets.only(left: 4, right: 20),
          leading: const [StyledBackButton()],
          actions: [
            WidgetButton(
              onPressed: c.openChat,
              child: Transform.translate(
                offset: const Offset(0, 1),
                child: SvgLoader.asset(
                  'assets/icons/chat.svg',
                  width: 20.12,
                  height: 21.62,
                ),
              ),
            ),
            if (!context.isMobile) ...[
              const SizedBox(width: 28),
              WidgetButton(
                onPressed: () => c.call(true),
                child: SvgLoader.asset(
                  'assets/icons/chat_video_call.svg',
                  height: 17,
                ),
              ),
            ],
            const SizedBox(width: 28),
            WidgetButton(
              onPressed: () => c.call(false),
              child: SvgLoader.asset(
                'assets/icons/chat_audio_call.svg',
                height: 19,
              ),
            ),
          ],
        ),
        body: Obx(() {
          Widget block({
            List<Widget> children = const [],
            EdgeInsets padding = const EdgeInsets.fromLTRB(32, 16, 32, 16),
          }) {
            return Center(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                decoration: BoxDecoration(
                  border: style.primaryBorder,
                  color: style.messageColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                constraints: context.isNarrow
                    ? null
                    : const BoxConstraints(maxWidth: 400),
                padding: padding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
              ),
            );
          }

          return ListView(
            children: [
              const SizedBox(height: 8),
              block(
                children: [
                  _label(context, 'Публичная информация'),
                  AvatarWidget.fromRxContact(
                    c.contact,
                    radius: 100,
                    // showBadge: false,
                    // quality: AvatarQuality.original,
                  ),
                  const SizedBox(height: 15),
                  _name(c, context),
                ],
              ),
              block(
                children: [
                  _label(context, 'Контактная информация'),
                  _num(c, context),
                  _emails(c, context),
                ],
              ),
              block(
                children: [
                  _label(context, 'Действия'),
                  _actions(c, context),
                ],
              ),
              const SizedBox(height: 8),
            ],
          );
        }),
      ),
    );
  }

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
  Widget _emails(ContactController c, BuildContext context) {
    final List<Widget> widgets = [];

    for (UserEmail e in c.contact.contact.value.emails) {
      widgets.add(
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
              onPressed: () => DeleteEmailView.show(
                context,
                email: e,
                onSubmit: () => c.removeEmail(e),
              ),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                width: 30,
                height: 30,
              ),
            ),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }

    widgets.add(
      ReactiveTextField(
        state: c.email,
        label: 'Добавить E-mail',
        // style: TextStyle(color: Theme.of(context).colorScheme.secondary),
      ),
    );
    widgets.add(const SizedBox(height: 10));

    for (UserPhone e in c.contact.contact.value.phones) {
      widgets.add(
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
              onPressed: () => DeletePhoneView.show(
                context,
                phone: e,
                onSubmit: () => c.removePhone(e),
              ),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                width: 30,
                height: 30,
              ),
            ),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }

    widgets.add(
      ReactiveTextField(
        state: c.phone,
        label: 'Добавить телефон',
        // style: TextStyle(color: Theme.of(context).colorScheme.secondary),
      ),
    );
    widgets.add(const SizedBox(height: 10));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets.map((e) => _dense(e)).toList(),
    );
  }

  /// Dense [Padding] wrapper.
  Widget _dense(Widget child) =>
      Padding(padding: const EdgeInsets.fromLTRB(8, 4, 8, 4), child: child);

  /// Basic [Padding] wrapper.
  Widget _padding(Widget child) =>
      Padding(padding: const EdgeInsets.all(8), child: child);

  Widget _actions(ContactController c, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dense(
          Obx(() {
            return WidgetButton(
              onPressed:
                  c.inContacts.value ? c.removeFromContacts : c.addToContacts,
              child: IgnorePointer(
                child: ReactiveTextField(
                  state: TextFieldState(
                    text: c.inContacts.value
                        ? 'Удалить из контактов'
                        : 'Добавить в контакты',
                    editable: false,
                  ),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        _dense(
          Obx(() {
            return WidgetButton(
              onPressed: c.inFavorites.value
                  ? c.removeFromFavorites
                  : c.addToFavorites,
              child: IgnorePointer(
                child: ReactiveTextField(
                  state: TextFieldState(
                    text: c.inFavorites.value
                        ? 'Удалить из избранных'
                        : 'Добавить в избранные',
                    editable: false,
                  ),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        _dense(
          Obx(() {
            final bool muted =
                c.contact.user.value!.user.value.dialog!.muted != null;

            return WidgetButton(
              onPressed: () => muted
                  ? c.unmuteChat(c.contact.user.value!.user.value.dialog!.id)
                  : MuteChatView.show(
                      context,
                      chatId: c.contact.user.value!.user.value.dialog!.id,
                      onMute: (duration) => c.muteChat(
                        c.contact.user.value!.user.value.dialog!.id,
                        duration: duration,
                      ),
                    ),
              child: IgnorePointer(
                child: ReactiveTextField(
                  state: TextFieldState(
                    text: muted
                        ? 'Включить уведомления'
                        : 'Отключить уведомления',
                    editable: false,
                  ),
                  trailing: Transform.translate(
                    offset: const Offset(0, -1),
                    child: Transform.scale(
                      scale: 1.15,
                      child: muted
                          ? SvgLoader.asset(
                              'assets/icons/btn_mute.svg',
                              width: 18.68,
                              height: 15,
                            )
                          : SvgLoader.asset(
                              'assets/icons/btn_unmute.svg',
                              width: 17.86,
                              height: 15,
                            ),
                    ),
                  ),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        _dense(
          WidgetButton(
            onPressed: () {},
            child: IgnorePointer(
              child: ReactiveTextField(
                state: TextFieldState(
                  text: 'Скрыть чат',
                  editable: false,
                ),
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
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _dense(
          WidgetButton(
            onPressed: () {},
            child: IgnorePointer(
              child: ReactiveTextField(
                state: TextFieldState(
                  text: 'Очистить чат',
                  editable: false,
                ),
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
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _dense(
          WidgetButton(
            onPressed: c.blocked.toggle,
            child: IgnorePointer(
              child: ReactiveTextField(
                state: TextFieldState(
                  text: c.blocked.value ? 'Разблокировать' : 'Заблокировать',
                  editable: false,
                ),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _dense(
          WidgetButton(
            onPressed: () {},
            child: IgnorePointer(
              child: ReactiveTextField(
                state: TextFieldState(
                  text: 'Пожаловаться',
                  editable: false,
                ),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Returns a [User.name] text widget with an [AvatarWidget].
  Widget _name(ContactController c, BuildContext context) {
    return _padding(
      ReactiveTextField(
        key: const Key('NameField'),
        state: c.name,
        label: 'label_name'.l10n,
        filled: true,
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
        onSuffixPressed: () {
          Clipboard.setData(
            ClipboardData(text: c.contact.user.value!.user.value.name?.val),
          );
          MessagePopup.success('label_copied_to_clipboard'.l10n);
        },
      ),
    );
  }

  /// Returns a [User.num] copyable field.
  Widget _num(ContactController c, BuildContext context) {
    return _padding(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CopyableTextField(
            key: const Key('NumCopyable'),
            state: TextFieldState(
              text: c.contact.user.value!.user.value.num.val.replaceAllMapped(
                RegExp(r'.{4}'),
                (match) => '${match.group(0)} ',
              ),
            ),
            label: 'label_num'.l10n,
            copy: c.contact.user.value!.user.value.num.val,
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}
