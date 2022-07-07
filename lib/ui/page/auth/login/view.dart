import 'package:flutter/cupertino.dart' show kCupertinoModalBarrierColor;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/auth/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/util/platform_utils.dart';

import 'controller.dart';

class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

  static Future<T?> show<T>(BuildContext context) {
    if (context.isMobile) {
      return showModalBottomSheet(
        context: context,
        barrierColor: kCupertinoModalBarrierColor,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 60,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCCCCC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: const LoginView(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      );
    } else {
      return showDialog(
        context: context,
        barrierColor: kCupertinoModalBarrierColor,
        builder: (context) => Stack(
          children: [
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.fromLTRB(
                  10,
                  10,
                  10,
                  10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        InkResponse(
                          onTap: Navigator.of(context).pop,
                          radius: 11,
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xBB818181),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: const Center(child: LoginView()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
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

          if (c.displayAccess.value) {
            children = [
              Center(
                child: Text(
                  'Восстановление доступа',
                  style: thin?.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 25),
              const SizedBox(height: 32),
              ReactiveTextField(
                key: const Key('RecoveryField'),
                state: c.recovery,
                label: 'label_sign_in_input'.tr,
                onChanged: () {},
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 10),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedRoundedButton(
                      maxWidth: null,
                      title: Text('Назад'.tr),
                      onPressed: c.displayAccess.toggle,
                      color: const Color(0xFFEEEEEE),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedRoundedButton(
                      maxWidth: null,
                      title: Text(
                        'Далее'.tr,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onPressed: c.recoverAccess,
                      color: const Color(0xFF63B4FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ];
          } else {
            children = [
              Center(
                child: Text(
                  'Вход',
                  style: thin?.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(height: 25),
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
              const SizedBox(height: 10),
              const SizedBox(height: 10),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedRoundedButton(
                      maxWidth: null,
                      title: Text(
                        'btn_login'.tr,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onPressed: c.signIn,
                      color: const Color(0xFF63B4FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedRoundedButton(
                      maxWidth: null,
                      title: Text('btn_forgot_password'.tr),
                      onPressed: () {
                        c.recovery.unchecked = c.login.text;
                        c.recovery.error.value = null;
                        c.displayAccess.toggle();
                      },
                      color: const Color(0xFFEEEEEE),
                    ),
                  ),
                ],
              ),
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
