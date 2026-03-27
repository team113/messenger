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
import 'package:medea_jason/medea_jason.dart';

import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/widget/video_view.dart';
import '/ui/page/home/page/my_profile/widget/switch_field.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/progress_indicator.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View for selecting display for screen sharing.
///
/// Intended to be displayed with the [show] method.
class ScreenShareView extends StatelessWidget {
  const ScreenShareView(this.call, {super.key});

  /// [OngoingCall] this [ScreenShareView] is bound to.
  final Rx<OngoingCall> call;

  /// Height of a single [RtcVideoView] to display.
  static const double videoHeight = 200;

  /// Displays a [ScreenShareView] wrapped in a [ModalPopup].
  static Future<ScreenShareRequest?> show<T>(
    BuildContext context,
    Rx<OngoingCall> call,
  ) {
    return ModalPopup.show<ScreenShareRequest?>(
      context: context,
      child: ScreenShareView(call),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    Widget framelessBuilder = const SizedBox(
      height: videoHeight,
      child: Center(child: CustomProgressIndicator()),
    );

    return GetBuilder(
      init: ScreenShareController(
        Get.find(),
        call: call,
        pop: context.popModal,
      ),
      builder: (ScreenShareController c) {
        return Obx(() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalPopupHeader(text: 'label_screen_sharing'.l10n),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  padding: ModalPopup.padding(context),
                  shrinkWrap: true,
                  itemBuilder: (_, i) {
                    return Obx(() {
                      final MediaDisplayDetails e = c.call.value.displays[i];
                      return GestureDetector(
                        onTap: () => c.selected.value = e,
                        child: SizedBox(
                          height: videoHeight,
                          child: c.renderers[e] != null
                              ? Center(
                                  child: RtcVideoView(
                                    c.renderers[e]!,
                                    border: c.selected.value == e
                                        ? Border.all(
                                            color: style.colors.primary,
                                            width: 4,
                                          )
                                        : null,
                                    source: MediaSourceKind.display,
                                    fit: BoxFit.contain,
                                    enableContextMenu: false,
                                    respectAspectRatio: true,
                                    framelessBuilder: () => framelessBuilder,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                )
                              : framelessBuilder,
                        ),
                      );
                    });
                  },
                  separatorBuilder: (c, i) => const SizedBox(height: 10),
                  itemCount: c.call.value.displays.length,
                ),
              ),
              Obx(() {
                if (!c.hasAudioSharingSupport.value) {
                  return const SizedBox();
                }

                return Padding(
                  padding: ModalPopup.padding(context),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 25),
                      SwitchField(
                        text: 'btn_share_audio'.l10n,
                        value: c.shareAudio.value,
                        onChanged: (b) => c.shareAudio.value = b,
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 25),
              Padding(
                padding: ModalPopup.padding(context),
                child: PrimaryButton(
                  key: const Key('Proceed'),
                  title: 'btn_share'.l10n,
                  onPressed: () {
                    c.freeTracks();

                    if (c.selected.value == null) {
                      Navigator.of(context).pop(null);
                    } else {
                      Navigator.of(context).pop(
                        ScreenShareRequest(
                          c.selected.value!,
                          audio: c.shareAudio.value,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        });
      },
    );
  }
}

/// [MediaDisplayDetails] along with a [audio] boolean whether it should be
/// included or not.
///
/// Intended to be served as a result of [ScreenShareView] invoke.
class ScreenShareRequest {
  const ScreenShareRequest(this.details, {this.audio = false});

  /// [MediaDisplayDetails] of this request.
  final MediaDisplayDetails details;

  /// Indicator whether audio should be captured as well.
  final bool audio;
}
