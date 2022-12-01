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

/// View for muting a [Chat] identified by its [chatId].
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
  final ChatId chatId;

  final List<MediaDisplayInfo> displays;

  /// Callback, called when a [Chat] mute action is triggered.
  final void Function(MediaDisplayInfo display)? onProceed;

  /// Displays a [ScreenShareSelector] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    required ChatId chatId,
    required List<MediaDisplayInfo> displays,
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
            title: 'label_mute_chat_for'.l10n,
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
                              minWidth: 100, maxWidth: 200),
                          child: SizedBox(
                            width: 150,
                            height: 100,
                            child: RtcVideoView(
                              c.renderers[e]!,
                              source: MediaSourceKind.Display,
                              mirror: false,
                              fit: BoxFit.fitWidth,
                              // borderRadius:
                              //     borderRadius ?? BorderRadius.circular(10),
                              // outline: outline,
                              // onSizeDetermined: onSizeDetermined,
                              enableContextMenu: false,
                              respectAspectRatio: true,
                              // offstageUntilDetermined: offstageUntilDetermined,
                              framelessBuilder: () =>
                                  Stack(children: const [Text('Preview')]),
                            ),
                          ),
                        ),
                        if (e.title() != null) Text(e.title()!),
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

// /// Dialog confirming a specific action from the provided [variants].
// ///
// /// Intended to be displayed with the [show] method.
// class ScreenShareSelector extends StatefulWidget {
//   const ScreenShareSelector({
//     Key? key,
//     required this.displays,
//   }) : super(key: key);
//
//   final List<MediaDisplayInfo> displays;
//
//   /// Displays a [ScreenShareSelector] wrapped in a [ModalPopup].
//   static Future<ScreenShareSelector?> show(
//     BuildContext context, {
//     required List<MediaDisplayInfo> displays,
//   }) {
//     return ModalPopup.show<ScreenShareSelector?>(
//       context: context,
//       child: ScreenShareSelector(displays: displays),
//     );
//   }
//
//   @override
//   State<ScreenShareSelector> createState() => _ScreenShareSelectorState();
// }

// /// State of a [ScreenShareSelector] keeping the selected [ConfirmDialogVariant].
// class _ScreenShareSelectorState extends State<ScreenShareSelector> {
//   /// Currently selected [ConfirmDialogVariant].
//   late MediaDisplayInfo? _display;
//
//   @override
//   void initState() {
//     //_deviceId = widget.variants.first;
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final TextStyle? thin =
//         Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);
//
//     // Builds a button representing the provided [ConfirmDialogVariant].
//     Widget button(MediaDisplayInfo variant) {
//       Style style = Theme.of(context).extension<Style>()!;
//       return Material(
//         type: MaterialType.card,
//         borderRadius: style.cardRadius,
//         child: InkWell(
//           onTap: () => setState(() => _display = variant),
//           borderRadius: style.cardRadius,
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: DefaultTextStyle.merge(
//                     style: Theme.of(context)
//                         .textTheme
//                         .bodyText1
//                         ?.copyWith(color: Colors.black, fontSize: 18),
//                     child: Container(),
//                   ),
//                 ),
//                 IgnorePointer(
//                   child: Radio<MediaDisplayInfo>(
//                     value: variant,
//                     groupValue: _display,
//                     onChanged: null,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }
//
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Flexible(
//           child: ListView.separated(
//             physics: const ClampingScrollPhysics(),
//             shrinkWrap: true,
//             itemBuilder: (c, i) => button(widget.variants[i]),
//             separatorBuilder: (c, i) => const SizedBox(height: 10),
//             itemCount: widget.variants.length,
//           ),
//         ),
//         Row(
//           children: [
//             Expanded(
//               child: OutlinedRoundedButton(
//                 key: const Key('Proceed'),
//                 maxWidth: null,
//                 title: Text(
//                   'btn_proceed'.l10n,
//                   style: thin?.copyWith(color: Colors.white),
//                 ),
//                 onPressed: () {
//                   _variant.onProceed?.call();
//                   Navigator.of(context).pop();
//                 },
//                 color: const Color(0xFF63B4FF),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: OutlinedRoundedButton(
//                 maxWidth: null,
//                 title: Text('btn_cancel'.l10n, style: thin),
//                 onPressed: Navigator.of(context).pop,
//                 color: const Color(0xFFEEEEEE),
//               ),
//             )
//           ],
//         ),
//         const SizedBox(height: 25),
//       ],
//     );
//   }
// }
