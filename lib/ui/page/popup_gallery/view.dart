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

import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/chat_gallery.dart';
import '/ui/page/player/view.dart';
import '/ui/widget/progress_indicator.dart';
import '/util/scoped_dependencies.dart';
import 'controller.dart';

/// View of the [Routes.gallery] page.
class PopupGalleryView extends StatefulWidget {
  const PopupGalleryView({
    super.key,
    required this.chatId,
    this.initialKey,
    this.initialIndex = 0,
    required this.depsFactory,
  });

  /// ID of a [Chat] this call is taking place in.
  final ChatId chatId;

  /// Initial [String] to pass to a [PlayerView.initialKey].
  final String? initialKey;

  /// Initial [int] to pass to a [PlayerView.initialKey].
  final int initialIndex;

  /// [ScopedDependencies] factory of the [Routes.gallery] page.
  final Future<ScopedDependencies> Function() depsFactory;

  @override
  State<PopupGalleryView> createState() => _PopupChatViewState();
}

/// State of a [PopupGalleryView] maintaining the [_deps].
class _PopupChatViewState extends State<PopupGalleryView> {
  /// [Routes.gallery] page dependencies.
  ScopedDependencies? _deps;

  /// [ChatItemKey] for the initial [ChatItem] to display, if any.
  ChatItemKey? _key;

  @override
  void initState() {
    super.initState();
    widget.depsFactory().then((v) => setState(() => _deps = v));

    if (widget.initialKey != null) {
      try {
        _key = ChatItemKey.fromString(widget.initialKey!);
      } catch (_) {
        // No-op.
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _deps?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_deps == null) {
      return const Scaffold(body: Center(child: CustomProgressIndicator()));
    }

    final style = Theme.of(context).style;

    return GetBuilder<PopupGalleryController>(
      init: PopupGalleryController(widget.chatId, Get.find()),
      builder: (PopupGalleryController c) {
        return Scaffold(
          backgroundColor: style.colors.backgroundGallery,
          body: Obx(() {
            if (c.chat.value != null) {
              return PaginatedGallery(
                key: c.key,
                paginated: c.calculateGallery(_key?.id),
                resourceId: ResourceId(chatId: widget.chatId),
                initial: widget.initialKey == null
                    ? null
                    : (widget.initialKey!, widget.initialIndex),
              );
            }

            if (c.status.value.isLoading) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: CustomProgressIndicator.primary()),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Text('err_popup_call_cant_be_closed'.l10n),
                  ),
                ),
              );
            }
          }),
        );
      },
    );
  }
}
