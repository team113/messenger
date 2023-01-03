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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/my_profile/call_window_switch/view.dart';
import 'package:messenger/ui/page/home/page/my_profile/camera_switch/view.dart';
import 'package:messenger/ui/page/home/page/my_profile/output_switch/view.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '../../home/page/my_profile/microphone_switch/view.dart';
import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import 'controller.dart';

/// View of the call overlay settings.
class CallSettingsView extends StatelessWidget {
  const CallSettingsView(this._call, {super.key});

  /// The [OngoingCall] that this settings are bound to.
  final Rx<OngoingCall> _call;

  /// Displays a [CallSettingsView] wrapped in a [ModalPopup].
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
      child: CallSettingsView(call),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    Widget header(
      String text, {
      EdgeInsets padding = const EdgeInsets.fromLTRB(0, 0, 0, 12),
    }) {
      return Padding(
        padding: padding,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              text,
              style: style.systemMessageStyle
                  .copyWith(color: Colors.black, fontSize: 18),
            ),
          ),
        ),
      );
    }

    return GetBuilder(
      init: CallSettingsController(
        _call,
        Get.find(),
        onPop: Navigator.of(context).pop,
      ),
      builder: (CallSettingsController c) {
        return Stack(
          children: [
            ListView(
              shrinkWrap: true,
              children: [
                const SizedBox(height: 12),
                header('Медиа'),
                _dense(
                  context,
                  WidgetButton(
                    onPressed: () =>
                        CameraSwitchView.show(context, call: _call),
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
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _dense(
                  context,
                  WidgetButton(
                    onPressed: () =>
                        MicrophoneSwitchView.show(context, call: _call),
                    child: IgnorePointer(
                      child: ReactiveTextField(
                        label: 'label_media_microphone'.l10n,
                        state: TextFieldState(
                          text: (c.devices.audio().firstWhereOrNull(
                                          (e) => e.deviceId() == c.mic.value) ??
                                      c.devices.audio().firstOrNull)
                                  ?.label() ??
                              'label_media_no_device_available'.l10n,
                          editable: false,
                        ),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _dense(
                  context,
                  WidgetButton(
                    onPressed: () =>
                        OutputSwitchView.show(context, call: _call),
                    child: IgnorePointer(
                      child: ReactiveTextField(
                        label: 'label_media_output'.l10n,
                        state: TextFieldState(
                          text: (c.devices.output().firstWhereOrNull((e) =>
                                          e.deviceId() == c.output.value) ??
                                      c.devices.output().firstOrNull)
                                  ?.label() ??
                              'label_media_no_device_available'.l10n,
                          editable: false,
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                header('Звонки'),
                _dense(
                  context,
                  WidgetButton(
                    onPressed: () => CallWindowSwitchView.show(context),
                    child: IgnorePointer(
                      child: ReactiveTextField(
                        state: TextFieldState(
                          text: (c.settings.value?.enablePopups ?? true)
                              ? 'Отображать звонки в отдельном окне.'
                              : 'Отображать звонки в окне приложения.',
                        ),
                        maxLines: null,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            const ModalPopupHeader(),
          ],
        );
      },
    );
  }

  /// Dense [Padding] wrapper.
  Widget _dense(BuildContext context, Widget child) => Padding(
        padding: ModalPopup.padding(context)
            .add(const EdgeInsets.fromLTRB(8, 4, 8, 4)),
        child: child,
      );
}


// // Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// //
// // This program is free software: you can redistribute it and/or modify it under
// // the terms of the GNU Affero General Public License v3.0 as published by the
// // Free Software Foundation, either version 3 of the License, or (at your
// // option) any later version.
// //
// // This program is distributed in the hope that it will be useful, but WITHOUT
// // ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// // FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// // more details.
// //
// // You should have received a copy of the GNU Affero General Public License v3.0
// // along with this program. If not, see
// // <https://www.gnu.org/licenses/agpl-3.0.html>.

// import 'package:collection/collection.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:medea_flutter_webrtc/medea_flutter_webrtc.dart' as webrtc;
// import 'package:medea_jason/medea_jason.dart';
// import 'package:messenger/themes.dart';
// import 'package:messenger/ui/page/home/page/my_profile/camera_switch/view.dart';
// import 'package:messenger/ui/page/home/page/my_profile/output_switch/view.dart';
// import 'package:messenger/ui/page/home/widget/avatar.dart';
// import 'package:messenger/ui/widget/modal_popup.dart';
// import 'package:messenger/ui/widget/svg/svg.dart';
// import 'package:messenger/ui/widget/text_field.dart';
// import 'package:messenger/ui/widget/widget_button.dart';

// import '../../home/page/my_profile/microphone_switch/view.dart';
// import '/domain/model/ongoing_call.dart';
// import '/l10n/l10n.dart';
// import '/util/platform_utils.dart';
// import 'controller.dart';

// /// View of the call overlay settings.
// class CallSettingsView extends StatefulWidget {
//   const CallSettingsView(
//     this._call, {
//     Key? key,
//     this.lmbValue = false,
//     this.onLmbChanged,
//     this.panelValue = false,
//     this.onPanelChanged,
//   }) : super(key: key);

//   /// The [OngoingCall] that this settings are bound to.
//   final Rx<OngoingCall> _call;

//   /// Temporary initial value of [CallController.handleLmb].
//   final bool lmbValue;

//   /// Temporary callback, called when [lmbValue] switches.
//   final void Function(bool?)? onLmbChanged;

//   /// Temporary initial value of [CallController.panelUp].
//   final bool panelValue;

//   /// Temporary callback, called when [panelValue] switches.
//   final void Function(bool?)? onPanelChanged;

//   /// Displays a [CallSettingsView] wrapped in a [ModalPopup].
//   static Future<T?> show<T>(
//     BuildContext context, {
//     required Rx<OngoingCall> call,
//   }) {
//     return ModalPopup.show(
//       context: context,
//       desktopConstraints: const BoxConstraints(
//         maxWidth: double.infinity,
//         maxHeight: double.infinity,
//       ),
//       modalConstraints: const BoxConstraints(maxWidth: 380),
//       mobilePadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
//       mobileConstraints: const BoxConstraints(
//         maxWidth: double.infinity,
//         maxHeight: double.infinity,
//       ),
//       child: CallSettingsView(call),
//     );
//   }

//   @override
//   State<CallSettingsView> createState() => _CallSettingsViewState();
// }

// /// State of a [CallSettingsView] used to keep [Checkbox] values.
// class _CallSettingsViewState extends State<CallSettingsView> {
//   /// Current value of a [Checkbox] representing [CallController.handleLmb].
//   late bool _lmbValue;

//   /// Current value of a [Checkbox] representing [CallController.panelUp].
//   late bool _panelValue;

//   @override
//   void initState() {
//     _lmbValue = widget.lmbValue;
//     _panelValue = widget.panelValue;
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final Style style = Theme.of(context).extension<Style>()!;

//     Widget header(
//       String text, {
//       EdgeInsets padding = const EdgeInsets.fromLTRB(0, 0, 0, 12),
//     }) {
//       return Padding(
//         padding: padding,
//         child: Center(
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             child: Text(
//               text,
//               style: style.systemMessageStyle
//                   .copyWith(color: Colors.black, fontSize: 18),
//             ),
//           ),
//         ),
//       );
//     }

//     return GetBuilder(
//       init: CallSettingsController(
//         widget._call,
//         Get.find(),
//         onPop: Navigator.of(context).pop,
//       ),
//       builder: (CallSettingsController c) {
//         return Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ModalPopupHeader(
//               header: header(
//                 'Настройка видео/аудио звонков'.l10n,
//                 padding: EdgeInsets.zero,
//               ),
//             ),
//             Expanded(
//               child: ListView(
//                 shrinkWrap: true,
//                 children: [
//                   const SizedBox(height: 8),
//                   header('label_media_camera'.l10n),
//                   Padding(
//                     padding: ModalPopup.padding(context),
//                     child: StreamBuilder(
//                       stream: c.localTracks?.changes,
//                       builder: (context, snapshot) {
//                         RtcVideoRenderer? local = c.localTracks
//                             ?.firstWhereOrNull((t) =>
//                                 t.source == MediaSourceKind.Device &&
//                                 t.renderer.value is RtcVideoRenderer)
//                             ?.renderer
//                             .value as RtcVideoRenderer?;
//                         return Center(
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(10),
//                             child: Container(
//                               height: 250,
//                               width: 370,
//                               decoration: BoxDecoration(
//                                 color: Colors.grey,
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               child: local == null
//                                   ? Center(
//                                       child: SvgLoader.asset(
//                                         'assets/icons/no_video.svg',
//                                         width: 48.54,
//                                         height: 42,
//                                       ),
//                                     )
//                                   : webrtc.VideoView(
//                                       local.inner,
//                                       objectFit:
//                                           webrtc.VideoViewObjectFit.cover,
//                                       mirror: true,
//                                     ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   if (c.devices.video().isEmpty)
//                     const Text('None')
//                   else
//                     ...c.devices.video().mapIndexed((i, e) {
//                       return Obx(() {
//                         final MediaDeviceInfo e = c.devices.video().toList()[i];

//                         final bool selected =
//                             (c.camera.value == null && i == 0) ||
//                                 c.camera.value == e.deviceId();

//                         return Padding(
//                           padding: ModalPopup.padding(context)
//                               .add(const EdgeInsets.only(bottom: 8)),
//                           child: Material(
//                             borderRadius: BorderRadius.circular(10),
//                             color: selected
//                                 ? const Color(0xFFD7ECFF).withOpacity(0.8)
//                                 : Colors.white.darken(0.05),
//                             child: InkWell(
//                               borderRadius: BorderRadius.circular(10),
//                               onTap: () => c.setVideoDevice(e.deviceId()),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(16.0),
//                                 child: Row(
//                                   children: [
//                                     Expanded(
//                                       child: Text(
//                                         e.label(),
//                                         maxLines: 2,
//                                         overflow: TextOverflow.ellipsis,
//                                         style: const TextStyle(fontSize: 15),
//                                       ),
//                                     ),
//                                     const SizedBox(width: 12),
//                                     AnimatedSwitcher(
//                                       duration: 200.milliseconds,
//                                       child: selected
//                                           ? const SizedBox(
//                                               width: 20,
//                                               height: 20,
//                                               child: CircleAvatar(
//                                                 backgroundColor:
//                                                     Color(0xFF63B4FF),
//                                                 radius: 12,
//                                                 child: Icon(
//                                                   Icons.check,
//                                                   color: Colors.white,
//                                                   size: 12,
//                                                 ),
//                                               ),
//                                             )
//                                           : const SizedBox(
//                                               width: 20,
//                                               height: 20,
//                                               key: Key('0'),
//                                             ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         );
//                       });
//                     }),

//                   // _dense(
//                   //   WidgetButton(
//                   //     onPressed: () =>
//                   //         CameraSwitchView.show(context, call: widget._call),
//                   //     child: IgnorePointer(
//                   //       child: ReactiveTextField(
//                   //         label: 'label_media_camera'.l10n,
//                   //         state: TextFieldState(
//                   //           text: (c.devices.video().firstWhereOrNull((e) =>
//                   //                           e.deviceId() == c.camera.value) ??
//                   //                       c.devices.video().firstOrNull)
//                   //                   ?.label() ??
//                   //               'label_media_no_device_available'.l10n,
//                   //           editable: false,
//                   //         ),
//                   //         style: TextStyle(
//                   //             color: Theme.of(context).colorScheme.secondary),
//                   //       ),
//                   //     ),
//                   //   ),
//                   // ),
//                   const SizedBox(height: 16),
//                   header('label_media_microphone'.l10n),
//                   if (c.devices.audio().isEmpty)
//                     const Text('None')
//                   else
//                     ...c.devices.audio().mapIndexed((i, e) {
//                       return Obx(() {
//                         final MediaDeviceInfo e = c.devices.audio().toList()[i];

//                         final bool selected = (c.mic.value == null && i == 0) ||
//                             c.mic.value == e.deviceId();

//                         return Padding(
//                           padding: ModalPopup.padding(context)
//                               .add(const EdgeInsets.only(bottom: 8)),
//                           child: Material(
//                             borderRadius: BorderRadius.circular(10),
//                             color: selected
//                                 ? const Color(0xFFD7ECFF).withOpacity(0.8)
//                                 : Colors.white.darken(0.05),
//                             child: InkWell(
//                               borderRadius: BorderRadius.circular(10),
//                               onTap: () => c.setAudioDevice(e.deviceId()),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(16.0),
//                                 child: Row(
//                                   children: [
//                                     Expanded(
//                                       child: Text(
//                                         e.label(),
//                                         maxLines: 2,
//                                         overflow: TextOverflow.ellipsis,
//                                         style: const TextStyle(fontSize: 15),
//                                       ),
//                                     ),
//                                     const SizedBox(width: 12),
//                                     AnimatedSwitcher(
//                                       duration: 200.milliseconds,
//                                       child: selected
//                                           ? const SizedBox(
//                                               width: 20,
//                                               height: 20,
//                                               child: CircleAvatar(
//                                                 backgroundColor:
//                                                     Color(0xFF63B4FF),
//                                                 radius: 12,
//                                                 child: Icon(
//                                                   Icons.check,
//                                                   color: Colors.white,
//                                                   size: 12,
//                                                 ),
//                                               ),
//                                             )
//                                           : const SizedBox(
//                                               width: 20,
//                                               height: 20,
//                                               key: Key('0'),
//                                             ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         );
//                       });
//                     }),

//                   // _dense(
//                   //   WidgetButton(
//                   //     onPressed: () =>
//                   //         MicrophoneSwitchView.show(context, call: widget._call),
//                   //     child: IgnorePointer(
//                   //       child: ReactiveTextField(
//                   //         label: 'label_media_microphone'.l10n,
//                   //         state: TextFieldState(
//                   //           text: (c.devices.audio().firstWhereOrNull(
//                   //                           (e) => e.deviceId() == c.mic.value) ??
//                   //                       c.devices.audio().firstOrNull)
//                   //                   ?.label() ??
//                   //               'label_media_no_device_available'.l10n,
//                   //           editable: false,
//                   //         ),
//                   //         style: TextStyle(
//                   //             color: Theme.of(context).colorScheme.secondary),
//                   //       ),
//                   //     ),
//                   //   ),
//                   // ),
//                   const SizedBox(height: 16),
//                   header('label_media_output'.l10n),

//                   if (c.devices.output().isEmpty)
//                     const Text('None')
//                   else
//                     ...c.devices.output().mapIndexed((i, e) {
//                       return Obx(() {
//                         final MediaDeviceInfo e =
//                             c.devices.output().toList()[i];

//                         final bool selected =
//                             (c.output.value == null && i == 0) ||
//                                 c.output.value == e.deviceId();

//                         return Padding(
//                           padding: ModalPopup.padding(context)
//                               .add(const EdgeInsets.only(bottom: 8)),
//                           child: Material(
//                             borderRadius: BorderRadius.circular(10),
//                             color: selected
//                                 ? const Color(0xFFD7ECFF).withOpacity(0.8)
//                                 : Colors.white.darken(0.05),
//                             child: InkWell(
//                               borderRadius: BorderRadius.circular(10),
//                               onTap: () => c.setOutputDevice(e.deviceId()),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(16.0),
//                                 child: Row(
//                                   children: [
//                                     Expanded(
//                                       child: Text(
//                                         e.label(),
//                                         maxLines: 2,
//                                         overflow: TextOverflow.ellipsis,
//                                         style: const TextStyle(fontSize: 15),
//                                       ),
//                                     ),
//                                     const SizedBox(width: 12),
//                                     AnimatedSwitcher(
//                                       duration: 200.milliseconds,
//                                       child: selected
//                                           ? const SizedBox(
//                                               width: 20,
//                                               height: 20,
//                                               child: CircleAvatar(
//                                                 backgroundColor:
//                                                     Color(0xFF63B4FF),
//                                                 radius: 12,
//                                                 child: Icon(
//                                                   Icons.check,
//                                                   color: Colors.white,
//                                                   size: 12,
//                                                 ),
//                                               ),
//                                             )
//                                           : const SizedBox(
//                                               width: 20,
//                                               height: 20,
//                                               key: Key('0'),
//                                             ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         );
//                       });
//                     }),

//                   // _dense(
//                   //   WidgetButton(
//                   //     onPressed: () =>
//                   //         OutputSwitchView.show(context, call: widget._call),
//                   //     child: IgnorePointer(
//                   //       child: ReactiveTextField(
//                   //         label: 'label_media_output'.l10n,
//                   //         state: TextFieldState(
//                   //           text: (c.devices.output().firstWhereOrNull(
//                   //                           (e) => e.deviceId() == c.output.value) ??
//                   //                       c.devices.output().firstOrNull)
//                   //                   ?.label() ??
//                   //               'label_media_no_device_available'.l10n,
//                   //           editable: false,
//                   //         ),
//                   //         style: TextStyle(
//                   //             color: Theme.of(context).colorScheme.secondary),
//                   //       ),
//                   //     ),
//                   //   ),
//                   // ),
//                   const SizedBox(height: 16),
//                 ],
//               ),
//             ),
//           ],
//         );
//       },
//     );

//     // TextStyle font17 = context.theme.outlinedButtonTheme.style!.textStyle!
//     //     .resolve({MaterialState.disabled})!.copyWith(color: Colors.black);

//     // Widget divider = Container(
//     //   margin: const EdgeInsets.symmetric(horizontal: 9),
//     //   color: const Color(0x99000000),
//     //   height: 1,
//     //   width: double.infinity,
//     // );

//     // Widget row(Widget left, Widget right, [bool flexible = false]) => Padding(
//     //       padding: const EdgeInsets.symmetric(horizontal: 18),
//     //       child: Row(
//     //         children: [
//     //           Expanded(flex: 9, child: left),
//     //           flexible
//     //               ? Flexible(flex: 31, child: right)
//     //               : Expanded(flex: 31, child: right),
//     //         ],
//     //       ),
//     //     );

//     // Widget dropdown({
//     //   required MediaDeviceInfo? value,
//     //   required Iterable<MediaDeviceInfo> devices,
//     //   required ValueChanged<MediaDeviceInfo?> onChanged,
//     // }) =>
//     //     Container(
//     //       margin: const EdgeInsets.symmetric(horizontal: 10),
//     //       padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
//     //       decoration: BoxDecoration(
//     //         color: Colors.white,
//     //         borderRadius: BorderRadius.circular(18),
//     //       ),
//     //       height: 36,
//     //       child: DropdownButton<MediaDeviceInfo>(
//     //         value: value,
//     //         items: devices
//     //             .map<DropdownMenuItem<MediaDeviceInfo>>(
//     //               (MediaDeviceInfo e) =>
//     //                   DropdownMenuItem(value: e, child: Text(e.label())),
//     //             )
//     //             .toList(),
//     //         onChanged: onChanged,
//     //         borderRadius: BorderRadius.circular(18),
//     //         isExpanded: true,
//     //         icon: const Icon(
//     //           Icons.keyboard_arrow_down,
//     //           color: Colors.black,
//     //           size: 31,
//     //         ),
//     //         disabledHint: Text('label_media_no_device_available'.l10n),
//     //         style: context.textTheme.subtitle1?.copyWith(color: Colors.black),
//     //         underline: const SizedBox(),
//     //       ),
//     //     );

//     // // Wrapper around [Checkbox].
//     // Widget checkbox({
//     //   required bool? value,
//     //   required void Function(bool?)? onChanged,
//     //   required String label,
//     // }) =>
//     //     Column(
//     //       mainAxisAlignment: MainAxisAlignment.center,
//     //       children: [
//     //         Theme(
//     //           data: Theme.of(context)
//     //               .copyWith(unselectedWidgetColor: Colors.black),
//     //           child: Checkbox(value: value, onChanged: onChanged),
//     //         ),
//     //         Text(
//     //           label,
//     //           style: context.textTheme.subtitle2
//     //               ?.copyWith(fontSize: 9, color: Colors.black),
//     //           maxLines: 1,
//     //         ),
//     //       ],
//     //     );

//     // return MediaQuery.removeViewInsets(
//     //   removeLeft: true,
//     //   removeTop: true,
//     //   removeRight: true,
//     //   removeBottom: true,
//     //   context: context,
//     //   child: Center(
//     //     child: ConstrainedBox(
//     //       constraints: const BoxConstraints(
//     //         maxWidth: 600,
//     //         maxHeight: 592,
//     //       ),
//     //       child: Material(
//     //         color: const Color(0xCCFFFFFF),
//     //         elevation: 8,
//     //         shape:
//     //             RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//     //         type: MaterialType.card,
//     //         child: GetBuilder(
//     //           init: CallSettingsController(
//     //             widget._call,
//     //             Get.find(),
//     //             onPop: Navigator.of(context).pop,
//     //           ),
//     //           builder: (CallSettingsController c) => Obx(
//     //             () => Column(
//     //               children: [
//     //                 const SizedBox(height: 5),
//     //                 Padding(
//     //                   padding: const EdgeInsets.fromLTRB(18, 0, 5, 0),
//     //                   child: Row(
//     //                     children: [
//     //                       Text('label_media_settings'.l10n, style: font17),
//     //                       const Spacer(),
//     //                       if (PlatformUtils.isDesktop) ...[
//     //                         checkbox(
//     //                           label: 'LMB',
//     //                           value: _lmbValue,
//     //                           onChanged: (b) {
//     //                             setState(() => _lmbValue = b ?? false);
//     //                             widget.onLmbChanged?.call(b);
//     //                           },
//     //                         ),
//     //                         const SizedBox(width: 5),
//     //                         checkbox(
//     //                           label: 'Panel up',
//     //                           value: _panelValue,
//     //                           onChanged: (b) {
//     //                             setState(() => _panelValue = b ?? false);
//     //                             widget.onPanelChanged?.call(b);
//     //                           },
//     //                         ),
//     //                         const SizedBox(width: 16),
//     //                       ],
//     //                       IconButton(
//     //                         hoverColor: Colors.transparent,
//     //                         highlightColor: Colors.transparent,
//     //                         splashColor: Colors.transparent,
//     //                         onPressed: Navigator.of(context).pop,
//     //                         icon: const Icon(Icons.close, size: 20),
//     //                       ),
//     //                     ],
//     //                   ),
//     //                 ),
//     //                 const SizedBox(height: 5),
//     //                 divider,
//     //                 Expanded(
//     //                   child: ListView(
//     //                     children: [
//     //                       const SizedBox(height: 25),
//     //                       row(
//     //                         Text('label_media_camera'.l10n, style: font17),
//     //                         dropdown(
//     //                           value: c.devices.video().firstWhereOrNull((e) =>
//     //                                   e.deviceId() == c.videoDevice.value) ??
//     //                               c.devices.video().firstOrNull,
//     //                           devices: c.devices.video(),
//     //                           onChanged: (d) => c.setVideoDevice(d!.deviceId()),
//     //                         ),
//     //                       ),
//     //                       const SizedBox(height: 25),
//     //                       StreamBuilder(
//     //                         stream: c.localTracks?.changes,
//     //                         builder: (context, snapshot) {
//     //                           RtcVideoRenderer? local = c.localTracks
//     //                               ?.firstWhereOrNull((t) =>
//     //                                   t.source == MediaSourceKind.Device &&
//     //                                   t.renderer.value is RtcVideoRenderer)
//     //                               ?.renderer
//     //                               .value as RtcVideoRenderer?;
//     //                           return row(
//     //                             Container(),
//     //                             Center(
//     //                               child: ClipRRect(
//     //                                 borderRadius: BorderRadius.circular(10),
//     //                                 child: Container(
//     //                                   height: 250,
//     //                                   width: 370,
//     //                                   decoration: BoxDecoration(
//     //                                     color: Colors.grey,
//     //                                     borderRadius: BorderRadius.circular(10),
//     //                                   ),
//     //                                   child: local == null
//     //                                       ? const Center(
//     //                                           child: Icon(
//     //                                             Icons.videocam_off,
//     //                                             color: Colors.white,
//     //                                             size: 40,
//     //                                           ),
//     //                                         )
//     //                                       : webrtc.VideoView(
//     //                                           local.inner,
//     //                                           objectFit: webrtc
//     //                                               .VideoViewObjectFit.cover,
//     //                                           mirror: true,
//     //                                         ),
//     //                                 ),
//     //                               ),
//     //                             ),
//     //                             true,
//     //                           );
//     //                         },
//     //                       ),
//     //                       const SizedBox(height: 25),
//     //                       divider,
//     //                       const SizedBox(height: 25),
//     //                       row(
//     //                         Text('label_media_microphone'.l10n, style: font17),
//     //                         dropdown(
//     //                           value: c.devices.audio().firstWhereOrNull((e) =>
//     //                                   e.deviceId() == c.audioDevice.value) ??
//     //                               c.devices.audio().firstOrNull,
//     //                           devices: c.devices.audio(),
//     //                           onChanged: (d) => c.setAudioDevice(d!.deviceId()),
//     //                         ),
//     //                       ),
//     //                       const SizedBox(height: 25),
//     //                       divider,
//     //                       const SizedBox(height: 25),
//     //                       row(
//     //                         Text('label_media_output'.l10n, style: font17),
//     //                         dropdown(
//     //                           value: c.devices.output().firstWhereOrNull((e) =>
//     //                                   e.deviceId() == c.outputDevice.value) ??
//     //                               c.devices.output().firstOrNull,
//     //                           devices: c.devices.output(),
//     //                           onChanged: (d) =>
//     //                               c.setOutputDevice(d!.deviceId()),
//     //                         ),
//     //                       ),
//     //                       const SizedBox(height: 25),
//     //                     ],
//     //                   ),
//     //                 ),
//     //               ],
//     //             ),
//     //           ),
//     //         ),
//     //       ),
//     //     ),
//     //   ),
//     // );
//   }

//   /// Dense [Padding] wrapper.
//   Widget _dense(Widget child) =>
//       Padding(padding: const EdgeInsets.fromLTRB(8, 4, 8, 4), child: child);
// }
