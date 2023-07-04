import 'package:flutter/material.dart';

import '/themes.dart';

class FontFamiliesView extends StatelessWidget {
  const FontFamiliesView({super.key});

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return Column(
      children: [
        FontWidget(
          label: 'SFUI-Light',
          textStyle: fonts.displayLarge!.copyWith(fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 30),
        FontWidget(
          label: 'SFUI-Regular',
          textStyle: fonts.displayLarge!.copyWith(
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 30),
        FontWidget(label: 'SFUI-Bold', textStyle: fonts.displayLarge!),
      ],
    );
  }
}

class FontWidget extends StatelessWidget {
  const FontWidget({super.key, required this.textStyle, required this.label});

  final String label;

  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Stack(
      children: [
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: style.colors.onPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 32),
            child: DefaultTextStyle(
              style: textStyle,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
                  SizedBox(height: 40),
                  Text('abcdefghijklmnopqrstuvwxyz'),
                  SizedBox(height: 40),
                  Padding(
                    padding: EdgeInsets.only(bottom: 25),
                    child: Row(
                      children: [
                        Text('1234567890'),
                        SizedBox(width: 50),
                        Text('_-–—.,:;!?()[]{}|©=+£€\$&%№«»“”˚*')
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 0,
          child: Text(
            label,
            style: fonts.displayLarge!.copyWith(
              color: const Color(0xFFF5F5F5),
              fontSize: 55,
            ),
          ),
        ),
      ],
    );
  }
}
