// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

/// Application themes constants.
class Themes {
  /// Returns a light theme.
  static ThemeData light() {
    final Palette colors = Palette(
      primary: const Color(0xFF63B4FF),
      primaryHighlight: const Color(0xFF2196F3),
      primaryHighlightShiny: const Color(0xFF58A6EF),
      primaryHighlightShiniest: const Color(0xFFD2E3F9),
      primaryHighlightLightest: const Color(0xFFB9D9FA),
      onPrimary: const Color(0xFFFFFFFF),
      secondary: const Color(0xFF888888),
      secondaryHighlight: const Color(0xFFEFEFEF),
      secondaryHighlightDark: const Color(0xFFDEDEDE),
      secondaryHighlightDarkest: const Color(0xFFC4C4C4),
      secondaryBackground: const Color(0xFF222222),
      secondaryBackgroundLight: const Color(0xFF444444),
      secondaryBackgroundLightest: const Color(0xFF666666),
      onSecondary: const Color(0xFF4E5A78),
      background: const Color(0xFFF5F8FA),
      backgroundAuxiliary: const Color(0xFF0A1724),
      backgroundAuxiliaryLight: const Color(0xFF132131),
      backgroundAuxiliaryLighter: const Color(0xFFE6F1FE),
      backgroundAuxiliaryLightest: const Color(0xFFF4F9FF),
      onBackground: const Color(0xFF000000),
      transparent: const Color(0x00000000),
      acceptColor: const Color(0x7F34B139),
      acceptAuxiliaryColor: const Color(0xFF4CAF50),
      declineColor: const Color(0x7FFF0000),
      dangerColor: const Color(0xFFF44336),
      warningColor: const Color(0xFFFF9800),
      userColors: [
        const Color(0xFF9C27B0),
        const Color(0xFF673AB7),
        const Color(0xFF3F51B5),
        const Color(0xFF2196F3),
        const Color(0xFF00BCD4),
        const Color(0xFF8BC34A),
        const Color(0xFFCDDC39),
        const Color(0xFFFFC107),
        const Color(0xFFFF9800),
        const Color(0xFFFF5722),
      ],
    );

    final TextStyle textStyle = TextStyle(
      fontFamily: 'SFUI',
      fontFamilyFallback: const ['.SF UI Display'],
      color: colors.onBackground,
      fontSize: 17,
      fontWeight: FontWeight.w400,
    );

    final Fonts fonts = Fonts(
      primary: colors.primary,
      secondary: colors.secondary,
      onPrimary: colors.onPrimary,
      danger: colors.dangerColor,
      displayLarge:
          textStyle.copyWith(fontSize: 27, fontWeight: FontWeight.bold),
      displayMedium:
          textStyle.copyWith(fontWeight: FontWeight.w300, fontSize: 24),
      displaySmall:
          textStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 11),
      headlineLarge: textStyle.copyWith(fontSize: 18),
      headlineMedium:
          textStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w300),
      headlineSmall: textStyle.copyWith(fontSize: 13),
      titleLarge: textStyle.copyWith(fontWeight: FontWeight.w300),
      titleMedium: textStyle.copyWith(fontSize: 15),
      titleSmall: textStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
      labelLarge: textStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w300),
      labelMedium:
          textStyle.copyWith(fontSize: 13, fontWeight: FontWeight.w300),
      labelSmall: textStyle.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w300,
        letterSpacing: 0.4,
      ),
      bodyLarge: textStyle,
      bodyMedium: textStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w300),
      bodySmall: textStyle.copyWith(fontSize: 13, fontWeight: FontWeight.w300),
      error: textStyle.copyWith(fontSize: 13, color: colors.dangerColor),
      input: textStyle.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w300,
        color: colors.secondaryHighlightDarkest,
      ),
      counter: textStyle.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w300,
        color: colors.secondaryHighlightDarkest,
      ),
    );

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: colors.primaryHighlight,
        statusBarColor: colors.transparent,
        statusBarBrightness: Brightness.light,
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
            cardBorder:
                Border.all(color: colors.secondaryHighlightDark, width: 0.5),
            cardColor: colors.onPrimaryOpacity95,
            cardHoveredBorder: Border.all(
              color: colors.primaryHighlightShiniest,
              width: 0.5,
            ),
            cardRadius: BorderRadius.circular(14),
            cardSelectedBorder:
                Border.all(color: colors.primaryHighlightShiny, width: 0.5),
            contextMenuBackgroundColor: colors.secondaryHighlight,
            contextMenuHoveredColor: colors.backgroundAuxiliaryLightest,
            contextMenuRadius: BorderRadius.circular(10),
            linkStyle: textStyle.copyWith(
              color: colors.primary,
              decoration: TextDecoration.underline,
              decorationThickness: 2,
            ),
            messageColor: colors.onPrimary,
            primaryBorder: Border.all(
              color: colors.secondaryHighlightDark,
              width: 0.5,
            ),
            readMessageColor: colors.primaryHighlightShiniest,
            secondaryBorder: Border.all(
              color: colors.primaryHighlightLightest,
              width: 0.5,
            ),
            sidebarColor: colors.onPrimaryOpacity50,
            systemMessageBorder: Border.all(
              color: colors.secondaryHighlightDarkest,
              width: 0.5,
            ),
            systemMessageColor: colors.secondaryHighlight,
            systemMessageStyle: fonts.bodySmallSecondary,
            systemMessagePrimary: fonts.bodySmallPrimary,
            unreadMessageColor: colors.backgroundAuxiliaryLightest,
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
          titleTextStyle: fonts.headlineMedium,
        ),
        tabBarTheme: theme.tabBarTheme.copyWith(
          labelColor: colors.primary,
          unselectedLabelColor: colors.secondary,
        ),
        primaryIconTheme: const IconThemeData.fallback().copyWith(
          color: colors.secondary,
        ),
        iconTheme: theme.iconTheme.copyWith(color: colors.onBackground),
        textTheme: Typography.blackCupertino.copyWith(
          displayLarge: fonts.displayLarge,
          displayMedium: fonts.displayMedium,
          displaySmall: fonts.displaySmall,
          headlineLarge: fonts.headlineLarge,
          headlineMedium: fonts.headlineMedium,
          headlineSmall: fonts.headlineSmall,
          titleLarge: fonts.titleLarge,
          titleMedium: fonts.titleMedium,
          titleSmall: fonts.titleSmall,
          labelLarge: fonts.labelLarge,
          labelMedium: fonts.displayLarge,
          labelSmall: fonts.labelSmall,
          bodyLarge: fonts.bodyLarge,
          bodyMedium: fonts.bodyMedium,
          bodySmall: fonts.bodySmall,
        ),
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          focusColor: colors.primary,
          hoverColor: colors.transparent,
          fillColor: colors.primary,
          hintStyle: fonts.input,
          labelStyle: fonts.input,
          errorStyle: fonts.error,
          helperStyle: fonts.input,
          prefixStyle: fonts.input,
          suffixStyle: fonts.input,
          counterStyle: fonts.counter,
          floatingLabelStyle: fonts.input,
          errorMaxLines: 5,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: colors.primary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(
              color: colors.secondaryHighlightDarkest,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(
              color: colors.secondaryHighlightDarkest,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(
              color: colors.secondaryHighlightDarkest,
            ),
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
            textStyle: fonts.bodyLargeSecondary,
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
            textStyle: fonts.bodyLargeSecondary,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.all(12),
            textStyle: fonts.titleMediumSecondary,
          ),
        ),
        scrollbarTheme: theme.scrollbarTheme.copyWith(
          interactive: true,
          thickness: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.dragged) ||
                states.contains(MaterialState.hovered)) {
              return 6;
            }

            return 4;
          }),
        ),
        radioTheme: theme.radioTheme.copyWith(
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }

            return colors.primary;
          }),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
          },
        ));
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
    Color color = const Color(0xFF000000),
    Offset offset = Offset.zero,
    double blurRadius = 0.0,
    BlurStyle blurStyle = BlurStyle.normal,
  })  : _blurStyle = blurStyle,
        super(
          color: color,
          offset: offset,
          blurRadius: blurRadius,
        );

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
      cardHoveredBorder:
          Border.lerp(cardHoveredBorder, other.cardHoveredBorder, t)!,
      cardRadius: BorderRadius.lerp(cardRadius, other.cardRadius, t)!,
      cardSelectedBorder:
          Border.lerp(cardSelectedBorder, other.cardSelectedBorder, t)!,
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
      contextMenuRadius:
          BorderRadius.lerp(contextMenuRadius, other.contextMenuRadius, t)!,
      linkStyle: TextStyle.lerp(linkStyle, other.linkStyle, t)!,
      messageColor: Color.lerp(messageColor, other.messageColor, t)!,
      primaryBorder: Border.lerp(primaryBorder, other.primaryBorder, t)!,
      readMessageColor:
          Color.lerp(readMessageColor, other.readMessageColor, t)!,
      secondaryBorder: Border.lerp(secondaryBorder, other.secondaryBorder, t)!,
      sidebarColor: Color.lerp(sidebarColor, other.sidebarColor, t)!,
      systemMessageBorder:
          Border.lerp(systemMessageBorder, other.systemMessageBorder, t)!,
      systemMessageColor:
          Color.lerp(systemMessageColor, other.systemMessageColor, t)!,
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
      unreadMessageColor:
          Color.lerp(unreadMessageColor, other.unreadMessageColor, t)!,
    );
  }
}

/// [TextStyle]s used throughout the application.
class Fonts {
  Fonts({
    Color? primary,
    Color? secondary,
    Color? onPrimary,
    Color? danger,
    required this.displayLarge,
    TextStyle? displayLargeOnPrimary,
    required this.displayMedium,
    TextStyle? displayMediumSecondary,
    required this.displaySmall,
    TextStyle? displaySmallSecondary,
    TextStyle? displaySmallOnPrimary,
    required this.headlineLarge,
    TextStyle? headlineLargeOnPrimary,
    required this.headlineMedium,
    TextStyle? headlineMediumOnPrimary,
    required this.headlineSmall,
    TextStyle? headlineSmallSecondary,
    TextStyle? headlineSmallOnPrimary,
    required this.titleLarge,
    TextStyle? titleLargeSecondary,
    TextStyle? titleLargeOnPrimary,
    required this.titleMedium,
    TextStyle? titleMediumPrimary,
    TextStyle? titleMediumSecondary,
    TextStyle? titleMediumOnPrimary,
    TextStyle? titleMediumDanger,
    required this.titleSmall,
    TextStyle? titleSmallOnPrimary,
    required this.labelLarge,
    TextStyle? labelLargePrimary,
    TextStyle? labelLargeSecondary,
    TextStyle? labelLargeOnPrimary,
    required this.labelMedium,
    TextStyle? labelMediumPrimary,
    TextStyle? labelMediumSecondary,
    TextStyle? labelMediumOnPrimary,
    required this.labelSmall,
    TextStyle? labelSmallPrimary,
    TextStyle? labelSmallSecondary,
    TextStyle? labelSmallOnPrimary,
    required this.bodyLarge,
    TextStyle? bodyLargePrimary,
    TextStyle? bodyLargeSecondary,
    required this.bodyMedium,
    TextStyle? bodyMediumPrimary,
    TextStyle? bodyMediumSecondary,
    TextStyle? bodyMediumOnPrimary,
    required this.bodySmall,
    TextStyle? bodySmallPrimary,
    TextStyle? bodySmallSecondary,
    TextStyle? bodySmallOnPrimary,
    required this.input,
    required this.error,
    required this.counter,
  })  : displayLargeOnPrimary =
            displayLargeOnPrimary ?? displayLarge.copyWith(color: onPrimary),
        displayMediumSecondary =
            displayMediumSecondary ?? displayMedium.copyWith(color: secondary),
        displaySmallSecondary =
            displaySmallSecondary ?? displaySmall.copyWith(color: secondary),
        displaySmallOnPrimary =
            displaySmallOnPrimary ?? displaySmall.copyWith(color: onPrimary),
        headlineLargeOnPrimary =
            headlineLargeOnPrimary ?? headlineLarge.copyWith(color: onPrimary),
        headlineMediumOnPrimary = headlineMediumOnPrimary ??
            headlineMedium.copyWith(color: onPrimary),
        headlineSmallSecondary =
            headlineSmallSecondary ?? headlineSmall.copyWith(color: secondary),
        headlineSmallOnPrimary =
            headlineSmallOnPrimary ?? headlineSmall.copyWith(color: onPrimary),
        titleLargeSecondary =
            titleLargeSecondary ?? titleLarge.copyWith(color: secondary),
        titleLargeOnPrimary =
            titleLargeOnPrimary ?? titleLarge.copyWith(color: onPrimary),
        titleMediumPrimary =
            titleMediumPrimary ?? titleMedium.copyWith(color: primary),
        titleMediumSecondary =
            titleMediumSecondary ?? titleMedium.copyWith(color: secondary),
        titleMediumOnPrimary =
            titleMediumOnPrimary ?? titleMedium.copyWith(color: onPrimary),
        titleMediumDanger =
            titleMediumDanger ?? titleMedium.copyWith(color: danger),
        titleSmallOnPrimary =
            titleSmallOnPrimary ?? titleSmall.copyWith(color: onPrimary),
        labelLargePrimary =
            labelLargePrimary ?? labelLarge.copyWith(color: primary),
        labelLargeSecondary =
            labelLargeSecondary ?? labelLarge.copyWith(color: secondary),
        labelLargeOnPrimary =
            labelLargeOnPrimary ?? labelLarge.copyWith(color: onPrimary),
        labelMediumPrimary =
            labelMediumPrimary ?? labelMedium.copyWith(color: primary),
        labelMediumSecondary =
            labelMediumSecondary ?? labelMedium.copyWith(color: secondary),
        labelMediumOnPrimary =
            labelMediumOnPrimary ?? labelMedium.copyWith(color: onPrimary),
        labelSmallPrimary =
            labelSmallPrimary ?? labelSmall.copyWith(color: primary),
        labelSmallSecondary =
            labelSmallSecondary ?? labelSmall.copyWith(color: secondary),
        labelSmallOnPrimary =
            labelSmallOnPrimary ?? labelSmall.copyWith(color: onPrimary),
        bodyLargePrimary =
            bodyLargePrimary ?? bodyLarge.copyWith(color: primary),
        bodyLargeSecondary =
            bodyLargeSecondary ?? bodyLarge.copyWith(color: secondary),
        bodyMediumPrimary =
            bodyMediumPrimary ?? bodyMedium.copyWith(color: primary),
        bodyMediumSecondary =
            bodyMediumSecondary ?? bodyMedium.copyWith(color: secondary),
        bodyMediumOnPrimary =
            bodyMediumOnPrimary ?? bodyMedium.copyWith(color: onPrimary),
        bodySmallPrimary =
            bodySmallPrimary ?? bodySmall.copyWith(color: primary),
        bodySmallSecondary =
            bodySmallSecondary ?? bodySmall.copyWith(color: secondary),
        bodySmallOnPrimary =
            bodySmallOnPrimary ?? bodySmall.copyWith(color: onPrimary);

  /// Large version of display text of `onBackground` color.
  final TextStyle displayLarge;

  /// [displayLarge] of `onPrimary` color.
  final TextStyle displayLargeOnPrimary;

  /// Medium version of display text of `onBackground` color.
  final TextStyle displayMedium;

  /// [displayMedium] with `secondary` color.
  final TextStyle displayMediumSecondary;

  /// Small version of display text of `onBackground` color.
  final TextStyle displaySmall;

  /// [displaySmall] with `secondary` color.
  final TextStyle displaySmallSecondary;

  /// [displaySmall] with `onPrimary` color.
  final TextStyle displaySmallOnPrimary;

  /// Large version of headline text of `onBackground` color.
  final TextStyle headlineLarge;

  /// [headlineLarge] of `onPrimary` color.
  final TextStyle headlineLargeOnPrimary;

  /// Medium version of headline text of `onBackground` color.
  final TextStyle headlineMedium;

  /// [headlineMedium] of `onPrimary` color.
  final TextStyle headlineMediumOnPrimary;

  /// Small version of headline text of `onBackground` color.
  final TextStyle headlineSmall;

  /// [headlineSmall] of `secondary` color.
  final TextStyle headlineSmallSecondary;

  /// [headlineSmall] of `onPrimary` color.
  final TextStyle headlineSmallOnPrimary;

  /// Large version of title text of `onBackground` color.
  final TextStyle titleLarge;

  /// [titleLarge] of `secondary` color.
  final TextStyle titleLargeSecondary;

  /// [titleLarge] of `onPrimary` color.
  final TextStyle titleLargeOnPrimary;

  /// Medium version of title text with `onBackground` color.
  final TextStyle titleMedium;

  /// [titleMedium] of `primary` color.
  final TextStyle titleMediumPrimary;

  /// [titleMedium] of `secondary` color.
  final TextStyle titleMediumSecondary;

  /// [titleMedium] of `onPrimary` color.
  final TextStyle titleMediumOnPrimary;

  /// [titleMedium] of `danger` color.
  final TextStyle titleMediumDanger;

  /// Small version of title text of `onBackground` color.
  final TextStyle titleSmall;

  /// [titleSmall] with `onPrimary` color.
  final TextStyle titleSmallOnPrimary;

  /// Large version of label text of `onBackground` color.
  final TextStyle labelLarge;

  /// [labelLarge] of `primary` color.
  final TextStyle labelLargePrimary;

  /// [labelLarge] of `secondary` color.
  final TextStyle labelLargeSecondary;

  /// [labelLarge] of `onPrimary` color.
  final TextStyle labelLargeOnPrimary;

  /// Medium version of label text of `onBackground` color.
  final TextStyle labelMedium;

  /// [labelMedium] of `primary` color.
  final TextStyle labelMediumPrimary;

  /// [labelMedium] of `secondary` color.
  final TextStyle labelMediumSecondary;

  /// [labelMedium] of `onPrimary` color.
  final TextStyle labelMediumOnPrimary;

  /// Small version of label text of `onBackground` color.
  final TextStyle labelSmall;

  /// [labelSmall] of `primary` color.
  final TextStyle labelSmallPrimary;

  /// [labelSmall] of `secondary` color.
  final TextStyle labelSmallSecondary;

  /// [labelSmall] of `onPrimary` color.
  final TextStyle labelSmallOnPrimary;

  /// Large version of body text of `onBackground` color.
  final TextStyle bodyLarge;

  /// [bodyLarge] of `primary` color.
  final TextStyle bodyLargePrimary;

  /// [bodyLarge] of `secondary` color.
  final TextStyle bodyLargeSecondary;

  /// Medium version of body text of `onBackground` color.
  final TextStyle bodyMedium;

  /// [bodyMedium] of `primary` color.
  final TextStyle bodyMediumPrimary;

  /// [bodyMedium] of `secondary` color.
  final TextStyle bodyMediumSecondary;

  /// [bodyMedium] of `onPrimary` color.
  final TextStyle bodyMediumOnPrimary;

  /// Small version of body text of `onBackground` color.
  final TextStyle bodySmall;

  /// [bodySmall] of `primary` color.
  final TextStyle bodySmallPrimary;

  /// [bodySmall] of `secondary` color.
  final TextStyle bodySmallSecondary;

  /// [bodySmall] of `onPrimary` color.
  final TextStyle bodySmallOnPrimary;

  /// [TextStyle] for the decoration text in an input field.
  final TextStyle input;

  /// [TextStyle] of an error.
  final TextStyle error;

  /// [TextStyle] of a small counter text.
  final TextStyle counter;

  /// Linear interpolation between two [Fonts] objects based on a given [t]
  /// value.
  static Fonts lerp(Fonts font, Fonts? other, double t) {
    if (other == null) {
      return font;
    }

    return Fonts(
      displayLarge: TextStyle.lerp(font.displayLarge, other.displayLarge, t)!,
      displayLargeOnPrimary: TextStyle.lerp(
          font.displayLargeOnPrimary, other.displayLargeOnPrimary, t)!,
      displayMedium:
          TextStyle.lerp(font.displayMedium, other.displayMedium, t)!,
      displayMediumSecondary: TextStyle.lerp(
          font.displayMediumSecondary, other.displayMediumSecondary, t)!,
      displaySmall: TextStyle.lerp(font.displaySmall, other.displaySmall, t)!,
      displaySmallSecondary: TextStyle.lerp(
          font.displaySmallSecondary, other.displaySmallSecondary, t)!,
      displaySmallOnPrimary: TextStyle.lerp(
          font.displaySmallOnPrimary, other.displaySmallOnPrimary, t)!,
      headlineLarge:
          TextStyle.lerp(font.headlineLarge, other.headlineLarge, t)!,
      headlineLargeOnPrimary: TextStyle.lerp(
          font.headlineLargeOnPrimary, other.headlineLargeOnPrimary, t)!,
      headlineMedium:
          TextStyle.lerp(font.headlineMedium, other.headlineMedium, t)!,
      headlineMediumOnPrimary: TextStyle.lerp(
          font.headlineMediumOnPrimary, other.headlineMediumOnPrimary, t)!,
      headlineSmall:
          TextStyle.lerp(font.headlineSmall, other.headlineSmall, t)!,
      headlineSmallSecondary: TextStyle.lerp(
          font.headlineSmallSecondary, other.headlineSmallSecondary, t)!,
      headlineSmallOnPrimary: TextStyle.lerp(
          font.headlineSmallOnPrimary, other.headlineSmallOnPrimary, t)!,
      titleLarge: TextStyle.lerp(font.titleLarge, other.titleLarge, t)!,
      titleLargeSecondary: TextStyle.lerp(
          font.titleLargeSecondary, other.titleLargeSecondary, t)!,
      titleLargeOnPrimary: TextStyle.lerp(
          font.titleLargeOnPrimary, other.titleLargeOnPrimary, t)!,
      titleMedium: TextStyle.lerp(font.titleMedium, other.titleMedium, t)!,
      titleMediumPrimary:
          TextStyle.lerp(font.titleMediumPrimary, other.titleMediumPrimary, t)!,
      titleMediumSecondary: TextStyle.lerp(
          font.titleMediumSecondary, other.titleMediumSecondary, t)!,
      titleMediumOnPrimary: TextStyle.lerp(
          font.titleMediumOnPrimary, other.titleMediumOnPrimary, t)!,
      titleSmall: TextStyle.lerp(font.titleSmall, other.titleSmall, t)!,
      titleSmallOnPrimary: TextStyle.lerp(
          font.titleSmallOnPrimary, other.titleSmallOnPrimary, t)!,
      labelLarge: TextStyle.lerp(font.labelLarge, other.labelLarge, t)!,
      labelLargeSecondary: TextStyle.lerp(
          font.labelLargeSecondary, other.labelLargeSecondary, t)!,
      labelLargeOnPrimary: TextStyle.lerp(
          font.labelLargeOnPrimary, other.labelLargeOnPrimary, t)!,
      labelMedium: TextStyle.lerp(font.labelMedium, other.labelMedium, t)!,
      labelMediumPrimary:
          TextStyle.lerp(font.labelMediumPrimary, other.labelMediumPrimary, t)!,
      labelMediumSecondary: TextStyle.lerp(
          font.labelMediumSecondary, other.labelMediumSecondary, t)!,
      labelMediumOnPrimary: TextStyle.lerp(
          font.labelMediumOnPrimary, other.labelMediumOnPrimary, t)!,
      labelSmall: TextStyle.lerp(font.labelSmall, other.labelSmall, t)!,
      labelSmallPrimary:
          TextStyle.lerp(font.labelSmallPrimary, other.labelSmallPrimary, t)!,
      labelSmallSecondary: TextStyle.lerp(
          font.labelSmallSecondary, other.labelSmallSecondary, t)!,
      labelSmallOnPrimary: TextStyle.lerp(
          font.labelSmallOnPrimary, other.labelSmallOnPrimary, t)!,
      bodyLarge: TextStyle.lerp(font.bodyLarge, other.bodyLarge, t)!,
      bodyLargePrimary:
          TextStyle.lerp(font.bodyLargePrimary, other.bodyLargePrimary, t)!,
      bodyLargeSecondary:
          TextStyle.lerp(font.bodyLargeSecondary, other.bodyLargeSecondary, t)!,
      bodyMedium: TextStyle.lerp(font.bodyMedium, other.bodyMedium, t)!,
      bodyMediumPrimary:
          TextStyle.lerp(font.bodyMediumPrimary, other.bodyMediumPrimary, t)!,
      bodyMediumSecondary: TextStyle.lerp(
          font.bodyMediumSecondary, other.bodyMediumSecondary, t)!,
      bodyMediumOnPrimary: TextStyle.lerp(
          font.bodyMediumOnPrimary, other.bodyMediumOnPrimary, t)!,
      bodySmall: TextStyle.lerp(font.bodySmall, other.bodySmall, t)!,
      bodySmallPrimary:
          TextStyle.lerp(font.bodySmallPrimary, other.bodySmallPrimary, t)!,
      bodySmallSecondary:
          TextStyle.lerp(font.bodySmallSecondary, other.bodySmallSecondary, t)!,
      bodySmallOnPrimary:
          TextStyle.lerp(font.bodySmallOnPrimary, other.bodySmallOnPrimary, t)!,
      input: TextStyle.lerp(font.input, other.input, t)!,
      error: TextStyle.lerp(font.error, other.error, t)!,
      counter: TextStyle.lerp(font.counter, other.counter, t)!,
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
    required this.onPrimary,
    Color? onPrimaryOpacity7,
    Color? onPrimaryOpacity25,
    Color? onPrimaryOpacity50,
    Color? onPrimaryOpacity95,
    required this.secondary,
    required this.secondaryBackground,
    required this.secondaryBackgroundLight,
    required this.secondaryBackgroundLightest,
    required this.secondaryHighlight,
    required this.secondaryHighlightDark,
    required this.secondaryHighlightDarkest,
    Color? secondaryOpacity87,
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
    required this.acceptColor,
    required this.acceptAuxiliaryColor,
    required this.declineColor,
    required this.dangerColor,
    required this.warningColor,
    required this.userColors,
  })  : primaryOpacity20 = primaryOpacity20 ?? primary.withOpacity(0.20),
        onPrimaryOpacity7 = onPrimaryOpacity7 ?? onPrimary.withOpacity(0.07),
        onPrimaryOpacity25 = onPrimaryOpacity25 ?? onPrimary.withOpacity(0.25),
        onPrimaryOpacity50 = onPrimaryOpacity50 ?? onPrimary.withOpacity(0.50),
        onPrimaryOpacity95 = onPrimaryOpacity95 ?? onPrimary.withOpacity(0.95),
        secondaryOpacity87 = secondaryOpacity87 ?? secondary.withOpacity(0.87),
        onSecondaryOpacity20 =
            onSecondaryOpacity20 ?? onSecondary.withOpacity(0.20),
        onSecondaryOpacity50 =
            onSecondaryOpacity50 ?? onSecondary.withOpacity(0.50),
        onSecondaryOpacity60 =
            onSecondaryOpacity60 ?? onSecondary.withOpacity(0.60),
        onSecondaryOpacity88 =
            onSecondaryOpacity88 ?? onSecondary.withOpacity(0.88),
        onBackgroundOpacity2 =
            onBackgroundOpacity2 ?? onBackground.withOpacity(0.02),
        onBackgroundOpacity7 =
            onBackgroundOpacity7 ?? onBackground.withOpacity(0.07),
        onBackgroundOpacity13 =
            onBackgroundOpacity13 ?? onBackground.withOpacity(0.13),
        onBackgroundOpacity20 =
            onBackgroundOpacity20 ?? onBackground.withOpacity(0.20),
        onBackgroundOpacity27 =
            onBackgroundOpacity27 ?? onBackground.withOpacity(0.27),
        onBackgroundOpacity40 =
            onBackgroundOpacity40 ?? onBackground.withOpacity(0.40),
        onBackgroundOpacity50 =
            onBackgroundOpacity50 ?? onBackground.withOpacity(0.50),
        onBackgroundOpacity70 =
            onBackgroundOpacity70 ?? onBackground.withOpacity(0.70);

  /// Primary [Color] of the application.
  ///
  /// Used to highlight the active interface elements.
  final Color primary;

  /// 20% opacity of the [primary] color.
  ///
  /// Used to highlight chat messages.
  final Color primaryOpacity20;

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

  /// Secondary [Color] used alongside with [primary].
  ///
  /// Used for texts, icons, outlines.
  final Color secondary;

  /// 87% opacity of the [secondary] color.
  ///
  /// Used as the muted indicator background in calls.
  final Color secondaryOpacity87;

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
  /// Used for [CallButton]s and [GalleryPopup] buttons.
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

  /// Indicator of an affirmative color to visually confirm elements of the user
  /// interface.
  ///
  /// Used in accept call button.
  final Color acceptColor;

  /// [Color] is used as an auxiliary color to display pleasant action
  /// confirmation messages.
  final Color acceptAuxiliaryColor;

  /// Indicator of rejection or cancellation in various elements of the user
  /// interface.
  ///
  /// Used in decline call button.
  final Color declineColor;

  /// [Color] used to indicate dangerous or critical elements in the user
  /// interface.
  final Color dangerColor;

  /// [Color] used to indicate caution, risk, or a potential threat.
  final Color warningColor;

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
      primaryHighlight:
          Color.lerp(color.primaryHighlight, other.primaryHighlight, t)!,
      primaryHighlightShiny: Color.lerp(
        color.primaryHighlightShiny,
        other.primaryHighlightShiny,
        t,
      )!,
      primaryHighlightShiniest: Color.lerp(
          color.primaryHighlightShiniest, other.primaryHighlightShiniest, t)!,
      primaryHighlightLightest: Color.lerp(
          color.primaryHighlightLightest, other.primaryHighlightLightest, t)!,
      onPrimary: Color.lerp(color.onPrimary, other.onPrimary, t)!,
      onPrimaryOpacity7:
          Color.lerp(color.onPrimaryOpacity7, other.onPrimaryOpacity7, t)!,
      onPrimaryOpacity25:
          Color.lerp(color.onPrimaryOpacity25, other.onPrimaryOpacity25, t)!,
      onPrimaryOpacity50:
          Color.lerp(color.onPrimaryOpacity50, other.onPrimaryOpacity50, t)!,
      onPrimaryOpacity95:
          Color.lerp(color.onPrimaryOpacity95, other.onPrimaryOpacity95, t)!,
      secondary: Color.lerp(color.secondary, other.secondary, t)!,
      secondaryOpacity87:
          Color.lerp(color.secondaryOpacity87, other.secondaryOpacity87, t)!,
      secondaryHighlight:
          Color.lerp(color.secondaryHighlight, other.secondaryHighlight, t)!,
      secondaryHighlightDark: Color.lerp(
          color.secondaryHighlightDark, other.secondaryHighlightDark, t)!,
      secondaryHighlightDarkest: Color.lerp(
          color.secondaryHighlightDarkest, other.secondaryHighlightDarkest, t)!,
      secondaryBackground:
          Color.lerp(color.secondaryBackground, other.secondaryBackground, t)!,
      secondaryBackgroundLight: Color.lerp(
          color.secondaryBackgroundLight, other.secondaryBackgroundLight, t)!,
      secondaryBackgroundLightest: Color.lerp(color.secondaryBackgroundLightest,
          other.secondaryBackgroundLightest, t)!,
      onSecondary: Color.lerp(color.onSecondary, other.onSecondary, t)!,
      onSecondaryOpacity20: Color.lerp(
          color.onSecondaryOpacity20, other.onSecondaryOpacity20, t)!,
      onSecondaryOpacity50: Color.lerp(
          color.onSecondaryOpacity50, other.onSecondaryOpacity50, t)!,
      onSecondaryOpacity60: Color.lerp(
          color.onSecondaryOpacity60, other.onSecondaryOpacity60, t)!,
      onSecondaryOpacity88: Color.lerp(
          color.onSecondaryOpacity88, other.onSecondaryOpacity88, t)!,
      background: Color.lerp(color.background, other.background, t)!,
      backgroundAuxiliary:
          Color.lerp(color.backgroundAuxiliary, other.backgroundAuxiliary, t)!,
      backgroundAuxiliaryLight: Color.lerp(
          color.backgroundAuxiliaryLight, other.backgroundAuxiliaryLight, t)!,
      backgroundAuxiliaryLighter: Color.lerp(color.backgroundAuxiliaryLighter,
          other.backgroundAuxiliaryLighter, t)!,
      backgroundAuxiliaryLightest: Color.lerp(color.backgroundAuxiliaryLightest,
          other.backgroundAuxiliaryLightest, t)!,
      onBackground: Color.lerp(color.onBackground, other.onBackground, t)!,
      onBackgroundOpacity2: Color.lerp(
          color.onBackgroundOpacity2, other.onBackgroundOpacity2, t)!,
      onBackgroundOpacity7: Color.lerp(
          color.onBackgroundOpacity7, other.onBackgroundOpacity7, t)!,
      onBackgroundOpacity13: Color.lerp(
          color.onBackgroundOpacity13, other.onBackgroundOpacity13, t)!,
      onBackgroundOpacity20: Color.lerp(
          color.onBackgroundOpacity20, other.onBackgroundOpacity20, t)!,
      onBackgroundOpacity27: Color.lerp(
          color.onBackgroundOpacity27, other.onBackgroundOpacity27, t)!,
      onBackgroundOpacity40: Color.lerp(
          color.onBackgroundOpacity40, other.onBackgroundOpacity40, t)!,
      onBackgroundOpacity50: Color.lerp(
          color.onBackgroundOpacity50, other.onBackgroundOpacity50, t)!,
      transparent: Color.lerp(color.transparent, other.transparent, t)!,
      acceptColor: Color.lerp(color.acceptColor, other.acceptColor, t)!,
      acceptAuxiliaryColor: Color.lerp(
          color.acceptAuxiliaryColor, other.acceptAuxiliaryColor, t)!,
      declineColor: Color.lerp(color.declineColor, other.declineColor, t)!,
      dangerColor: Color.lerp(color.dangerColor, other.dangerColor, t)!,
      warningColor: Color.lerp(color.warningColor, other.warningColor, t)!,
      userColors:
          other.userColors.isNotEmpty ? other.userColors : color.userColors,
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
  String toHex() => '#'
      '${alpha.toRadixString(16).toUpperCase().padLeft(2, '0')}'
      '${red.toRadixString(16).toUpperCase().padLeft(2, '0')}'
      '${green.toRadixString(16).toUpperCase().padLeft(2, '0')}'
      '${blue.toRadixString(16).toUpperCase().padLeft(2, '0')}';
}
