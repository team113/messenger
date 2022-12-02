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
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import '/domain/model/chat.dart';
import '/l10n/l10n.dart';
import '/ui/page/call/widget/video_view.dart';
import '/ui/page/home/widget/confirm_dialog.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for selecting display for screen sharing.
///
/// Intended to be displayed with the [show] method.
class ScreenShareSelector extends StatelessWidget {
  const ScreenShareSelector({
    Key? key,
    required this.chatId,
    required this.displays,
    this.onProceed,
  }) : super(key: key);

  /// ID of the [Chat] to mute.
  final Rx<ChatId> chatId;

  /// Available [MediaDisplayInfo]s for screen sharing.
  final RxList<MediaDisplayInfo> displays;

  /// Callback, called when this [ScreenShareSelector] is submitted.
  final void Function(MediaDisplayInfo display)? onProceed;

  /// Displays a [ScreenShareSelector] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    required Rx<ChatId> chatId,
    required RxList<MediaDisplayInfo> displays,
    void Function(MediaDisplayInfo duration)? onProceed,
  }) {
    return ModalPopup.show(
      context: context,
      child: ScreenShareSelector(
        chatId: chatId,
        displays: displays,
        onProceed: onProceed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: ScreenShareSelectorController(
        Get.find(),
        chatId: chatId,
        displays: displays,
        pop: Navigator.of(context).pop,
      ),
      builder: (ScreenShareSelectorController c) {
        return Obx(() {
          if (c.isReady.isFalse) {
            return const CircularProgressIndicator();
          }

          return ConfirmDialog(
            title: 'label_start_screen_sharing'.l10n,
            variants: displays
                .map(
                  (e) => ConfirmDialogVariant(
                    onProceed: () => onProceed?.call(e),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          constraints: const BoxConstraints(
                            maxWidth: 200,
                            maxHeight: 200,
                          ),
                          child: c.renderers[e] != null
                              ? RtcVideoView(
                                  c.renderers[e]!,
                                  source: MediaSourceKind.Display,
                                  mirror: false,
                                  fit: BoxFit.fitWidth,
                                  enableContextMenu: false,
                                  respectAspectRatio: true,
                                )
                              : const CircularProgressIndicator(),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
        });
      },
    );
  }
}
