import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/field_button.dart';
import 'package:messenger/ui/page/home/widget/paddings.dart';
import 'package:messenger/ui/page/login/widget/primary_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/util/get.dart';
import 'package:messenger/util/message_popup.dart';

import 'controller.dart';

class EraseView extends StatelessWidget {
  const EraseView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: EraseController(Get.find(), Get.findOrNull<MyUserService>()),
      builder: (EraseController c) {
        return Scaffold(
          appBar: const CustomAppBar(title: Text('Request deletion')),
          body: ListView(
            children: [
              const Block(
                title: 'Instruction',
                children: [
                  Text(
                    'Account deletion can be requested from this page. This process in IRREVERSIBLE and you will never be able to restore your account.\n'
                    '\n'
                    'The data that will be deleted is:\n'
                    '- your avatar;\n'
                    '- your name;\n'
                    '- your biography;\n'
                    '- your login;\n'
                    '- all of your emails;\n'
                    '- all of your phone numbers;\n'
                    '- your contacts list.\n'
                    '\n'
                    'The data that will not be deleted:\n'
                    '- your Gapopa ID, as is does not represent personal information and cannot be used to associate account with you;\n'
                    '- the messages you have sent, however no one will see you as an author of those messages.\n'
                    '\n'
                    'Not a single user will be able to find, identify or detect the information of your presence within the system.',
                  ),
                ],
              ),
              _deletion(context, c),
            ],
          ),
        );
      },
    );
  }

  Widget _deletion(BuildContext context, EraseController c) {
    final style = Theme.of(context).style;

    return Obx(() {
      final List<Widget> children;

      if (c.authStatus.value.isLoading) {
        children = const [Center(child: CircularProgressIndicator())];
      } else if (c.authStatus.value.isEmpty) {
        children = [
          const Text(
            'In order to delete your account, please, authorize first in the form below.',
          ),
          const SizedBox(height: 25),
          ReactiveTextField(
            key: const Key('UsernameField'),
            state: c.login,
            label: 'label_sign_in_input'.l10n,
          ),
          const SizedBox(height: 16),
          ReactiveTextField(
            key: const ValueKey('PasswordField'),
            state: c.password,
            label: 'label_password'.l10n,
            obscure: c.obscurePassword.value,
            onSuffixPressed: c.obscurePassword.toggle,
            treatErrorAsStatus: false,
            trailing: SvgIcon(
              c.obscurePassword.value
                  ? SvgIcons.visibleOff
                  : SvgIcons.visibleOn,
            ),
          ),
          const SizedBox(height: 25),
          Obx(() {
            final bool enabled = !c.login.isEmpty.value &&
                c.login.error.value == null &&
                !c.password.isEmpty.value &&
                c.password.error.value == null;

            return PrimaryButton(
              title: 'Proceed',
              onPressed: enabled ? c.signIn : null,
            );
          }),
        ];
      } else {
        children = [
          Paddings.dense(
            FieldButton(
              key: const Key('DeleteAccount'),
              text: 'btn_delete_account'.l10n,
              onPressed: () => _deleteAccount(context, c),
              danger: true,
              style: style.fonts.normal.regular.danger,
            ),
          ),
        ];
      }

      return AnimatedSizeAndFade(
        fadeDuration: const Duration(milliseconds: 250),
        sizeDuration: const Duration(milliseconds: 250),
        child: Block(
          key: Key(
            '${c.authStatus.value.isLoading}${c.authStatus.value.isEmpty}',
          ),
          title: 'Delete account',
          children: children,
        ),
      );
    });
  }

  /// Opens a confirmation popup deleting the [MyUser]'s account.
  Future<void> _deleteAccount(BuildContext context, EraseController c) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_delete_account'.l10n,
      description: [
        TextSpan(text: 'alert_account_will_be_deleted1'.l10n),
        TextSpan(
          text: c.myUser?.value?.name?.val ??
              c.myUser?.value?.login?.val ??
              c.myUser?.value?.num.toString() ??
              'dot'.l10n * 3,
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_account_will_be_deleted2'.l10n),
      ],
    );

    if (result == true) {
      await c.deleteAccount();
    }
  }
}
