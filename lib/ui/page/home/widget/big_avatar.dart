// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import '/domain/model/attachment.dart';
import '/domain/model/avatar.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/chat_gallery.dart';
import '/ui/page/player/controller.dart';
import '/ui/page/player/view.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/widget_button.dart';
import 'avatar.dart';

/// Circular big [Avatar] with optional manipulation buttons.
class BigAvatarWidget extends StatefulWidget {
  /// Builds a [BigAvatarWidget] of the provided [myUser].
  const BigAvatarWidget.myUser(
    this.myUser, {
    super.key,
    this.onUpload,
    this.onDelete,
    this.onEdit,
    this.loading = false,
    this.error,
  }) : _mode = _BigAvatarMode.myUser,
       user = null,
       chat = null,
       builder = _defaultBuilder;

  /// Builds a [BigAvatarWidget] of the provided [chat].
  const BigAvatarWidget.chat(
    this.chat, {
    super.key,
    this.onUpload,
    this.onDelete,
    this.onEdit,
    this.loading = false,
    this.error,
    this.builder = _defaultBuilder,
  }) : _mode = _BigAvatarMode.chat,
       myUser = null,
       user = null;

  /// Builds a [BigAvatarWidget] of the provided [user].
  const BigAvatarWidget.user(
    this.user, {
    super.key,
    this.onUpload,
    this.onDelete,
    this.onEdit,
    this.loading = false,
    this.error,
  }) : _mode = _BigAvatarMode.user,
       myUser = null,
       chat = null,
       builder = _defaultBuilder;

  /// [MyUser] to display an [Avatar] of.
  final MyUser? myUser;

  /// [User] to display an [Avatar] of.
  final RxUser? user;

  /// [RxChat] to display an [Avatar] of.
  final RxChat? chat;

  /// Indicator whether a [CustomProgressIndicator] should be displayed.
  final bool loading;

  /// Text to display under the [Avatar], indicating an error.
  final String? error;

  /// Callback, called when an upload of [Avatar] is required.
  final void Function()? onUpload;

  /// Callback, called when delete of [Avatar] is required.
  final void Function()? onDelete;

  /// Callback, called when edit of [Avatar] is required.
  final void Function()? onEdit;

  /// Builder building the [AvatarWidget] itself.
  final Widget Function(Widget) builder;

  /// [_BigAvatarMode] of this [BigAvatarWidget].
  final _BigAvatarMode _mode;

  /// Returns the [child].
  static Widget _defaultBuilder(Widget child) => child;

  @override
  State<BigAvatarWidget> createState() => _BigAvatarWidgetState();
}

/// State of a [BigAvatarWidget] maintaining the [_avatarKey].
class _BigAvatarWidgetState extends State<BigAvatarWidget> {
  /// [GlobalKey] of an [AvatarWidget] to display [PlayerView] from.
  final GlobalKey _avatarKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final Iterable<void Function()> callbacks = [
      widget.onUpload,
      widget.onEdit,
      widget.onDelete,
    ].nonNulls;

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
                        width: AvatarRadius.largest.toDouble() * 2,
                        height: AvatarRadius.largest.toDouble() * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(
                            0.035 * (AvatarRadius.largest.toDouble() * 2),
                          ),
                          color: style.colors.onBackgroundOpacity13,
                        ),
                        child: const Center(child: CustomProgressIndicator()),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        if (callbacks.isNotEmpty) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: callbacks.length == 1
                  ? MainAxisSize.min
                  : MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.onUpload != null)
                  WidgetButton(
                    key: const Key('UploadAvatar'),
                    onPressed: widget.onUpload,
                    child: Text(
                      'btn_upload'.l10n,
                      style: style.fonts.small.regular.primary,
                    ),
                  ),
                if (widget.onEdit != null)
                  WidgetButton(
                    key: const Key('EditAvatar'),
                    onPressed: widget.onEdit,
                    child: Text(
                      'btn_edit'.l10n,
                      style: style.fonts.small.regular.primary,
                    ),
                  ),
                if (widget.onDelete != null)
                  WidgetButton(
                    key: const Key('DeleteAvatar'),
                    onPressed: widget.onDelete,
                    child: Text(
                      'btn_delete'.l10n,
                      style: style.fonts.small.regular.primary,
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (widget.error != null) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: AvatarRadius.largest.toDouble() * 2,
            child: Text(widget.error!, style: style.fonts.small.regular.danger),
          ),
          const SizedBox(height: 8),
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
          child = widget.builder(
            AvatarWidget.fromMyUser(
              widget.myUser,
              key: _avatarKey,
              radius: AvatarRadius.largest,
              badge: false,
              shape: BoxShape.rectangle,
            ),
          );
          break;

        case _BigAvatarMode.user:
          avatar = widget.user?.user.value.avatar;
          child = widget.builder(
            AvatarWidget.fromRxUser(
              widget.user,
              key: _avatarKey,
              radius: AvatarRadius.largest,
              badge: false,
              shape: BoxShape.rectangle,
            ),
          );
          break;

        case _BigAvatarMode.chat:
          avatar = widget.chat?.avatar.value;
          child = widget.builder(
            AvatarWidget.fromRxChat(
              widget.chat,
              key: _avatarKey,
              radius: AvatarRadius.largest,
              shape: BoxShape.rectangle,
            ),
          );
          break;
      }

      return WidgetButton(
        onPressed: avatar == null
            ? widget.onUpload
            : () async {
                await PlayerView.show(
                  context,
                  gallery: RegularGallery(
                    resourceId: ResourceId(chatId: widget.chat?.id),
                    items: [
                      MediaItem([
                        ImageAttachment(
                          id: AttachmentId.local(),
                          original: avatar!.original,
                          filename: '${DateTime.now()}',
                          big: avatar.big,
                          medium: avatar.medium,
                          small: avatar.small,
                        ),
                      ], null),
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
