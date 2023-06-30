import 'package:flutter/material.dart';

import '/themes.dart';

class FontFamiliesView extends StatelessWidget {
  const FontFamiliesView({super.key});

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Stack(
      children: [
        Container(
          height: 500,
          decoration: BoxDecoration(
            color: style.colors.onPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ',
                  style: fonts.displayLarge,
                ),
                const SizedBox(height: 40),
                Text(
                  'абвгдеёжзийклмнопрстуфхцчшщъыьэюя',
                  style: fonts.displayLarge,
                ),
                const SizedBox(height: 40),
                Text(
                  'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                  style: fonts.displayLarge,
                ),
                const SizedBox(height: 40),
                Text(
                  'abcdefghijklmnopqrstuvwxyz',
                  style: fonts.displayLarge,
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Text('1234567890', style: fonts.displayLarge),
                    const SizedBox(width: 50),
                    Text(
                      '_-–—.,:;!?()[]{}|©=+£€\$&%№«»“”˚*',
                      style: fonts.displayLarge,
                    )
                  ],
                )
              ],
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 0,
          child: Text(
            'SFUI',
            style: fonts.displayLarge!.copyWith(
              color: const Color(0xFFF5F5F5),
              fontSize: 100,
            ),
          ),
        ),
      ],
    );
  }
}
