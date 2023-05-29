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

import '/domain/model/chat.dart';
import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/widget_button.dart';

/// [Widget] which returns a [Chat.avatar] visual representation along with its
/// manipulation buttons.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar(
    this.chat, {
    super.key,
    required this.avatar,
    this.avatarKey,
    this.pickAvatar,
    this.deleteAvatar,
  });

  /// Reactive [Chat] with chat items.
  final RxChat? chat;

  /// [GlobalKey] of an [AvatarWidget] displayed used to open a [GalleryPopup].
  final GlobalKey<State<StatefulWidget>>? avatarKey;

  /// Status of the [Chat.avatar] upload or removal.
  final RxStatus avatar;

  /// Opens a file choose popup and updates the [Chat.avatar] with the selected
  /// image, if any.
  final Future<void> Function()? pickAvatar;

  /// Resets the [Chat.avatar] to `null`.
  final Future<void> Function()? deleteAvatar;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            WidgetButton(
              key: Key('ChatAvatar_${chat!.id}'),
              onPressed: chat?.chat.value.avatar == null
                  ? pickAvatar
                  : () async {
                      await GalleryPopup.show(
                        context: context,
                        gallery: GalleryPopup(
                          initialKey: avatarKey,
                          children: [
                            GalleryItem.image(
                              chat!.chat.value.avatar!.original.url,
                              chat!.chat.value.id.val,
                            ),
                          ],
                        ),
                      );
                    },
              child: AvatarWidget.fromRxChat(
                chat,
                key: avatarKey,
                radius: 100,
              ),
            ),
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: 200.milliseconds,
                child: avatar.isLoading
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
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WidgetButton(
              key: const Key('UploadAvatar'),
              onPressed: pickAvatar,
              child: Text(
                'btn_upload'.l10n,
                style: TextStyle(color: style.colors.primary, fontSize: 11),
              ),
            ),
            if (chat?.chat.value.avatar != null) ...[
              Text(
                'space_or_space'.l10n,
                style:
                    TextStyle(color: style.colors.onBackground, fontSize: 11),
              ),
              WidgetButton(
                key: const Key('DeleteAvatar'),
                onPressed: deleteAvatar,
                child: Text(
                  'btn_delete'.l10n.toLowerCase(),
                  style: TextStyle(color: style.colors.primary, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
