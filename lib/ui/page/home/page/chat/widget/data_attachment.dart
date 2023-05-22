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

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:path/path.dart' as p;

// import '/domain/model/attachment.dart';
// import '/domain/model/sending_status.dart';
// import '/l10n/l10n.dart';
// import '/themes.dart';
// import '/ui/widget/svg/svg.dart';
// import '/ui/widget/widget_button.dart';

// /// Visual representation of a file [Attachment].
// class DataAttachment extends StatefulWidget {
//   const DataAttachment(this.attachment, {super.key, this.onPressed});

//   /// [Attachment] to display.
//   final Attachment attachment;

//   /// Callback, called when this [DataAttachment] is pressed.
//   final void Function(Attachment)? onPressed;

//   @override
//   State<DataAttachment> createState() => _DataAttachmentState();
// }

// /// State of a [DataAttachment] maintaining the [_hovered] indicator.
// class _DataAttachmentState extends State<DataAttachment> {
//   /// Indicator whether this [DataAttachment] is hovered.
//   bool _hovered = false;

//   @override
//   Widget build(BuildContext context) {
//     final Attachment e = widget.attachment;

//     return Obx(() {
//       Widget leading = Container();

//       if (e is FileAttachment) {
//         switch (e.downloadStatus.value) {
//           case DownloadStatus.inProgress:
//             leading = InkWell(
//               key: const Key('CancelDownloading'),
//               onTap: e.cancelDownload,
//               child: Container(
//                 key: const Key('Downloading'),
//                 width: 17,
//                 height: 17,
//                 decoration: BoxDecoration(
//                   border: Border.all(
//                     width: 2,
//                     color: Theme.of(context).colorScheme.primary,
//                   ),
//                   shape: BoxShape.circle,
//                   gradient: LinearGradient(
//                     begin: Alignment.bottomCenter,
//                     end: Alignment.topCenter,
//                     colors: [
//                       Theme.of(context).colorScheme.primary,
//                       Theme.of(context).colorScheme.primary,
//                       const Color(0xFFD1E1F0),
//                     ],
//                     stops: [
//                       0,
//                       e.progress.value,
//                       e.progress.value,
//                     ],
//                   ),
//                 ),
//                 child: Center(
//                   child: SvgImage.asset(
//                     'assets/icons/cancel.svg',
//                     width: 8,
//                     height: 8,
//                   ),
//                 ),
//               ),
//             );
//             break;

//           case DownloadStatus.isFinished:
//             leading = Container(
//               key: const Key('Downloaded'),
//               height: 17,
//               width: 17,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               child: const Center(
//                 child: Icon(
//                   Icons.insert_drive_file,
//                   color: Colors.white,
//                   size: 8,
//                 ),
//               ),
//             );
//             break;

//           case DownloadStatus.notStarted:
//             leading = AnimatedContainer(
//               duration: const Duration(milliseconds: 200),
//               key: const Key('Download'),
//               height: 17,
//               width: 17,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: _hovered
//                     ? const Color(0xFFD1E1F0)
//                     : const Color(0x00D1E1F0),
//                 border: Border.all(
//                   width: 2,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//               ),
//               child: KeyedSubtree(
//                 key: const Key('Sent'),
//                 child: Center(
//                   child: SvgImage.asset(
//                     'assets/icons/arrow_down.svg',
//                     width: 10.55 * 0.5,
//                     height: 14 * 0.5,
//                   ),
//                 ),
//               ),
//             );
//             break;
//         }
//       } else if (e is LocalAttachment) {
//         switch (e.status.value) {
//           case SendingStatus.sending:
//             leading = SizedBox.square(
//               key: const Key('Sending'),
//               dimension: 18,
//               child: CircularProgressIndicator(
//                 value: e.progress.value,
//                 backgroundColor: Colors.white,
//                 strokeWidth: 5,
//               ),
//             );
//             break;

//           case SendingStatus.sent:
//             leading = const Icon(
//               Icons.check_circle,
//               key: Key('Sent'),
//               size: 18,
//               color: Colors.green,
//             );
//             break;

//           case SendingStatus.error:
//             leading = const Icon(
//               Icons.error_outline,
//               key: Key('Error'),
//               size: 18,
//               color: Colors.red,
//             );
//             break;
//         }
//       }

//       final Style style = Theme.of(context).extension<Style>()!;

//       return MouseRegion(
//         onEnter: (_) => setState(() => _hovered = true),
//         onExit: (_) => setState(() => _hovered = false),
//         child: Padding(
//           key: Key('File_${e.id}'),
//           padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
//           child: WidgetButton(
//             onPressed: () => widget.onPressed?.call(e),
//             child: Container(
//               decoration: const BoxDecoration(
//                   // borderRadius: BorderRadius.circular(10),
//                   // border: Border.all(
//                   //   color: Colors.black.withOpacity(0.1),
//                   //   width: 0.5,
//                   // ),
//                   // color: Colors.black.withOpacity(0.03),
//                   ),
//               // padding: const EdgeInsets.all(4),
//               child: Row(
//                 children: [
//                   const SizedBox(width: 8),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 8),
//                     child: AnimatedSwitcher(
//                       key: Key('AttachmentStatus_${e.id}'),
//                       duration: 250.milliseconds,
//                       child: leading,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Flexible(
//                     child: Text(
//                       p.basenameWithoutExtension(e.filename),
//                       style: style.boldBody,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   Text(
//                     p.extension(e.filename),
//                     style: style.boldBody,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(width: 8),
//                   Transform.translate(
//                     offset: const Offset(0, 2),
//                     child: Text(
//                       'label_kb'.l10nfmt({
//                         'amount': e.original.size == null
//                             ? 'dot'.l10n * 3
//                             : e.original.size! ~/ 1024
//                       }),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: style.boldBody.copyWith(
//                         fontSize: 13,
//                         color: Theme.of(context).colorScheme.secondary,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     });
//   }
// }

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
import 'package:path/path.dart' as p;

import '/domain/model/attachment.dart';
import '/domain/model/sending_status.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';

/// Visual representation of a file [Attachment].
class DataAttachment extends StatefulWidget {
  const DataAttachment(this.attachment, {super.key, this.onPressed});

  /// [Attachment] to display.
  final Attachment attachment;

  /// Callback, called when this [DataAttachment] is pressed.
  final void Function(Attachment)? onPressed;

  @override
  State<DataAttachment> createState() => _DataAttachmentState();
}

/// State of a [DataAttachment] maintaining the [_hovered] indicator.
class _DataAttachmentState extends State<DataAttachment> {
  /// Indicator whether this [DataAttachment] is hovered.
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Attachment e = widget.attachment;

    return Obx(() {
      final Style style = Theme.of(context).extension<Style>()!;

      Widget leading = Container();
      RxDouble? value;

      if (e is FileAttachment) {
        switch (e.downloadStatus.value) {
          case DownloadStatus.inProgress:
            value = e.progress;
            leading = InkWell(
              key: const Key('CancelDownloading'),
              onTap: e.cancelDownload,
              child: Container(
                key: const Key('Downloading'),
                width: 34 * 0.75,
                height: 34 * 0.75,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: style.colors.primary,
                  ),
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      style.colors.primary,
                      style.colors.primary,
                      style.colors.backgroundAuxiliaryLighter,
                    ],
                    stops: [
                      0,
                      e.progress.value,
                      e.progress.value,
                    ],
                  ),
                ),
                child: Center(
                  child: SvgImage.asset(
                    'assets/icons/cancel1.svg',
                    width: 9,
                    height: 9,
                  ),
                ),
              ),
            );
            break;

          case DownloadStatus.isFinished:
            leading = Container(
              key: const Key('Downloaded'),
              height: 34 * 0.75,
              width: 34 * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.colors.primary,
              ),
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0.3, -0.5),
                  child: SvgImage.asset(
                    'assets/icons/file1.svg',
                    width: 8.8,
                    height: 11,
                  ),
                ),
              ),
            );
            break;

          case DownloadStatus.notStarted:
            leading = AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              key: const Key('Download'),
              height: 34 * 0.75,
              width: 34 * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hovered
                    ? style.colors.backgroundAuxiliaryLighter
                    : style.colors.transparent,
                border: Border.all(
                  width: 2,
                  color: style.colors.primary,
                ),
              ),
              child: KeyedSubtree(
                key: const Key('Sent'),
                child: Center(
                  child: SvgImage.asset(
                    'assets/icons/arrow_down2.svg',
                    width: 9.12,
                    height: 10.39,
                  ),
                ),
              ),
            );
            break;
        }
      } else if (e is LocalAttachment) {
        switch (e.status.value) {
          case SendingStatus.sending:
            leading = SizedBox.square(
              key: const Key('Sending'),
              dimension: 18,
              child: CircularProgressIndicator(
                value: e.progress.value,
                backgroundColor: style.colors.onPrimary,
                strokeWidth: 5,
              ),
            );
            break;

          case SendingStatus.sent:
            leading = const Icon(
              Icons.check_circle,
              key: Key('Sent'),
              size: 18,
              color: Colors.green,
            );
            break;

          case SendingStatus.error:
            leading = const Icon(
              Icons.error_outline,
              key: Key('Error'),
              size: 18,
              color: Colors.red,
            );
            break;
        }
      }

      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Padding(
          key: Key('File_${e.id}'),
          padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
          child: WidgetButton(
            onPressed: () => widget.onPressed?.call(e),
            child: Container(
              decoration: const BoxDecoration(
                  // borderRadius: BorderRadius.circular(10),
                  // border: Border.all(
                  //   color: Colors.black.withOpacity(0.1),
                  //   width: 0.5,
                  // ),
                  //  color: style.colors.onBackgroundOpacity2,
                  ),
              // padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  const SizedBox(width: 8 * 0.75),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: AnimatedSwitcher(
                      key: Key('AttachmentStatus_${e.id}'),
                      duration: 250.milliseconds,
                      child: leading,
                    ),
                  ),
                  const SizedBox(width: 12 * 0.75),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.basenameWithoutExtension(e.filename),
                                style: style.boldBody,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              p.extension(e.filename),
                              style: style.boldBody,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // if (value != null)
                            //   Obx(() {
                            //     return Text(
                            //       '${'label_kb'.l10nfmt({
                            //             'amount': e.original.size == null
                            //                 ? 'dot'.l10n * 3
                            //                 : e.original.size! *
                            //                     value!.value ~/
                            //                     1024,
                            //           })} / ',
                            //       maxLines: 1,
                            //       overflow: TextOverflow.ellipsis,
                            //       style: style.systemMessageStyle.copyWith(
                            //         fontSize: 11,
                            //         color:
                            //             Theme.of(context).colorScheme.secondary,
                            //       ),
                            //     );
                            //   }),
                            Text(
                              'label_kb'.l10nfmt({
                                'amount': e.original.size == null
                                    ? 'dot'.l10n * 3
                                    : e.original.size! ~/ 1024
                              }),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: style.systemMessageStyle.copyWith(
                                fontSize: 11,
                                color: style.colors.secondary,
                              ),
                            ),
                            // if (value != null)
                            //   Obx(() {
                            //     return Text(
                            //       ' (${'label_kb'.l10nfmt({
                            //             'amount': e.original.size == null
                            //                 ? 'dot'.l10n * 3
                            //                 : e.original.size! *
                            //                     value!.value ~/
                            //                     1024,
                            //           })})',
                            //       maxLines: 1,
                            //       overflow: TextOverflow.ellipsis,
                            //       style: style.systemMessageStyle.copyWith(
                            //         fontSize: 11,
                            //         color:
                            //             Theme.of(context).colorScheme.secondary,
                            //       ),
                            //     );
                            //   }),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(vertical: 8),
                  //   child: AnimatedSwitcher(
                  //     key: Key('AttachmentStatus_${e.id}'),
                  //     duration: 250.milliseconds,
                  //     child: leading,
                  //   ),
                  // ),
                  // const SizedBox(width: 8),
                  // Flexible(
                  //   child: Text(
                  //     p.basenameWithoutExtension(e.filename),
                  //     style: style.boldBody,
                  //     maxLines: 1,
                  //     overflow: TextOverflow.ellipsis,
                  //   ),
                  // ),
                  // Text(
                  //   p.extension(e.filename),
                  //   style: style.boldBody,
                  //   maxLines: 1,
                  //   overflow: TextOverflow.ellipsis,
                  // ),
                  // const SizedBox(width: 8),
                  // Transform.translate(
                  //   offset: const Offset(0, 2),
                  //   child: Text(
                  //     'label_kb'.l10nfmt({
                  //       'amount': e.original.size == null
                  //           ? 'dot'.l10n * 3
                  //           : e.original.size! ~/ 1024
                  //     }),
                  //     maxLines: 1,
                  //     overflow: TextOverflow.ellipsis,
                  //     style: style.boldBody.copyWith(
                  //       fontSize: 13,
                  //       color: Theme.of(context).colorScheme.secondary,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
