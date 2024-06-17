import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/model/native_file.dart';
import 'package:messenger/domain/service/balance.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/page/home/widget/field_button.dart';
import 'package:messenger/ui/widget/info_tile.dart';

import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:phone_form_field/phone_form_field.dart';

import '/themes.dart';
import 'line_divider.dart';
import 'uploadable_photo.dart';

class VerificationBlock extends StatefulWidget {
  const VerificationBlock({
    super.key,
    this.editing = false,
    this.person,
    this.onChanged,
    this.onEditing,
    required this.myUser,
  });

  final VerifiedPerson? person;
  final bool editing;

  final void Function(VerifiedPerson?)? onChanged;
  final void Function(bool)? onEditing;

  final Rx<MyUser?> myUser;

  @override
  State<VerificationBlock> createState() => _VerificationBlockState();
}

class _VerificationBlockState extends State<VerificationBlock> {
  late final RxBool editing;

  late final TextFieldState name;
  late final TextFieldState address;
  late final TextFieldState index;
  late final TextFieldState phone;

  late final Rx<Country?> country;
  late final Rx<DateTime?> birthday;
  late final Rx<NativeFile?> passport;

  @override
  void didUpdateWidget(covariant VerificationBlock oldWidget) {
    editing.value = widget.editing;
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    editing = RxBool(widget.editing);

    name = TextFieldState(text: widget.person?.name ?? '');
    address = TextFieldState(text: widget.person?.address ?? '');
    index = TextFieldState(text: widget.person?.index ?? '');
    phone = TextFieldState(text: widget.person?.phone ?? '');
    country = Rx(widget.person?.country);
    birthday = Rx(widget.person?.birthday);
    passport = Rx(widget.person?.passport);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Obx(() {
      final List<Widget> children;

      // Не верифицирован | Not verified
      // На модерации | Being moderated
      // Верифицирован | Verified
      if (editing.value) {
        children = [
          AvatarWidget.fromMyUser(
            widget.myUser.value,
            radius: AvatarRadius.large,
            verified: false,
          ),
          const SizedBox(height: 8),
          const Text('Не верифицирован'),
          const SizedBox(height: 24),
          const LineDivider('Фото'),
          const SizedBox(height: 12),
          Text(
            'Для подтверждения личности, пожалуйста, сделайте своё фото вместе с документом, удостоверяющим личность.',
            style: style.fonts.small.regular.secondary,
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Важно:',
                  style: style.fonts.small.regular.onBackground,
                ),
                TextSpan(
                  text: '\n'
                      '${PlatformUtils.isDesktop ? '- сделать фото Вы можете только с мобильного телефона. Пожалуйста, войдите в Ваш Assist аккаунт на мобильном телефоне. Вы можете использовать как приложение, так и браузер;\n' : ''}'
                      '- на фото должно быть чётко видно Ваше лицо полностью;\n'
                      '- на фото должен быть чётко виден документ, удостоверяющий личность, полностью;\n'
                      '- текст документа, удостоверяющего личность, должен быть хорошо читаем, не допускается присутствие бликов, размытий и т.п.\n'
                      '- документом, удостоверяющим личность, считается заграничный паспорт, вид на жительство, внутренний паспорт, ID карта, водительское удостоверение.',
                  style: style.fonts.small.regular.secondary,
                ),
              ],
            ),
            style: style.fonts.small.regular.secondary,
          ),
          const SizedBox(height: 24),
          Obx(() {
            return UploadablePhoto(
              onChanged: (f) => passport.value = f,
              file: passport.value,
            );
          }),
          const SizedBox(height: 24),
          const LineDivider('Личные данные'),
          const SizedBox(height: 12),
          Text(
            'Все поля заполняются латинскими буквами так, как они указываются в документах, удостоверяющих личность, и/или финансовых институтах для получения международных платежей (банк, платежная система, платежная карта и т.п.).',
            style: style.fonts.small.regular.secondary,
          ),
          const SizedBox(height: 24),
          ReactiveTextField(
            label: 'Имя получателя',
            state: name,
            hint: 'JOHN SMITH',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            formatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[A-Za-z0-9]|[ ]|[.]|[,]'),
              ),
            ],
            onChanged: _emit,
          ),
          const SizedBox(height: 24),
          WidgetButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: birthday.value,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                locale: L10n.chosen.value?.locale,
              );

              if (date != null) {
                birthday.value = date;
                _emit();
              }
            },
            child: IgnorePointer(
              child: Obx(() {
                return ReactiveTextField(
                  label: 'Дата рождения',
                  state: TextFieldState(
                    text:
                        birthday.value == null ? '' : '${birthday.value?.yMd}',
                    editable: false,
                  ),
                  hint: '01.02.2003',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 8),
          FieldButton(
            text: /*c.country.value?.name ??*/ 'Не выбрано',
            headline: Text('Страна'.l10n),
            onPressed: () async {
              // final result = await const _CountrySelectorNavigator()
              //    .navigate(context, FlagCache());
              // if (rsult != null) {
              //   ccountry.value = result;
              // }

              _emit();
            },
            style: style.fonts.normal.regular.primary,
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 16),
          ReactiveTextField(
            label: 'Адрес',
            hint: 'Дом, улица, город, область/район/провинция/штат',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            state: address,
            formatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[A-Za-z0-9]|[ ]|[.]|[,]'),
              ),
            ],
            onChanged: _emit,
          ),
          const SizedBox(height: 16),
          ReactiveTextField(
            label: 'Почтовый индекс',
            hint: '00000',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            state: index,
            onChanged: _emit,
          ),
          const SizedBox(height: 16),
          ReactiveTextField(
            label: 'Телефон',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hint: '+1 234 567 8901',
            state: phone,
            formatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[0-9]|[ ]|[+]'),
              ),
            ],
            onChanged: _emit,
          ),
          const SizedBox(height: 12),
          Obx(() {
            final bool enabled = !name.isEmpty.value &&
                birthday.value != null &&
                !address.isEmpty.value &&
                !index.isEmpty.value &&
                !phone.isEmpty.value;

            return WidgetButton(
              onPressed: enabled
                  ? () {
                      editing.value = false;
                      widget.onEditing?.call(editing.value);
                    }
                  : null,
              child: Text(
                'btn_save'.l10n,
                style: enabled
                    ? style.fonts.small.regular.primary
                    : style.fonts.small.regular.secondary,
              ),
            );
          }),
        ];
      } else {
        children = [
          AvatarWidget.fromMyUser(
            widget.myUser.value,
            radius: AvatarRadius.large,
            verified: true,
          ),
          const SizedBox(height: 8),
          const Text('Верифицирован'),
          const SizedBox(height: 24),
          const LineDivider('Данные'),
          const SizedBox(height: 8),
          InfoTile(title: 'Имя получателя', content: name.text),
          const SizedBox(height: 16),
          InfoTile(
            title: 'Дата рождения',
            content: '${birthday.value?.yMd}',
          ),
          const SizedBox(height: 16),
          InfoTile(
            title: 'Страна',
            content: '${country.value?.name}',
          ),
          const SizedBox(height: 16),
          InfoTile(
            title: 'Адрес',
            content: address.text,
          ),
          const SizedBox(height: 16),
          InfoTile(
            title: 'Почтовый индекс',
            content: index.text,
          ),
          const SizedBox(height: 16),
          InfoTile(
            title: 'Телефон',
            content: phone.text,
          ),
          const SizedBox(height: 12),
          WidgetButton(
            onPressed: () {
              editing.value = true;
              widget.onEditing?.call(editing.value);
            },
            child: Text(
              'btn_change'.l10n,
              style: style.fonts.small.regular.primary,
            ),
          ),
        ];
      }

      return AnimatedSizeAndFade(
        sizeDuration: const Duration(milliseconds: 300),
        fadeDuration: const Duration(milliseconds: 300),
        child: Column(
          key: Key(editing.value.toString()),
          children: children,
        ),
      );
    });
  }

  void _emit() {
    widget.onChanged?.call(
      VerifiedPerson(
        name: name.text,
        address: address.text,
        index: index.text,
        phone: phone.text,
        country: country.value,
        birthday: birthday.value,
        passport: passport.value,
      ),
    );
  }
}
