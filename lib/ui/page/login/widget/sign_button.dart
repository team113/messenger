import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/download_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';

class SignButton extends StatelessWidget {
  const SignButton({
    required this.text,
    this.leading,
    this.asset = '',
    this.assetWidth = 20,
    this.assetHeight = 20,
    this.padding = EdgeInsets.zero,
    this.onPressed,
    super.key,
  });

  final String text;
  final Widget? leading;
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
        style: style.fonts.titleMedium.copyWith(color: style.colors.primary),
        onPressed: onPressed ?? () {},
        prefix: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 0).add(padding),
          child: leading ??
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
