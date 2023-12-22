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
import 'package:get/get.dart';

import '/domain/model/avatar.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/widget_button.dart';
import 'avatar.dart';
import 'gallery_popup.dart';

/// Circular big [Avatar] with optional manipulation buttons.
class BigAvatarWidget extends StatefulWidget {
  /// Builds a [BigAvatarWidget] of the provided [myUser].
  const BigAvatarWidget.myUser(
    this.myUser, {
    super.key,
    this.onUpload,
    this.onDelete,
    this.loading = false,
  })  : _mode = _BigAvatarMode.myUser,
        user = null,
        chat = null;

  /// Builds a [BigAvatarWidget] of the provided [chat].
  const BigAvatarWidget.chat(
    this.chat, {
    super.key,
    this.onUpload,
    this.onDelete,
    this.loading = false,
  })  : _mode = _BigAvatarMode.chat,
        myUser = null,
        user = null;

  /// Builds a [BigAvatarWidget] of the provided [user].
  const BigAvatarWidget.user(
    this.user, {
    super.key,
    this.onUpload,
    this.onDelete,
    this.loading = false,
  })  : _mode = _BigAvatarMode.user,
        myUser = null,
        chat = null;

  /// [_BigAvatarMode] of this [BigAvatarWidget].
  final _BigAvatarMode _mode;

  /// [MyUser] to display an [Avatar] of.
  final MyUser? myUser;

  /// [User] to display an [Avatar] of.
  final RxUser? user;

  /// [RxChat] to display an [Avatar] of.
  final RxChat? chat;

  /// Indicator whether a [CustomProgressIndicator] should be displayed.
  final bool loading;

  /// Callback, called when an upload of [Avatar] is required.
  final void Function()? onUpload;

  /// Callback, called when delete of [Avatar] is required.
  final void Function()? onDelete;

  @override
  State<BigAvatarWidget> createState() => _BigAvatarWidgetState();
}

/// State of a [BigAvatarWidget] maintaining the [_avatarKey].
class _BigAvatarWidgetState extends State<BigAvatarWidget> {
  /// [GlobalKey] of an [AvatarWidget] to display [GalleryPopup] from.
  final GlobalKey _avatarKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            _avatar(context),
            Positioned.fill(
              child: SafeAnimatedSwitcher(
                duration: 200.milliseconds,
                child: widget.loading
                    ? Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: style.colors.onBackgroundOpacity13,
                        ),
                        child: const Center(child: CustomProgressIndicator()),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        if (widget.onUpload != null || widget.onDelete != null) ...[
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onUpload != null)
                WidgetButton(
                  key: const Key('UploadAvatar'),
                  onPressed: widget.onUpload,
                  child: Text(
                    'btn_upload'.l10n,
                    style: style.fonts.smaller.regular.primary,
                  ),
                ),
              if (widget.onUpload != null && widget.onDelete != null)
                Text(
                  'space_or_space'.l10n,
                  style: style.fonts.smaller.regular.onBackground,
                ),
              if (widget.onDelete != null)
                WidgetButton(
                  key: const Key('DeleteAvatar'),
                  onPressed: widget.onDelete,
                  child: Text(
                    'btn_delete'.l10n.toLowerCase(),
                    style: style.fonts.smaller.regular.primary,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  /// Builds a visual representation of the [AvatarWidget] itself.
  Widget _avatar(BuildContext context) {
    Widget obx(bool value, Widget Function() builder) {
      if (value) {
        return Obx(builder);
      }

      return builder();
    }

    return obx(widget._mode.isReactive, () {
      final Avatar? avatar;
      final Widget child;

      switch (widget._mode) {
        case _BigAvatarMode.myUser:
          avatar = widget.myUser?.avatar;
          child = AvatarWidget.fromMyUser(
            widget.myUser,
            key: _avatarKey,
            radius: AvatarRadius.largest,
            badge: false,
          );
          break;

        case _BigAvatarMode.user:
          avatar = widget.user?.user.value.avatar;
          child = AvatarWidget.fromRxUser(
            widget.user,
            key: _avatarKey,
            radius: AvatarRadius.largest,
            badge: false,
          );
          break;

        case _BigAvatarMode.chat:
          avatar = widget.chat?.avatar.value;
          child = AvatarWidget.fromRxChat(
            widget.chat,
            key: _avatarKey,
            radius: AvatarRadius.largest,
          );
          break;
      }

      return WidgetButton(
        onPressed: avatar == null
            ? widget.onUpload
            : () async {
                await GalleryPopup.show(
                  context: context,
                  gallery: GalleryPopup(
                    initialKey: _avatarKey,
                    children: [
                      GalleryItem.image(
                        avatar!.original.url,
                        avatar.original.name,
                        width: avatar.original.width,
                        height: avatar.original.height,
                        checksum: avatar.original.checksum,
                        thumbhash: avatar.big.thumbhash,
                      ),
                    ],
                  ),
                );
              },
        child: child,
      );
    });
  }
}

/// Mode of [BigAvatarWidget].
enum _BigAvatarMode { myUser, user, chat }

/// Extension adding reactive indicator on [_BigAvatarMode].
extension on _BigAvatarMode {
  /// Indicates whether this [_BigAvatarMode] is supposed to be reactive.
  bool get isReactive {
    switch (this) {
      case _BigAvatarMode.myUser:
        return false;

      case _BigAvatarMode.user:
      case _BigAvatarMode.chat:
        return true;
    }
  }
}
