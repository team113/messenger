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
      primaryHighlight: Colors.blue,
      primaryHighlightShiny: const Color(0xFF58A6EF),
      primaryHighlightShiniest: const Color(0xFFD2E3F9),
      primaryHighlightLightest: const Color(0xFFB9D9FA),
      onPrimary: Colors.white,
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
      onBackground: Colors.black,
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

    final TextStyle textStyle = TextStyle(
      fontFamily: 'SFUI',
      fontFamilyFallback: const ['.SF UI Display'],
      color: colors.onBackground,
      fontSize: 17,
      fontWeight: FontWeight.w400,
    );

    final ThemeData theme = ThemeData.light();

    return theme.copyWith(
        extensions: [
          Style(
            colors: colors,
            barrierColor: colors.onBackgroundOpacity50,
            boldBody: textStyle.copyWith(
              color: colors.onBackground,
              fontSize: 17,
            ),
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
            linkStyle: TextStyle(
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
            systemMessageStyle: textStyle.copyWith(
              color: colors.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w300,
            ),
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
        tabBarTheme: theme.tabBarTheme.copyWith(
          labelColor: colors.primary,
          unselectedLabelColor: colors.secondary,
        ),
        primaryIconTheme: const IconThemeData.fallback().copyWith(
          color: colors.secondary,
        ),
        iconTheme: theme.iconTheme.copyWith(color: colors.onBackground),
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
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
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
          errorStyle:
              textStyle.copyWith(color: colors.dangerColor, fontSize: 13),
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
    required this.barrierColor,
    required this.boldBody,
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
    required this.unreadMessageColor,
  });

  /// [Palette] to use in the application.
  final Palette colors;

  /// [Color] of the modal background barrier.
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

  /// Background [Color] of unread [ChatMessage]s, [ChatForward]s and
  /// [ChatCall]s posted by the authenticated [MyUser].
  final Color unreadMessageColor;

  @override
  ThemeExtension<Style> copyWith({
    Palette? colors,
    Color? barrierColor,
    TextStyle? boldBody,
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
      barrierColor: Color.lerp(barrierColor, other.barrierColor, t)!,
      boldBody: TextStyle.lerp(boldBody, other.boldBody, t)!,
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
      unreadMessageColor:
          Color.lerp(unreadMessageColor, other.unreadMessageColor, t)!,
    );
  }
}

/// [Color]s used throughout the application.
class Palette {
  Palette({
    required this.primary,
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
    Color? onBackgroundOpacity33,
    Color? onBackgroundOpacity40,
    Color? onBackgroundOpacity50,
    required this.transparent,
    required this.acceptColor,
    required this.acceptAuxiliaryColor,
    required this.declineColor,
    required this.dangerColor,
    required this.warningColor,
    required this.userColors,
  })  : onPrimaryOpacity7 = onPrimaryOpacity7 ?? onPrimary.withOpacity(0.07),
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
            onBackgroundOpacity50 ?? onBackground.withOpacity(0.50);

  /// Primary [Color] of the application.
  ///
  /// Used to highlight the active interface elements.
  final Color primary;

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
