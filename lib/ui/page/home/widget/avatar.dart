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

import 'package:badges/badges.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/api/backend/schema.dart' show Presence;
import 'package:messenger/domain/repository/contact.dart';
import 'package:messenger/domain/repository/user.dart';

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
    this.showBadge = false,
    this.isAway = false,
    this.useLayoutBuilder = true,
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

  static Widget fromRxContact(
    RxChatContact? contact, {
    Avatar? avatar,
    double? radius,
    double? maxRadius,
    double? minRadius,
    double opacity = 1,
  }) {
    if (contact == null) {
      return AvatarWidget.fromContact(
        contact?.contact.value,
        avatar: avatar,
        radius: radius,
        maxRadius: maxRadius,
        minRadius: minRadius,
        opacity: opacity,
      );
    }

    return Obx(() {
      return AvatarWidget(
        showBadge: contact.user.value?.user.value.online == true,
        isAway: contact.user.value?.user.value.presence == Presence.away,
        avatar: contact.user.value?.user.value.avatar,
        title: '${contact.contact.value.name}',
        color: (contact.user.value == null)
            ? contact.contact.value.name.val.sum()
            : contact.user.value?.user.value.num.val.sum(),
        radius: radius,
        maxRadius: maxRadius,
        minRadius: minRadius,
        opacity: opacity,
      );
    });
  }

  /// Creates an [AvatarWidget] from the specified [myUser].
  static Widget fromMyUser(
    MyUser? myUser, {
    double? radius,
    double? maxRadius,
    double? minRadius,
    double opacity = 1,
  }) =>
      AvatarWidget(
        showBadge: true,
        isAway: myUser?.presence == Presence.away,
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
    Key? key,
    double? radius,
    double? maxRadius,
    double? minRadius,
    double opacity = 1,
  }) =>
      AvatarWidget(
        key: key,
        avatar: user?.avatar,
        title: user?.name?.val ?? user?.num.val,
        color: user?.num.val.sum(),
        radius: radius,
        maxRadius: maxRadius,
        minRadius: minRadius,
        opacity: opacity,
      );

  /// Creates an [AvatarWidget] from the specified [user].
  static Widget fromRxUser(
    RxUser? user, {
    Key? key,
    double? radius,
    double? maxRadius,
    double? minRadius,
    double opacity = 1,
    bool useLayoutBuilder = true,
  }) {
    if (user == null) {
      return AvatarWidget(
        key: key,
        avatar: user?.user.value.avatar,
        title: user?.user.value.name?.val ?? user?.user.value.num.val,
        color: user?.user.value.num.val.sum(),
        radius: radius,
        maxRadius: maxRadius,
        minRadius: minRadius,
        opacity: opacity,
        useLayoutBuilder: useLayoutBuilder,
      );
    }

    return Obx(
      () => AvatarWidget(
        key: key,
        showBadge: user.user.value.online == true,
        isAway: user.user.value.presence == Presence.away,
        avatar: user.user.value.avatar,
        title: user.user.value.name?.val ?? user.user.value.num.val,
        color: user.user.value.num.val.sum(),
        radius: radius,
        maxRadius: maxRadius,
        minRadius: minRadius,
        opacity: opacity,
        useLayoutBuilder: false,
      ),
    );
  }

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
          ? Obx(() {
              RxUser? user =
                  chat.members.values.firstWhereOrNull((e) => e.id != chat.me);
              return AvatarWidget(
                showBadge:
                    chat.chat.value.isDialog && user?.user.value.online == true,
                isAway: user?.user.value.presence == Presence.away,
                avatar: chat.avatar.value,
                title: chat.title.value,
                color: chat.chat.value.colorDiscriminant(chat.me).sum(),
                radius: radius,
                maxRadius: maxRadius,
                minRadius: minRadius,
                opacity: opacity,
              );
            })
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

  /// Opacity of this
  final double opacity;

  final bool showBadge;
  final bool isAway;
  final bool useLayoutBuilder;

  /// Avatar color swatches.
  static const List<Color> colors = [
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    // Colors.lightBlue,
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

  /// Returns an actual interface of this
  Widget _avatar(BuildContext context) {
    Widget child(BoxConstraints? constraints) {
      Color gradient;

      if (color != null) {
        gradient = AvatarWidget.colors[color! % AvatarWidget.colors.length];
      } else if (title != null) {
        gradient =
            AvatarWidget.colors[(title!.hashCode) % AvatarWidget.colors.length];
      } else {
        gradient = const Color(0xFF555555);
      }

      double minWidth = min(
        _minDiameter,
        constraints?.smallest.shortestSide ?? _minDiameter,
      );
      double minHeight = min(
        _minDiameter,
        constraints?.smallest.shortestSide ?? _minDiameter,
      );
      double maxWidth = min(
        _maxDiameter,
        constraints?.biggest.shortestSide ?? _maxDiameter,
      );
      double maxHeight = min(
        _maxDiameter,
        constraints?.biggest.shortestSide ?? _maxDiameter,
      );

      double badgeSize = max(5, maxWidth / 12);
      if (maxWidth < 40) {
        badgeSize = maxWidth / 8;
      }

      return Badge(
        showBadge: showBadge,
        badgeContent: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isAway ? Colors.orange : Colors.green,
          ),
          padding: EdgeInsets.all(badgeSize),
        ),
        padding: EdgeInsets.all(badgeSize / 3),
        badgeColor: Colors.white,
        animationType: BadgeAnimationType.scale,
        position: BadgePosition.bottomEnd(
          bottom: maxWidth >= 40 ? badgeSize / 4 : -badgeSize / 5,
          end: maxWidth >= 40 ? badgeSize / 4 : -badgeSize / 5,
        ),
        elevation: 0,
        child: Container(
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
              ? Center(
                  child: Text(
                    (title ?? '??').initials(),
                    style: Theme.of(context).textTheme.headline4?.copyWith(
                          fontSize: 15 * (maxWidth / 40.0),
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                )
              : null,
        ),
      );
    }

    if (!useLayoutBuilder) {
      return child(null);
    }

    return LayoutBuilder(builder: (context, constraints) => child(constraints));
  }
}

/// Extension adding an ability to get initials from a [String].
extension _InitialsExtension on String {
  /// Returns initials (two letters which begin each word) of this string.
  String initials() {
    List<String> words = split(' ').where((e) => e.isNotEmpty).toList();

    // if (words.length >= 3) {
    //   return '${words[0][0]}${words[1][0]}${words[2][0]}'.toUpperCase();
    // } else

    if (words.length >= 2) {
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
extension SumStringExtension on String {
  /// Returns a sum of [codeUnits].
  int sum() => codeUnits.fold(0, (a, b) => a + b);
}

/// Extension adding an ability to lighten or darken a color.
extension LightenColorExtension on Color {
  /// Returns a lighten variant of this color.
  Color lighten([double amount = .2]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final hslLight =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }

  /// Returns a darken variant of this color.
  Color darken([double amount = .2]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final hslLight =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }
}
