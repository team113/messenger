class _Fonts {
  const _Fonts({
    required this.largest,
    required this.larger,
    required this.large,
    required this.medium,
    required this.normal,
    required this.small,
    required this.smaller,
    required this.smallest,
  });

  final _LargestFonts largest;
  final _LargerFonts larger;
  final _LargeFonts large; // 21
  final _BigFonts big; // 18
  final _MediumFonts medium;
  final _NormalFonts normal;
  final _SmallFonts small;
  final _SmallerFonts smaller;
  final _SmallestFonts smallest;
}

class _LargestFonts {
  const _LargestFonts({
    required this.bold,
    required this.regular,
  });

  final _LargestFontsBold bold;
  final _LargestFontsRegular regular;
}

class FontsAnnotation {
  const FontsAnnotation({
    required this.style,
    {
      'bold': {
        'weight': 18,
        '',
      },
    }
  });

  final TextStyle style;
}

class _LargestFontsBold {
  const _LargestFontsBold({
    required this.onBackground,
    required this.onPrimary,
  });

  final TextStyle onBackground;
  final TextStyle onPrimary;
}

class _FontsWeight {
  // final bold;
  // final regular;
}

/// Fonts {
///   largest
///   large
///   ...
///   normal {
///     bold
///     regular {
///       onBackground
///       primary
///     }
///   }
/// }
///
///
/// 1. Map? -> нестрого
/// 2. Каждый шрифт = отдельный класс? миксины?
/// но нужен список всех цветов, всех толщин, всех размеров
/// 3. Кодогенерация...
///
/// А где список нужен? Только на странице стилей и всё. Мб и ок с классами.
