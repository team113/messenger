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

import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import '/ui/page/call/widget/video_view.dart';
import '/ui/page/home/widget/confirm_dialog.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for selecting display for screen sharing.
///
/// Intended to be displayed with the [show] method.
class ScreenShareView extends StatelessWidget {
  const ScreenShareView(this.call, {Key? key}) : super(key: key);

  /// [OngoingCall] this [ScreenShareView] is bound to.
  final Rx<OngoingCall> call;

  /// Size of the biggest side of a [RtcVideoView].
  static const double videoSize = 200;

  /// Displays a [ScreenShareView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context, Rx<OngoingCall> call) {
    return ModalPopup.show<T>(
      context: context,
      child: ScreenShareView(call),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget framelessBuilder = const SizedBox(
      height: videoSize * (9 / 16),
      child: Center(child: CircularProgressIndicator()),
    );

    return GetBuilder(
      init: ScreenShareController(
        Get.find(),
        call: call,
        pop: Navigator.of(context).pop,
      ),
      builder: (ScreenShareController c) {
        return Obx(() {
          return ConfirmDialog(
            title: 'label_start_screen_sharing'.l10n,
            variants: call.value.displays
                .map(
                  (e) => ConfirmDialogVariant(
                    onProceed: () => call.value
                        .setScreenShareEnabled(true, deviceId: e.deviceId()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          constraints: const BoxConstraints(
                            maxWidth: videoSize,
                            maxHeight: videoSize,
                          ),
                          child: AnimatedSize(
                            duration: 200.milliseconds,
                            child: c.renderers[e] != null
                                ? RtcVideoView(
                                    c.renderers[e]!,
                                    source: MediaSourceKind.Display,
                                    mirror: false,
                                    fit: BoxFit.contain,
                                    enableContextMenu: false,
                                    respectAspectRatio: true,
                                    framelessBuilder: () => framelessBuilder,
                                  )
                                : framelessBuilder,
                          ),
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
