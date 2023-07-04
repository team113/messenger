import 'package:flutter/material.dart';

import '/themes.dart';
import '../../../../widget/svg/svg.dart';

class ImagesView extends StatelessWidget {
  const ImagesView({super.key});

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                child: Tooltip(
                  message: 'Dark background image',
                  child: Container(
                    decoration: BoxDecoration(
                      color: style.colors.onPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SvgImage.asset(
                          'assets/images/background_dark.svg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Flexible(
                child: Tooltip(
                  message: 'Light background image',
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F3C5D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SvgImage.asset(
                          'assets/images/background_light.svg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Tooltip(
                message: 'Full-length Logo',
                child: Column(
                  children: [
                    Container(
                      height: 300,
                      width: 200,
                      decoration: BoxDecoration(
                        color: style.colors.onPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child:
                            SvgImage.asset('assets/images/logo/logo0000.svg'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Tooltip(
                    message: 'Logo head',
                    child: Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        color: style.colors.onPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child:
                            SvgImage.asset('assets/images/logo/head0000.svg'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Tooltip(
                    message: 'Unread message counter icons',
                    child: Container(
                      width: 150,
                      height: 130,
                      decoration: BoxDecoration(
                        color: style.colors.onPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Wrap(
                          spacing: 3,
                          runSpacing: 3,
                          alignment: WrapAlignment.center,
                          children: List.generate(16, (index) {
                            final int number = index + 1;

                            return SizedBox(
                              height: 25,
                              width: 25,
                              child: Material(
                                type: MaterialType.circle,
                                color: style.colors.dangerColor,
                                child: Center(
                                  child: Text(
                                    number.toString(),
                                    style: fonts.headlineSmall!.copyWith(
                                      color: style.colors.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
