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

import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/my_profile/widget/copyable.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'widgets/delete_contact_record.dart';

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
                      Text(c.contact.contact.value.name.val),
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
                  _label(context, 'label_public_information'.l10n),
                  AvatarWidget.fromRxContact(
                    c.contact,
                    radius: 100,
                    showBadge: false,
                  ),
                  const SizedBox(height: 15),
                  _name(c, context),
                ],
              ),
              block(
                children: [
                  _label(context, 'label_contact_information'.l10n),
                  _num(c, context),
                  _emails(c, context),
                  _phones(c, context),
                ],
              ),
              block(
                children: [
                  _label(context, 'label_actions'.l10n),
                  _actions(c, context),
                ],
              ),
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
            style: style.systemMessageStyle.copyWith(
              color: Colors.black,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  /// Returns addable list of [ChatContact.emails].
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
                  label: 'label_email'.l10n,
                  trailing: Transform.translate(
                    offset: const Offset(0, -1),
                    child: Transform.scale(
                      scale: 1.15,
                      child: SvgLoader.asset(
                        'assets/icons/delete.svg',
                        color: Theme.of(context).primaryIconTheme.color,
                        height: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            WidgetButton(
              onPressed: () => DeleteContactRecordView.show(
                context,
                title: 'label_delete_email'.l10n,
                text: [
                  TextSpan(text: '${'label_email'.l10n}${'space'.l10n}'),
                  TextSpan(
                    text: e.val,
                    style: const TextStyle(color: Colors.black),
                  ),
                  TextSpan(
                    text:
                        '${'space'.l10n}${'label_will_be_removed'.l10n}${'dot'.l10n}',
                  ),
                ],
                onSubmit: () => c.deleteContactRecord(email: e),
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
        label: 'label_add_email'.l10n,
      ),
    );
    widgets.add(const SizedBox(height: 10));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets.map((e) => _dense(e)).toList(),
    );
  }

  /// Returns addable list of [ChatContact.phones].
  Widget _phones(ContactController c, BuildContext context) {
    final List<Widget> widgets = [];

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
                  label: 'label_phone_number'.l10n,
                  trailing: Transform.translate(
                    offset: const Offset(0, -1),
                    child: Transform.scale(
                      scale: 1.15,
                      child: SvgLoader.asset(
                        'assets/icons/delete.svg',
                        color: Theme.of(context).primaryIconTheme.color,
                        height: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            WidgetButton(
              onPressed: () => DeleteContactRecordView.show(
                context,
                title: 'label_delete_phone_number'.l10n,
                text: [
                  TextSpan(text: '${'label_phone_number'.l10n}${'space'.l10n}'),
                  TextSpan(
                    text: e.val,
                    style: const TextStyle(color: Colors.black),
                  ),
                  TextSpan(
                    text:
                        '${'space'.l10n}${'label_will_be_removed'.l10n}${'dot'.l10n}',
                  ),
                ],
                onSubmit: () => c.deleteContactRecord(phone: e),
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
        label: 'label_add_number'.l10n,
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

  /// Returns list of action buttons.
  Widget _actions(ContactController c, BuildContext context) {
    Widget action({
      required String text,
      void Function()? onPressed,
      Widget? svg,
      double marginBottom = 10,
    }) {
      return Container(
        margin: EdgeInsets.only(bottom: marginBottom),
        child: _dense(
          WidgetButton(
            onPressed: onPressed ?? () {},
            child: IgnorePointer(
              child: ReactiveTextField(
                state: TextFieldState(
                  text: text,
                  editable: false,
                ),
                trailing: svg != null
                    ? Transform.translate(
                        offset: const Offset(0, -1),
                        child: Transform.scale(
                          scale: 1.15,
                          child: svg,
                        ),
                      )
                    : null,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          ),
        ),
      );
    }

    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          action(
            text: c.inContacts.value
                ? 'btn_delete_from_contacts'.l10n
                : 'btn_add_to_contacts'.l10n,
            onPressed:
                c.inContacts.value ? c.removeFromContacts : c.addToContacts,
          ),
          action(
            text: c.inFavorites.value
                ? 'btn_delete_from_favorites'.l10n
                : 'btn_add_to_favorites'.l10n,
          ),
          action(
            text: 'btn_mute_chat'.l10n,
            svg: SvgLoader.asset(
              'assets/icons/btn_mute.svg',
              width: 17.86,
              height: 15,
            ),
          ),
          action(
            text: 'btn_hide_chat'.l10n,
            svg: SvgLoader.asset('assets/icons/delete.svg', height: 14),
          ),
          action(
            text: 'btn_clear_chat'.l10n,
            svg: SvgLoader.asset('assets/icons/delete.svg', height: 14),
          ),
          action(text: 'btn_blacklist'.l10n),
          action(text: 'btn_report'.l10n, marginBottom: 8),
        ],
      );
    });
  }

  /// Returns a [ChatContact.name] editable text field.
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

  /// Returns a [ChatContact]s [User.num] copyable field.
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
