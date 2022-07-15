import 'package:flutter/cupertino.dart' show kCupertinoModalBarrierColor;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/routes.dart';

import 'package:messenger/ui/page/auth/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/sharable.dart';
import 'package:messenger/ui/widget/popup/popup.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/util/platform_utils.dart';

import '/ui/page/home/page/my_profile/widget/copyable.dart';
import 'controller.dart';

// TODO: SHOW ONLY ONCE!!!!! Persist flag.
class IntroductionView extends StatelessWidget {
  const IntroductionView({Key? key}) : super(key: key);

  static Future<T?> show<T>(BuildContext context) {
    return Popup.show(context, const IntroductionView(), verticalPadding: 0);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final TextStyle? thin =
        theme.textTheme.caption?.copyWith(color: Colors.black);

    return GetBuilder(
      init: IntroductionController(Get.find(), pop: Navigator.of(context).pop),
      builder: (IntroductionController c) {
        return Obx(() {
          List<Widget> children;

          if (c.displaySuccess.value) {
            children = [
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Пароль успешно задан',
                  style: thin?.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 25),
              Center(
                child: OutlinedRoundedButton(
                  title: Text('Закрыть'.tr),
                  onPressed: Navigator.of(context).pop,
                  color: const Color(0xFFEEEEEE),
                ),
              ),
            ];
          } else if (c.displayPassword.value) {
            children = [
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Задать пароль',
                  style: thin?.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 18),
              ReactiveTextField(
                state: c.password,
                label: 'label_password'.tr,
                obscure: c.obscurePassword.value,
                style: thin,
                onSuffixPressed: c.obscurePassword.toggle,
                treatErrorAsStatus: false,
                trailing: SvgLoader.asset(
                  'assets/icons/visible_${c.obscurePassword.value ? 'off' : 'on'}.svg',
                  width: 17.07,
                ),
              ),
              const SizedBox(height: 12),
              ReactiveTextField(
                state: c.repeat,
                label: 'label_repeat_password'.tr,
                obscure: c.obscureRepeat.value,
                style: thin,
                onSuffixPressed: c.obscureRepeat.toggle,
                treatErrorAsStatus: false,
                trailing: SvgLoader.asset(
                  'assets/icons/visible_${c.obscureRepeat.value ? 'off' : 'on'}.svg',
                  width: 17.07,
                ),
              ),
              const SizedBox(height: 25),
              OutlinedRoundedButton(
                title: Text(
                  'btn_save'.tr,
                  style: thin?.copyWith(color: Colors.white),
                ),
                onPressed: c.setPassword,
                height: 50,
                leading: SvgLoader.asset(
                  'assets/icons/save.svg',
                  height: 25 * 0.7,
                ),
                color: const Color(0xFF63B4FF),
              ),
            ];
          } else {
            children = [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      style: thin,
                      text:
                          'Пароль не задан. Доступ к аккаунту без пароля сохраняется в течение одного года с момента создания аккаунта или пока:\n'
                          '\n'
                          '   - Вы не удалите пользовательские данные из приложения (браузера);\n'
                          '\n'
                          '   - Вы не нажмёте кнопку “Выход”.\n'
                          '\n'
                          'Чтобы не потерять доступ к аккаунту, задайте пароль.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedRoundedButton(
                      maxWidth: null,
                      title: Text(
                        'Задать пароль'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        router.me();
                      },
                      color: const Color(0xFF63B4FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedRoundedButton(
                      maxWidth: null,
                      title: Text(
                        'Закрыть'.tr,
                        style: const TextStyle(),
                      ),
                      onPressed: Navigator.of(context).pop,
                      color: const Color(0xFFEEEEEE),
                    ),
                  )
                ],
              ),
            ];
          }

          return AnimatedSize(
            duration: 200.milliseconds,
            child: AnimatedSwitcher(
              duration: 150.milliseconds,
              child: ListView(
                key: Key('${c.displayPassword.value}${c.displaySuccess.value}'),
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Аккаунт создан',
                      style: thin?.copyWith(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 25),
                  if (PlatformUtils.isMobile)
                    SharableTextField(
                      key: const Key('NumCopyable'),
                      text: c.num.text,
                      label: 'label_num'.tr,
                      copy: 'Gapopa ID: ${c.myUser.value?.num.val}',
                      trailing:
                          SvgLoader.asset('assets/icons/share.svg', width: 18),
                      style: thin,
                    )
                  else
                    CopyableTextField(
                      key: const Key('NumCopyable'),
                      state: c.num,
                      label: 'label_num'.tr,
                      copy: c.myUser.value?.num.val,
                      style: thin?.copyWith(fontSize: 18),
                    ),
                  const SizedBox(height: 25),
                  ...children,
                  const SizedBox(height: 25),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
