// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/file.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/svg/svg.dart';

/// Possible radiuses of an [AvatarWidget].
enum AvatarRadius {
  smallest,
  smaller,
  small,
  normal,
  medium,
  big,
  large,
  larger,
  largest;

  /// Converts this [AvatarRadius] to a [double].
  double toDouble() {
    return switch (this) {
      AvatarRadius.smallest => 8,
      AvatarRadius.smaller => 10,
      AvatarRadius.small => 15,
      AvatarRadius.normal => 16,
      AvatarRadius.medium => 17,
      AvatarRadius.big => 20,
      AvatarRadius.large => 30,
      AvatarRadius.larger => 32,
      AvatarRadius.largest => 200,
    };
  }
}

/// Widget to build an [Avatar].
///
/// Displays a colored [BoxDecoration] with initials based on a [title] if
/// [avatar] is not specified.
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    this.avatar,
    this.radius,
    this.title,
    this.color,
    this.opacity = 1,
    this.isOnline = false,
    this.isAway = false,
    this.label,
    this.onForbidden,
    this.child,
  });

  /// Creates an [AvatarWidget] from the specified [contact].
  factory AvatarWidget.fromContact(
    ChatContact? contact, {
    Key? key,
    Avatar? avatar,
    AvatarRadius? radius,
    double opacity = 1,
  }) =>
      AvatarWidget(
        key: key,
        avatar: avatar,
        title: contact?.name.val,
        color: (contact?.users.isEmpty ?? false)
            ? contact?.name.val.sum()
            : contact?.users.first.num.val.sum(),
        radius: radius,
        opacity: opacity,
      );

  /// Creates an [AvatarWidget] from the specified reactive [contact].
  static Widget fromRxContact(
    RxChatContact? contact, {
    Key? key,
    Avatar? avatar,
    AvatarRadius? radius,
    double opacity = 1,
    bool badge = true,
  }) {
    if (contact == null) {
      return AvatarWidget.fromContact(
        key: key,
        contact?.contact.value,
        avatar: avatar,
        radius: radius,
        opacity: opacity,
      );
    }

    return Obx(() {
      return AvatarWidget(
        key: key,
        isOnline: badge &&
            contact.contact.value.users.length == 1 &&
            contact.user.value?.user.value.online == true,
        isAway: contact.user.value?.user.value.presence == Presence.away,
        avatar: contact.user.value?.user.value.avatar,
        title: contact.contact.value.name.val,
        color: contact.user.value == null
            ? contact.contact.value.name.val.sum()
            : contact.user.value?.user.value.num.val.sum(),
        radius: radius,
        opacity: opacity,
      );
    });
  }

  /// Creates an [AvatarWidget] from the specified [MyUser].
  factory AvatarWidget.fromMyUser(
    MyUser? myUser, {
    Key? key,
    AvatarRadius? radius,
    double opacity = 1,
    bool badge = true,
    FutureOr<void> Function()? onForbidden,
  }) =>
      AvatarWidget(
        key: key,
        isOnline: badge && myUser?.online == true,
        isAway: myUser?.presence == Presence.away,
        avatar: myUser?.avatar,
        title: myUser?.name?.val ?? myUser?.num.toString(),
        color: myUser?.num.val.sum(),
        radius: radius,
        opacity: opacity,
        onForbidden: onForbidden,
      );

  /// Creates an [AvatarWidget] from the specified [user].
  factory AvatarWidget.fromUser(
    User? user, {
    Key? key,
    AvatarRadius? radius,
    double opacity = 1,
  }) =>
      AvatarWidget(
        key: key,
        avatar: user?.avatar,
        title: user?.title,
        color: user?.num.val.sum(),
        radius: radius,
        opacity: opacity,
      );

  /// Creates an [AvatarWidget] from the specified reactive [user].
  static Widget fromRxUser(
    RxUser? user, {
    Key? key,
    AvatarRadius? radius,
    double opacity = 1,
    bool badge = true,
  }) {
    if (user == null) {
      return AvatarWidget.fromUser(
        user?.user.value,
        key: key,
        radius: radius,
        opacity: opacity,
      );
    }

    return Obx(
      () => AvatarWidget(
        key: key,
        isOnline: badge && user.user.value.online == true,
        isAway: user.user.value.presence == Presence.away,
        avatar: user.user.value.avatar,
        title: user.title,
        color: user.user.value.num.val.sum(),
        radius: radius,
        opacity: opacity,
      ),
    );
  }

  /// Creates an [AvatarWidget] from the specified [chat]-monolog.
  factory AvatarWidget.fromMonolog(
    Chat? chat,
    UserId? me, {
    Key? key,
    AvatarRadius? radius,
    double opacity = 1,
  }) =>
      AvatarWidget(
        key: key,
        label: LayoutBuilder(
          builder: (context, constraints) {
            return SvgIcon(
              SvgIcons.notes,
              width: constraints.maxWidth,
              height: constraints.maxWidth / 2,
            );
          },
        ),
        avatar: chat?.avatar,
        color: chat?.colorDiscriminant(me).sum(),
        radius: radius,
        opacity: opacity,
      );

  /// Creates an [AvatarWidget] from the specified [Chat] and its parameters.
  factory AvatarWidget.fromChat(
    Chat? chat,
    String? title,
    Avatar? avatar,
    UserId? me, {
    Key? key,
    AvatarRadius? radius,
    double opacity = 1,
  }) =>
      AvatarWidget(
        key: key,
        avatar: avatar,
        title: title,
        color: chat?.colorDiscriminant(me).sum(),
        radius: radius,
        opacity: opacity,
      );

  /// Creates an [AvatarWidget] from the specified [RxChat].
  static Widget fromRxChat(
    RxChat? chat, {
    Key? key,
    AvatarRadius? radius,
    double opacity = 1,
    FutureOr<void> Function()? onForbidden,
  }) {
    if (chat == null) {
      return AvatarWidget(
        key: key,
        radius: radius,
        opacity: opacity,
      );
    }

    return Obx(() {
      if (chat.chat.value.isMonolog) {
        return AvatarWidget.fromMonolog(
          chat.chat.value,
          chat.me,
          radius: radius,
          opacity: opacity,
        );
      }

      final RxUser? user = chat.members.values
          .firstWhereOrNull((e) => e.user.id != chat.me)
          ?.user;
      return AvatarWidget(
        key: key,
        isOnline: chat.chat.value.isDialog && user?.user.value.online == true,
        isAway: user?.user.value.presence == Presence.away,
        avatar: chat.avatar.value,
        title: chat.title,
        color: chat.chat.value.colorDiscriminant(chat.me).sum(),
        radius: radius,
        opacity: opacity,
        onForbidden: onForbidden,
      );
    });
  }

  /// [Avatar] to display.
  final Avatar? avatar;

  /// [AvatarRadius] to display [avatar] with.
  ///
  /// [AvatarRadius.big] is used, if `null`.
  final AvatarRadius? radius;

  /// Optional title of an avatar to display.
  final String? title;

  /// Integer that determining the gradient color of the avatar.
  final int? color;

  /// Opacity of this [AvatarWidget].
  final double opacity;

  /// Indicator whether to display an online [Badge] in the bottom-right corner
  /// of this [AvatarWidget].
  final bool isOnline;

  /// Indicator whether to display an away [Badge] in the bottom-right corner
  /// of this [AvatarWidget].
  ///
  /// [Badge] is displayed only if [isOnline] is `true` as well.
  final bool isAway;

  /// Optional label to show inside this [AvatarWidget].
  final Widget? label;

  /// Callback, called when [avatar] fetching fails with `Forbidden` error.
  final FutureOr<void> Function()? onForbidden;

  /// [Widget] to display inside this [AvatarWidget].
  ///
  /// No-op, if [avatar] is specified.
  ///
  /// Intended to be used on the [Routes.style] page only.
  final Widget? child;

  /// Returns minimum diameter of the avatar.
  double get _minDiameter {
    if (radius == null) {
      return AvatarRadius.big.toDouble() * 2;
    }
    return 2.0 * radius!.toDouble();
  }

  /// Returns maximum diameter of the avatar.
  double get _maxDiameter {
    if (radius == null) {
      return AvatarRadius.big.toDouble() * 2;
    }
    return 2.0 * radius!.toDouble();
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
    final style = Theme.of(context).style;

    return LayoutBuilder(builder: (context, constraints) {
      final Color gradient;

      if (color != null) {
        gradient =
            style.colors.userColors[color! % style.colors.userColors.length];
      } else if (title != null) {
        gradient = style.colors
            .userColors[(title!.hashCode) % style.colors.userColors.length];
      } else {
        gradient = style.colors.secondaryBackgroundLightest;
      }

      double minWidth = min(_minDiameter, constraints.smallest.shortestSide);
      double minHeight = min(_minDiameter, constraints.smallest.shortestSide);
      double maxWidth = min(_maxDiameter, constraints.biggest.shortestSide);
      double maxHeight = min(_maxDiameter, constraints.biggest.shortestSide);

      final double badgeSize = maxWidth >= 40 ? maxWidth / 5 : maxWidth / 3.75;

      final ImageFile? image = maxWidth > 250
          ? avatar?.full
          : maxWidth > 100
              ? avatar?.big
              : maxWidth > 46
                  ? avatar?.medium
                  : avatar?.small;

      final Widget defaultAvatar = Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradient.lighten(), gradient],
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: label ??
              SelectionContainer.disabled(
                child: Text(
                  (title ?? '??').initials(),
                  style: style.fonts.normal.bold.onPrimary.copyWith(
                    fontSize: style.fonts.normal.bold.onPrimary.fontSize! *
                        (maxWidth / 40.0),
                  ),

                  // Disable the accessibility size settings for this [Text].
                  textScaler: const TextScaler.linear(1),
                ),
              ),
        ),
      );

      return ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth,
          minHeight: minHeight,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: Badge(
          largeSize: badgeSize * 1.16,
          isLabelVisible: isOnline,
          alignment: Alignment.bottomRight,
          backgroundColor: style.colors.onPrimary,
          padding: EdgeInsets.all(badgeSize / 12),
          offset:
              maxWidth >= 40 ? const Offset(-2.5, -2.5) : const Offset(0, 0),
          label: SizedBox(
            width: badgeSize,
            height: badgeSize,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAway
                    ? style.colors.warning
                    : style.colors.acceptAuxiliary,
              ),
            ),
          ),
          child: Stack(
            children: [
              if (avatar == null) defaultAvatar,
              if (avatar != null || child != null)
                Positioned.fill(
                  child: ClipOval(
                    child: child ??
                        RetryImage(
                          image!.url,
                          checksum: image.checksum,
                          thumbhash: image.thumbhash,
                          fit: BoxFit.cover,
                          height: double.infinity,
                          width: double.infinity,
                          displayProgress: false,
                          onForbidden: onForbidden,
                          loadingBuilder: () => defaultAvatar,
                        ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

/// Extension adding an ability to get initials from a [String].
extension InitialsExtension on String {
  /// Returns initials (two letters which begin each word) of this string.
  String initials() {
    List<String> words = split(' ').where((e) => e.isNotEmpty).toList();

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
extension BrightnessColorExtension on Color {
  /// Returns a lighten variant of this color.
  Color lighten([double amount = .2]) {
    assert(amount >= 0 && amount <= 1);

    if (amount == 0) {
      return this;
    }

    final hsl = HSLColor.fromColor(this);
    final hslLight =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }

  /// Returns a darken variant of this color.
  Color darken([double amount = .2]) {
    assert(amount >= 0 && amount <= 1);

    if (amount == 0) {
      return this;
    }

    final hsl = HSLColor.fromColor(this);
    final hslLight =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }
}
