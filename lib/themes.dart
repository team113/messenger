// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import 'package:google_fonts/google_fonts.dart';

/// Application themes constants.
class Themes {
  /// Returns a light theme.
  static ThemeData light() {
    final ColorScheme colors = ThemeData.light().colorScheme.copyWith(
          background: const Color(0xFFF5F8FA),
          primary: const Color(0xFF888888),
          secondary: const Color(0xFF63B4FF),
          onBackground: Colors.black,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        );

    SystemChrome.setSystemUIOverlayStyle(colors.brightness == Brightness.light
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light);

    return ThemeData.light().copyWith(
        extensions: [
          Style(
            boldBody: GoogleFonts.roboto(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w400,
            ),
            cardRadius: BorderRadius.circular(14),
            cardColor: Colors.white.withOpacity(0.95),
            cardBlur: 5,
            cardBorder: Border.all(
              color: const Color(0xFFEBEBEB),
              width: 0.5,
            ),
            primaryCardColor: const Color.fromRGBO(210, 227, 249, 1),
            primaryBorder: Border.all(
              color: const Color(0xFFB9D9FA),
              width: 0.5,
            ),
            hoveredBorderUnselected: Border.all(
              color: const Color(0xFFDAEDFF),
              width: 0.5,
            ),
            subtitleColor: const Color(0xFF666666),
            subtitle2Color: const Color(0xFF63B4FF),
            sidebarColor: Colors.white.withOpacity(0.4),
            statusMessageRead: const Color(0xFF63B4FF),
            statusMessageNotRead: const Color(0xFF888888),
            statusMessageError: Colors.red,
            unselectedHoverColor: const Color.fromARGB(255, 244, 249, 255),
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
                statusBarColor: Color(0xFFF8F8F8),
              ),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: GoogleFonts.roboto(
                color: Colors.black,
                fontWeight: FontWeight.w300,
                fontSize: 18,
              ),
            ),
        tabBarTheme: ThemeData.light().tabBarTheme.copyWith(
              labelColor: colors.secondary,
              unselectedLabelColor: colors.primary,
            ),
        primaryTextTheme: ThemeData.light()
            .primaryTextTheme
            .copyWith(headline6: TextStyle(color: colors.primary)),
        primaryIconTheme:
            const IconThemeData.fallback().copyWith(color: colors.primary),
        iconTheme: ThemeData.light().iconTheme.copyWith(color: Colors.black),
        textTheme: GoogleFonts.robotoTextTheme().copyWith(
          headline1: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.w300,
            fontSize: 24,
          ),
          headline2: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.w300,
            fontSize: 15.4,
          ),
          headline3: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w300,
            fontSize: 18,
          ),
          headline4: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w300,
            fontSize: 18,
          ),
          headline5: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w400,
            fontSize: 18,
          ),
          headline6: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          caption: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.w300,
            fontSize: 13,
          ),
          button: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w300,
            fontSize: 17,
          ),
          overline: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w300,
            fontSize: 17,
          ),
          subtitle1: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w300,
          ),
          subtitle2: TextStyle(
            color: colors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w300,
          ),
          bodyText1: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w300,
          ),
          bodyText2: const TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w300,
          ),
        ),
        inputDecorationTheme: ThemeData.light().inputDecorationTheme.copyWith(
              focusColor: colors.secondary,
              hoverColor: colors.secondary,
              fillColor: colors.secondary,
              hintStyle: GoogleFonts.roboto(color: colors.primary),
              labelStyle: GoogleFonts.roboto(color: colors.primary),
              errorStyle: GoogleFonts.roboto(color: Colors.red, fontSize: 13),
              errorMaxLines: 5,
              floatingLabelStyle: GoogleFonts.roboto(color: colors.primary),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color: colors.secondary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color: colors.primary),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color: colors.primary),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color: colors.primary),
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
            textStyle: GoogleFonts.roboto(
              color: colors.primary,
              fontSize: 17,
            ),
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
            textStyle: GoogleFonts.roboto(
              color: colors.primary,
              fontSize: 17,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.secondary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.all(12),
            textStyle: GoogleFonts.roboto(
              color: colors.primary,
              fontSize: 15,
            ),
          ),
        ),
        scrollbarTheme: ThemeData.light()
            .scrollbarTheme
            .copyWith(thickness: MaterialStateProperty.all(6)),
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
    Color color = Colors.black,
    Offset offset = Offset.zero,
    double blurRadius = 0,
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
    required this.boldBody,
    required this.cardRadius,
    required this.cardBlur,
    required this.cardColor,
    required this.cardBorder,
    required this.primaryCardColor,
    required this.primaryBorder,
    required this.hoveredBorderUnselected,
    required this.subtitleColor,
    required this.subtitle2Color,
    required this.sidebarColor,
    required this.statusMessageRead,
    required this.statusMessageNotRead,
    required this.statusMessageError,
    required this.unselectedHoverColor,
  });

  /// [TextStyle] to use in the body to make content readable.
  final TextStyle boldBody;

  /// [BorderRadius] to use .
  final BorderRadius cardRadius;

  /// Blur to use in sidebar for chats.
  final double cardBlur;

  /// [Color] to use in sidebar for chats if chat is not selected.
  final Color cardColor;

  /// [Border] to use in sidebar for chats if chat is not selected.
  final Border cardBorder;

  /// [Color] to use in sidebar for chats if chat is selected.
  final Color primaryCardColor;

  /// [Border] to use in sidebar for chats if chat is selected.
  final Border primaryBorder;

  /// [Border] to use in sidebar for chats.
  final Border hoveredBorderUnselected;

  /// [Color] used for the primary text in lists.
  final Color subtitleColor;

  /// [Color] used for medium emphasis text in lists.
  final Color subtitle2Color;

  /// [Color] of the [HomeView]'s side bar.
  final Color sidebarColor;

  /// Icon [Color] when a message has been read.
  final Color statusMessageRead;

  /// Icon [Color] when a message has not been read.
  final Color statusMessageNotRead;

  /// Icon [Color] when an error occurred while sending a message.
  final Color statusMessageError;

  /// [Color] to use in sidebar for chats when hovering.
  final Color unselectedHoverColor;

  @override
  ThemeExtension<Style> copyWith({
    TextStyle? boldBody,
    BorderRadius? cardRadius,
    double? cardBlur,
    Color? cardColor,
    Border? cardBorder,
    Color? primaryCardColor,
    Border? primaryBorder,
    Border? hoveredBorderUnselected,
    Color? subtitleColor,
    Color? subtitle2Color,
    Color? sidebarColor,
    Color? statusMessageRead,
    Color? statusMessageNotRead,
    Color? statusMessageError,
    Color? unselectedHoverColor,
  }) {
    return Style(
      boldBody: boldBody ?? this.boldBody,
      cardRadius: cardRadius ?? this.cardRadius,
      cardBlur: cardBlur ?? this.cardBlur,
      cardColor: cardColor ?? this.cardColor,
      cardBorder: cardBorder ?? this.cardBorder,
      primaryCardColor: primaryCardColor ?? this.primaryCardColor,
      primaryBorder: primaryBorder ?? this.primaryBorder,
      hoveredBorderUnselected:
          hoveredBorderUnselected ?? this.hoveredBorderUnselected,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      subtitle2Color: subtitle2Color ?? this.subtitle2Color,
      sidebarColor: sidebarColor ?? this.sidebarColor,
      statusMessageRead: statusMessageRead ?? this.statusMessageRead,
      statusMessageNotRead: statusMessageNotRead ?? this.statusMessageNotRead,
      statusMessageError: statusMessageError ?? this.statusMessageError,
      unselectedHoverColor: unselectedHoverColor ?? this.unselectedHoverColor,
    );
  }

  @override
  ThemeExtension<Style> lerp(ThemeExtension<Style>? other, double t) {
    if (other is! Style) {
      return this;
    }

    return Style(
      boldBody: TextStyle.lerp(boldBody, other.boldBody, t)!,
      cardRadius: BorderRadius.lerp(cardRadius, other.cardRadius, t)!,
      cardBlur: cardBlur * (1 - t) + other.cardBlur * t,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      cardBorder: Border.lerp(cardBorder, other.cardBorder, t)!,
      primaryCardColor:
          Color.lerp(primaryCardColor, other.primaryCardColor, t)!,
      primaryBorder: Border.lerp(primaryBorder, other.primaryBorder, t)!,
      hoveredBorderUnselected: Border.lerp(
          hoveredBorderUnselected, other.hoveredBorderUnselected, t)!,
      subtitleColor: Color.lerp(subtitleColor, other.subtitleColor, t)!,
      subtitle2Color: Color.lerp(subtitle2Color, other.subtitle2Color, t)!,
      sidebarColor: Color.lerp(sidebarColor, other.sidebarColor, t)!,
      statusMessageRead:
          Color.lerp(statusMessageRead, other.statusMessageRead, t)!,
      statusMessageNotRead:
          Color.lerp(statusMessageNotRead, other.statusMessageNotRead, t)!,
      statusMessageError:
          Color.lerp(statusMessageError, other.statusMessageError, t)!,
      unselectedHoverColor:
          Color.lerp(unselectedHoverColor, other.unselectedHoverColor, t)!,
    );
  }
}
