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
    ColorScheme colors = ThemeData.light().colorScheme.copyWith(
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
            transparent: const Color(0x00000000),
            transparentOpacity98: const Color(0x04000000),
            transparentOpacity94: const Color(0x11000000),
            transparentOpacity88: const Color(0x22000000),
            transparentOpacity85: const Color(0x25000000), //Later
            transparentOpacity81: const Color(0x33000000),
            transparentOpacity74: const Color(0x44000000),
            transparentOpacity67: const Color(0x55000000),
            transparentOpacity60: const Color(0x66000000),
            transparentOpacity50: const Color(0x80000000),
            transparentOpacity44: const Color(0x90000000),
            transparentOpacity25: const Color(0xA0000000),
            transparentOpacity10: const Color(0xE6000000),
            primary: const Color(0xFF888888),
            primaryCharcoal: const Color(0xFF222222),
            primaryCharcoalLight: const Color(0xFF444444),
            primaryCharcoalLightest: const Color(0xFF666666),
            primarySlate: const Color(0xFFF5F5F5),
            primarySlateDark: const Color(0xFFDEDEDE),
            primarySlateDarkest: const Color(0xFFC0C0C0),
            primaryOpacity20: const Color(0xDD818181),
            primaryOpacity15: const Color(0xBB818181),
            onPrimary: Colors.white,
            onPrimaryOpacity90: const Color(0x11FFFFFF),
            onPrimaryOpacity75: const Color(0x40FFFFFF),
            onPrimaryOpacity60: const Color(0x66FFFFFF),
            onPrimaryOpacity50: const Color(0x80FFFFFF),
            onPrimaryOpacity40: const Color(0x99FFFFFF),
            onPrimaryOpacity20: const Color(0xCCFFFFFF),
            onPrimaryOpacity10: const Color(0xE6FFFFFF),
            secondary: const Color(0xFF63B4FF),
            secondaryAzure: Colors.blue,
            secondaryAzureLight: const Color(0xFF00A3FF),
            //тернарка с backgroundCobaltLighter
            secondaryAzureLighter: const Color(0xFFB6DCFF),
            secondaryAzureLightest: const Color(0xFFDBEAFD),
            onSecondary: Colors.white,

            /// onSecondaryOpacity:
            /// onSecondaryOpacity2:
            background: const Color(0xFFF5F8FA),
            backgroundCobalt: const Color(0xFF0A1724),
            backgroundCobaltLight: const Color(0xFF132131),
            backgroundCobaltLighter: const Color(0xFFE6F1FE),
            backgroundCobaltLightest: const Color(0xFFF4F9FF),
            // СВЕТЛЕЕ
            /// backgroundAzureOpacity:
            /// Применять к ним различные нейминги цветов.
            // ТЕМНЕЕ
            /// backgroundCobaltOpacity
            onBackground: Colors.black,
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
    required this.primary,
    required this.primaryCharcoal,
    required this.primaryCharcoalLight,
    required this.primaryCharcoalLightest,
    required this.primarySlate,
    required this.primarySlateDark,
    required this.primarySlateDarkest,
    required this.primaryOpacity20,
    required this.primaryOpacity15,
    required this.onPrimary,
    required this.onPrimaryOpacity90,
    required this.onPrimaryOpacity75,
    required this.onPrimaryOpacity60,
    required this.onPrimaryOpacity50,
    required this.onPrimaryOpacity40,
    required this.onPrimaryOpacity20,
    required this.onPrimaryOpacity10,
    required this.secondary,
    required this.secondaryAzure,
    required this.secondaryAzureLight,
    required this.secondaryAzureLighter,
    required this.secondaryAzureLightest,
    required this.backgroundCobalt,
    required this.backgroundCobaltLight,
    required this.backgroundCobaltLighter,
    required this.backgroundCobaltLightest,
    required this.onSecondary,
    required this.background,
    required this.onBackground,
    required this.transparent,
    required this.transparentOpacity98,
    required this.transparentOpacity94,
    required this.transparentOpacity88,
    required this.transparentOpacity85,
    required this.transparentOpacity81,
    required this.transparentOpacity74,
    required this.transparentOpacity67,
    required this.transparentOpacity60,
    required this.transparentOpacity50,
    required this.transparentOpacity44,
    required this.transparentOpacity25,
    required this.transparentOpacity10,
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

  /// TODO: DOCS
  final Color primary;

  final Color primaryCharcoal;

  final Color primaryCharcoalLight;

  final Color primaryCharcoalLightest;

  final Color primarySlate;

  final Color primarySlateDark;

  final Color primarySlateDarkest;

  final Color primaryOpacity20;

  final Color primaryOpacity15;

  final Color onPrimary;

  /// Color(0x11FFFFFF)(93%)
  final Color onPrimaryOpacity90;

  /// Color(0x40FFFFFF)
  final Color onPrimaryOpacity75;

  /// Color(0x66FFFFFF)
  final Color onPrimaryOpacity60;

  /// Color(0x80FFFFFF)
  final Color onPrimaryOpacity50;

  /// Color(0x99FFFFFF)
  final Color onPrimaryOpacity40;

  /// Color(0xCCFFFFFF)
  final Color onPrimaryOpacity20;

  /// Color(0xE6FFFFFF)
  final Color onPrimaryOpacity10;

  final Color secondary;

  final Color secondaryAzure;

  final Color secondaryAzureLight;

  final Color secondaryAzureLighter;

  final Color secondaryAzureLightest;

  final Color backgroundCobalt;

  final Color backgroundCobaltLight;

  final Color backgroundCobaltLighter;

  final Color backgroundCobaltLightest;

  final Color onSecondary;

  final Color background;

  final Color onBackground;

  final Color transparent;

  /// Same as Color(0x04000000)
  final Color transparentOpacity98;

  /// Same as Color(0x11000000) and 0x0D000000
  final Color transparentOpacity94;

  /// Same as Color(0x22000000)
  final Color transparentOpacity88;

  /// Same as Color(0x25000000)
  final Color transparentOpacity85;

  /// Same as Color(0x33000000)
  final Color transparentOpacity81;

  /// Same as Color(0x44000000)
  final Color transparentOpacity74;

  /// Same as Color(0x55000000)
  final Color transparentOpacity67;

  /// Same as Color(0x66000000)
  final Color transparentOpacity60;

  /// Same as Color(0x80000000)
  final Color transparentOpacity50;

  /// Same as Color(0x90000000) and black54
  final Color transparentOpacity44;

  /// Color(0xA0000000)
  final Color transparentOpacity25;

  /// Colors.black.with(0.9)
  final Color transparentOpacity10;

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
    Color? primary,
    Color? primaryCharcoal,
    Color? primaryCharcoalLight,
    Color? primaryCharcoalLighter,
    Color? primaryCharcoalLightest,
    Color? primarySlate,
    Color? primarySlateDark,
    Color? primarySlateDarkest,
    Color? primaryOpacity20,
    Color? primaryOpacity15,
    Color? onPrimary,
    Color? onPrimaryOpacity90,
    Color? onPrimaryOpacity75,
    Color? onPrimaryOpacity60,
    Color? onPrimaryOpacity50,
    Color? onPrimaryOpacity40,
    Color? onPrimaryOpacity20,
    Color? onPrimaryOpacity10,
    Color? secondary,
    Color? secondaryNative,
    Color? secondaryAzure,
    Color? secondaryAzureLight,
    Color? secondaryAzureLighter,
    Color? secondaryAzureLightest,
    Color? backgroundCobalt,
    Color? backgroundCobaltLight,
    Color? backgroundCobaltLighter,
    Color? backgroundCobaltLightest,
    Color? onSecondary,
    Color? background,
    Color? onBackground,
    Color? transparent,
    Color? transparentOpacity98,
    Color? transparentOpacity94,
    Color? transparentOpacity88,
    Color? transparentOpacity85,
    Color? transparentOpacity81,
    Color? transparentOpacity74,
    Color? transparentOpacity67,
    Color? transparentOpacity60,
    Color? transparentOpacity50,
    Color? transparentOpacity44,
    Color? transparentOpacity25,
    Color? transparentOpacity10,
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
      primary: primary ?? this.primary,
      primaryCharcoal: primaryCharcoal ?? this.primaryCharcoal,
      primaryCharcoalLight: primaryCharcoalLight ?? this.primaryCharcoalLight,
      primaryCharcoalLightest:
          primaryCharcoalLightest ?? this.primaryCharcoalLightest,
      primarySlate: primarySlate ?? this.primarySlate,
      primarySlateDark: primarySlateDark ?? this.primarySlateDark,
      primarySlateDarkest: primarySlateDarkest ?? this.primarySlateDarkest,
      primaryOpacity20: primaryOpacity20 ?? this.primaryOpacity20,
      primaryOpacity15: primaryOpacity15 ?? this.primaryOpacity15,
      onPrimary: onPrimary ?? this.onPrimary,
      onPrimaryOpacity90: onPrimaryOpacity90 ?? this.onPrimaryOpacity90,
      onPrimaryOpacity75: onPrimaryOpacity75 ?? this.onPrimaryOpacity75,
      onPrimaryOpacity60: onPrimaryOpacity60 ?? this.onPrimaryOpacity60,
      onPrimaryOpacity50: onPrimaryOpacity50 ?? this.onPrimaryOpacity50,
      onPrimaryOpacity40: onPrimaryOpacity40 ?? this.onPrimaryOpacity40,
      onPrimaryOpacity20: onPrimaryOpacity20 ?? this.onPrimaryOpacity20,
      onPrimaryOpacity10: onPrimaryOpacity10 ?? this.onPrimaryOpacity10,
      secondary: secondary ?? this.secondary,
      secondaryAzure: secondaryAzure ?? this.secondaryAzure,
      secondaryAzureLight: secondaryAzure ?? this.secondaryAzure,
      secondaryAzureLighter: secondaryAzure ?? this.secondaryAzure,
      secondaryAzureLightest: secondaryAzure ?? this.secondaryAzure,
      backgroundCobalt: secondaryAzure ?? this.secondaryAzure,
      backgroundCobaltLight: secondaryAzure ?? this.secondaryAzure,
      backgroundCobaltLighter: secondaryAzure ?? this.secondaryAzure,
      backgroundCobaltLightest: secondaryAzure ?? this.secondaryAzure,
      onSecondary: onSecondary ?? this.onSecondary,
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      transparent: transparent ?? this.transparent,
      transparentOpacity98: transparentOpacity98 ?? this.transparentOpacity98,
      transparentOpacity94: transparentOpacity94 ?? this.transparentOpacity94,
      transparentOpacity88: transparentOpacity88 ?? this.transparentOpacity88,
      transparentOpacity85: transparentOpacity85 ?? this.transparentOpacity85,
      transparentOpacity81: transparentOpacity81 ?? this.transparentOpacity81,
      transparentOpacity74: transparentOpacity74 ?? this.transparentOpacity74,
      transparentOpacity67: transparentOpacity67 ?? this.transparentOpacity67,
      transparentOpacity60: transparentOpacity60 ?? this.transparentOpacity60,
      transparentOpacity50: transparentOpacity50 ?? this.transparentOpacity50,
      transparentOpacity44: transparentOpacity44 ?? this.transparentOpacity44,
      transparentOpacity25: transparentOpacity25 ?? this.transparentOpacity25,
      transparentOpacity10: transparentOpacity10 ?? this.transparentOpacity10,
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
      primary: Color.lerp(primary, other.primary, t)!,
      primaryCharcoal: Color.lerp(primaryCharcoal, other.primaryCharcoal, t)!,
      primaryCharcoalLight:
          Color.lerp(primaryCharcoalLight, other.primaryCharcoalLight, t)!,
      primaryCharcoalLightest: Color.lerp(
          primaryCharcoalLightest, other.primaryCharcoalLightest, t)!,
      primarySlate: Color.lerp(primarySlate, other.primarySlate, t)!,
      primarySlateDark:
          Color.lerp(primarySlateDark, other.primarySlateDark, t)!,
      primarySlateDarkest:
          Color.lerp(primarySlateDarkest, other.primarySlateDarkest, t)!,
      primaryOpacity20:
          Color.lerp(primaryOpacity20, other.primaryOpacity20, t)!,
      primaryOpacity15:
          Color.lerp(primaryOpacity15, other.primaryOpacity15, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onPrimaryOpacity90: Color.lerp(
        onPrimaryOpacity90,
        other.onPrimaryOpacity90,
        t,
      )!,
      onPrimaryOpacity75:
          Color.lerp(onPrimaryOpacity75, other.onPrimaryOpacity75, t)!,
      onPrimaryOpacity60:
          Color.lerp(onPrimaryOpacity60, other.onPrimaryOpacity60, t)!,
      onPrimaryOpacity50:
          Color.lerp(onPrimaryOpacity50, other.onPrimaryOpacity50, t)!,
      onPrimaryOpacity40:
          Color.lerp(onPrimaryOpacity40, other.onPrimaryOpacity40, t)!,
      onPrimaryOpacity20:
          Color.lerp(onPrimaryOpacity20, other.onPrimaryOpacity20, t)!,
      onPrimaryOpacity10:
          Color.lerp(onPrimaryOpacity10, other.onPrimaryOpacity10, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryAzure: Color.lerp(secondaryAzure, other.secondaryAzure, t)!,
      secondaryAzureLight:
          Color.lerp(secondaryAzureLight, other.secondaryAzureLight, t)!,
      secondaryAzureLighter:
          Color.lerp(secondaryAzureLighter, other.secondaryAzureLighter, t)!,
      secondaryAzureLightest:
          Color.lerp(secondaryAzureLightest, other.secondaryAzureLightest, t)!,
      backgroundCobalt:
          Color.lerp(backgroundCobalt, other.backgroundCobalt, t)!,
      backgroundCobaltLight:
          Color.lerp(backgroundCobaltLight, other.backgroundCobaltLight, t)!,
      backgroundCobaltLighter: Color.lerp(
          backgroundCobaltLighter, other.backgroundCobaltLighter, t)!,
      backgroundCobaltLightest: Color.lerp(
          backgroundCobaltLightest, other.backgroundCobaltLightest, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      transparent: Color.lerp(transparent, other.transparent, t)!,
      transparentOpacity98:
          Color.lerp(transparentOpacity98, other.transparentOpacity98, t)!,
      transparentOpacity94:
          Color.lerp(transparentOpacity94, other.transparentOpacity94, t)!,
      transparentOpacity88:
          Color.lerp(transparentOpacity88, other.transparentOpacity88, t)!,
      transparentOpacity85:
          Color.lerp(transparentOpacity85, other.transparentOpacity85, t)!,
      transparentOpacity81:
          Color.lerp(transparentOpacity81, other.transparentOpacity81, t)!,
      transparentOpacity74:
          Color.lerp(transparentOpacity74, other.transparentOpacity74, t)!,
      transparentOpacity67:
          Color.lerp(transparentOpacity67, other.transparentOpacity67, t)!,
      transparentOpacity60:
          Color.lerp(transparentOpacity60, other.transparentOpacity60, t)!,
      transparentOpacity50:
          Color.lerp(transparentOpacity50, other.transparentOpacity50, t)!,
      transparentOpacity44:
          Color.lerp(transparentOpacity44, other.transparentOpacity44, t)!,
      transparentOpacity25:
          Color.lerp(transparentOpacity25, other.transparentOpacity25, t)!,
      transparentOpacity10:
          Color.lerp(transparentOpacity10, other.transparentOpacity10, t)!,
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
