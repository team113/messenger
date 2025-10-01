// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sound_fonts/sound_fonts.dart';

import 'ui/widget/custom_page.dart';
import 'util/log.dart';
import 'util/platform_utils.dart';

part 'themes.g.dart';

/// Application themes constants.
@SoundFonts({
  'largest': {
    'bold': ['onBackground', 'onPrimary'],
    'regular': ['onBackground', 'onPrimary', 'secondary'],
  },
  'larger': {
    'regular': ['onBackground', 'secondary'],
  },
  'large': {
    'regular': ['onBackground', 'secondary'],
  },
  'big': {
    'regular': ['onBackground', 'onPrimary', 'secondary', 'primary'],
  },
  'medium': {
    'regular': [
      'onBackground',
      'onPrimary',
      'primary',
      'primaryHighlightLightest',
      'secondary',
    ],
    'bold': ['onPrimary'],
  },
  'normal': {
    'bold': ['onBackground', 'onPrimary'],
    'regular': [
      'danger',
      'onBackground',
      'onPrimary',
      'primary',
      'secondary',
      'secondaryHighlightDarkest',
    ],
  },
  'small': {
    'regular': [
      'danger',
      'onBackground',
      'onPrimary',
      'primary',
      'secondary',
      'secondaryHighlight',
      'secondaryHighlightDarkest',
    ],
  },
  'smaller': {
    'bold': ['onPrimary', 'secondary'],
    'regular': ['onBackground', 'secondary', 'onPrimary', 'primary'],
  },
  'smallest': {
    'regular': ['onBackground', 'onPrimary', 'secondary', 'primary'],
  },
})
class Themes {
  /// [FontLoader] of a `Roboto` font.
  static FontLoader? _roboto;

  /// Returns a light theme.
  static ThemeData light() {
    final Palette colors = Palette(
      primary: const Color(0xFF63B4FF),
      primaryHighlight: const Color(0xFF2196F3),
      primaryHighlightShiny: const Color(0xFF58A6EF),
      primaryHighlightShiniest: const Color(0xFFD2E3F9),
      primaryHighlightLightest: const Color(0xFFB9D9FA),
      primaryLight: const Color(0xFFD2E9FE),
      primaryLightest: const Color(0xFFD5EDFE),
      primaryDark: const Color(0xFF1F3C5D),
      primaryAuxiliary: const Color(0xFF0A2E4F),
      onPrimary: const Color(0xFFFFFFFF),
      onPrimaryLight: const Color(0xFFF5F5F5),
      secondary: const Color(0xFF888888),
      secondaryLight: const Color(0xFFCCCCCC),
      secondaryHighlight: const Color(0xFFEFEFEF),
      secondaryHighlightDark: const Color(0xFFDEDEDE),
      secondaryHighlightDarkest: const Color(0xFFC4C4C4),
      secondaryBackground: const Color(0xFF222222),
      secondaryBackgroundLight: const Color(0xFF444444),
      secondaryBackgroundLightest: const Color(0xFF666666),
      onSecondary: const Color(0xFF4E5A78),
      background: const Color(0xFFF2F5F8),
      backgroundAuxiliary: const Color(0xFF0A1724),
      backgroundAuxiliaryLight: const Color(0xFF132131),
      backgroundAuxiliaryLighter: const Color(0xFFE6F1FE),
      backgroundAuxiliaryLightest: const Color(0xFFF4F9FF),
      backgroundGallery: const Color(0xF20C0C0C),
      onBackground: const Color(0xFF000000),
      transparent: const Color(0x00000000),
      almostTransparent: const Color(0x01000000),
      accept: const Color(0x7F34B139),
      acceptAuxiliary: const Color(0xFF4CAF50),
      acceptLight: const Color(0xFFBFE3B9),
      acceptLighter: const Color(0xFFD9FDD3),
      acceptLightest: const Color(0xFFF2FDED),
      decline: const Color(0xFFFF0000),
      danger: const Color(0xFFF44336),
      warning: const Color(0xFFFF9800),
      userColors: const [
        Color(0xFFD2B334),
        Color(0xFF2192FF),
        Color(0xFF9C27B0),
        Color(0xFFFF9800),
        Color(0xFF0094A7),
        Color(0xFF7F81FF),
        Color(0xFFFF5722),
        Color(0xFFC70100),
        Color(0xFF8BC34A),
        Color(0xFF16712D),
        Color(0xFFFF5B89),
        Color(0xFF332FD0),
        Color(0xFFB96215),
        Color(0xFF00BF79),
        Color(0xFF00ACCF),
        Color(0xFFED36FF),
        Color(0xFF00CC25),
        Color(0xFFFF1008),
        Color(0xFFCB9F7A),
      ],
    );

    if (_roboto == null) {
      _roboto = FontLoader('Roboto');
      _roboto?.addFont(
        PlatformUtils.loadBytes('assets/fonts/Roboto-Gapopa-Regular.ttf'),
      );
      _roboto?.addFont(
        PlatformUtils.loadBytes('assets/fonts/Roboto-Gapopa-Bold.ttf'),
      );
      _roboto?.load().then((_) async {
        Log.debug('light() -> `FontLoader` has loaded the font', 'Themes');
      });
    }

    final TextStyle textStyle = TextStyle(
      fontFamily: 'Roboto',
      color: colors.onBackground,
      fontSize: 17,
      fontWeight: FontWeight.w400,
      height: 1.3,
      letterSpacing: 0,
      wordSpacing: 0,
    );

    final Fonts fonts = Fonts(
      style: textStyle,
      primary: colors.primary,
      primaryHighlightLightest: colors.primaryHighlightLightest,
      onBackground: colors.onBackground,
      secondary: colors.secondary,
      secondaryHighlight: colors.secondaryHighlight,
      secondaryHighlightDarkest: colors.secondaryHighlightDarkest,
      onPrimary: colors.onPrimary,
      danger: colors.danger,
      bold: FontWeight.w700,
      regular: FontWeight.w400,
      largest: 27,
      larger: 24,
      large: 21,
      big: 18,
      medium: 17,
      normal: 15,
      small: 13,
      smaller: 11,
      smallest: 9,
    );

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: colors.transparent,
        statusBarColor: colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final ThemeData theme = ThemeData.light();

    return theme.copyWith(
      extensions: [
        Style(
          colors: colors,
          fonts: fonts,
          barrierColor: colors.onBackgroundOpacity50,
          cardBlur: 5,
          cardBorder: Border.all(
            color: colors.secondaryHighlightDark,
            width: 0.5,
          ),
          cardColor: colors.onPrimaryOpacity95,
          cardHoveredColor: colors.backgroundAuxiliaryLightest,
          cardHoveredBorder: Border.all(
            color: colors.primaryHighlightShiniest,
            width: 0.5,
          ),
          cardRadius: BorderRadius.circular(14),
          cardSelectedBorder: Border.all(
            color: colors.primaryHighlightShiny,
            width: 0.5,
          ),
          contextMenuBackgroundColor: colors.onPrimary,
          contextMenuHoveredColor: colors.backgroundAuxiliaryLightest,
          contextMenuRadius: BorderRadius.circular(11),
          linkStyle: textStyle.copyWith(color: colors.primary),
          messageColor: colors.onPrimary,
          primaryBorder: Border.all(
            color: colors.secondaryHighlightDark,
            width: 0.5,
          ),
          readMessageColor: colors.primaryLight,
          secondaryBorder: Border.all(color: colors.acceptLight, width: 0.5),
          sidebarColor: colors.onPrimaryOpacity50,
          systemMessageBorder: Border.all(
            color: colors.secondaryHighlightDark,
            width: 0.5,
          ),
          systemMessageColor: colors.secondaryHighlight,
          systemMessageStyle: fonts.small.regular.secondary,
          systemMessagePrimary: fonts.small.regular.primary,
          unreadMessageColor: colors.primaryLightest,
        ),
      ],
      scaffoldBackgroundColor: colors.transparent,
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: colors.onPrimaryOpacity25,
        foregroundColor: colors.secondary,
        iconTheme: theme.appBarTheme.iconTheme?.copyWith(
          color: colors.secondary,
        ),
        actionsIconTheme: theme.appBarTheme.iconTheme?.copyWith(
          color: colors.secondary,
        ),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: fonts.big.regular.onBackground,
      ),
      tabBarTheme: theme.tabBarTheme.copyWith(
        labelColor: colors.primary,
        unselectedLabelColor: colors.secondary,
      ),
      primaryIconTheme: const IconThemeData.fallback().copyWith(
        color: colors.secondary,
      ),
      splashColor: colors.transparent,
      iconTheme: theme.iconTheme.copyWith(color: colors.onBackground),
      textTheme: Typography.blackCupertino.copyWith(
        displayLarge: fonts.largest.regular.onBackground,
        displayMedium: fonts.larger.regular.onBackground,
        displaySmall: fonts.large.regular.onBackground,
        headlineLarge: fonts.big.regular.onBackground,
        headlineMedium: fonts.big.regular.onBackground,
        headlineSmall: fonts.small.regular.onBackground,
        titleLarge: fonts.medium.regular.onBackground,
        titleMedium: fonts.normal.regular.onBackground,
        titleSmall: fonts.normal.bold.onBackground,
        labelLarge: fonts.normal.regular.onBackground,
        labelMedium: fonts.small.regular.onBackground,
        labelSmall: fonts.smaller.regular.onBackground,
        bodyLarge: fonts.medium.regular.onBackground,
        bodyMedium: fonts.normal.regular.onBackground,
        bodySmall: fonts.small.regular.onBackground,
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        focusColor: colors.primary,
        hoverColor: colors.transparent,
        fillColor: colors.primary,
        hintStyle: fonts.normal.regular.secondaryHighlightDarkest,
        labelStyle: fonts.normal.regular.secondaryHighlightDarkest,
        errorStyle: fonts.small.regular.danger,
        helperStyle: fonts.normal.regular.secondaryHighlightDarkest,
        prefixStyle: fonts.normal.regular.secondaryHighlightDarkest,
        suffixStyle: fonts.normal.regular.secondaryHighlightDarkest,
        counterStyle: fonts.small.regular.secondaryHighlightDarkest,
        floatingLabelStyle: fonts.normal.regular.secondary,
        errorMaxLines: 5,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.secondaryHighlightDarkest),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.secondaryHighlightDarkest),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.secondaryHighlightDarkest),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.danger),
        ),
      ),
      textSelectionTheme: theme.textSelectionTheme.copyWith(
        cursorColor: colors.primary,
        selectionHandleColor: colors.primary,
      ),
      floatingActionButtonTheme: theme.floatingActionButtonTheme.copyWith(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      bottomNavigationBarTheme: theme.bottomNavigationBarTheme.copyWith(
        backgroundColor: colors.primaryHighlightShiniest,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.secondary,
      ),
      progressIndicatorTheme: theme.progressIndicatorTheme.copyWith(
        color: colors.primary,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.secondary,
          textStyle: fonts.medium.regular.secondary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.transparent,
          foregroundColor: colors.secondary,
          minimumSize: const Size(100, 60),
          maximumSize: const Size(250, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          side: BorderSide(width: 1, color: colors.secondary),
          textStyle: fonts.medium.regular.secondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.all(12),
          textStyle: fonts.normal.regular.secondary,
        ),
      ),
      scrollbarTheme: theme.scrollbarTheme.copyWith(
        interactive: true,
        thickness: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged) ||
              states.contains(WidgetState.hovered)) {
            return 6;
          }

          return 4;
        }),
      ),
      radioTheme: theme.radioTheme.copyWith(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }

          return colors.primary;
        }),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CustomCupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CustomCupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CustomCupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CustomCupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Returns a dark theme.
  static ThemeData dark() {
    /// TODO: Dark theme support.
    throw UnimplementedError();
  }
}

/// Shadow cast by a box that allows to customize its [blurStyle].
class CustomBoxShadow extends BoxShadow {
  const CustomBoxShadow({
    super.color,
    super.offset,
    super.blurRadius,
    BlurStyle blurStyle = BlurStyle.normal,
  }) : _blurStyle = blurStyle;

  /// Style to use for blur in [MaskFilter] object.
  final BlurStyle _blurStyle;

  @override
  Paint toPaint() {
    final Paint result = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(_blurStyle, blurSigma);
    assert(() {
      if (debugDisableShadows) {
        result.maskFilter = null;
      }
      return true;
    }());
    return result;
  }
}

/// [ThemeExtension] containing custom additional style-related fields.
class Style extends ThemeExtension<Style> {
  const Style({
    required this.colors,
    required this.fonts,
    required this.barrierColor,
    required this.cardBlur,
    required this.cardBorder,
    required this.cardColor,
    required this.cardHoveredColor,
    required this.cardHoveredBorder,
    required this.cardRadius,
    required this.cardSelectedBorder,
    required this.contextMenuBackgroundColor,
    required this.contextMenuHoveredColor,
    required this.contextMenuRadius,
    required this.linkStyle,
    required this.messageColor,
    required this.primaryBorder,
    required this.readMessageColor,
    required this.secondaryBorder,
    required this.sidebarColor,
    required this.systemMessageBorder,
    required this.systemMessageColor,
    required this.systemMessageStyle,
    required this.systemMessagePrimary,
    required this.unreadMessageColor,
  });

  /// [Palette] to use in the application.
  final Palette colors;

  /// [Fonts] to use in the application.
  final Fonts fonts;

  /// [Color] of the modal background barrier.
  final Color barrierColor;

  /// Blur to apply to card-like [Widget]s.
  final double cardBlur;

  /// [Border] to apply to card-like [Widget]s.
  final Border cardBorder;

  /// Background [Color] of card-like [Widget]s.
  final Color cardColor;

  /// Background [Color] of card-like [Widget]s when hovered.
  final Color cardHoveredColor;

  /// [Border] to apply to hovered card-like [Widget]s.
  final Border cardHoveredBorder;

  /// [BorderRadius] to use in card-like [Widget]s.
  final BorderRadius cardRadius;

  /// [Border] to apply to selected card-like [Widget]s.
  final Border cardSelectedBorder;

  /// Background [Color] of the [ContextMenu].
  final Color contextMenuBackgroundColor;

  /// [Color] of the hovered [ContextMenuButton].
  final Color contextMenuHoveredColor;

  /// [BorderRadius] of the [ContextMenu].
  final BorderRadius contextMenuRadius;

  /// [TextStyle] to apply to a link.
  final TextStyle linkStyle;

  /// Background [Color] of [ChatMessage]s, [ChatForward]s and [ChatCall]s.
  final Color messageColor;

  /// [Border] to apply to [ColorScheme.primary] color.
  final Border primaryBorder;

  /// Background [Color] of [ChatMessage]s, [ChatForward]s and [ChatCall]s
  /// posted by the authenticated [MyUser].
  final Color readMessageColor;

  /// [Border] to apply to [ColorScheme.secondary] color.
  final Border secondaryBorder;

  /// [Color] of the [HomeView]'s side bar.
  final Color sidebarColor;

  /// [Border] to apply to system messages.
  final Border systemMessageBorder;

  /// [Color] of system messages.
  final Color systemMessageColor;

  /// [TextStyle] of system messages.
  final TextStyle systemMessageStyle;

  /// [TextStyle] of system messages with a primary color.
  final TextStyle systemMessagePrimary;

  /// Background [Color] of unread [ChatMessage]s, [ChatForward]s and
  /// [ChatCall]s posted by the authenticated [MyUser].
  final Color unreadMessageColor;

  @override
  ThemeExtension<Style> copyWith({
    Palette? colors,
    Fonts? fonts,
    Color? barrierColor,
    double? cardBlur,
    Border? cardBorder,
    Color? cardColor,
    Color? cardHoveredColor,
    Border? cardHoveredBorder,
    BorderRadius? cardRadius,
    Border? cardSelectedBorder,
    Color? contextMenuBackgroundColor,
    Color? contextMenuHoveredColor,
    BorderRadius? contextMenuRadius,
    TextStyle? linkStyle,
    Color? messageColor,
    Border? primaryBorder,
    Color? readMessageColor,
    Border? secondaryBorder,
    Color? sidebarColor,
    Border? systemMessageBorder,
    Color? systemMessageColor,
    TextStyle? systemMessageStyle,
    TextStyle? systemMessagePrimary,
    Color? unreadMessageColor,
  }) {
    return Style(
      colors: colors ?? this.colors,
      fonts: fonts ?? this.fonts,
      barrierColor: barrierColor ?? this.barrierColor,
      cardBlur: cardBlur ?? this.cardBlur,
      cardBorder: cardBorder ?? this.cardBorder,
      cardColor: cardColor ?? this.cardColor,
      cardHoveredColor: cardHoveredColor ?? this.cardHoveredColor,
      cardHoveredBorder: cardHoveredBorder ?? this.cardHoveredBorder,
      cardRadius: cardRadius ?? this.cardRadius,
      cardSelectedBorder: cardSelectedBorder ?? this.cardSelectedBorder,
      contextMenuBackgroundColor:
          contextMenuBackgroundColor ?? this.contextMenuBackgroundColor,
      contextMenuHoveredColor:
          contextMenuHoveredColor ?? this.contextMenuHoveredColor,
      contextMenuRadius: contextMenuRadius ?? this.contextMenuRadius,
      linkStyle: linkStyle ?? this.linkStyle,
      messageColor: messageColor ?? this.messageColor,
      primaryBorder: primaryBorder ?? this.primaryBorder,
      readMessageColor: readMessageColor ?? this.readMessageColor,
      secondaryBorder: secondaryBorder ?? this.secondaryBorder,
      sidebarColor: sidebarColor ?? this.sidebarColor,
      systemMessageBorder: systemMessageBorder ?? this.systemMessageBorder,
      systemMessageColor: systemMessageColor ?? this.systemMessageColor,
      systemMessageStyle: systemMessageStyle ?? this.systemMessageStyle,
      systemMessagePrimary: systemMessagePrimary ?? this.systemMessagePrimary,
      unreadMessageColor: unreadMessageColor ?? this.unreadMessageColor,
    );
  }

  @override
  ThemeExtension<Style> lerp(ThemeExtension<Style>? other, double t) {
    if (other is! Style) {
      return this;
    }

    return Style(
      colors: Palette.lerp(colors, other.colors, t),
      fonts: Fonts.lerp(fonts, other.fonts, t),
      barrierColor: Color.lerp(barrierColor, other.barrierColor, t)!,
      cardBlur: cardBlur * (1.0 - t) + other.cardBlur * t,
      cardBorder: Border.lerp(cardBorder, other.cardBorder, t)!,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      cardHoveredColor: Color.lerp(
        cardHoveredColor,
        other.cardHoveredColor,
        t,
      )!,
      cardHoveredBorder: Border.lerp(
        cardHoveredBorder,
        other.cardHoveredBorder,
        t,
      )!,
      cardRadius: BorderRadius.lerp(cardRadius, other.cardRadius, t)!,
      cardSelectedBorder: Border.lerp(
        cardSelectedBorder,
        other.cardSelectedBorder,
        t,
      )!,
      contextMenuBackgroundColor: Color.lerp(
        contextMenuBackgroundColor,
        other.contextMenuBackgroundColor,
        t,
      )!,
      contextMenuHoveredColor: Color.lerp(
        contextMenuHoveredColor,
        other.contextMenuHoveredColor,
        t,
      )!,
      contextMenuRadius: BorderRadius.lerp(
        contextMenuRadius,
        other.contextMenuRadius,
        t,
      )!,
      linkStyle: TextStyle.lerp(linkStyle, other.linkStyle, t)!,
      messageColor: Color.lerp(messageColor, other.messageColor, t)!,
      primaryBorder: Border.lerp(primaryBorder, other.primaryBorder, t)!,
      readMessageColor: Color.lerp(
        readMessageColor,
        other.readMessageColor,
        t,
      )!,
      secondaryBorder: Border.lerp(secondaryBorder, other.secondaryBorder, t)!,
      sidebarColor: Color.lerp(sidebarColor, other.sidebarColor, t)!,
      systemMessageBorder: Border.lerp(
        systemMessageBorder,
        other.systemMessageBorder,
        t,
      )!,
      systemMessageColor: Color.lerp(
        systemMessageColor,
        other.systemMessageColor,
        t,
      )!,
      systemMessageStyle: TextStyle.lerp(
        systemMessageStyle,
        other.systemMessageStyle,
        t,
      )!,
      systemMessagePrimary: TextStyle.lerp(
        systemMessagePrimary,
        other.systemMessagePrimary,
        t,
      )!,
      unreadMessageColor: Color.lerp(
        unreadMessageColor,
        other.unreadMessageColor,
        t,
      )!,
    );
  }
}

/// [Color]s used throughout the application.
class Palette {
  Palette({
    required this.primary,
    Color? primaryOpacity20,
    required this.primaryHighlight,
    required this.primaryHighlightShiny,
    required this.primaryHighlightShiniest,
    required this.primaryHighlightLightest,
    required this.primaryLight,
    required this.primaryLightest,
    required this.primaryDark,
    Color? primaryDarkOpacity70,
    Color? primaryDarkOpacity90,
    required this.primaryAuxiliary,
    Color? primaryAuxiliaryOpacity25,
    Color? primaryAuxiliaryOpacity90,
    Color? primaryAuxiliaryOpacity95,
    required this.onPrimary,
    required this.onPrimaryLight,
    Color? onPrimaryOpacity7,
    Color? onPrimaryOpacity10,
    Color? onPrimaryOpacity25,
    Color? onPrimaryOpacity50,
    Color? onPrimaryOpacity95,
    required this.secondary,
    required this.secondaryLight,
    required this.secondaryBackground,
    required this.secondaryBackgroundLight,
    required this.secondaryBackgroundLightest,
    required this.secondaryHighlight,
    required this.secondaryHighlightDark,
    required this.secondaryHighlightDarkest,
    Color? secondaryOpacity87,
    Color? secondaryOpacity40,
    required this.onSecondary,
    Color? onSecondaryOpacity20,
    Color? onSecondaryOpacity50,
    Color? onSecondaryOpacity60,
    Color? onSecondaryOpacity88,
    required this.background,
    required this.backgroundAuxiliary,
    required this.backgroundAuxiliaryLight,
    required this.backgroundAuxiliaryLighter,
    required this.backgroundAuxiliaryLightest,
    required this.backgroundGallery,
    required this.onBackground,
    Color? onBackgroundOpacity2,
    Color? onBackgroundOpacity7,
    Color? onBackgroundOpacity13,
    Color? onBackgroundOpacity20,
    Color? onBackgroundOpacity27,
    Color? onBackgroundOpacity40,
    Color? onBackgroundOpacity50,
    Color? onBackgroundOpacity70,
    required this.transparent,
    required this.almostTransparent,
    required this.accept,
    required this.acceptAuxiliary,
    required this.acceptLight,
    required this.acceptLighter,
    required this.acceptLightest,
    required this.decline,
    Color? declineOpacity50,
    Color? declineOpacity88,
    required this.danger,
    required this.warning,
    required this.userColors,
  }) : primaryOpacity20 = primaryOpacity20 ?? primary.withValues(alpha: 0.20),
       primaryDarkOpacity70 =
           primaryDarkOpacity70 ?? primaryDark.withValues(alpha: 0.70),
       primaryDarkOpacity90 =
           primaryDarkOpacity90 ?? primaryDark.withValues(alpha: 0.90),
       primaryAuxiliaryOpacity25 =
           primaryAuxiliaryOpacity25 ??
           primaryAuxiliary.withValues(alpha: 0.25),
       primaryAuxiliaryOpacity90 =
           primaryAuxiliaryOpacity90 ??
           primaryAuxiliary.withValues(alpha: 0.90),
       primaryAuxiliaryOpacity95 =
           primaryAuxiliaryOpacity95 ??
           primaryAuxiliary.withValues(alpha: 0.95),
       onPrimaryOpacity7 =
           onPrimaryOpacity7 ?? onPrimary.withValues(alpha: 0.07),
       onPrimaryOpacity10 =
           onPrimaryOpacity10 ?? onPrimary.withValues(alpha: 0.10),
       onPrimaryOpacity25 =
           onPrimaryOpacity25 ?? onPrimary.withValues(alpha: 0.25),
       onPrimaryOpacity50 =
           onPrimaryOpacity50 ?? onPrimary.withValues(alpha: 0.50),
       onPrimaryOpacity95 =
           onPrimaryOpacity95 ?? onPrimary.withValues(alpha: 0.95),
       secondaryOpacity87 =
           secondaryOpacity87 ?? secondary.withValues(alpha: 0.87),
       secondaryOpacity40 =
           secondaryOpacity40 ?? secondary.withValues(alpha: 0.40),
       onSecondaryOpacity20 =
           onSecondaryOpacity20 ?? onSecondary.withValues(alpha: 0.20),
       onSecondaryOpacity50 =
           onSecondaryOpacity50 ?? onSecondary.withValues(alpha: 0.50),
       onSecondaryOpacity60 =
           onSecondaryOpacity60 ?? onSecondary.withValues(alpha: 0.60),
       onSecondaryOpacity88 =
           onSecondaryOpacity88 ?? onSecondary.withValues(alpha: 0.88),
       onBackgroundOpacity2 =
           onBackgroundOpacity2 ?? onBackground.withValues(alpha: 0.02),
       onBackgroundOpacity7 =
           onBackgroundOpacity7 ?? onBackground.withValues(alpha: 0.07),
       onBackgroundOpacity13 =
           onBackgroundOpacity13 ?? onBackground.withValues(alpha: 0.13),
       onBackgroundOpacity20 =
           onBackgroundOpacity20 ?? onBackground.withValues(alpha: 0.20),
       onBackgroundOpacity27 =
           onBackgroundOpacity27 ?? onBackground.withValues(alpha: 0.27),
       onBackgroundOpacity40 =
           onBackgroundOpacity40 ?? onBackground.withValues(alpha: 0.40),
       onBackgroundOpacity50 =
           onBackgroundOpacity50 ?? onBackground.withValues(alpha: 0.50),
       onBackgroundOpacity70 =
           onBackgroundOpacity70 ?? onBackground.withValues(alpha: 0.70),
       declineOpacity50 = declineOpacity50 ?? decline.withValues(alpha: 0.50),
       declineOpacity88 = declineOpacity88 ?? decline.withValues(alpha: 0.88);

  /// Primary [Color] of the application.
  ///
  /// Used to highlight the active interface elements.
  final Color primary;

  /// 20% opacity of the [primary] color.
  ///
  /// Used to highlight chat messages.
  final Color primaryOpacity20;

  /// Highlight [Color] of the [primary] elements.
  ///
  /// Used to highlight [primary] elements when hovering or activated.
  final Color primaryHighlight;

  /// Highlight [Color] to draw attention to specific [primary] elements.
  ///
  /// Used as a border of the selected [ChatTile]s and [ContactTile]s.
  final Color primaryHighlightShiny;

  /// The shiniest and most contrasting [primary] highlight [Color].
  ///
  /// Used to highlight read [ChatMessage]s and [ChatForward]s.
  final Color primaryHighlightShiniest;

  /// Lightest [primary] highlight [Color].
  ///
  /// Used as a border of [ChatMessage]s and [ChatForward]s.
  final Color primaryHighlightLightest;

  /// Light [primary] highlight [Color].
  ///
  /// Used as a read [ChatMessage] color.
  final Color primaryLight;

  /// Lightest [primary].
  ///
  /// Used as an unread [ChatMessage] color.
  final Color primaryLightest;

  /// Dark [Color] of the [primary] elements.
  ///
  /// Used to darken the [primary] elements when hovering or activated.
  final Color primaryDark;

  /// 70% opacity of the [primaryDark] color.
  ///
  /// Used for `Draggable` panel elements.
  final Color primaryDarkOpacity70;

  /// 90% opacity of the [primaryDark] color.
  ///
  /// Used for [Launchpad] background color.
  final Color primaryDarkOpacity90;

  /// [Color] responsible for the helper primary color.
  ///
  /// Used for alternative primary in case we need to darken.
  final Color primaryAuxiliary;

  /// 25% opacity of the [primaryAuxiliary] color.
  ///
  /// Used as [DockDecorator] color.
  final Color primaryAuxiliaryOpacity25;

  /// 90% opacity of the [primaryAuxiliary] color.
  final Color primaryAuxiliaryOpacity90;

  /// 95% opacity of the [primaryAuxiliary] color.
  final Color primaryAuxiliaryOpacity95;

  /// [Color] for elements to put above the [primary] color.
  ///
  /// Used for texts on [primary] buttons and icons.
  final Color onPrimary;

  /// 95% opacity of the [onPrimary] color.
  ///
  /// Used as a card colors.
  final Color onPrimaryOpacity95;

  /// 50% opacity of the [onPrimary] color.
  ///
  /// Used as a border to highlight the answer call button.
  final Color onPrimaryOpacity50;

  /// 25% opacity of the [onPrimary] color.
  ///
  /// Used as a replied message background in [ChatItemWidget].
  final Color onPrimaryOpacity25;

  /// 7% opacity of the [onPrimary] color.
  ///
  /// Used to highlight some [DragTarget]s and backgrounds.
  final Color onPrimaryOpacity7;

  /// 10% opacity of the [onPrimary] color.
  final Color onPrimaryOpacity10;

  /// Lighter version of [onPrimary] for elements to put above the [primary].
  final Color onPrimaryLight;

  /// Secondary [Color] used alongside with [primary].
  ///
  /// Used for texts, icons, outlines.
  final Color secondary;

  /// 87% opacity of the [secondary] color.
  ///
  /// Used as the muted indicator background in calls.
  final Color secondaryOpacity87;

  /// 40% opacity of the [secondary] color.
  ///
  /// Used as the muted indicator background in calls.
  final Color secondaryOpacity40;

  /// Lighter variation of the [secondary] color.
  final Color secondaryLight;

  /// Background [Color] of the [secondary] elements.
  ///
  /// Used for buttons background, pop-ups, dialog boxes.
  final Color secondaryBackground;

  /// Light shade of the [secondaryBackground] color.
  final Color secondaryBackgroundLight;

  /// Lightest shade of the [secondaryBackground].
  final Color secondaryBackgroundLightest;

  /// [Color] highlighting the active [secondary] elements.
  final Color secondaryHighlight;

  /// Dark shade of the [secondaryHighlight].
  ///
  /// Used to create contrast and depth effect.
  final Color secondaryHighlightDark;

  /// Darkest shade of the [secondaryHighlight].
  ///
  /// Used to emphasize buttons, labels, or other user interface elements.
  final Color secondaryHighlightDarkest;

  /// [Color] for elements to put above the [secondary] color.
  final Color onSecondary;

  /// 88% opacity of the [onSecondary] color.
  ///
  /// Used as a hovered mobile call panel and desktop call launchpad background.
  final Color onSecondaryOpacity88;

  /// 60% opacity of the [onSecondary] color.
  ///
  /// Used as a mobile call panel and desktop call launchpad background.
  final Color onSecondaryOpacity60;

  /// 50% opacity of the [onSecondary] color.
  ///
  /// Used for [CallButton]s buttons.
  final Color onSecondaryOpacity50;

  /// 20% opacity of the [onSecondary] color.
  ///
  /// Used as a [Dock] color.
  final Color onSecondaryOpacity20;

  /// Background [Color] of the application.
  final Color background;

  /// [Color] responsible for the helper background color.
  ///
  /// Used for alternative background in case we need to highlight
  /// some interface element using a background color other than the main one.
  final Color backgroundAuxiliary;

  /// Slightly lighter [Color] than the standard [backgroundAuxiliary] color.
  ///
  /// Used in a secondary call panel.
  final Color backgroundAuxiliaryLight;

  /// [Color] represents an even lighter shade than the standard
  /// [backgroundAuxiliary] color.
  final Color backgroundAuxiliaryLighter;

  /// Lightest possible shade of the [Color] for the [backgroundAuxiliary]
  /// color.
  final Color backgroundAuxiliaryLightest;

  /// [PlayerView] background color.
  final Color backgroundGallery;

  /// [Color] for elements to put above the [background] color.
  final Color onBackground;

  /// 70% opacity of the [onBackground] color.
  ///
  /// Used to darken inactive interface elements.
  final Color onBackgroundOpacity70;

  /// 50% opacity of the [onBackground] color.
  ///
  /// Used as a play video circle button background.
  final Color onBackgroundOpacity50;

  /// 40% opacity of the [onBackground] color.
  ///
  /// Used as a video player controls background.
  final Color onBackgroundOpacity40;

  /// 27% opacity of the [onBackground] color.
  ///
  /// Used as a shadow [Color] in some elements.
  final Color onBackgroundOpacity27;

  /// 20% opacity of the [onBackground] color.
  ///
  /// Used as a shadow and border [Color] in some elements, elevation of
  /// [ChatTile]s and [ContactTile]s.
  final Color onBackgroundOpacity20;

  /// 13% opacity of the [onBackground] color.
  ///
  /// Used as a shadow [Color] in some elements.
  final Color onBackgroundOpacity13;

  /// 7% opacity of the [onBackground] color.
  ///
  /// Used as a divider color in [ContextMenu].
  final Color onBackgroundOpacity7;

  /// 2% opacity of the [onBackground] color.
  ///
  /// Used as a shadow in [RetryImage]s and [ContextMenu]s, background of a
  /// replied message.
  final Color onBackgroundOpacity2;

  /// Completely transparent [Color] that has no visible saturation or
  /// brightness.
  final Color transparent;

  /// Almost transparent [Color].
  final Color almostTransparent;

  /// Indicator of an affirmative color of confirmable elements.
  final Color accept;

  /// [Color] displaying pleasant action confirmation messages.
  final Color acceptAuxiliary;

  /// Light variant of the [accept] color.
  final Color acceptLight;

  /// Lighter variant of the [accept] color.
  final Color acceptLighter;

  /// Lightest variant of the [accept] color.
  final Color acceptLightest;

  /// Indicator of rejection or cancellation in various elements of the user
  /// interface.
  final Color decline;

  /// 88% opacity of the [decline] color.
  ///
  /// Used in decline call button.
  final Color declineOpacity88;

  /// 50% opacity of the [decline] color.
  ///
  /// Used in decline call button.
  final Color declineOpacity50;

  /// [Color] used to indicate dangerous or critical elements in the user
  /// interface.
  final Color danger;

  /// [Color] used to indicate caution, risk, or a potential threat.
  final Color warning;

  /// [Color]s associated with the [User].
  ///
  /// Used for [AvatarWidget]s and [UserName]s.
  final List<Color> userColors;

  /// Linear interpolation between two [Palette] objects based on a given [t]
  /// value.
  static Palette lerp(Palette color, Palette? other, double t) {
    if (other is! Palette) {
      return color;
    }

    return Palette(
      primary: Color.lerp(color.primary, other.primary, t)!,
      primaryAuxiliary: Color.lerp(
        color.primaryAuxiliary,
        other.primaryAuxiliary,
        t,
      )!,
      primaryAuxiliaryOpacity25: Color.lerp(
        color.primaryAuxiliaryOpacity25,
        other.primaryAuxiliaryOpacity25,
        t,
      )!,
      primaryHighlight: Color.lerp(
        color.primaryHighlight,
        other.primaryHighlight,
        t,
      )!,
      primaryHighlightShiny: Color.lerp(
        color.primaryHighlightShiny,
        other.primaryHighlightShiny,
        t,
      )!,
      primaryHighlightShiniest: Color.lerp(
        color.primaryHighlightShiniest,
        other.primaryHighlightShiniest,
        t,
      )!,
      primaryHighlightLightest: Color.lerp(
        color.primaryHighlightLightest,
        other.primaryHighlightLightest,
        t,
      )!,
      primaryLight: Color.lerp(color.primaryLight, other.primaryLight, t)!,
      primaryLightest: Color.lerp(
        color.primaryLightest,
        other.primaryLightest,
        t,
      )!,
      primaryDark: Color.lerp(color.primaryDark, other.primaryDark, t)!,
      primaryDarkOpacity70: Color.lerp(
        color.primaryDarkOpacity70,
        other.primaryDarkOpacity70,
        t,
      )!,
      primaryDarkOpacity90: Color.lerp(
        color.primaryDarkOpacity90,
        other.primaryDarkOpacity90,
        t,
      )!,
      onPrimary: Color.lerp(color.onPrimary, other.onPrimary, t)!,
      onPrimaryOpacity7: Color.lerp(
        color.onPrimaryOpacity7,
        other.onPrimaryOpacity7,
        t,
      )!,
      onPrimaryOpacity10: Color.lerp(
        color.onPrimaryOpacity10,
        other.onPrimaryOpacity10,
        t,
      )!,
      onPrimaryOpacity25: Color.lerp(
        color.onPrimaryOpacity25,
        other.onPrimaryOpacity25,
        t,
      )!,
      onPrimaryOpacity50: Color.lerp(
        color.onPrimaryOpacity50,
        other.onPrimaryOpacity50,
        t,
      )!,
      onPrimaryOpacity95: Color.lerp(
        color.onPrimaryOpacity95,
        other.onPrimaryOpacity95,
        t,
      )!,
      onPrimaryLight: Color.lerp(
        color.onPrimaryLight,
        other.onPrimaryLight,
        t,
      )!,
      secondary: Color.lerp(color.secondary, other.secondary, t)!,
      secondaryLight: Color.lerp(
        color.secondaryLight,
        other.secondaryLight,
        t,
      )!,
      secondaryOpacity87: Color.lerp(
        color.secondaryOpacity87,
        other.secondaryOpacity87,
        t,
      )!,
      secondaryHighlight: Color.lerp(
        color.secondaryHighlight,
        other.secondaryHighlight,
        t,
      )!,
      secondaryHighlightDark: Color.lerp(
        color.secondaryHighlightDark,
        other.secondaryHighlightDark,
        t,
      )!,
      secondaryHighlightDarkest: Color.lerp(
        color.secondaryHighlightDarkest,
        other.secondaryHighlightDarkest,
        t,
      )!,
      secondaryBackground: Color.lerp(
        color.secondaryBackground,
        other.secondaryBackground,
        t,
      )!,
      secondaryBackgroundLight: Color.lerp(
        color.secondaryBackgroundLight,
        other.secondaryBackgroundLight,
        t,
      )!,
      secondaryBackgroundLightest: Color.lerp(
        color.secondaryBackgroundLightest,
        other.secondaryBackgroundLightest,
        t,
      )!,
      onSecondary: Color.lerp(color.onSecondary, other.onSecondary, t)!,
      onSecondaryOpacity20: Color.lerp(
        color.onSecondaryOpacity20,
        other.onSecondaryOpacity20,
        t,
      )!,
      onSecondaryOpacity50: Color.lerp(
        color.onSecondaryOpacity50,
        other.onSecondaryOpacity50,
        t,
      )!,
      onSecondaryOpacity60: Color.lerp(
        color.onSecondaryOpacity60,
        other.onSecondaryOpacity60,
        t,
      )!,
      onSecondaryOpacity88: Color.lerp(
        color.onSecondaryOpacity88,
        other.onSecondaryOpacity88,
        t,
      )!,
      background: Color.lerp(color.background, other.background, t)!,
      backgroundAuxiliary: Color.lerp(
        color.backgroundAuxiliary,
        other.backgroundAuxiliary,
        t,
      )!,
      backgroundAuxiliaryLight: Color.lerp(
        color.backgroundAuxiliaryLight,
        other.backgroundAuxiliaryLight,
        t,
      )!,
      backgroundAuxiliaryLighter: Color.lerp(
        color.backgroundAuxiliaryLighter,
        other.backgroundAuxiliaryLighter,
        t,
      )!,
      backgroundAuxiliaryLightest: Color.lerp(
        color.backgroundAuxiliaryLightest,
        other.backgroundAuxiliaryLightest,
        t,
      )!,
      backgroundGallery: Color.lerp(
        color.backgroundGallery,
        other.backgroundGallery,
        t,
      )!,
      onBackground: Color.lerp(color.onBackground, other.onBackground, t)!,
      onBackgroundOpacity2: Color.lerp(
        color.onBackgroundOpacity2,
        other.onBackgroundOpacity2,
        t,
      )!,
      onBackgroundOpacity7: Color.lerp(
        color.onBackgroundOpacity7,
        other.onBackgroundOpacity7,
        t,
      )!,
      onBackgroundOpacity13: Color.lerp(
        color.onBackgroundOpacity13,
        other.onBackgroundOpacity13,
        t,
      )!,
      onBackgroundOpacity20: Color.lerp(
        color.onBackgroundOpacity20,
        other.onBackgroundOpacity20,
        t,
      )!,
      onBackgroundOpacity27: Color.lerp(
        color.onBackgroundOpacity27,
        other.onBackgroundOpacity27,
        t,
      )!,
      onBackgroundOpacity40: Color.lerp(
        color.onBackgroundOpacity40,
        other.onBackgroundOpacity40,
        t,
      )!,
      onBackgroundOpacity50: Color.lerp(
        color.onBackgroundOpacity50,
        other.onBackgroundOpacity50,
        t,
      )!,
      transparent: Color.lerp(color.transparent, other.transparent, t)!,
      almostTransparent: Color.lerp(
        color.almostTransparent,
        other.almostTransparent,
        t,
      )!,
      accept: Color.lerp(color.accept, other.accept, t)!,
      acceptAuxiliary: Color.lerp(
        color.acceptAuxiliary,
        other.acceptAuxiliary,
        t,
      )!,
      acceptLight: Color.lerp(color.acceptLight, other.acceptLight, t)!,
      acceptLighter: Color.lerp(color.acceptLighter, other.acceptLighter, t)!,
      acceptLightest: Color.lerp(
        color.acceptLightest,
        other.acceptLightest,
        t,
      )!,
      decline: Color.lerp(color.decline, other.decline, t)!,
      declineOpacity50: Color.lerp(
        color.declineOpacity50,
        other.declineOpacity50,
        t,
      )!,
      declineOpacity88: Color.lerp(
        color.declineOpacity88,
        other.declineOpacity88,
        t,
      )!,
      danger: Color.lerp(color.danger, other.danger, t)!,
      warning: Color.lerp(color.warning, other.warning, t)!,
      userColors: other.userColors.isNotEmpty
          ? other.userColors
          : color.userColors,
    );
  }
}

/// Extension adding [Style] handy getter from the [ThemeData].
extension ThemeStylesExtension on ThemeData {
  /// Returns the [Style] of this [ThemeData].
  Style get style => extension<Style>()!;
}

/// Adds the ability to get HEX value of the color.
extension HexColor on Color {
  /// Returns a HEX string value of this color.
  String toHex({bool withAlpha = true}) =>
      '#'
      '${(withAlpha ? (a * 255).round().toRadixString(16).toUpperCase().padLeft(2, '0') : '')}'
      '${(r * 255).round().toRadixString(16).toUpperCase().padLeft(2, '0')}'
      '${(g * 255).round().toRadixString(16).toUpperCase().padLeft(2, '0')}'
      '${(b * 255).round().toRadixString(16).toUpperCase().padLeft(2, '0')}';
}

// TODO: Remove, when flutter/flutter#132839 is fixed:
//       https://github.com/flutter/flutter/issues/132839
/// Extension adding workaround of [BlurStyle.outer] rendered incorrectly on
/// iOS.
extension BlurStylePlatformExtension on BlurStyle {
  /// Returns the [BlurStyle.outer], if not [PlatformUtilsImpl.isIOS], or
  /// [BlurStyle.normal] otherwise.
  BlurStyle get workaround {
    if (PlatformUtils.isIOS) {
      return BlurStyle.normal;
    }

    return BlurStyle.outer;
  }
}
