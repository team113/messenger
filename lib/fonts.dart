import 'package:flutter/rendering.dart';
import 'package:messenger/themes.dart';

///
/// 27
///   Bold
///     onBackground
///     primary
///   Regular
///     onBackground
///
/// 24
///   Bold
///     secondary
///   Regular
///     primary
///

class _Annotation {
  const _Annotation(this.schema);
  final Map<String, Map<String, List<String>>> schema;
}

class FontsSchema {
  FontsSchema({
    required TextStyle style,
    double largest = 27,
    double larger = 24,
    double large = 21,
    double big = 18,
    double medium = 17,
    double normal = 15,
    double small = 13,
    double smaller = 11,
    double smallest = 9,
    FontWeight bold = FontWeight.bold,
    FontWeight regular = FontWeight.normal,
    required Color onBackground,
  });

  final Sizes largest;
  final Sizes larger;
  final Sizes large;
  final Sizes big;
  final Sizes medium;
  final Sizes normal;
  final Sizes small;
  final Sizes smaller;
  final Sizes smallest;
}

@_Annotation(
  {
    'largest': {
      'bold': ['onBackground', 'primary'],
      'regular': ['onBackground', 'primary'],
    },
    'large': {
      'bold': ['onBackground', 'primary', 'secondary'],
      'regular': ['onBackground', 'onPrimary'],
    },
  },
)
class FontsExample extends FontsSchema {
  FontsExample();
}

class Fonts {
  Fonts({
    double largest = 27,
    double larger = 24,
    double large = 21,
    double big = 18,
    double medium = 17,
    double normal = 15,
    double small = 13,
    double smaller = 11,
    double smallest = 9,
    FontWeight bold = FontWeight.bold,
    FontWeight regular = FontWeight.normal,
    required TextStyle style,
    required Palette palette,
  }) : largest = _BoldRegular(
          _LargestFontsBold(
            style.copyWith(fontSize: largest, fontWeight: bold),
            palette,
          ),
          _LargestFontsRegular(
            style.copyWith(fontSize: largest, fontWeight: regular),
            palette,
          ),
        );

  final BoldRegular<_LargestFontsBold, _LargestFontsRegular> largest;
  final _Sizes larger;
  final _Sizes large; // 21
  final _Sizes big; // 18
  final _Sizes medium;
  final _Sizes normal;
  final _Sizes small;
  final _Sizes smaller;
  final _Sizes smallest;
}

class BoldRegular<T, K> {
  const BoldRegular(this.bold, this.regular);
  final T bold;
  final K regular;
}

class OnBackgroundOnPrimary<T, K> {
  const OnBackgroundOnPrimary(this.bold, this.regular);
  final T bold;
  final K regular;
}

class _LargestFonts {
  _LargestFonts(
    TextStyle style,
    Palette palette, {
    FontWeight bold = FontWeight.bold,
    FontWeight regular = FontWeight.normal,
  })  : bold = _LargestFontsBold(
          style.copyWith(fontWeight: bold),
          palette,
        ),
        regular = _LargestFontsRegular(
          style.copyWith(fontWeight: regular),
          palette,
        );

  final _LargestFontsBold bold;
  final _LargestFontsRegular regular;
}

class _LargestFontsBold {
  _LargestFontsBold(
    TextStyle style,
    Palette palette,
  )   : onBackground = style.copyWith(color: palette.onBackground),
        onPrimary = style.copyWith(color: palette.onPrimary);

  final TextStyle onBackground;
  final TextStyle onPrimary;
}

class _LargestFontsRegular {
  _LargestFontsRegular(
    TextStyle style,
    Palette palette,
  )   : onBackground = style.copyWith(color: palette.onBackground),
        onPrimary = style.copyWith(color: palette.onPrimary);

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
