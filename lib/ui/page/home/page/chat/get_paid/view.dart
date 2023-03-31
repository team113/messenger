import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/page/my_profile/add_email/view.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/util/platform_utils.dart';

import 'controller.dart';

class GetPaidView extends StatelessWidget {
  const GetPaidView({
    super.key,
    this.mode = GetPaidMode.users,
    this.user,
  });

  final GetPaidMode mode;
  final RxUser? user;

  /// Displays a [GetPaidView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    GetPaidMode mode = GetPaidMode.users,
    RxUser? user,
  }) {
    return ModalPopup.show(
      context: context,
      desktopPadding: EdgeInsets.zero,
      mobilePadding: EdgeInsets.zero,
      child: GetPaidView(mode: mode, user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: GetPaidController(Get.find(), mode: mode, user: user),
      builder: (GetPaidController c) {
        final TextStyle? thin = Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: Colors.black);

        final Widget buttons = Row(
          children: [
            if (context.isMobile) ...[
              Expanded(
                child: OutlinedRoundedButton(
                  key: const Key('Close'),
                  maxWidth: double.infinity,
                  title: Text('btn_close'.l10n),
                  onPressed: () {},
                  color: const Color(0xFFEEEEEE),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Obx(() {
                if (!c.verified.value) {
                  return OutlinedRoundedButton(
                    maxWidth: double.infinity,
                    title: Text(
                      'btn_verify_email'.l10n,
                      style: thin?.copyWith(color: Colors.white),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await Future.delayed(Duration(milliseconds: 100));
                      await AddEmailView.show(
                        router.context!,
                        email: c.myUser.value?.emails.unconfirmed,
                      );
                    },
                    color: Theme.of(context).colorScheme.secondary,
                  );
                }

                return OutlinedRoundedButton(
                  maxWidth: double.infinity,
                  title: Text(
                    'btn_confirm'.l10n,
                    style: thin?.copyWith(color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  color: Theme.of(context).colorScheme.secondary,
                );
              }),
            ),
          ],
        );

        return Stack(
          children: [
            Padding(
              padding: PlatformUtils.isMobile
                  ? const EdgeInsets.symmetric(horizontal: 10)
                  : const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  ModalPopupHeader(
                    header: Center(
                      child: Text(
                        c.user == null
                            ? 'label_get_paid_for_incoming'.l10n
                            : 'label_get_paid_for_incoming_from'.l10nfmt(
                                {
                                  'user': c.user!.user.value.name?.val ??
                                      c.user!.user.value.num.val
                                },
                              ),
                        textAlign: TextAlign.center,
                        style: thin?.copyWith(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      shrinkWrap: true,
                      children: [
                        if (c.mode != GetPaidMode.user)
                          _padding(
                            Center(
                              child: Text(
                                c.mode == GetPaidMode.users
                                    ? 'От всех пользователей (кроме Ваших контактов и индивидуальных пользователей)'
                                    : 'От Ваших контактов',
                                textAlign: TextAlign.center,
                                style: thin?.copyWith(
                                  color: Colors.black,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        _padding(
                          Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              ReactiveTextField(
                                enabled: c.verified.value,
                                state: c.messageCost,
                                hint: '0.00',
                                prefixText: '    ',
                                prefixStyle: const TextStyle(fontSize: 13),
                                label: 'label_fee_per_incoming_message'.l10n,
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                type: TextInputType.number,
                                formatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 21,
                                  bottom: PlatformUtils.isWeb ? 6 : 0,
                                ),
                                child: Text(
                                  '¤',
                                  style: TextStyle(
                                    height: 0.8,
                                    fontFamily: 'InterRoboto',
                                    fontWeight: FontWeight.w400,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    // color: Color(0xFFC6C6C6),
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _padding(
                          Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              ReactiveTextField(
                                enabled: c.verified.value,
                                state: c.callsCost,
                                hint: '0.00',
                                prefixText: '    ',
                                prefixStyle: const TextStyle(fontSize: 13),
                                label:
                                    'label_fee_per_incoming_call_minute'.l10n,
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                type: TextInputType.number,
                                formatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  // FilteringTextInputFormatter.deny(RegExp(r'[a-z]')),
                                  // FilteringTextInputFormatter.deny(RegExp(r'[A-Z]')),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 21,
                                  bottom: PlatformUtils.isWeb ? 6 : 0,
                                ),
                                child: Text(
                                  '¤',
                                  style: TextStyle(
                                    height: 0.8,
                                    fontFamily: 'InterRoboto',
                                    fontWeight: FontWeight.w400,
                                    // color: Color(0xFFC6C6C6),
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: buttons,
                  ),
                  Obx(() {
                    if (c.verified.value) {
                      return const SizedBox();
                    }

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(30 + 6, 6, 30 + 6, 6),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  'Данная опция доступна только для аккаунтов с верифицированным E-mail'
                                      .l10n,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Positioned.fill(
              child: Obx(() {
                return IgnorePointer(
                  ignoring: true,
                  child: Center(
                    child: AnimatedContainer(
                      duration: 200.milliseconds,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: c.verified.value
                            ? const Color(0x00000000)
                            : const Color(0x0A000000),
                      ),
                      constraints: context.isNarrow
                          ? null
                          : const BoxConstraints(maxWidth: 400),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  /// Basic [Padding] wrapper.
  Widget _padding(Widget child) =>
      Padding(padding: const EdgeInsets.all(8), child: child);
}
