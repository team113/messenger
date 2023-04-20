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
    /// All the necessary properties of [Color]s that are used in various elements
    /// of the application interface
    final Palette colors = Palette(
      primary: const Color(0xFF63B4FF),
      primaryHighlight: Colors.blue,
      primaryHighlightShiny: const Color(0xFF00A3FF),
      primaryHighlightShinier: const Color(0xFFB6DCFF),
      primaryHighlightShiniest: const Color(0xFFDBEAFD),
      onPrimary: Colors.white,
      onPrimaryOpacity7: const Color(0x11FFFFFF),
      onPrimaryOpacity25: const Color(0x40FFFFFF),
      onPrimaryOpacity40: const Color(0x66FFFFFF),
      onPrimaryOpacity50: const Color(0x80FFFFFF),
      onPrimaryOpacity60: const Color(0x99FFFFFF),
      onPrimaryOpacity80: const Color(0xCCFFFFFF),
      secondary: const Color(0xFF888888),
      secondaryHighlight: const Color(0xFFF5F5F5),
      secondaryHighlightDark: const Color(0xFFDEDEDE),
      secondaryHighlightDarkest: const Color(0xFFC0C0C0),
      secondaryBackground: const Color(0xFF222222),
      secondaryBackgroundLight: const Color(0xFF444444),
      secondaryBackgroundLightest: const Color(0xFF666666),
      secondaryOpacity87: const Color(0xDD818181),
      secondaryOpacity73: const Color(0xBB818181),
      onSecondary: const Color(0xBB1F3C5D),
      onSecondaryOpacity88: const Color(0xE0165084),
      onSecondaryOpacity60: const Color(0x9D165084),
      onSecondaryOpacity50: const Color(0x794E5A78),
      onSecondaryOpacity30: const Color(0x4D165084),
      onSecondaryOpacity20: const Color(0x301D6AAE),
      background: const Color(0xFFF5F8FA),
      backgroundAuxiliary: const Color(0xFF0A1724),
      backgroundAuxiliaryLight: const Color(0xFF132131),
      backgroundAuxiliaryLighter: const Color(0xFFE6F1FE),
      backgroundAuxiliaryLightest: const Color(0xFFF4F9FF),
      onBackground: Colors.black,
      onBackgroundOpacity2: const Color(0x04000000),
      onBackgroundOpacity7: const Color(0x11000000),
      onBackgroundOpacity13: const Color(0x22000000),
      onBackgroundOpacity20: const Color(0x33000000),
      onBackgroundOpacity27: const Color(0x44000000),
      onBackgroundOpacity33: const Color(0x55000000),
      onBackgroundOpacity40: const Color(0x66000000),
      onBackgroundOpacity50: const Color(0x80000000),
      onBackgroundOpacity56: const Color(0x90000000),
      onBackgroundOpacity63: const Color(0xA0000000),
      transparent: const Color(0x00000000),
      acceptColor: const Color(0x7F34B139),
      acceptAuxiliaryColor: Colors.green,
      declineColor: const Color(0x7FFF0000),
      dangerColor: Colors.red,
      warningColor: Colors.orange,
      userColors: [
        Colors.purple,
        Colors.deepPurple,
        Colors.indigo,
        Colors.blue,
        Colors.cyan,
        Colors.lightGreen,
        Colors.lime,
        Colors.amber,
        Colors.orange,
        Colors.deepOrange,
      ],
    );

    TextStyle textStyle = TextStyle(
      fontFamily: 'SFUI',
      fontFamilyFallback: const ['.SF UI Display'],
      color: colors.onBackground,
      fontSize: 17,
      fontWeight: FontWeight.w400,
    );

    return ThemeData.light().copyWith(
        extensions: [
          Style(
            colors: Palette(
              primary: colors.primary,
              secondaryBackground: colors.secondaryBackground,
              secondaryBackgroundLight: colors.secondaryBackgroundLight,
              secondaryBackgroundLightest: colors.secondaryBackgroundLightest,
              secondaryHighlight: colors.secondaryHighlight,
              secondaryHighlightDark: colors.secondaryHighlightDark,
              secondaryHighlightDarkest: colors.secondaryHighlightDarkest,
              secondaryOpacity87:
                  colors.secondaryOpacity87 ?? colors.primary.withOpacity(0.87),
              secondaryOpacity73:
                  colors.secondaryOpacity73 ?? colors.primary.withOpacity(0.73),
              onPrimary: colors.onPrimary,
              onPrimaryOpacity7: colors.onPrimaryOpacity7 ??
                  colors.onPrimary.withOpacity(0.07),
              onPrimaryOpacity25: colors.onPrimaryOpacity25 ??
                  colors.onPrimary.withOpacity(0.25),
              onPrimaryOpacity40: colors.onPrimaryOpacity40 ??
                  colors.onPrimary.withOpacity(0.40),
              onPrimaryOpacity50: colors.onPrimaryOpacity50 ??
                  colors.onPrimary.withOpacity(0.50),
              onPrimaryOpacity60: colors.onPrimaryOpacity60 ??
                  colors.onPrimary.withOpacity(0.60),
              onPrimaryOpacity80: colors.onPrimaryOpacity80 ??
                  colors.onPrimary.withOpacity(0.80),
              secondary: colors.secondary,
              primaryHighlight: colors.primaryHighlight,
              primaryHighlightShiny: colors.primaryHighlightShiny,
              primaryHighlightShinier: colors.primaryHighlightShinier,
              primaryHighlightShiniest: colors.primaryHighlightShiniest,
              onSecondary: colors.onSecondary,
              onSecondaryOpacity88: colors.onSecondaryOpacity88 ??
                  colors.onSecondary.withOpacity(0.88),
              onSecondaryOpacity60: colors.onSecondaryOpacity60 ??
                  colors.onSecondary.withOpacity(0.60),
              onSecondaryOpacity50: colors.onSecondaryOpacity50 ??
                  colors.onSecondary.withOpacity(0.50),
              onSecondaryOpacity30: colors.onSecondaryOpacity30 ??
                  colors.onSecondary.withOpacity(0.30),
              onSecondaryOpacity20: colors.onSecondaryOpacity20 ??
                  colors.onSecondary.withOpacity(0.20),
              background: colors.background,
              backgroundAuxiliary: colors.backgroundAuxiliary,
              backgroundAuxiliaryLight: colors.backgroundAuxiliaryLight,
              backgroundAuxiliaryLighter: colors.backgroundAuxiliaryLighter,
              backgroundAuxiliaryLightest: colors.backgroundAuxiliaryLightest,
              onBackground: colors.onBackground,
              onBackgroundOpacity2: colors.onBackgroundOpacity2 ??
                  colors.onBackground.withOpacity(0.025),
              onBackgroundOpacity7: colors.onBackgroundOpacity7 ??
                  colors.onBackground.withOpacity(0.07),
              onBackgroundOpacity13: colors.onBackgroundOpacity13 ??
                  colors.onBackground.withOpacity(0.13),
              onBackgroundOpacity20: colors.onBackgroundOpacity20 ??
                  colors.onBackground.withOpacity(0.2),
              onBackgroundOpacity27: colors.onBackgroundOpacity27 ??
                  colors.onBackground.withOpacity(0.27),
              onBackgroundOpacity33: colors.onBackgroundOpacity33 ??
                  colors.onBackground.withOpacity(0.33),
              onBackgroundOpacity40: colors.onBackgroundOpacity40 ??
                  colors.onBackground.withOpacity(0.4),
              onBackgroundOpacity50: colors.onBackgroundOpacity50 ??
                  colors.onBackground.withOpacity(0.5),
              onBackgroundOpacity56: colors.onBackgroundOpacity56 ??
                  colors.onBackground.withOpacity(0.56),
              onBackgroundOpacity63: colors.onBackgroundOpacity63 ??
                  colors.onBackground.withOpacity(0.63),
              transparent: colors.transparent,
              acceptColor: colors.acceptColor,
              acceptAuxiliaryColor: colors.acceptAuxiliaryColor,
              declineColor: colors.declineColor,
              dangerColor: colors.dangerColor,
              warningColor: colors.warningColor,
              userColors: colors.userColors,
            ),
            barrierColor: colors.onBackgroundOpacity63 ??
                colors.onBackground.withOpacity(0.63),
            boldBody: textStyle.copyWith(
              color: colors.onBackground,
              fontSize: 17,
            ),
            cardBlur: 5,
            cardBorder: Border.all(
              color: colors.secondaryHighlight,
              width: 0.5,
            ),
            cardColor: colors.onPrimary.withOpacity(0.95),
            cardHoveredBorder: Border.all(
              color: colors.primaryHighlightShiniest,
              width: 0.5,
            ),
            cardHoveredColor: colors.primaryHighlightShiniest,
            cardRadius: BorderRadius.circular(14),
            cardSelectedColor: colors.primaryHighlightShinier,
            contextMenuBackgroundColor: colors.secondaryHighlight,
            contextMenuHoveredColor: colors.secondaryHighlightDark,
            contextMenuRadius: BorderRadius.circular(10),
            linkStyle: TextStyle(
              color: colors.primaryHighlight,
              decoration: TextDecoration.underline,
              decorationThickness: 2,
            ),
            messageColor: Colors.white,
            primaryBorder: Border.all(
              color: colors.secondaryHighlightDark,
              width: 0.5,
            ),
            readMessageColor: colors.primaryHighlightShiniest,
            secondaryBorder: Border.all(
              color: colors.primaryHighlightShinier,
              width: 0.5,
            ),
            sidebarColor:
                colors.onPrimaryOpacity40 ?? colors.onPrimary.withOpacity(0.6),
            systemMessageBorder: Border.all(
              color: colors.secondaryHighlight,
              width: 0.5,
            ),
            systemMessageColor: colors.secondaryHighlight.withOpacity(0.95),
            systemMessageStyle: textStyle.copyWith(
              color: colors.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w300,
            ),
            unreadMessageColor: colors.primaryHighlightShiniest,
          ),
        ],
        scaffoldBackgroundColor: colors.transparent,
        appBarTheme: ThemeData.light().appBarTheme.copyWith(
              backgroundColor: colors.primaryHighlightShiniest,
              foregroundColor: colors.secondary,
              iconTheme: ThemeData.light().appBarTheme.iconTheme?.copyWith(
                    color: colors.secondary,
                  ),
              actionsIconTheme:
                  ThemeData.light().appBarTheme.iconTheme?.copyWith(
                        color: colors.secondary,
                      ),
              systemOverlayStyle: SystemUiOverlayStyle(
                systemNavigationBarColor: colors.primaryHighlight,
                statusBarColor: colors.transparent,
              ),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: textStyle.copyWith(
                color: colors.onBackground,
                fontWeight: FontWeight.w300,
                fontSize: 18,
              ),
            ),
        tabBarTheme: ThemeData.light().tabBarTheme.copyWith(
              labelColor: colors.primary,
              unselectedLabelColor: colors.secondary,
            ),
        primaryIconTheme: const IconThemeData.fallback().copyWith(
          color: colors.secondary,
        ),
        iconTheme: ThemeData.light().iconTheme.copyWith(
              color: colors.onBackground,
            ),
        textTheme: Typography.blackCupertino.copyWith(
          displayLarge: textStyle.copyWith(
            color: colors.secondary,
            fontWeight: FontWeight.w300,
            fontSize: 24,
          ),
          displayMedium: textStyle.copyWith(
            color: colors.secondary,
            fontWeight: FontWeight.w300,
            fontSize: 15.4,
          ),
          displaySmall:
              textStyle.copyWith(fontWeight: FontWeight.w300, fontSize: 18),
          headlineLarge:
              textStyle.copyWith(fontWeight: FontWeight.w300, fontSize: 24),
          headlineMedium: textStyle.copyWith(fontSize: 18),
          headlineSmall: textStyle.copyWith(fontSize: 18),
          labelLarge:
              textStyle.copyWith(fontWeight: FontWeight.w300, fontSize: 17),
          labelMedium:
              textStyle.copyWith(fontWeight: FontWeight.w300, fontSize: 17),
          labelSmall:
              textStyle.copyWith(fontWeight: FontWeight.w300, fontSize: 17),
          titleMedium: textStyle.copyWith(fontSize: 15),
          titleSmall: textStyle.copyWith(
            color: colors.secondary,
            fontSize: 15,
            fontWeight: FontWeight.w300,
          ),
          bodyLarge:
              textStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w300),
          bodyMedium:
              textStyle.copyWith(fontSize: 13, fontWeight: FontWeight.w300),
          bodySmall: textStyle.copyWith(
            color: colors.secondary,
            fontWeight: FontWeight.w300,
            fontSize: 13,
          ),
        ),
        inputDecorationTheme: ThemeData.light().inputDecorationTheme.copyWith(
              focusColor: colors.primary,
              hoverColor: colors.transparent,
              fillColor: colors.primary,
              hintStyle: textStyle.copyWith(
                color: colors.secondaryHighlightDarkest,
                fontSize: 15,
                fontWeight: FontWeight.w300,
              ),
              labelStyle: textStyle.copyWith(
                color: colors.secondaryHighlightDarkest,
                fontSize: 15,
                fontWeight: FontWeight.w300,
              ),
              errorStyle: textStyle.copyWith(color: Colors.red, fontSize: 13),
              helperStyle: textStyle.copyWith(
                color: colors.secondaryHighlightDarkest,
                fontSize: 15,
                fontWeight: FontWeight.w300,
              ),
              prefixStyle: textStyle.copyWith(
                color: colors.secondaryHighlightDarkest,
                fontSize: 15,
                fontWeight: FontWeight.w300,
              ),
              suffixStyle: textStyle.copyWith(
                color: colors.secondaryHighlightDarkest,
                fontSize: 15,
                fontWeight: FontWeight.w300,
              ),
              counterStyle: textStyle.copyWith(
                color: colors.secondaryHighlightDarkest,
                fontSize: 13,
                fontWeight: FontWeight.w300,
              ),
              floatingLabelStyle: textStyle.copyWith(
                color: colors.secondaryHighlightDarkest,
                fontSize: 15,
                fontWeight: FontWeight.w300,
              ),
              errorMaxLines: 5,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(
                  width: 2,
                  color: colors.secondaryHighlightDark,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(
                  color: colors.secondaryHighlightDark,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(
                  color: colors.secondaryHighlightDark,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(
                  color: colors.secondaryHighlightDark,
                ),
              ),
            ),
        textSelectionTheme: ThemeData.light().textSelectionTheme.copyWith(
              cursorColor: colors.primary,
              selectionHandleColor: colors.primary,
            ),
        floatingActionButtonTheme:
            ThemeData.light().floatingActionButtonTheme.copyWith(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
        bottomNavigationBarTheme:
            ThemeData.light().bottomNavigationBarTheme.copyWith(
                  backgroundColor: colors.primaryHighlightShiniest,
                  selectedItemColor: colors.primary,
                  unselectedItemColor: colors.secondary,
                ),
        progressIndicatorTheme:
            ThemeData.light().progressIndicatorTheme.copyWith(
                  color: colors.primary,
                ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: colors.secondary,
            textStyle: textStyle.copyWith(
              color: colors.secondary,
              fontSize: 17,
            ),
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
            textStyle: textStyle.copyWith(
              color: colors.secondary,
              fontSize: 17,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.all(12),
            textStyle: textStyle.copyWith(
              color: colors.secondary,
              fontSize: 15,
            ),
          ),
        ),
        scrollbarTheme: ThemeData.light().scrollbarTheme.copyWith(
              interactive: true,
              thickness: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.dragged) ||
                    states.contains(MaterialState.hovered)) {
                  return 6;
                }

                return 4;
              }),
            ),
        radioTheme: ThemeData.light().radioTheme.copyWith(
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return colors.primary;
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
    required this.barrierColor,
    required this.boldBody,
    required this.cardBlur,
    required this.cardBorder,
    required this.cardColor,
    required this.cardHoveredBorder,
    required this.cardHoveredColor,
    required this.cardRadius,
    required this.cardSelectedColor,
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
    required this.unreadMessageColor,
  });

  /// Set of properties representing the colors of the application.
  final Palette colors;

  /// [Color] of the modal background barrier color.
  final Color barrierColor;

  /// [TextStyle] to use in the body to make content readable.
  final TextStyle boldBody;

  /// Blur to apply to card-like [Widget]s.
  final double cardBlur;

  /// [Border] to apply to card-like [Widget]s.
  final Border cardBorder;

  /// Background [Color] of card-like [Widget]s.
  final Color cardColor;

  /// [Border] to apply to hovered card-like [Widget]s.
  final Border cardHoveredBorder;

  /// Background [Color] of hovered card-like [Widget]s.
  final Color cardHoveredColor;

  /// [BorderRadius] to use in card-like [Widget]s.
  final BorderRadius cardRadius;

  /// Background [Color] of selected card-like [Widget]s.
  final Color cardSelectedColor;

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

  /// Background [Color] of unread [ChatMessage]s, [ChatForward]s and
  /// [ChatCall]s posted by the authenticated [MyUser].
  final Color unreadMessageColor;

  @override
  ThemeExtension<Style> copyWith({
    Palette? colors,
    Color? primary,
    Color? secondaryBackground,
    Color? secondaryBackgroundLight,
    Color? secondaryBackgroundLighter,
    Color? secondaryBackgroundLightest,
    Color? secondaryHighlight,
    Color? secondaryHighlightDark,
    Color? secondaryHighlightDarkest,
    Color? secondaryOpacity87,
    Color? secondaryOpacity73,
    Color? onPrimary,
    Color? onPrimaryOpacity7,
    Color? onPrimaryOpacity25,
    Color? onPrimaryOpacity40,
    Color? onPrimaryOpacity50,
    Color? onPrimaryOpacity60,
    Color? onPrimaryOpacity80,
    Color? secondary,
    Color? secondaryNative,
    Color? primaryHighlight,
    Color? primaryHighlightShiny,
    Color? primaryHighlightShinier,
    Color? primaryHighlightShiniest,
    Color? onSecondary,
    Color? onSecondaryOpacity88,
    Color? onSecondaryOpacity60,
    Color? onSecondaryOpacity50,
    Color? onSecondaryOpacity30,
    Color? onSecondaryOpacity20,
    Color? background,
    Color? backgroundAuxiliary,
    Color? backgroundAuxiliaryLight,
    Color? backgroundAuxiliaryLighter,
    Color? backgroundAuxiliaryLightest,
    Color? onBackground,
    Color? onBackgroundOpacity2,
    Color? onBackgroundOpacity7,
    Color? onBackgroundOpacity13,
    Color? onBackgroundOpacity20,
    Color? onBackgroundOpacity27,
    Color? onBackgroundOpacity33,
    Color? onBackgroundOpacity40,
    Color? onBackgroundOpacity50,
    Color? onBackgroundOpacity56,
    Color? onBackgroundOpacity63,
    Color? transparent,
    Color? acceptColor,
    Color? acceptAuxiliaryColor,
    Color? declineColor,
    Color? dangerColor,
    Color? warningColor,
    List<Color>? userColors,
    Color? barrierColor,
    TextStyle? boldBody,
    double? cardBlur,
    Border? cardBorder,
    Color? cardColor,
    Border? cardHoveredBorder,
    Color? cardHoveredColor,
    BorderRadius? cardRadius,
    Color? cardSelectedColor,
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
    Color? unreadMessageColor,
  }) {
    return Style(
      colors: colors ?? this.colors,
      barrierColor: barrierColor ?? this.barrierColor,
      boldBody: boldBody ?? this.boldBody,
      cardBlur: cardBlur ?? this.cardBlur,
      cardBorder: cardBorder ?? this.cardBorder,
      cardColor: cardColor ?? this.cardColor,
      cardHoveredBorder: cardHoveredBorder ?? this.cardHoveredBorder,
      cardHoveredColor: cardHoveredColor ?? this.cardHoveredColor,
      cardRadius: cardRadius ?? this.cardRadius,
      cardSelectedColor: cardSelectedColor ?? this.cardSelectedColor,
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
      unreadMessageColor: unreadMessageColor ?? this.unreadMessageColor,
    );
  }

  @override
  ThemeExtension<Style> lerp(ThemeExtension<Style>? other, double t) {
    if (other is! Style) {
      return this;
    }

    return Style(
      colors: Palette.lerpColors(colors, other.colors, t),
      barrierColor: Color.lerp(barrierColor, other.barrierColor, t)!,
      boldBody: TextStyle.lerp(boldBody, other.boldBody, t)!,
      cardBlur: cardBlur * (1.0 - t) + other.cardBlur * t,
      cardBorder: Border.lerp(cardBorder, other.cardBorder, t)!,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      cardHoveredBorder:
          Border.lerp(cardHoveredBorder, other.cardHoveredBorder, t)!,
      cardHoveredColor:
          Color.lerp(cardHoveredColor, other.cardHoveredColor, t)!,
      cardRadius: BorderRadius.lerp(cardRadius, other.cardRadius, t)!,
      cardSelectedColor:
          Color.lerp(cardSelectedColor, other.cardSelectedColor, t)!,
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
      unreadMessageColor:
          Color.lerp(unreadMessageColor, other.unreadMessageColor, t)!,
    );
  }
}

/// Set of properties representing the colors of the application.
class Palette {
  Palette({
    required this.primary,
    required this.secondaryBackground,
    required this.secondaryBackgroundLight,
    required this.secondaryBackgroundLightest,
    required this.secondaryHighlight,
    required this.secondaryHighlightDark,
    required this.secondaryHighlightDarkest,
    this.secondaryOpacity87,
    this.secondaryOpacity73,
    required this.onPrimary,
    this.onPrimaryOpacity7,
    this.onPrimaryOpacity25,
    this.onPrimaryOpacity40,
    this.onPrimaryOpacity50,
    this.onPrimaryOpacity60,
    this.onPrimaryOpacity80,
    required this.secondary,
    required this.primaryHighlight,
    required this.primaryHighlightShiny,
    required this.primaryHighlightShinier,
    required this.primaryHighlightShiniest,
    required this.onSecondary,
    this.onSecondaryOpacity88,
    this.onSecondaryOpacity60,
    this.onSecondaryOpacity50,
    this.onSecondaryOpacity30,
    this.onSecondaryOpacity20,
    required this.background,
    required this.backgroundAuxiliary,
    required this.backgroundAuxiliaryLight,
    required this.backgroundAuxiliaryLighter,
    required this.backgroundAuxiliaryLightest,
    required this.onBackground,
    this.onBackgroundOpacity2,
    this.onBackgroundOpacity7,
    this.onBackgroundOpacity13,
    this.onBackgroundOpacity20,
    this.onBackgroundOpacity27,
    this.onBackgroundOpacity33,
    this.onBackgroundOpacity40,
    this.onBackgroundOpacity50,
    this.onBackgroundOpacity56,
    this.onBackgroundOpacity63,
    required this.transparent,
    required this.acceptColor,
    required this.acceptAuxiliaryColor,
    required this.declineColor,
    required this.dangerColor,
    required this.warningColor,
    required this.userColors,
  });

  /// Main [Color] of the application, used to highlight the active interface elements.
  final Color primary;

  /// Background [Color] for elements associated with the [primary] color.
  /// For example, the background for buttons, pop-ups, dialog boxes, etc.
  final Color secondaryBackground;

  /// Light shade of the primary background [Color].
  final Color secondaryBackgroundLight;

  /// Lightest shade of the primary background [Color].
  final Color secondaryBackgroundLightest;

  /// [Color] for highlighting UI elements, used to highlight the active elements.
  final Color secondaryHighlight;

  /// Dark shade of the accent [Color]. Used to create contrast and depth effect.
  final Color secondaryHighlightDark;

  /// Darkest shade of the main accent [Color]. It is used to emphasize buttons, labels,
  /// or other user interface elements that should be highlighted and easily visible to the user.
  final Color secondaryHighlightDarkest;

  /// 20% opacity of the [primary] color.
  /// Used for - [handRaisedIcon], [element], etc.
  final Color? secondaryOpacity87;

  /// 15% opacity of the [primary] color.
  /// Used for - [HintWidget] elements.
  final Color? secondaryOpacity73;

  ///  [Color] that is used for elements that are displayed on top
  /// of the main color of the application, for example, text on buttons and icons.
  final Color onPrimary;

  /// 90% opacity of the [onPrimary] color.
  /// Used for - [_secondaryTarget] boxes, [DecorationTween], etc.
  final Color? onPrimaryOpacity7;

  /// 75% opacity of the [onPrimary] color.
  /// Used for - [BoxDecoration].
  final Color? onPrimaryOpacity25;

  /// 60% opacity of the [onPrimary] color.
  /// Used for - [MessageFieldView] containers.
  final Color? onPrimaryOpacity40;

  /// 50% opacity of the [onPrimary] color.
  /// Used for - [AcceptVideoButton], [ChewieProgressColors] etc.
  final Color? onPrimaryOpacity50;

  /// 40% opacity of the [onPrimary] color.
  /// Used for - [MobileCall] boxes, etc.
  final Color? onPrimaryOpacity60;

  /// 20% opacity of the [onPrimary] color.
  /// Used for - [MobileControls] text, etc.
  final Color? onPrimaryOpacity80;

  /// [Color] is used to combine with the main color, giving the interface a nice and balanced look.
  /// For example, for lists, the background of some elements and other additional interface elements.
  final Color secondary;

  /// Highlight [Color] of the secondary element.
  /// Used to highlight secondary elements when hovering or when activated.
  final Color primaryHighlight;

  /// Glowing tone of secondary [Color] that is used to draw the user's attention
  /// to an area of the screen that contains important information.
  final Color primaryHighlightShiny;

  /// [Color] used to highlight or highlight interface elements of secondary importance with a brighter sheen.
  final Color primaryHighlightShinier;

  /// Most brilliant and contrasting secondary highlight [Color].
  /// Can be used as a background or to highlight certain elements.
  final Color primaryHighlightShiniest;

  /// [Color] that is displayed on a secondary color background
  /// is used as an accent color for the interface and does not cause eye strain.
  final Color onSecondary;

  /// 90% opacity of the [onSecondary] color.
  /// Used for - [CallController.panel] box, [SlidingUpPanel], etc.
  final Color? onSecondaryOpacity88;

  /// 60% opacity of the [onSecondary] color.
  /// Used for - [launchpad] box, [SlidingUpPanel], etc.
  final Color? onSecondaryOpacity60;

  /// 50% opacity of the [onSecondary] color.
  /// Used for - [CallButton], [chat] card, [GalleryPopup] interface, etc.
  final Color? onSecondaryOpacity50;

  /// 30% opacity of the [onSecondary] color.
  /// Used for - [possibleContainer], [ParticipantOverlayWidget] tooltip, etc.
  final Color? onSecondaryOpacity30;

  /// 20% opacity of the [onSecondary] color.
  /// Used for - [DockedPanelPadding], [Selector] hover, etc.
  final Color? onSecondaryOpacity20;

  /// Used to set the background [Color] for the overall look.
  final Color background;

  /// [Color] responsible for the helper background color.
  /// It acts as an alternative for background in case we need to highlight
  /// some interface element using a background color other than the main one.
  final Color backgroundAuxiliary;

  /// Slightly lighter [Color] than the standard [backgroundAuxiliary] color.
  final Color backgroundAuxiliaryLight;

  /// [Color] represents an even lighter shade than the standard [backgroundAuxiliary] color.
  final Color backgroundAuxiliaryLighter;

  /// Lightest possible shade of the [Color] for the [backgroundAuxiliary] color.
  final Color backgroundAuxiliaryLightest;

  /// Neutral [Color] that does not compete with the main content of the application.
  /// For example for text, BoxShadow's, etc.
  final Color onBackground;

  /// 98% opacity of the [onBackground] color.
  /// Used for - [mobileCall], [ColoredBox], etc.
  final Color? onBackgroundOpacity2;

  /// 94% opacity of the [onBackground] color.
  /// Used for - [HomeView.background], [AddContactListTile] selectedTileColor, etc.
  final Color? onBackgroundOpacity7;

  /// 88% opacity of the [onBackground] color.
  /// Used for - [BlockedField], [SendField], [DesktopControls] buildHitArea, etc.
  final Color? onBackgroundOpacity13;

  /// 81% opacity of the [onBackground] color.
  /// Used for - [ParticipantDecoratorWidget], [CustomBoxShadow], etc.
  final Color? onBackgroundOpacity20;

  /// 74% opacity of the [onBackground] color.
  /// Used for - [desktopCall] Secondary panel shadow, [HintWidget] card shadow, etc.
  final Color? onBackgroundOpacity27;

  /// 67% opacity of the [onBackground] color.
  /// Used for - [ChatView] id, [ChatInfoView], etc.
  final Color? onBackgroundOpacity33;

  /// 60% opacity of the [onBackground] color.
  /// Used for - mobile and desktop [ChatView] bottom bar, etc.
  final Color? onBackgroundOpacity40;

  /// 50% opacity of the [onBackground] color.
  /// Used for - [MessageFieldView] attachment.
  final Color? onBackgroundOpacity50;

  /// 44% opacity of the [onBackground] color.
  /// Used for - [CallView] primary view, [ParticipantRedialing], etc.
  final Color? onBackgroundOpacity56;

  /// 25% opacity of the [onBackground] color.
  /// Used for - [ParticipantConnecting].
  final Color? onBackgroundOpacity63;

  /// Сompletely transparent [Color] that has no visible saturation or brightness.
  /// It is used to indicate the absence of a color or background of the element on which it is used.
  final Color transparent;

  /// Used as an affirmative [Color] for visual confirmation of the action.
  /// For example, for the "Accept call" buttons.
  final Color acceptColor;

  /// [Color] is used as an auxiliary color to display pleasant action confirmation messages.
  final Color acceptAuxiliaryColor;

  /// Used to indicate the color of rejection or rejection in various elements of the user interface.
  /// For example, on the "Cancel call" button.
  final Color declineColor;

  /// [Color] used to indicate dangerous or critical elements in the user interface,
  /// such as error messages or warnings about a potential threat.
  final Color dangerColor;

  /// [Color] used to indicate caution, risk, or a potential threat.
  final Color warningColor;

  /// [Colors] refer to the range of colors that can be used for a profile picture.
  /// These colors may predefined or customizable and are selected to help differentiate between users or to provide a visual cue for different types of accounts.
  final List<Color> userColors;

  static Palette lerpColors(Palette color, Palette? other, double t) {
    if (other is! Palette) {
      return color;
    }

    return Palette(
      primary: Color.lerp(color.primary, other.primary, t) as Color,
      primaryHighlight:
          Color.lerp(color.primaryHighlight, other.primaryHighlight, t)
              as Color,
      primaryHighlightShiny: Color.lerp(
          color.primaryHighlightShiny, other.primaryHighlightShiny, t) as Color,
      primaryHighlightShinier: Color.lerp(
              color.primaryHighlightShinier, other.primaryHighlightShinier, t)
          as Color,
      primaryHighlightShiniest: Color.lerp(
              color.primaryHighlightShiniest, other.primaryHighlightShiniest, t)
          as Color,
      onPrimary: Color.lerp(color.onPrimary, other.onPrimary, t) as Color,
      onPrimaryOpacity7:
          Color.lerp(color.onPrimaryOpacity7, other.onPrimaryOpacity7, t)
              as Color,
      onPrimaryOpacity25:
          Color.lerp(color.onPrimaryOpacity25, other.onPrimaryOpacity25, t)
              as Color,
      onPrimaryOpacity40:
          Color.lerp(color.onPrimaryOpacity40, other.onPrimaryOpacity40, t)
              as Color,
      onPrimaryOpacity50:
          Color.lerp(color.onPrimaryOpacity50, other.onPrimaryOpacity50, t)
              as Color,
      onPrimaryOpacity60:
          Color.lerp(color.onPrimaryOpacity60, other.onPrimaryOpacity60, t)
              as Color,
      onPrimaryOpacity80:
          Color.lerp(color.onPrimaryOpacity80, other.onPrimaryOpacity80, t)
              as Color,
      secondary: Color.lerp(color.secondary, other.secondary, t) as Color,
      secondaryHighlight:
          Color.lerp(color.secondaryHighlight, other.secondaryHighlight, t)
              as Color,
      secondaryHighlightDark: Color.lerp(
              color.secondaryHighlightDark, other.secondaryHighlightDark, t)
          as Color,
      secondaryHighlightDarkest: Color.lerp(color.secondaryHighlightDarkest,
          other.secondaryHighlightDarkest, t) as Color,
      secondaryBackground:
          Color.lerp(color.secondaryBackground, other.secondaryBackground, t)
              as Color,
      secondaryBackgroundLight: Color.lerp(
              color.secondaryBackgroundLight, other.secondaryBackgroundLight, t)
          as Color,
      secondaryBackgroundLightest: Color.lerp(color.secondaryBackgroundLightest,
          other.secondaryBackgroundLightest, t) as Color,
      secondaryOpacity73:
          Color.lerp(color.secondaryOpacity73, other.secondaryOpacity73, t)
              as Color,
      secondaryOpacity87:
          Color.lerp(color.secondaryOpacity87, other.secondaryOpacity87, t)
              as Color,
      onSecondary: Color.lerp(color.onSecondary, other.onSecondary, t) as Color,
      onSecondaryOpacity88:
          Color.lerp(color.onSecondaryOpacity88, other.onSecondaryOpacity88, t)
              as Color,
      onSecondaryOpacity60:
          Color.lerp(color.onSecondaryOpacity60, other.onSecondaryOpacity60, t)
              as Color,
      onSecondaryOpacity50:
          Color.lerp(color.onSecondaryOpacity50, other.onSecondaryOpacity50, t)
              as Color,
      onSecondaryOpacity30:
          Color.lerp(color.onSecondaryOpacity30, other.onSecondaryOpacity30, t)
              as Color,
      onSecondaryOpacity20:
          Color.lerp(color.onSecondaryOpacity20, other.onSecondaryOpacity20, t)
              as Color,
      background: Color.lerp(color.background, other.background, t) as Color,
      backgroundAuxiliary:
          Color.lerp(color.backgroundAuxiliary, other.backgroundAuxiliary, t)
              as Color,
      backgroundAuxiliaryLight: Color.lerp(
              color.backgroundAuxiliaryLight, other.backgroundAuxiliaryLight, t)
          as Color,
      backgroundAuxiliaryLighter: Color.lerp(color.backgroundAuxiliaryLighter,
          other.backgroundAuxiliaryLighter, t) as Color,
      backgroundAuxiliaryLightest: Color.lerp(color.backgroundAuxiliaryLightest,
          other.backgroundAuxiliaryLightest, t) as Color,
      onBackground:
          Color.lerp(color.onBackground, other.onBackground, t) as Color,
      onBackgroundOpacity2:
          Color.lerp(color.onBackgroundOpacity2, other.onBackgroundOpacity2, t)
              as Color,
      onBackgroundOpacity7:
          Color.lerp(color.onBackgroundOpacity7, other.onBackgroundOpacity7, t)
              as Color,
      onBackgroundOpacity13: Color.lerp(
          color.onBackgroundOpacity13, other.onBackgroundOpacity13, t) as Color,
      onBackgroundOpacity20: Color.lerp(
          color.onBackgroundOpacity20, other.onBackgroundOpacity20, t) as Color,
      onBackgroundOpacity27: Color.lerp(
          color.onBackgroundOpacity27, other.onBackgroundOpacity27, t) as Color,
      onBackgroundOpacity33: Color.lerp(
          color.onBackgroundOpacity33, other.onBackgroundOpacity33, t) as Color,
      onBackgroundOpacity40: Color.lerp(
          color.onBackgroundOpacity40, other.onBackgroundOpacity40, t) as Color,
      onBackgroundOpacity56: Color.lerp(
          color.onBackgroundOpacity56, other.onBackgroundOpacity56, t) as Color,
      onBackgroundOpacity63: Color.lerp(
          color.onBackgroundOpacity63, other.onBackgroundOpacity63, t) as Color,
      onBackgroundOpacity50: Color.lerp(
          color.onBackgroundOpacity50, other.onBackgroundOpacity50, t) as Color,
      transparent: Color.lerp(color.transparent, other.transparent, t) as Color,
      acceptColor: Color.lerp(color.acceptColor, other.acceptColor, t) as Color,
      acceptAuxiliaryColor:
          Color.lerp(color.acceptAuxiliaryColor, other.acceptAuxiliaryColor, t)
              as Color,
      declineColor:
          Color.lerp(color.declineColor, other.declineColor, t) as Color,
      dangerColor: Color.lerp(color.dangerColor, other.dangerColor, t) as Color,
      warningColor:
          Color.lerp(color.warningColor, other.warningColor, t) as Color,
      userColors: [],
    );
  }
}
