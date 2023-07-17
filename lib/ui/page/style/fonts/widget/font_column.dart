import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';

class FontColumnWidget extends StatelessWidget {
  const FontColumnWidget(this.isDarkMode, {super.key});

  /// Indicator whether the dark mode is enabled or not.
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return AnimatedContainer(
      height: 750,
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF142839) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CustomFont(
                isDarkMode,
                title: 'Display Large',
                style: fonts.displayLarge,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Display Medium',
                style: fonts.displayMedium,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Display Small',
                style: fonts.displaySmall,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Headline Large',
                style: fonts.headlineLarge,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Headline Medium',
                style: fonts.headlineMedium,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Headline Small',
                style: fonts.headlineSmall,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Title Large',
                style: fonts.titleLarge,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Title Medium',
                style: fonts.titleMedium,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Title Small',
                style: fonts.titleSmall,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Label Large',
                style: fonts.labelLarge,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Label Medium',
                style: fonts.labelMedium,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Label Small',
                style: fonts.labelSmall,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Body Large',
                style: fonts.bodyLarge,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Body Medium',
                style: fonts.bodyMedium,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Body Small',
                style: fonts.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomFont extends StatelessWidget {
  const _CustomFont(
    this.isDarkMode, {
    required this.title,
    this.style,
  });

  final bool isDarkMode;

  final String title;

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 15,
      ),
      child: Text(
        title,
        style: style?.copyWith(
          color: isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
        ),
      ),
    );
  }
}
