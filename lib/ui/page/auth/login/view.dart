import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/auth/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/popup/popup.dart';
import 'package:messenger/ui/widget/text_field.dart';

import 'controller.dart';

class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

  static Future<T?> show<T>(BuildContext context) {
    return Popup.show(context, const LoginView(),
        contentMaxWidth: 400, layoutMaxWidth: 520);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final TextStyle? thin =
        theme.textTheme.caption?.copyWith(color: Colors.black);

    return GetBuilder(
      init: LoginController(Get.find()),
      builder: (LoginController c) {
        return Obx(() {
          List<Widget> children;
          if (c.showNewPasswordSection.value) {
            children = [
              Center(
                child: Text(
                  'Задайте новый пароль для входа в аккаунт',
                  style: thin?.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 57),
              ReactiveTextField(
                key: const Key('PasswordField'),
                state: c.newPassword,
                label: 'label_new_password'.tr,
                obscure: true,
              ),
              const SizedBox(height: 16),
              ReactiveTextField(
                key: const Key('RepeatPasswordField'),
                state: c.repeatPassword,
                label: 'label_repeat_password'.tr,
                obscure: true,
              ),
              const SizedBox(height: 58),
              loginPopupButtons(
                  mainButtonTitle: 'btn_next'.tr,
                  onMainButtonPressed: c.resetUserPassword,
                  secondaryButtonTitle: 'btn_back'.tr,
                  onSecondaryButtonPressed: c.showNewPasswordSection.toggle),
              const SizedBox(height: 16),
            ];
          } else if (c.showCodeSection.value) {
            children = [
              Center(
                child: Text(
                  'Код подтверждения был выслан на ваш e-mail. Пожалуйста, введите его ниже.',
                  style: thin?.copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 57),
              ReactiveTextField(
                key: const Key('RecoveryCodeField'),
                state: c.recoveryCode,
                label: 'label_recovery_code'.tr,
                type: TextInputType.number,
              ),
              const SizedBox(height: 58),
              loginPopupButtons(
                  mainButtonTitle: 'btn_next'.tr,
                  onMainButtonPressed: c.recoveryCode.submit,
                  secondaryButtonTitle: 'btn_back'.tr,
                  onSecondaryButtonPressed: c.showCodeSection.toggle),
              const SizedBox(height: 16),
            ];
          } else if (c.displayAccess.value) {
            children = [
              Center(
                child: Text(
                  'label_recover_account'.tr,
                  style: thin?.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 57),
              ReactiveTextField(
                key: const Key('RecoveryField'),
                state: c.recovery,
                label: 'label_sign_in_input'.tr,
              ),
              const SizedBox(height: 58),
              loginPopupButtons(
                  mainButtonTitle: 'btn_next'.tr,
                  onMainButtonPressed: c.recovery.submit,
                  secondaryButtonTitle: 'btn_back'.tr,
                  onSecondaryButtonPressed: c.displayAccess.toggle),
              const SizedBox(height: 16),
            ];
          } else {
            children = [
              Center(
                child: Text(
                  'label_entrance'.tr,
                  style: thin?.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 57),
              ReactiveTextField(
                key: const Key('UsernameField'),
                state: c.login,
                label: 'label_sign_in_input'.tr,
                onChanged: () {},
              ),
              const SizedBox(height: 16),
              ReactiveTextField(
                key: const ValueKey('PasswordField'),
                obscure: true,
                state: c.password,
                label: 'label_password'.tr,
              ),
              const SizedBox(height: 52),
              loginPopupButtons(
                  isRightMainButton: false,
                  mainButtonTitle: 'btn_login'.tr,
                  secondaryButtonTitle: 'btn_forgot_password'.tr,
                  onMainButtonPressed: c.signIn,
                  onSecondaryButtonPressed: () {
                    c.recovery.unchecked = c.login.text;
                    c.recovery.error.value = null;
                    c.displayAccess.toggle();
                  }),
              const SizedBox(height: 16),
            ];
          }

          return AnimatedSize(
            duration: 250.milliseconds,
            curve: Curves.easeOut,
            child: AnimatedSwitcher(
              duration: 250.milliseconds,
              child: ListView(
                key: Key('${c.displayAccess.value}'),
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 12),
                  ...children,
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

Widget loginPopupButtons(
    {bool isRightMainButton = true,
    String mainButtonTitle = '',
    String secondaryButtonTitle = '',
    VoidCallback? onMainButtonPressed,
    VoidCallback? onSecondaryButtonPressed,
    Color mainButtonColor = const Color(0xFF63B4FF),
    Color secondaryButtonColor = const Color(0xFFEEEEEE),
    Color mainButtonTextColor = Colors.white}) {
  var elements = [
    Expanded(
      child: OutlinedRoundedButton(
        maxWidth: null,
        title: Text(secondaryButtonTitle),
        onPressed: onSecondaryButtonPressed,
        color: secondaryButtonColor,
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: OutlinedRoundedButton(
        maxWidth: null,
        title: Text(
          mainButtonTitle,
          style: TextStyle(color: mainButtonTextColor),
        ),
        onPressed: onMainButtonPressed,
        color: const Color(0xFF63B4FF),
      ),
    ),
  ];
  return Row(
    children: isRightMainButton ? elements : elements.reversed.toList(),
  );
}
