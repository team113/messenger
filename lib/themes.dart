// ignore_for_file: public_member_api_docs, sort_constructors_first
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
    final ColorScheme colors = ThemeData.light().colorScheme.copyWith(
          primary: const Color(0xFF888888),
          onPrimary: Colors.white,
          secondary: const Color(0xFF63B4FF),
          onSecondary: Colors.white,
          background: const Color(0xFFF5F8FA),
          onBackground: Colors.black,
        );

    SystemChrome.setSystemUIOverlayStyle(
      colors.brightness == Brightness.light
          ? SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
              systemStatusBarContrastEnforced: false,
              systemNavigationBarContrastEnforced: false,
              systemNavigationBarIconBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.light,
    );

    const TextStyle textStyle = TextStyle(
      fontFamily: 'SFUI',
      fontFamilyFallback: ['.SF UI Display'],
      color: Colors.black,
      fontSize: 17,
      fontWeight: FontWeight.w400,
    );

    return ThemeData.light().copyWith(
        extensions: [
          Style(
            colors: Palette(
              primary: const Color(0xFF63B4FF),
              primaryBackground: const Color(0xFF222222),
              primaryBackgroundLight: const Color(0xFF444444),
              primaryBackgroundLightest: const Color(0xFF666666),
              primaryHighlight: const Color(0xFFF5F5F5),
              primaryHighlightDark: const Color(0xFFDEDEDE),
              primaryHighlightDarkest: const Color(0xFFC0C0C0),
              primaryOpacity20: const Color(0xDD818181),
              primaryOpacity15: const Color(0xBB818181),
              onPrimary: Colors.white,
              onPrimaryOpacity90: const Color(0x11FFFFFF),
              onPrimaryOpacity75: const Color(0x40FFFFFF),
              onPrimaryOpacity60: const Color(0x66FFFFFF),
              onPrimaryOpacity50: const Color(0x80FFFFFF),
              onPrimaryOpacity40: const Color(0x99FFFFFF),
              onPrimaryOpacity20: const Color(0xCCFFFFFF),
              secondary: const Color(0xFF888888),
              secondaryHighlight: Colors.blue,
              secondaryHighlightShiny: const Color(0xFF00A3FF),
              secondaryHighlightShinier: const Color(0xFFB6DCFF),
              secondaryHighlightShiniest: const Color(0xFFDBEAFD),
              onSecondary: const Color(0xBB1F3C5D),
              onSecondaryOpacity90: const Color(0xE0165084),
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
              onBackgroundOpacity98: const Color(0x04000000),
              onBackgroundOpacity94: const Color(0x11000000),
              onBackgroundOpacity88: const Color(0x22000000),
              onBackgroundOpacity81: const Color(0x33000000),
              onBackgroundOpacity74: const Color(0x44000000),
              onBackgroundOpacity67: const Color(0x55000000),
              onBackgroundOpacity60: const Color(0x66000000),
              onBackgroundOpacity50: const Color(0x80000000),
              onBackgroundOpacity44: const Color(0x90000000),
              onBackgroundOpacity25: const Color(0xA0000000),
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
            ),
            barrierColor: const Color(0xBB000000),
            boldBody: textStyle.copyWith(color: Colors.black, fontSize: 17),
            cardBlur: 5,
            cardBorder: Border.all(color: const Color(0xFFEBEBEB), width: 0.5),
            cardColor: Colors.white.withOpacity(0.95),
            cardHoveredBorder:
                Border.all(color: const Color(0xFFDAEDFF), width: 0.5),
            cardHoveredColor: const Color(0xFFF4F9FF),
            cardRadius: BorderRadius.circular(14),
            cardSelectedColor: const Color(0xFFD7ECFF),
            contextMenuBackgroundColor: const Color(0xFFF2F2F2),
            contextMenuHoveredColor: const Color(0xFFE5E7E9),
            contextMenuRadius: BorderRadius.circular(10),
            linkStyle: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
              decorationThickness: 2,
            ),
            messageColor: Colors.white,
            primaryBorder:
                Border.all(color: const Color(0xFFDADADA), width: 0.5),
            readMessageColor: const Color(0xFFD2E3F9),
            secondaryBorder:
                Border.all(color: const Color(0xFFB9D9FA), width: 0.5),
            sidebarColor: const Color(0x66FFFFFF),
            systemMessageBorder:
                Border.all(color: const Color(0xFFD2D2D2), width: 0.5),
            systemMessageColor: const Color(0xFFEFEFEF).withOpacity(0.95),
            systemMessageStyle: textStyle.copyWith(
              color: colors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w300,
            ),
            unreadMessageColor: const Color(0xFFF4F9FF),
          ),
        ],
        colorScheme: colors,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: ThemeData.light().appBarTheme.copyWith(
              backgroundColor: colors.background,
              foregroundColor: colors.primary,
              iconTheme: ThemeData.light()
                  .appBarTheme
                  .iconTheme
                  ?.copyWith(color: colors.primary),
              actionsIconTheme: ThemeData.light()
                  .appBarTheme
                  .iconTheme
                  ?.copyWith(color: colors.primary),
              systemOverlayStyle: const SystemUiOverlayStyle(
                systemNavigationBarColor: Colors.blue,
                statusBarColor: Colors.transparent,
              ),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: textStyle.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w300,
                fontSize: 18,
              ),
            ),
        tabBarTheme: ThemeData.light().tabBarTheme.copyWith(
              labelColor: colors.secondary,
              unselectedLabelColor: colors.primary,
            ),
        primaryIconTheme:
            const IconThemeData.fallback().copyWith(color: colors.primary),
        iconTheme: ThemeData.light().iconTheme.copyWith(color: Colors.black),
        textTheme: Typography.blackCupertino.copyWith(
          displayLarge: textStyle.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w300,
            fontSize: 24,
          ),
          displayMedium: textStyle.copyWith(
            color: colors.primary,
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
            color: colors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w300,
          ),
          bodyLarge:
              textStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w300),
          bodyMedium:
              textStyle.copyWith(fontSize: 13, fontWeight: FontWeight.w300),
          bodySmall: textStyle.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w300,
            fontSize: 13,
          ),
        ),
        inputDecorationTheme: ThemeData.light().inputDecorationTheme.copyWith(
              focusColor: colors.secondary,
              hoverColor: Colors.transparent,
              fillColor: colors.secondary,
              hintStyle: textStyle.copyWith(
                color: const Color(0xFFC4C4C4),
                fontSize: 15,
                fontWeight: FontWeight.w300,
              ),
              labelStyle: textStyle.copyWith(
                color: const Color(0xFFC4C4C4),
                fontSize: 15,
                fontWeight: FontWeight.w300,
              ),
              errorStyle: textStyle.copyWith(color: Colors.red, fontSize: 13),
              helperStyle: textStyle.copyWith(
                color: const Color(0xFFC4C4C4),
                fontSize: 15,
                fontWeight: FontWeight.w300,
              ),
              prefixStyle: textStyle.copyWith(
                color: const Color(0xFFC4C4C4),
                fontSize: 15,
                fontWeight: FontWeight.w300,
              ),
              suffixStyle: textStyle.copyWith(
                color: const Color(0xFFC4C4C4),
                fontSize: 15,
                fontWeight: FontWeight.w300,
              ),
              counterStyle: textStyle.copyWith(
                color: const Color(0xFFC4C4C4),
                fontSize: 13,
                fontWeight: FontWeight.w300,
              ),
              floatingLabelStyle: textStyle.copyWith(
                color: const Color(0xFFC4C4C4),
                fontSize: 15,
                fontWeight: FontWeight.w300,
              ),
              errorMaxLines: 5,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide:
                    const BorderSide(width: 2, color: Color(0xFFD0D0D0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
              ),
            ),
        textSelectionTheme: ThemeData.light().textSelectionTheme.copyWith(
              cursorColor: colors.secondary,
              selectionHandleColor: colors.secondary,
            ),
        floatingActionButtonTheme:
            ThemeData.light().floatingActionButtonTheme.copyWith(
                  backgroundColor: colors.secondary,
                  foregroundColor: colors.onSecondary,
                ),
        bottomNavigationBarTheme:
            ThemeData.light().bottomNavigationBarTheme.copyWith(
                  backgroundColor: colors.background,
                  selectedItemColor: colors.secondary,
                  unselectedItemColor: colors.primary,
                ),
        progressIndicatorTheme: ThemeData.light()
            .progressIndicatorTheme
            .copyWith(color: colors.secondary),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
            textStyle: textStyle.copyWith(color: colors.primary, fontSize: 17),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: colors.primary,
            minimumSize: const Size(100, 60),
            maximumSize: const Size(250, 60),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            side: BorderSide(width: 1, color: colors.primary),
            textStyle: textStyle.copyWith(color: colors.primary, fontSize: 17),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.secondary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.all(12),
            textStyle: textStyle.copyWith(color: colors.primary, fontSize: 15),
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
              return const Color(0xFF63B4FF);
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

  /// Сontains a set of properties representing the colors of the application.
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
    Color? primaryBackground,
    Color? primaryBackgroundLight,
    Color? primaryBackgroundLighter,
    Color? primaryBackgroundLightest,
    Color? primaryHighlight,
    Color? primaryHighlightDark,
    Color? primaryHighlightDarkest,
    Color? primaryOpacity20,
    Color? primaryOpacity15,
    Color? onPrimary,
    Color? onPrimaryOpacity90,
    Color? onPrimaryOpacity75,
    Color? onPrimaryOpacity60,
    Color? onPrimaryOpacity50,
    Color? onPrimaryOpacity40,
    Color? onPrimaryOpacity20,
    Color? secondary,
    Color? secondaryNative,
    Color? secondaryHighlight,
    Color? secondaryHighlightShiny,
    Color? secondaryHighlightShinier,
    Color? secondaryHighlightShiniest,
    Color? onSecondary,
    Color? onSecondaryOpacity90,
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
    Color? onBackgroundOpacity98,
    Color? onBackgroundOpacity94,
    Color? onBackgroundOpacity88,
    Color? onBackgroundOpacity81,
    Color? onBackgroundOpacity74,
    Color? onBackgroundOpacity67,
    Color? onBackgroundOpacity60,
    Color? onBackgroundOpacity50,
    Color? onBackgroundOpacity44,
    Color? onBackgroundOpacity25,
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
      colors: Palette(
        primary: Color.lerp(colors.primary, other.colors.primary, t)!,
        primaryBackground: Color.lerp(
            colors.primaryBackground, other.colors.primaryBackground, t)!,
        primaryBackgroundLight: Color.lerp(colors.primaryBackgroundLight,
            other.colors.primaryBackgroundLight, t)!,
        primaryBackgroundLightest: Color.lerp(colors.primaryBackgroundLightest,
            other.colors.primaryBackgroundLightest, t)!,
        primaryHighlight: Color.lerp(
            colors.primaryHighlight, other.colors.primaryHighlight, t)!,
        primaryHighlightDark: Color.lerp(
            colors.primaryHighlightDark, other.colors.primaryHighlightDark, t)!,
        primaryHighlightDarkest: Color.lerp(colors.primaryHighlightDarkest,
            other.colors.primaryHighlightDarkest, t)!,
        primaryOpacity20: Color.lerp(
            colors.primaryOpacity20, other.colors.primaryOpacity20, t)!,
        primaryOpacity15: Color.lerp(
            colors.primaryOpacity15, other.colors.primaryOpacity15, t)!,
        onPrimary: Color.lerp(colors.onPrimary, other.colors.onPrimary, t)!,
        onPrimaryOpacity90: Color.lerp(
            colors.onPrimaryOpacity90, other.colors.onPrimaryOpacity90, t)!,
        onPrimaryOpacity75: Color.lerp(
            colors.onPrimaryOpacity75, other.colors.onPrimaryOpacity75, t)!,
        onPrimaryOpacity60: Color.lerp(
            colors.onPrimaryOpacity60, other.colors.onPrimaryOpacity60, t)!,
        onPrimaryOpacity50: Color.lerp(
            colors.onPrimaryOpacity50, other.colors.onPrimaryOpacity50, t)!,
        onPrimaryOpacity40: Color.lerp(
            colors.onPrimaryOpacity40, other.colors.onPrimaryOpacity40, t)!,
        onPrimaryOpacity20: Color.lerp(
            colors.onPrimaryOpacity20, other.colors.onPrimaryOpacity20, t)!,
        secondary: Color.lerp(colors.secondary, other.colors.secondary, t)!,
        secondaryHighlight: Color.lerp(
            colors.secondaryHighlight, other.colors.secondaryHighlight, t)!,
        secondaryHighlightShiny: Color.lerp(colors.secondaryHighlightShiny,
            other.colors.secondaryHighlightShiny, t)!,
        secondaryHighlightShinier: Color.lerp(colors.secondaryHighlightShinier,
            other.colors.secondaryHighlightShinier, t)!,
        secondaryHighlightShiniest: Color.lerp(
            colors.secondaryHighlightShiniest,
            other.colors.secondaryHighlightShiniest,
            t)!,
        onSecondary:
            Color.lerp(colors.onSecondary, other.colors.onSecondary, t)!,
        onSecondaryOpacity90: Color.lerp(
            colors.onSecondaryOpacity90, other.colors.onSecondaryOpacity90, t)!,
        onSecondaryOpacity60: Color.lerp(
            colors.onSecondaryOpacity60, other.colors.onSecondaryOpacity60, t)!,
        onSecondaryOpacity50: Color.lerp(
            colors.onSecondaryOpacity50, other.colors.onSecondaryOpacity50, t)!,
        onSecondaryOpacity30: Color.lerp(
            colors.onSecondaryOpacity30, other.colors.onSecondaryOpacity30, t)!,
        onSecondaryOpacity20: Color.lerp(
            colors.onSecondaryOpacity20, other.colors.onSecondaryOpacity20, t)!,
        background: Color.lerp(colors.background, other.colors.background, t)!,
        backgroundAuxiliary: Color.lerp(
            colors.backgroundAuxiliary, other.colors.backgroundAuxiliary, t)!,
        backgroundAuxiliaryLight: Color.lerp(colors.backgroundAuxiliaryLight,
            other.colors.backgroundAuxiliaryLight, t)!,
        backgroundAuxiliaryLighter: Color.lerp(
            colors.backgroundAuxiliaryLighter,
            other.colors.backgroundAuxiliaryLighter,
            t)!,
        backgroundAuxiliaryLightest: Color.lerp(
            colors.backgroundAuxiliaryLightest,
            other.colors.backgroundAuxiliaryLightest,
            t)!,
        onBackground:
            Color.lerp(colors.onBackground, other.colors.onBackground, t)!,
        onBackgroundOpacity98: Color.lerp(colors.onBackgroundOpacity98,
            other.colors.onBackgroundOpacity98, t)!,
        onBackgroundOpacity94: Color.lerp(colors.onBackgroundOpacity94,
            other.colors.onBackgroundOpacity94, t)!,
        onBackgroundOpacity88: Color.lerp(colors.onBackgroundOpacity88,
            other.colors.onBackgroundOpacity88, t)!,
        onBackgroundOpacity81: Color.lerp(colors.onBackgroundOpacity81,
            other.colors.onBackgroundOpacity81, t)!,
        onBackgroundOpacity74: Color.lerp(colors.onBackgroundOpacity74,
            other.colors.onBackgroundOpacity74, t)!,
        onBackgroundOpacity67: Color.lerp(colors.onBackgroundOpacity67,
            other.colors.onBackgroundOpacity67, t)!,
        onBackgroundOpacity60: Color.lerp(colors.onBackgroundOpacity60,
            other.colors.onBackgroundOpacity60, t)!,
        onBackgroundOpacity50: Color.lerp(colors.onBackgroundOpacity50,
            other.colors.onBackgroundOpacity50, t)!,
        onBackgroundOpacity44: Color.lerp(colors.onBackgroundOpacity44,
            other.colors.onBackgroundOpacity44, t)!,
        onBackgroundOpacity25: Color.lerp(colors.onBackgroundOpacity25,
            other.colors.onBackgroundOpacity25, t)!,
        transparent:
            Color.lerp(colors.transparent, other.colors.transparent, t)!,
        acceptColor:
            Color.lerp(colors.acceptColor, other.colors.acceptColor, t)!,
        acceptAuxiliaryColor: Color.lerp(
            colors.acceptAuxiliaryColor, other.colors.acceptAuxiliaryColor, t)!,
        declineColor:
            Color.lerp(colors.declineColor, other.colors.declineColor, t)!,
        dangerColor:
            Color.lerp(colors.dangerColor, other.colors.dangerColor, t)!,
        warningColor:
            Color.lerp(colors.warningColor, other.colors.warningColor, t)!,
        userColors: [],
      ),
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

/// Сontains a set of properties representing the colors of the application.
class Palette {
  /// Main [Color] of the application, used to highlight the active interface elements.
  final Color primary;

  /// Background [Color] for elements associated with the [primary] color.
  /// For example, the background for buttons, pop-ups, dialog boxes, etc.
  final Color primaryBackground;

  /// Light shade of the primary background [Color].
  final Color primaryBackgroundLight;

  /// Lightest shade of the primary background [Color].
  final Color primaryBackgroundLightest;

  /// [Color] for highlighting UI elements, used to highlight the active elements.
  final Color primaryHighlight;

  /// Dark shade of the accent [Color]. Used to create contrast and depth effect.
  final Color primaryHighlightDark;

  /// Darkest shade of the main accent [Color]. It is used to emphasize buttons, labels,
  /// or other user interface elements that should be highlighted and easily visible to the user.
  final Color primaryHighlightDarkest;

  /// 20% opacity of the [primary] color.
  /// Used for - [handRaisedIcon], [element], etc.
  final Color? primaryOpacity20;

  /// 15% opacity of the [primary] color.
  /// Used for - [HintWidget] elements.
  final Color primaryOpacity15;

  ///  [Color] that is used for elements that are displayed on top
  /// of the main color of the application, for example, text on buttons and icons.
  final Color onPrimary;

  /// 90% opacity of the [onPrimary] color.
  /// Used for - [_secondaryTarget] boxes, [DecorationTween], etc.
  final Color onPrimaryOpacity90;

  /// 75% opacity of the [onPrimary] color.
  /// Used for - [BoxDecoration].
  final Color onPrimaryOpacity75;

  /// 60% opacity of the [onPrimary] color.
  /// Used for - [MessageFieldView] containers.
  final Color onPrimaryOpacity60;

  /// 50% opacity of the [onPrimary] color.
  /// Used for - [AcceptVideoButton], [ChewieProgressColors] etc.
  final Color onPrimaryOpacity50;

  /// 40% opacity of the [onPrimary] color.
  /// Used for - [MobileCall] boxes, etc.
  final Color onPrimaryOpacity40;

  /// 20% opacity of the [onPrimary] color.
  /// Used for - [MobileControls] text, etc.
  final Color onPrimaryOpacity20;

  /// [Color] is used to combine with the main color, giving the interface a nice and balanced look.
  /// For example, for lists, the background of some elements and other additional interface elements.
  final Color secondary;

  /// Highlight [Color] of the secondary element.
  /// Used to highlight secondary elements when hovering or when activated.
  final Color secondaryHighlight;

  /// Glowing tone of secondary [Color] that is used to draw the user's attention
  /// to an area of the screen that contains important information.
  final Color secondaryHighlightShiny;

  /// [Color] used to highlight or highlight interface elements of secondary importance with a brighter sheen.
  final Color secondaryHighlightShinier;

  /// Most brilliant and contrasting secondary highlight [Color].
  /// Can be used as a background or to highlight certain elements.
  final Color secondaryHighlightShiniest;

  /// [Color] that is displayed on a secondary color background
  /// is used as an accent color for the interface and does not cause eye strain.
  final Color onSecondary;

  /// 90% opacity of the [onSecondary] color.
  /// Used for - [CallController.panel] box, [SlidingUpPanel], etc.
  final Color onSecondaryOpacity90;

  /// 60% opacity of the [onSecondary] color.
  /// Used for - [launchpad] box, [SlidingUpPanel], etc.
  final Color onSecondaryOpacity60;

  /// 50% opacity of the [onSecondary] color.
  /// Used for - [CallButton], [chat] card, [GalleryPopup] interface, etc.
  final Color onSecondaryOpacity50;

  /// 30% opacity of the [onSecondary] color.
  /// Used for - [possibleContainer], [ParticipantOverlayWidget] tooltip, etc.
  final Color onSecondaryOpacity30;

  /// 20% opacity of the [onSecondary] color.
  /// Used for - [DockedPanelPadding], [Selector] hover, etc.
  final Color onSecondaryOpacity20;

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
  final Color onBackgroundOpacity98;

  /// 94% opacity of the [onBackground] color.
  /// Used for - [HomeView.background], [AddContactListTile] selectedTileColor, etc.
  final Color onBackgroundOpacity94;

  /// 88% opacity of the [onBackground] color.
  /// Used for - [BlockedField], [SendField], [DesktopControls] buildHitArea, etc.
  final Color onBackgroundOpacity88;

  /// 81% opacity of the [onBackground] color.
  /// Used for - [ParticipantDecoratorWidget], [CustomBoxShadow], etc.
  final Color onBackgroundOpacity81;

  /// 74% opacity of the [onBackground] color.
  /// Used for - [desktopCall] Secondary panel shadow, [HintWidget] card shadow, etc.
  final Color onBackgroundOpacity74;

  /// 67% opacity of the [onBackground] color.
  /// Used for - [ChatView] id, [ChatInfoView], etc.
  final Color onBackgroundOpacity67;

  /// 60% opacity of the [onBackground] color.
  /// Used for - mobile and desktop [ChatView] bottom bar, etc.
  final Color onBackgroundOpacity60;

  /// 50% opacity of the [onBackground] color.
  /// Used for - [MessageFieldView] attachment.
  final Color onBackgroundOpacity50;

  /// 44% opacity of the [onBackground] color.
  /// Used for - [CallView] primary view, [ParticipantRedialing], etc.
  final Color onBackgroundOpacity44;

  /// 25% opacity of the [onBackground] color.
  /// Used for - [ParticipantConnecting].
  final Color onBackgroundOpacity25;

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

  Palette({
    required this.primary,
    required this.primaryBackground,
    required this.primaryBackgroundLight,
    required this.primaryBackgroundLightest,
    required this.primaryHighlight,
    required this.primaryHighlightDark,
    required this.primaryHighlightDarkest,
    required this.primaryOpacity20,
    required this.primaryOpacity15,
    required this.onPrimary,
    required this.onPrimaryOpacity90,
    required this.onPrimaryOpacity75,
    required this.onPrimaryOpacity60,
    required this.onPrimaryOpacity50,
    required this.onPrimaryOpacity40,
    required this.onPrimaryOpacity20,
    required this.secondary,
    required this.secondaryHighlight,
    required this.secondaryHighlightShiny,
    required this.secondaryHighlightShinier,
    required this.secondaryHighlightShiniest,
    required this.onSecondary,
    required this.onSecondaryOpacity90,
    required this.onSecondaryOpacity60,
    required this.onSecondaryOpacity50,
    required this.onSecondaryOpacity30,
    required this.onSecondaryOpacity20,
    required this.background,
    required this.backgroundAuxiliary,
    required this.backgroundAuxiliaryLight,
    required this.backgroundAuxiliaryLighter,
    required this.backgroundAuxiliaryLightest,
    required this.onBackground,
    required this.onBackgroundOpacity98,
    required this.onBackgroundOpacity94,
    required this.onBackgroundOpacity88,
    required this.onBackgroundOpacity81,
    required this.onBackgroundOpacity74,
    required this.onBackgroundOpacity67,
    required this.onBackgroundOpacity60,
    required this.onBackgroundOpacity50,
    required this.onBackgroundOpacity44,
    required this.onBackgroundOpacity25,
    required this.transparent,
    required this.acceptColor,
    required this.acceptAuxiliaryColor,
    required this.declineColor,
    required this.dangerColor,
    required this.warningColor,
    required this.userColors,
  });
}
