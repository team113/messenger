import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';
import 'package:medea_flutter_webrtc/medea_flutter_webrtc.dart' as webrtc;
import 'package:messenger/domain/model/ongoing_call.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/selector.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

class CameraSwitchView extends StatelessWidget {
  const CameraSwitchView(this._call, {super.key});

  final Rx<OngoingCall> _call;

  /// Displays a [LinkDetailsView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    required Rx<OngoingCall> call,
  }) {
    return ModalPopup.show(
      context: context,
      desktopConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      modalConstraints: const BoxConstraints(maxWidth: 380),
      mobilePadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      mobileConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      child: CameraSwitchView(call),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: CameraSwitchController(_call, Get.find()),
      builder: (CameraSwitchController c) {
        return AnimatedSizeAndFade(
          fadeDuration: const Duration(milliseconds: 250),
          sizeDuration: const Duration(milliseconds: 250),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16 - 12),
              ModalPopupHeader(
                header: Center(
                  child: Text(
                    'Camera'.l10n,
                    style: thin?.copyWith(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 25 - 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: ModalPopup.padding(context),
                  children: [
                    WidgetButton(
                      key: c.cameraKey,
                      onPressed: () async {
                        await Selector.menu(
                          context,
                          key: c.cameraKey,
                          width: 340,
                          alignment: Alignment.bottomLeft,
                          margin: const EdgeInsets.only(top: 30),
                          actions: c.devices.video().mapIndexed((i, e) {
                            final bool selected =
                                (c.camera.value == null && i == 0) ||
                                    c.camera.value == e.deviceId();

                            return ContextMenuButton(
                              label: e.label(),
                              onPressed: () => c.setVideoDevice(e.deviceId()),
                              style: const TextStyle(fontSize: 15),
                              trailing: AnimatedSwitcher(
                                duration: 200.milliseconds,
                                child: selected
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircleAvatar(
                                          backgroundColor: Color(0xFF63B4FF),
                                          radius: 12,
                                          child: Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      )
                                    : const SizedBox(key: Key('0')),
                              ),
                            );
                          }).toList(),
                        );
                      },
                      child: IgnorePointer(
                        child: ReactiveTextField(
                          label: 'label_media_camera'.l10n,
                          state: TextFieldState(
                            text: (c.devices.video().firstWhereOrNull((e) =>
                                            e.deviceId() == c.camera.value) ??
                                        c.devices.video().firstOrNull)
                                    ?.label() ??
                                'label_media_no_device_available'.l10n,
                            editable: false,
                          ),
                          trailing: RotatedBox(
                            quarterTurns: 3,
                            child: Icon(
                              Icons.arrow_back_ios_rounded,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: ModalPopup.padding(context),
                child: StreamBuilder(
                  stream: c.localTracks?.changes,
                  builder: (context, snapshot) {
                    RtcVideoRenderer? local = c.localTracks
                        ?.firstWhereOrNull((t) =>
                            t.source == MediaSourceKind.Device &&
                            t.renderer.value is RtcVideoRenderer)
                        ?.renderer
                        .value as RtcVideoRenderer?;
                    return Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 250,
                          width: 370,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: local == null
                              ? Center(
                                  child: SvgLoader.asset(
                                    'assets/icons/no_video.svg',
                                    width: 48.54,
                                    height: 42,
                                  ),
                                  // child: Icon(
                                  //   Icons.videocam_off,
                                  //   color: Colors.white,
                                  //   size: 40,
                                  // ),
                                )
                              : webrtc.VideoView(
                                  local.inner,
                                  objectFit: webrtc.VideoViewObjectFit.cover,
                                  mirror: true,
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // const SizedBox(height: 25),
              // Padding(
              //   padding: ModalPopup.padding(context),
              //   child: OutlinedRoundedButton(
              //     key: const Key('Proceed'),
              //     maxWidth: null,
              //     title: Text(
              //       'btn_proceed'.l10n,
              //       style: thin?.copyWith(color: Colors.white),
              //     ),
              //     onPressed: Navigator.of(context).pop,
              //     color: const Color(0xFF63B4FF),
              //   ),
              // ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
