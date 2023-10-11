import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/download_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';

class SignButton extends StatelessWidget {
  const SignButton({
    super.key,
    required this.text,
    this.leading,
    this.icon,
    this.asset = '',
    this.assetWidth = 20,
    this.assetHeight = 20,
    this.padding = EdgeInsets.zero,
    this.onPressed,
    this.dense = false,
  });

  final String text;
  final bool dense;
  final Widget? leading;

  final Widget? icon;

  final String asset;
  final double assetWidth;
  final double assetHeight;
  final EdgeInsets padding;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Center(
      child: PrefixButton(
        text: text,
        style: dense ? style.fonts.labelMediumPrimary : style.fonts.titleLarge,
        onPressed: onPressed ?? () {},
        prefix: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 0).add(padding),
          child: icon ??
              leading ??
              SvgImage.asset(
                'assets/icons/$asset.svg',
                width: assetWidth,
                height: assetHeight,
              ),
        ),
      ),
    );
  }
}
