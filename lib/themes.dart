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
    ColorScheme colors = ThemeData.light().colorScheme.copyWith(
          primary: const Color(0xFF888888),
          onPrimary: Colors.white,
          secondary: const Color(0xFF63B4FF),
          onSecondary: Colors.white,
          background: const Color(0xFFF5F8FA),
          onBackground: Colors.black,
        );

    SystemChrome.setSystemUIOverlayStyle(colors.brightness == Brightness.light
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light);

    return ThemeData.light().copyWith(
        extensions: [
          Style(
            callDock: const Color(0xFF1E88E5),
            cardBorder: Border.all(
              color: const Color(0xFFEBEBEB),
              width: 0.5,
            ),
            secondaryBorder: Border.all(
              color: const Color(0xFFDADADA),
              width: 0.5,
            ),
            primaryBorder: Border.all(
              color: const Color(0xFFB9D9FA),
              width: 0.5,
            ),
            cardRadius: BorderRadius.circular(14),
            cardColor: Colors.white.withOpacity(0.95),
            cardBlur: 5,
            boldBody: GoogleFonts.roboto(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w400,
            ),
            unreadMessageThickness: 4,
            systemMessageTextStyle: GoogleFonts.roboto(
              color: const Color(0xFF888888),
              fontSize: 13,
              fontWeight: FontWeight.w300,
            ),
            systemMessageBorder:
                Border.all(color: const Color(0xFFD2D2D2), width: 0.5),
            systemMessageColor: const Color(0xFFEFEFEF).withOpacity(0.95),
          ),
        ],
        colorScheme: colors,
        scaffoldBackgroundColor: colors.background,
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
            ),
        tabBarTheme: ThemeData.light().tabBarTheme.copyWith(
              labelColor: colors.secondary,
              unselectedLabelColor: colors.primary,
            ),
        primaryTextTheme: GoogleFonts.robotoTextTheme(),
        primaryIconTheme:
            const IconThemeData.fallback().copyWith(color: colors.primary),
        iconTheme: ThemeData.light().iconTheme.copyWith(color: Colors.black),
        textTheme: GoogleFonts.robotoTextTheme().copyWith(
                headline3: TextStyle(color: colors.primary, fontSize: 30),
                headline4: TextStyle(color: colors.primary, fontSize: 24),
                headline5: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
                caption: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w300,
                  fontSize: 17,
                ),
                subtitle1: const TextStyle(color: Colors.black, fontSize: 15),
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
            foregroundColor: colors.primary,
            backgroundColor: Colors.transparent,
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

class Style extends ThemeExtension<Style> {
  const Style({
    required this.callDock,
    required this.cardRadius,
    required this.cardBorder,
    required this.primaryBorder,
    required this.secondaryBorder,
    required this.cardBlur,
    required this.cardColor,
    required this.boldBody,
    required this.unreadMessageThickness,
    required this.systemMessageTextStyle,
    required this.systemMessageBorder,
    required this.systemMessageColor,
  });

  final Color callDock;
  final BorderRadius cardRadius;
  final Border cardBorder;
  final Border primaryBorder;
  final Border secondaryBorder;
  final double cardBlur;
  final Color cardColor;
  final TextStyle boldBody;

  final double unreadMessageThickness;
  final TextStyle systemMessageTextStyle;
  final Border systemMessageBorder;
  final Color systemMessageColor;

  @override
  ThemeExtension<Style> copyWith({
    Color? callDock,
    BorderRadius? cardRadius,
    Border? cardBorder,
    Border? primaryBorder,
    Border? secondaryBorder,
    double? cardBlur,
    Color? cardColor,
    TextStyle? boldBody,
    double? unreadMessageThickness,
    TextStyle? systemMessageTextStyle,
    Border? systemMessageBorder,
    Color? systemMessageColor,
  }) {
    return Style(
      callDock: callDock ?? this.callDock,
      cardRadius: cardRadius ?? this.cardRadius,
      cardBorder: cardBorder ?? this.cardBorder,
      primaryBorder: primaryBorder ?? this.primaryBorder,
      secondaryBorder: secondaryBorder ?? this.secondaryBorder,
      cardBlur: cardBlur ?? this.cardBlur,
      cardColor: cardColor ?? this.cardColor,
      boldBody: boldBody ?? this.boldBody,
      unreadMessageThickness:
          unreadMessageThickness ?? this.unreadMessageThickness,
      systemMessageTextStyle:
          systemMessageTextStyle ?? this.systemMessageTextStyle,
      systemMessageBorder: systemMessageBorder ?? this.systemMessageBorder,
      systemMessageColor: systemMessageColor ?? this.systemMessageColor,
    );
  }

  @override
  ThemeExtension<Style> lerp(ThemeExtension<Style>? other, double t) {
    if (other is! Style) {
      return this;
    }

    return Style(
      callDock: Color.lerp(callDock, other.callDock, t)!,
      cardRadius: BorderRadius.lerp(cardRadius, other.cardRadius, t)!,
      cardBorder: Border.lerp(cardBorder, other.cardBorder, t)!,
      primaryBorder: Border.lerp(primaryBorder, other.primaryBorder, t)!,
      secondaryBorder: Border.lerp(secondaryBorder, other.secondaryBorder, t)!,
      cardBlur: cardBlur * (1.0 - t) + other.cardBlur * t,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      boldBody: TextStyle.lerp(boldBody, other.boldBody, t)!,
      systemMessageTextStyle: TextStyle.lerp(
        systemMessageTextStyle,
        other.systemMessageTextStyle,
        t,
      )!,
      unreadMessageThickness:
          unreadMessageThickness * (1.0 - t) + other.unreadMessageThickness * t,
      systemMessageBorder:
          Border.lerp(systemMessageBorder, other.systemMessageBorder, t)!,
      systemMessageColor:
          Color.lerp(systemMessageColor, other.systemMessageColor, t)!,
    );
  }
}
