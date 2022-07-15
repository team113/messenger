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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/config.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/ui/page/home/page/chat/controller.dart';

/// Widget to build an [Avatar].
///
/// Displays a colored [BoxDecoration] with initials based on a [title] if
/// [avatar] is not specified.
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    Key? key,
    this.avatar,
    this.radius,
    this.maxRadius,
    this.minRadius,
    this.title,
    this.color,
    this.opacity = 1,
  }) : super(key: key);

  /// Creates an [AvatarWidget] from the specified [contact].
  factory AvatarWidget.fromContact(
    ChatContact? contact, {
    Avatar? avatar,
    double? radius,
    double? maxRadius,
    double? minRadius,
    double opacity = 1,
  }) =>
      AvatarWidget(
        avatar: avatar,
        title: contact?.name.val,
        color: (contact?.users.isEmpty ?? false)
            ? contact?.name.val.sum()
            : contact?.users.first.num.val.sum(),
        radius: radius,
        maxRadius: maxRadius,
        minRadius: minRadius,
        opacity: opacity,
      );

  /// Creates an [AvatarWidget] from the specified [myUser].
  factory AvatarWidget.fromMyUser(
    MyUser? myUser, {
    double? radius,
    double? maxRadius,
    double? minRadius,
    double opacity = 1,
  }) =>
      AvatarWidget(
        avatar: myUser?.avatar,
        title: myUser?.name?.val ?? myUser?.num.val,
        color: myUser?.num.val.sum(),
        radius: radius,
        maxRadius: maxRadius,
        minRadius: minRadius,
        opacity: opacity,
      );

  /// Creates an [AvatarWidget] from the specified [user].
  factory AvatarWidget.fromUser(
    User? user, {
    double? radius,
    double? maxRadius,
    double? minRadius,
    double opacity = 1,
  }) =>
      AvatarWidget(
        avatar: user?.avatar,
        title: user?.name?.val ?? user?.num.val,
        color: user?.num.val.sum(),
        radius: radius,
        maxRadius: maxRadius,
        minRadius: minRadius,
        opacity: opacity,
      );

  /// Creates an [AvatarWidget] from the specified [Chat] and its parameters.
  factory AvatarWidget.fromChat(
    Chat? chat,
    String? title,
    Avatar? avatar,
    UserId? me, {
    double? radius,
    double? maxRadius,
    double? minRadius,
    double opacity = 1,
  }) =>
      AvatarWidget(
        avatar: avatar,
        title: title,
        color: chat?.colorDiscriminant(me).sum(),
        radius: radius,
        maxRadius: maxRadius,
        minRadius: minRadius,
        opacity: opacity,
      );

  /// Creates an [AvatarWidget] from the specified [RxChat].
  static Widget fromRxChat(
    RxChat? chat, {
    double? radius,
    double? maxRadius,
    double? minRadius,
    double opacity = 1,
  }) =>
      chat != null
          ? Obx(
              () => AvatarWidget(
                avatar: chat.avatar.value,
                title: chat.title.value,
                color: chat.chat.value.colorDiscriminant(chat.me).sum(),
                radius: radius,
                maxRadius: maxRadius,
                minRadius: minRadius,
                opacity: opacity,
              ),
            )
          : AvatarWidget(
              radius: radius,
              maxRadius: maxRadius,
              minRadius: minRadius,
              opacity: opacity,
            );

  /// [Avatar] to display.
  final Avatar? avatar;

  /// Size of the avatar, expressed as the radius (half the diameter).
  ///
  /// If [radius] is specified, then neither [minRadius] nor [maxRadius] may be
  /// specified. Specifying [radius] is equivalent to specifying a [minRadius]
  /// and [maxRadius], both with the value of [radius].
  ///
  /// If neither [minRadius] nor [maxRadius] are specified, defaults to 20
  /// logical pixels.
  final double? radius;

  /// The maximum size of the avatar, expressed as the radius (half the
  /// diameter).
  ///
  /// If [maxRadius] is specified, then [radius] must not also be specified.
  ///
  /// Defaults to [double.infinity].
  final double? maxRadius;

  /// The minimum size of the avatar, expressed as the radius (half the
  /// diameter).
  ///
  /// If [minRadius] is specified, then [radius] must not also be specified.
  ///
  /// Defaults to zero.
  final double? minRadius;

  /// Optional title of an avatar to display.
  final String? title;

  /// Integer that determining the gradient color of the avatar.
  final int? color;

  /// Opacity of this [AvatarWidget].
  final double opacity;

  /// Avatar color swatches.
  static const List<Color> colors = [
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.lightGreen,
    Colors.lime,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
  ];

  /// Returns minimum diameter of the avatar.
  double get _minDiameter {
    if (radius == null && minRadius == null && maxRadius == null) {
      return 40;
    }
    return 2.0 * (radius ?? minRadius ?? 20);
  }

  /// Returns maximum diameter of the avatar.
  double get _maxDiameter {
    if (radius == null && minRadius == null && maxRadius == null) {
      return 40;
    }
    return 2.0 * (radius ?? maxRadius ?? 40);
  }

  @override
  Widget build(BuildContext context) {
    return opacity == 1
        ? _avatar(context)
        : Opacity(
            opacity: opacity,
            child: _avatar(context),
          );
  }

  /// Returns an actual interface of this [AvatarWidget].
  Widget _avatar(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      Color gradient;

      if (color != null) {
        gradient = colors[color! % colors.length];
      } else if (title != null) {
        gradient = colors[(title!.hashCode) % colors.length];
      } else {
        gradient = const Color(0xFF555555);
      }

      var minWidth = min(_minDiameter, constraints.smallest.shortestSide);
      var minHeight = min(_minDiameter, constraints.smallest.shortestSide);
      var maxWidth = min(_maxDiameter, constraints.biggest.shortestSide);
      var maxHeight = min(_maxDiameter, constraints.biggest.shortestSide);

      return Container(
        constraints: BoxConstraints(
          minHeight: minHeight,
          minWidth: minWidth,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradient.lighten(), gradient],
          ),
          image: avatar == null
              ? null
              : DecorationImage(
                  image: NetworkImage(
                    '${Config.url}:${Config.port}/files${avatar?.original}',
                  ),
                  fit: BoxFit.cover,
                  isAntiAlias: true,
                ),
          shape: BoxShape.circle,
        ),
        child: avatar == null
            ? LayoutBuilder(builder: (context, constraints) {
                return Center(
                  child: Text(
                    (title ?? '??').initials(),
                    style: Theme.of(context).textTheme.headline4?.copyWith(
                          fontSize: 15 * (maxWidth / 40.0),
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                );
              })
            : null,
      );
    });
  }
}

/// Extension adding an ability to get initials from a [String].
extension _InitialsExtension on String {
  /// Returns initials (two letters which begin each word) of this string.
  String initials() {
    List<String> words = split(' ').where((e) => e.isNotEmpty).toList();

    if (words.length >= 3) {
      return '${words[0][0]}${words[1][0]}${words[2][0]}'.toUpperCase();
    } else if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      if (words[0].length >= 2) {
        return '${words[0][0].toUpperCase()}${words[0][1].toLowerCase()}';
      } else {
        return words[0].toUpperCase();
      }
    }

    return '';
  }
}

/// Extension adding an ability to get a sum of [String] code units.
extension _SumStringExtension on String {
  /// Returns a sum of [codeUnits].
  int sum() => codeUnits.fold(0, (a, b) => a + b);
}

/// Extension adding an ability to lighten a color.
extension _LightenColorExtension on Color {
  /// Returns a lighten variant of this color.
  Color lighten([double amount = .2]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final hslLight =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }
}
