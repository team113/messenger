import 'package:flutter/material.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/login/widget/primary_button.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/widget_button.dart';

class BuyButton extends StatelessWidget {
  const BuyButton({
    super.key,
    this.onPressed,
  });

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    // final style = Theme.of(context).style;

    return PrimaryButton(
      title: 'btn_add_funds'.l10n,
      onPressed: onPressed,
    );

    // return WidgetButton(
    //   onPressed: () {},
    //   child: Container(
    //     decoration: BoxDecoration(
    //       color: style.colors.primary,
    //       borderRadius: BorderRadius.circular(8),
    //     ),
    //     padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    //     child: Text(
    //       'btn_add_funds'.l10n,
    //       style: style.fonts.small.regular.onPrimary,
    //     ),
    //   ),
    // );
  }
}
