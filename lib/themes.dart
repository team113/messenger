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
            barrierColor: const Color(0xBB000000),
            boldBody: GoogleFonts.roboto(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w400,
            ),
            cardBlur: 5,
            cardBorder: Border.all(color: const Color(0xFFEBEBEB), width: 0.5),
            cardColor: Colors.white.withOpacity(0.95),
            cardRadius: BorderRadius.circular(14),
            contextMenuBackgroundColor: const Color(0xFFF2F2F2),
            contextMenuHoveredColor: const Color(0xFFE5E7E9),
            contextMenuRadius: BorderRadius.circular(10),
            dropButtonColor: Colors.red,
            hoveredBorderUnselected:
                Border.all(color: const Color(0xFFDAEDFF), width: 0.5),
            joinButtonColor: const Color(0xFF63B4FF),
            primaryBorder:
                Border.all(color: const Color(0xFFB9D9FA), width: 0.5),
            primaryCardColor: const Color.fromRGBO(210, 227, 249, 1),
            sidebarColor: Colors.white.withOpacity(0.4),
            statusMessageError: Colors.red,
            statusMessageNotRead: const Color(0xFF888888),
            statusMessageRead: const Color(0xFF63B4FF),
            subtitleColor: const Color(0xFF666666),
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
          headline3: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w300,
            fontSize: 18,
          ),
          headline4: const TextStyle(color: Colors.black, fontSize: 18),
          headline5: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w400,
            fontSize: 18,
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
          subtitle1: const TextStyle(color: Colors.black, fontSize: 15),
          subtitle2: TextStyle(color: colors.primary, fontSize: 15),
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
        radioTheme: ThemeData.light().radioTheme.copyWith(
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF63B4FF);
            }

            return const Color(0xFF888888);
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
    required this.barrierColor,
    required this.boldBody,
    required this.cardBlur,
    required this.cardBorder,
    required this.cardColor,
    required this.cardRadius,
    required this.contextMenuBackgroundColor,
    required this.contextMenuHoveredColor,
    required this.contextMenuRadius,
    required this.dropButtonColor,
    required this.hoveredBorderUnselected,
    required this.joinButtonColor,
    required this.primaryBorder,
    required this.primaryCardColor,
    required this.sidebarColor,
    required this.statusMessageError,
    required this.statusMessageNotRead,
    required this.statusMessageRead,
    required this.subtitleColor,
    required this.unselectedHoverColor,
  });

  /// [Color] of the modal background barrier color.
  final Color barrierColor;

  /// [TextStyle] to use in the body to make content readable.
  final TextStyle boldBody;

  /// Blur to use in sidebar for chats.
  final double cardBlur;

  /// [Color] to use in sidebar for chats if chat is not selected.
  final Color cardColor;

  /// [Border] to use in sidebar for chats if chat is not selected.
  final Border cardBorder;

  /// [BorderRadius] to use in card-like [Widget]s.
  final BorderRadius cardRadius;

  /// Background [Color] of the [ContextMenu].
  final Color contextMenuBackgroundColor;

  /// [Color] of the hovered [ContextMenuButton].
  final Color contextMenuHoveredColor;

  /// [BorderRadius] of the [ContextMenu].
  final BorderRadius contextMenuRadius;

  /// [Color] reset button.
  final Color dropButtonColor;

  /// [Border] to use in sidebar for chats.
  final Border hoveredBorderUnselected;

  /// [Color] join button.
  final Color joinButtonColor;

  /// [Border] to use in sidebar for chats if chat is selected.
  final Border primaryBorder;

  /// [Color] to use in sidebar for chats if chat is selected.
  final Color primaryCardColor;

  /// [Color] of the [HomeView]'s side bar.
  final Color sidebarColor;

  /// Icon [Color] when an error occurred while sending a message.
  final Color statusMessageError;

  /// Icon [Color] when a message has not been read.
  final Color statusMessageNotRead;

  /// Icon [Color] when a message has been read.
  final Color statusMessageRead;

  /// [Color] used for the primary text in lists.
  final Color subtitleColor;

  /// [Color] to use in sidebar for chats when hovering.
  final Color unselectedHoverColor;

  @override
  ThemeExtension<Style> copyWith({
    Border? cardBorder,
    Border? hoveredBorderUnselected,
    Border? primaryBorder,
    BorderRadius? cardRadius,
    BorderRadius? contextMenuRadius,
    Color? barrierColor,
    Color? cardColor,
    Color? contextMenuBackgroundColor,
    Color? contextMenuHoveredColor,
    Color? dropButtonColor,
    Color? joinButtonColor,
    Color? primaryCardColor,
    Color? sidebarColor,
    Color? statusMessageError,
    Color? statusMessageNotRead,
    Color? statusMessageRead,
    Color? subtitle2Color,
    Color? subtitleColor,
    Color? unselectedHoverColor,
    double? cardBlur,
    TextStyle? boldBody,
  }) {
    return Style(
      barrierColor: barrierColor ?? this.barrierColor,
      boldBody: boldBody ?? this.boldBody,
      cardBlur: cardBlur ?? this.cardBlur,
      cardBorder: cardBorder ?? this.cardBorder,
      cardColor: cardColor ?? this.cardColor,
      cardRadius: cardRadius ?? this.cardRadius,
      contextMenuBackgroundColor:
          contextMenuBackgroundColor ?? this.contextMenuBackgroundColor,
      contextMenuHoveredColor:
          contextMenuHoveredColor ?? this.contextMenuHoveredColor,
      contextMenuRadius: contextMenuRadius ?? this.contextMenuRadius,
      dropButtonColor: dropButtonColor ?? this.dropButtonColor,
      hoveredBorderUnselected:
          hoveredBorderUnselected ?? this.hoveredBorderUnselected,
      joinButtonColor: joinButtonColor ?? this.joinButtonColor,
      primaryBorder: primaryBorder ?? this.primaryBorder,
      primaryCardColor: primaryCardColor ?? this.primaryCardColor,
      sidebarColor: sidebarColor ?? this.sidebarColor,
      statusMessageError: statusMessageError ?? this.statusMessageError,
      statusMessageNotRead: statusMessageNotRead ?? this.statusMessageNotRead,
      statusMessageRead: statusMessageRead ?? this.statusMessageRead,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      unselectedHoverColor: unselectedHoverColor ?? this.unselectedHoverColor,
    );
  }

  @override
  ThemeExtension<Style> lerp(ThemeExtension<Style>? other, double t) {
    if (other is! Style) {
      return this;
    }

    return Style(
      barrierColor: Color.lerp(barrierColor, other.barrierColor, t)!,
      boldBody: TextStyle.lerp(boldBody, other.boldBody, t)!,
      cardBlur: cardBlur * (1 - t) + other.cardBlur * t,
      cardBorder: Border.lerp(cardBorder, other.cardBorder, t)!,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      cardRadius: BorderRadius.lerp(cardRadius, other.cardRadius, t)!,
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
      dropButtonColor: Color.lerp(dropButtonColor, other.dropButtonColor, t)!,
      hoveredBorderUnselected: Border.lerp(
          hoveredBorderUnselected, other.hoveredBorderUnselected, t)!,
      joinButtonColor: Color.lerp(joinButtonColor, other.joinButtonColor, t)!,
      primaryBorder: Border.lerp(primaryBorder, other.primaryBorder, t)!,
      primaryCardColor:
          Color.lerp(primaryCardColor, other.primaryCardColor, t)!,
      sidebarColor: Color.lerp(sidebarColor, other.sidebarColor, t)!,
      statusMessageError:
          Color.lerp(statusMessageError, other.statusMessageError, t)!,
      statusMessageNotRead:
          Color.lerp(statusMessageNotRead, other.statusMessageNotRead, t)!,
      statusMessageRead:
          Color.lerp(statusMessageRead, other.statusMessageRead, t)!,
      subtitleColor: Color.lerp(subtitleColor, other.subtitleColor, t)!,
      unselectedHoverColor:
          Color.lerp(unselectedHoverColor, other.unselectedHoverColor, t)!,
    );
  }
}
