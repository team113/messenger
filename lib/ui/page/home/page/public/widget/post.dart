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

import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/chat_item_quote.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/sending_status.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/call/widget/fit_view.dart';
import 'package:messenger/ui/page/call/widget/fit_wrap.dart';
import 'package:messenger/ui/page/home/page/chat/controller.dart';
import 'package:messenger/ui/page/home/page/chat/forward/view.dart';
import 'package:messenger/ui/page/home/page/chat/widget/swipeable_status.dart';
import 'package:messenger/ui/page/home/page/chat/widget/video_thumbnail/video_thumbnail.dart';
import 'package:messenger/ui/page/home/page/user/controller.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/page/home/widget/gallery_popup.dart';
import 'package:messenger/ui/page/home/widget/init_callback.dart';
import 'package:messenger/ui/widget/animated_delayed_switcher.dart';
import 'package:messenger/ui/widget/animations.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';

import 'swipeable_info.dart';

class PostWidget extends StatefulWidget {
  const PostWidget({
    Key? key,
    required this.item,
    this.onDelete,
    this.onFileTap,
    this.onGallery,
    this.onResend,
    this.onReply,
    this.onCopy,
    this.onEdit,
    this.getUser,
    this.me,
    this.onAttachmentError,
    this.animation,
  }) : super(key: key);

  /// Reactive value of a [ChatItem] to display.
  final Rx<ChatItem> item;

  /// Callback, called when a delete action of this post is triggered.
  final Function()? onDelete;

  /// Callback, called when a [FileAttachment] of this [ChatItem] is tapped.
  final Function(FileAttachment)? onFileTap;

  /// Callback, called when a gallery list is required.
  ///
  /// If not specified, then only media in this [item] will be in a gallery.
  final List<Attachment> Function()? onGallery;

  /// Callback, called when a reply action of this [ChatItem] is triggered.
  final Function()? onReply;

  /// Callback, called when an edit action of this [ChatItem] is triggered.
  final Function()? onEdit;

  /// Callback, called when a copy action of this [ChatItem] is triggered.
  final Function(String text)? onCopy;

  /// Callback, called when a resend action of this [ChatItem] is triggered.
  final Function()? onResend;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final Future<RxUser?> Function(UserId userId)? getUser;

  final UserId? me;

  /// Callback, called on the [Attachment] fetching errors.
  final Future<void> Function()? onAttachmentError;

  /// Optional animation that controls a [SwipeableStatus].
  final AnimationController? animation;

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  /// [GlobalKey]s of [Attachment]s used to animate a [GalleryPopup] from/to
  /// corresponding [Widget].
  List<GlobalKey> _galleryKeys = [];

  bool liked = false;

  bool expanded = false;

  @override
  void initState() {
    _populateGlobalKeys(widget.item.value);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Style style = Theme.of(context).extension<Style>()!;
    return DefaultTextStyle(
      style: style.boldBody,
      child: Obx(() {
        if (widget.item.value is ChatMessage) {
          return _renderAsChatMessage(context);
        } else if (widget.item.value is ChatForward) {
          return _renderAsChatForward(context);
        } else {
          return Container();
        }
      }),
    );
  }

  /// Renders [widget.item] as [ChatMessage].
  Widget _renderAsChatMessage(BuildContext context) {
    var msg = widget.item.value as ChatMessage;

    String? text = msg.text?.val.replaceAll(' ', '');
    if (text?.isEmpty == true) {
      text = null;
    } else {
      text = msg.text?.val;
    }

    Style style = Theme.of(context).extension<Style>()!;

    List<Attachment> media = msg.attachments.where((e) {
      return ((e is ImageAttachment) ||
          (e is FileAttachment && e.isVideo) ||
          (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
    }).toList();

    List<Attachment> files = msg.attachments.where((e) {
      return ((e is FileAttachment && !e.isVideo) ||
          (e is LocalAttachment && (e.file.isImage || e.file.isVideo)));
    }).toList();

    const Color iconColor = Color(0xFF63B4FF); // Color(0xFF03a803);
    final Color badgeColor = Colors.black.withOpacity(0.05);

    Widget reaction({
      bool enabled = false,
      String? icon,
      List<Widget> children = const [],
    }) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: WidgetButton(
          onPressed: () {},
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              12 / 1.5,
              8 / 1.5,
              12 / 1.5,
              8 / 1.5,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              // border: style.systemMessageBorder,
              // color: Colors.white.darken(0.05),
              // color: badgeColor,
              color: Colors.white,
            ),
            child: DefaultTextStyle.merge(
              style: style.systemMessageStyle.copyWith(
                fontSize: 15,
                color: iconColor,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Text(
                      icon,
                      style: const TextStyle(fontSize: 21),
                    ),
                    const SizedBox(width: 4),
                    const Text('4'),
                  ] else
                    ...children,
                ],
              ),
            ),
          ),
        ),
      );
    }

    return _rounded(
      context,
      Container(
        padding: const EdgeInsets.fromLTRB(
          5 + 5,
          6 + 6,
          5 + 5,
          6 + 6,
        ),
        width: context.isNarrow ? double.infinity : null,
        child: IntrinsicWidth(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: style.secondaryBorder,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (text != null)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          12,
                          10 + 4,
                          9,
                          (files.isEmpty ? 10 : 0) + 4,
                        ),
                        child: SelectableText(
                          text,
                          style: style.boldBody,
                        ),
                      ),
                    if (files.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                        child: Column(
                            children: files.map(_fileAttachment).toList()),
                      ),
                    if (media.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: text != null
                              ? Radius.zero
                              : files.isEmpty
                                  ? const Radius.circular(15)
                                  : Radius.zero,
                          topRight: text != null
                              ? Radius.zero
                              : files.isEmpty
                                  ? const Radius.circular(15)
                                  : Radius.zero,
                          bottomLeft: expanded
                              ? Radius.zero
                              : const Radius.circular(15),
                          bottomRight: expanded
                              ? Radius.zero
                              : const Radius.circular(15),
                        ),
                        child: media.length == 1
                            ? _mediaAttachment(
                                0,
                                media.first,
                                media,
                                filled: false,
                              )
                            : SizedBox(
                                width: media.length * 250,
                                height: max(media.length * 60, 300),
                                child: FitView(
                                  dividerColor: Colors.transparent,
                                  children: media
                                      .mapIndexed((i, e) =>
                                          _mediaAttachment(i, e, media))
                                      .toList(),
                                ),
                              ),
                      ),

                    Container(
                      padding: EdgeInsets.fromLTRB(
                        0, // 16,
                        0, // media.isEmpty ? 0 : 8,
                        0, // 16,
                        0,
                      ),
                      decoration: BoxDecoration(
                        // color: Color(0xFFEFF8F0),
                        color: expanded ? Colors.white : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (expanded)
                            Row(
                              children: [
                                const Spacer(),
                                WidgetButton(
                                  onPressed: () =>
                                      setState(() => expanded = !expanded),
                                  child: DefaultTextStyle.merge(
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                    overflow: TextOverflow.visible,
                                    style: style.systemMessageStyle
                                        .copyWith(fontSize: 11),
                                    child: Container(
                                      padding:
                                          const EdgeInsets.fromLTRB(3, 3, 3, 3),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: style.systemMessageBorder,
                                        color: Colors.white,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            expanded
                                                ? Icons.expand_less
                                                : Icons.expand_more,
                                            color: const Color(0xFF888888),
                                            size: 15,
                                          ),
                                          const SizedBox(width: 3),
                                          const Text('11:19'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                            ),
                          if (expanded) ...[
                            const SizedBox(height: 2),
                            Container(
                              margin: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                  // borderRadius: BorderRadius.circular(15),
                                  // color: const Color(0xFFF1F1F1),
                                  ),
                              child: Column(
                                children: [
                                  // Container(
                                  //   color: const Color(0x11000000),
                                  //   height: 1,
                                  //   width: double.infinity,
                                  //   padding:
                                  //       const EdgeInsets.only(left: 10, right: 10),
                                  // ),
                                  const SizedBox(height: 16),
                                  DefaultTextStyle.merge(
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF888888),
                                    ),
                                    child: Wrap(
                                      // alignment: WrapAlignment.spaceBetween,
                                      // runAlignment: WrapAlignment.spaceBetween,
                                      // crossAxisAlignment: WrapCrossAlignment.start,
                                      runSpacing: 10,
                                      spacing: 10,
                                      children: [
                                        reaction(icon: '👍'),
                                        reaction(icon: '👎'),
                                        reaction(icon: '😾'),
                                        reaction(icon: '😿'),
                                        reaction(icon: '🙀'),
                                        reaction(icon: '😽'),
                                        reaction(icon: '😼'),
                                        reaction(icon: '🤡'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    color: const Color(0x11000000),
                                    height: 1,
                                    width: double.infinity,
                                    padding: const EdgeInsets.only(
                                        left: 10, right: 10),
                                  ),
                                  // const SizedBox(height: 10),
                                  DefaultTextStyle.merge(
                                    style: const TextStyle(
                                      fontSize: 17,
                                      color: Color(0xFF63B4FF),
                                      // color: Color(0xFF03A803),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 0),
                                      child: Row(
                                        children: [
                                          WidgetButton(
                                            onPressed: () {},
                                            child: Container(
                                              // decoration: BoxDecoration(
                                              //   borderRadius:
                                              //       BorderRadius.circular(30),
                                              //   color: badgeColor,
                                              // ),
                                              padding: const EdgeInsets.all(8),
                                              child: const Text(
                                                  '152 комментариев >'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // const SizedBox(height: 6),
                          if (false)
                            DefaultTextStyle.merge(
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888888),
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 0),
                                child: Row(
                                  children: [
                                    WidgetButton(
                                      onPressed: () =>
                                          setState(() => expanded = !expanded),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          color: badgeColor,
                                        ),
                                        padding: const EdgeInsets.fromLTRB(
                                            8, 4, 8, 4),
                                        child: Row(
                                          children: [
                                            Text(
                                              DateFormat.Hm().format(widget
                                                  .item.value.at.val
                                                  .toLocal()),
                                            ),
                                            const SizedBox(width: 12),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SvgLoader.asset(
                                                  'assets/icons/eye.svg',
                                                  height: 14.25 * 0.8,
                                                ),
                                                const SizedBox(width: 4),
                                                const Text('12'),
                                              ],
                                            ),

                                            // Row(
                                            //   mainAxisSize: MainAxisSize.min,
                                            //   children: const [
                                            //     Icon(
                                            //       Icons.pan_tool_alt,
                                            //       size: 21,
                                            //       color: Color(0xFFFFD03D),
                                            //     ),
                                            //     SizedBox(width: 6),
                                            //     Text('152'),
                                            //   ],
                                            // ),

                                            const SizedBox(width: 12),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Text(
                                                  '🤣',
                                                  style:
                                                      TextStyle(fontSize: 17),
                                                ),
                                                SizedBox(width: 2),
                                                Text('4'),
                                              ],
                                            ),

                                            const SizedBox(width: 12),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(
                                                  Icons.comment_outlined,
                                                  size: 17,
                                                  color: Color(0xFF888888),
                                                ),
                                                SizedBox(width: 6),
                                                Text('4'),
                                              ],
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              expanded
                                                  ? Icons.expand_less
                                                  : Icons.expand_more,
                                              size: 21,
                                              color: const Color(0xFF63B4FF),
                                            ),

                                            // Text(msg.at.val.toDifferenceAgo()),
                                            // Text('${msg.at.val.toRelative()}, '),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    const Spacer(),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        color: badgeColor,
                                      ),
                                      padding:
                                          const EdgeInsets.fromLTRB(8, 4, 8, 4),
                                      child: WidgetButton(
                                        onPressed: () {},
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Transform.scale(
                                              scaleX: -1,
                                              child: const Icon(
                                                Icons.reply_outlined,
                                                color: Color(0xFF63B4FF),
                                                // color: Color(0xFF03A803),
                                                size: 21,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text('16'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // if (expanded) ...[
                          //   const SizedBox(height: 2),
                          //   Container(
                          //     margin: const EdgeInsets.all(2),
                          //     decoration: BoxDecoration(
                          //       borderRadius: BorderRadius.circular(15),
                          //       color: const Color(0xFFF1F1F1),
                          //     ),
                          //     child: Column(
                          //       children: [
                          //         // Container(
                          //         //   color: const Color(0x11000000),
                          //         //   height: 1,
                          //         //   width: double.infinity,
                          //         //   padding:
                          //         //       const EdgeInsets.only(left: 10, right: 10),
                          //         // ),
                          //         const SizedBox(height: 10),
                          //         DefaultTextStyle.merge(
                          //           style: const TextStyle(
                          //             fontSize: 15,
                          //             color: Color(0xFF888888),
                          //           ),
                          //           child: Wrap(
                          //             // alignment: WrapAlignment.spaceBetween,
                          //             // runAlignment: WrapAlignment.spaceBetween,
                          //             // crossAxisAlignment: WrapCrossAlignment.start,
                          //             runSpacing: 10,
                          //             spacing: 10,
                          //             children: [
                          //               reaction(icon: '👍'),
                          //               reaction(icon: '👎'),
                          //               reaction(icon: '😾'),
                          //               reaction(icon: '😿'),
                          //               reaction(icon: '🙀'),
                          //               reaction(icon: '😽'),
                          //               reaction(icon: '😼'),
                          //               reaction(icon: '🤡'),
                          //             ],
                          //           ),
                          //         ),
                          //         const SizedBox(height: 10),
                          //         Container(
                          //           color: const Color(0x11000000),
                          //           height: 1,
                          //           width: double.infinity,
                          //           padding: const EdgeInsets.only(
                          //               left: 10, right: 10),
                          //         ),
                          //         // const SizedBox(height: 10),
                          //         DefaultTextStyle.merge(
                          //           style: const TextStyle(
                          //             fontSize: 17,
                          //             color: Color(0xFF63B4FF),
                          //             // color: Color(0xFF03A803),
                          //           ),
                          //           child: Padding(
                          //             padding: const EdgeInsets.fromLTRB(
                          //                 16, 0, 16, 0),
                          //             child: Row(
                          //               children: [
                          //                 WidgetButton(
                          //                   onPressed: () {},
                          //                   child: Container(
                          //                     // decoration: BoxDecoration(
                          //                     //   borderRadius:
                          //                     //       BorderRadius.circular(30),
                          //                     //   color: badgeColor,
                          //                     // ),
                          //                     padding:
                          //                         const EdgeInsets.all(8),
                          //                     child: const Text(
                          //                         '152 комментариев >'),
                          //                   ),
                          //                 ),
                          //               ],
                          //             ),
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // ] else ...[
                          //   // const SizedBox(height: 10),
                          // ],

                          // if (expanded) ...[
                          //   const SizedBox(height: 6),
                          //   Container(
                          //     color: const Color(0x11000000),
                          //     height: 1,
                          //     width: double.infinity,
                          //     padding: const EdgeInsets.only(left: 10, right: 10),
                          //   ),
                          //   const SizedBox(height: 10),
                          //   DefaultTextStyle.merge(
                          //     style: const TextStyle(
                          //       fontSize: 15,
                          //       color: Color(0xFF888888),
                          //     ),
                          //     child: Wrap(
                          //       // alignment: WrapAlignment.spaceBetween,
                          //       // runAlignment: WrapAlignment.spaceBetween,
                          //       // crossAxisAlignment: WrapCrossAlignment.start,
                          //       runSpacing: 10,
                          //       spacing: 10,
                          //       children: [
                          //         reaction(icon: '👍'),
                          //         reaction(icon: '👎'),
                          //         reaction(icon: '😾'),
                          //         reaction(icon: '😿'),
                          //         reaction(icon: '🙀'),
                          //         reaction(icon: '😽'),
                          //         reaction(icon: '😼'),
                          //         reaction(icon: '🤡'),
                          //       ],
                          //     ),
                          //   ),
                          //   const SizedBox(height: 10),
                          //   Container(
                          //     color: const Color(0x11000000),
                          //     height: 1,
                          //     width: double.infinity,
                          //     padding: const EdgeInsets.only(left: 10, right: 10),
                          //   ),
                          //   const SizedBox(height: 10),
                          //   DefaultTextStyle.merge(
                          //     style: const TextStyle(
                          //       fontSize: 17,
                          //       color: Color(0xFF03A803),
                          //     ),
                          //     child: Row(
                          //       children: [
                          //         WidgetButton(
                          //           onPressed: () {},
                          //           child: Container(
                          //             decoration: BoxDecoration(
                          //               borderRadius: BorderRadius.circular(30),
                          //               color: badgeColor,
                          //             ),
                          //             padding: const EdgeInsets.all(8),
                          //             child: const Text('152 комментариев >'),
                          //           ),
                          //         ),
                          //         const Spacer(),
                          //         const SizedBox(width: 2),
                          //         const AvatarWidget(
                          //           title: '01',
                          //           useLayoutBuilder: false,
                          //           radius: 16,
                          //         ),
                          //         const SizedBox(width: 2),
                          //         const AvatarWidget(
                          //           title: '02',
                          //           useLayoutBuilder: false,
                          //           radius: 16,
                          //         ),
                          //         const SizedBox(width: 2),
                          //         const AvatarWidget(
                          //           title: '03',
                          //           useLayoutBuilder: false,
                          //           radius: 16,
                          //         ),
                          //         // WidgetButton(
                          //         //   onPressed: () {},
                          //         //   child: Transform.scale(
                          //         //     scaleX: -1,
                          //         //     child: const Icon(
                          //         //       Icons.reply,
                          //         //       color: Color(0xFF03A803),
                          //         //       size: 27,
                          //         //     ),
                          //         //   ),
                          //         // ),
                          //       ],
                          //     ),
                          //   ),
                          // ],

                          // DefaultTextStyle.merge(
                          //   style: const TextStyle(
                          //     fontSize: 15,
                          //     color: Color(0xFF888888),
                          //   ),
                          //   child: Row(
                          //     mainAxisSize: MainAxisSize.min,
                          //     children: [
                          //       // reaction(icon: Icons.comment),
                          //       // const SizedBox(width: 12),
                          //       // reaction(icon: '👍'),
                          //       // const SizedBox(width: 12),

                          //       const Icon(
                          //         Icons.comment,
                          //         size: 12,
                          //         color: Color(0xFF888888),
                          //       ),
                          //       const SizedBox(width: 4),
                          //       const Text(
                          //         '14К',
                          //         style: TextStyle(fontSize: 11),
                          //       ),
                          //       const SizedBox(width: 8),
                          //       const Spacer(),
                          //       const SizedBox(width: 8),
                          //       // SvgLoader.asset(
                          //       //   'assets/icons/eye.svg',
                          //       //   height: 14.25,
                          //       // ),
                          //       // const SizedBox(width: 4),
                          //       // const Text('1235'),
                          //       // const SizedBox(width: 12),
                          //       Text(
                          //         DateFormat.Hm().format(
                          //           widget.item.value.at.val.toLocal(),
                          //         ),
                          //         style: const TextStyle(fontSize: 11),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                    // Padding(
                    //   padding: EdgeInsets.fromLTRB(8, media.isEmpty ? 0 : 0, 8, 8),
                    //   child: ,
                    // ),
                    /* Padding(
                              padding: EdgeInsets.fromLTRB(8, media.isEmpty ? 8 : 16, 8, 8),
                              child: DefaultTextStyle.merge(
                                style:
                                    const TextStyle(fontSize: 15, color: Color(0xFF888888)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // reaction(icon: Icons.comment),
                                    // const SizedBox(width: 12),
                                    reaction(icon: '👍'),
                                    const SizedBox(width: 12),
                                    reaction(icon: '👎'),
                                    const SizedBox(width: 12),
                                    const Spacer(),
                                    // if (context.isNarrow)
                                    //   const Spacer()
                                    // else
                                    //   const SizedBox(width: 12),
                                    const SizedBox(width: 8),
                                    SvgLoader.asset(
                                      'assets/icons/eye.svg',
                                      // width: 23.07,
                                      height: 14.25,
                                    ),
                                    // const Icon(
                                    //   Icons.visibility_outlined,
                                    //   size: 21,
                                    //   // color: iconColor,
                                    //   color: Color(0xFF888888),
                                    // ),
                                    const SizedBox(width: 4),
                                    const Text('1235'),
                                    const SizedBox(width: 12),
                                    Text(
                                      DateFormat.Hm().format(
                                        widget.item.value.at.val.toLocal(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DefaultTextStyle.merge(
                              style: const TextStyle(fontSize: 15),
                              child: WidgetButton(
                                onPressed: () {},
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    12 / 1.5,
                                    12 / 1,
                                    12 / 1.5,
                                    12 / 1,
                                  ),
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(15),
                                      bottomRight: Radius.circular(15),
                                    ),
                                    // border: style.systemMessageBorder,
                                    // color: Colors.white.darken(0.04),
                                    color: Color.fromRGBO(241, 249, 241, 1),
                                  ),
                                  child: DefaultTextStyle.merge(
                                    style: style.systemMessageTextStyle.copyWith(
                                      fontSize: 15,
                                      color: const Color(0xFF888888),
                                      // color: const Color(0xFF3078BA),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        // Icon(
                                        //   Icons.comment,
                                        //   size: 21,
                                        //   color: Theme.of(context).colorScheme.secondary,
                                        // ),
                                        const SizedBox(width: 4),
                                        const Text('1205'),
                                        const SizedBox(width: 4),
                                        const Text('comments'),
                                        const SizedBox(width: 4),
                                        const Spacer(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),*/
                  ],
                ),
              ),
              if (!expanded)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                  child: WidgetButton(
                    onPressed: () => setState(() => expanded = !expanded),
                    child: DefaultTextStyle.merge(
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: style.systemMessageStyle.copyWith(fontSize: 11),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: style.systemMessageBorder,
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat.Hm()
                                  .format(widget.item.value.at.val.toLocal()),
                            ),
                            const SizedBox(width: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgLoader.asset(
                                  'assets/icons/eye.svg',
                                  height: 14.25 * 0.8,
                                ),
                                const SizedBox(width: 4),
                                const Text('12'),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  '🤣',
                                  style: TextStyle(fontSize: 17),
                                ),
                                SizedBox(width: 2),
                                Text('4'),
                              ],
                            ),
                            const SizedBox(width: 12),
                            const Spacer(),
                            Icon(
                              expanded ? Icons.expand_less : Icons.expand_more,
                              color: const Color(0xFF888888),
                              size: 15,
                            ),
                            const SizedBox(width: 3),
                            const Text('11:19'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _renderAsChatForward(BuildContext context) {
    ChatForward msg = widget.item.value as ChatForward;
    ChatItem item = msg.item;

    Style style = Theme.of(context).extension<Style>()!;

    return DefaultTextStyle(
      style: style.boldBody,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(),
              child: Padding(
                padding: EdgeInsets.zero,
                child: Material(
                  borderRadius: BorderRadius.circular(15),
                  type: MaterialType.transparency,
                  child: ContextMenuRegion(
                    preventContextMenu: false,
                    alignment: Alignment.bottomLeft,
                    actions: [
                      ContextMenuButton(
                        key: const Key('ReplyButton'),
                        label: 'Reply'.l10n,
                        leading: SvgLoader.asset(
                          'assets/icons/reply.svg',
                          width: 18.8,
                          height: 16,
                        ),
                        onPressed: () => widget.onReply?.call(),
                      ),
                      ContextMenuButton(
                        key: const Key('ForwardButton'),
                        label: 'Forward'.l10n,
                        leading: SvgLoader.asset(
                          'assets/icons/forward.svg',
                          width: 18.8,
                          height: 16,
                        ),
                        onPressed: () async {},
                      ),
                      ContextMenuButton(
                        label: 'Delete'.l10n,
                        leading: SvgLoader.asset(
                          'assets/icons/delete_small.svg',
                          width: 17.75,
                          height: 17,
                        ),
                        onPressed: () async {},
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 6, 5, 6),
                      child: ClipRRect(
                        clipBehavior: Clip.none,
                        borderRadius: BorderRadius.circular(15),
                        child: IntrinsicWidth(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: style.secondaryBorder,
                            ),
                            child: _forwardedMessage(item),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _forwardedMessage(ChatItem item) {
    Style style = Theme.of(context).extension<Style>()!;

    Widget? content;
    List<Widget> additional = [];

    if (item is ChatMessage) {
      var desc = StringBuffer();

      if (item.text != null) {
        desc.write(item.text!.val);
      }

      if (item.attachments.isNotEmpty) {
        List<Attachment> media = item.attachments
            .where((e) =>
                e is ImageAttachment ||
                (e is FileAttachment && e.isVideo) ||
                (e is LocalAttachment && (e.file.isImage || e.file.isVideo)))
            .toList();

        List<Attachment> files = item.attachments
            .where((e) =>
                (e is FileAttachment && !e.isVideo) ||
                (e is LocalAttachment && !e.file.isImage && !e.file.isVideo))
            .toList();

        if (media.isNotEmpty || files.isNotEmpty) {
          additional = [
            if (files.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                child: Column(
                  children: files.map(_fileAttachment).toList(),
                ),
              ),
            if (media.isNotEmpty)
              ClipRRect(
                child: media.length == 1
                    ? _mediaAttachment(
                        0,
                        media.first,
                        media,
                        filled: false,
                      )
                    : SizedBox(
                        width: media.length * 120,
                        height: max(media.length * 60, 300),
                        child: FitView(
                          dividerColor: Colors.transparent,
                          children: media
                              .mapIndexed(
                                  (i, e) => _mediaAttachment(i, e, media))
                              .toList(),
                        ),
                      ),
              ),
          ];
        }
      }

      if (desc.isNotEmpty) {
        content = Text(
          desc.toString(),
          style: style.boldBody,
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: WidgetButton(
        child: FutureBuilder<RxUser?>(
          key: Key('FutureBuilder_${item.id}'),
          future: widget.getUser?.call(item.authorId),
          builder: (context, snapshot) {
            Color color = snapshot.data?.user.value.id == widget.me
                ? const Color(0xFF63B4FF)
                : AvatarWidget.colors[
                    (snapshot.data?.user.value.num.val.sum() ?? 3) %
                        AvatarWidget.colors.length];

            return Row(
              key: Key('Row_${item.id}'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 12),
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(width: 2, color: color),
                      ),
                    ),
                    margin: const EdgeInsets.fromLTRB(0, 8, 12, 8),
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // const SizedBox(width: 6),
                            Transform.scale(
                              scaleX: -1,
                              child: Icon(Icons.reply, size: 17, color: color),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                snapshot.data?.user.value.name?.val ??
                                    snapshot.data?.user.value.num.val ??
                                    '...',
                                style: style.boldBody.copyWith(color: color),
                              ),
                            ),
                          ],
                        ),
                        if (content != null) ...[
                          const SizedBox(height: 2),
                          content,
                        ],
                        if (additional.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: additional,
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  /// Returns rounded rectangle of a [child] representing a message box.
  Widget _rounded(BuildContext context, Widget child) {
    ChatItem item = widget.item.value;

    String? copyable;
    if (widget.item.value is ChatMessage) {
      copyable = (widget.item.value as ChatMessage).text?.val;
    }

    bool isSent = widget.item.value.status.value == SendingStatus.sent;

    return SwipeableInfo(
      animation: widget.animation,
      asStack: true,
      isSent: isSent,
      isDelivered: true,
      isRead: isSent && false,
      isError: item.status.value == SendingStatus.error,
      isSending: item.status.value == SendingStatus.sending,
      swipeable:
          Text(DateFormat.Hm().format(widget.item.value.at.val.toLocal())),
      onPressed: () => setState(() => expanded = !expanded),
      expanded: expanded,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: AnimatedDelayedSwitcher(
              delay: item.status.value == SendingStatus.sending
                  ? const Duration(seconds: 2)
                  : Duration.zero,
              child: item.status.value == SendingStatus.sending
                  ? const Padding(
                      key: Key('Sending'),
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.access_alarm, size: 15),
                    )
                  : item.status.value == SendingStatus.error
                      ? const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.error_outline,
                            size: 15,
                            color: Colors.red,
                          ),
                        )
                      : Container(),
            ),
          ),
          Flexible(
            child: LayoutBuilder(builder: (context, constraints) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Material(
                      key: Key('Message_${widget.item.value.id}'),
                      type: MaterialType.transparency,
                      child: ContextMenuRegion(
                        preventContextMenu: false,
                        alignment: Alignment.bottomLeft,
                        actions: [
                          if (widget.item.value is ChatMessage &&
                              (widget.item.value as ChatMessage)
                                  .attachments
                                  .isNotEmpty) ...[
                            ContextMenuButton(
                              label: 'Download all'.l10n,
                              leading: SvgLoader.asset(
                                'assets/icons/copy_small.svg',
                                width: 14.82,
                                height: 17,
                              ),
                              onPressed: () {},
                            ),
                            ContextMenuButton(
                              label: 'Download all as'.l10n,
                              leading: SvgLoader.asset(
                                'assets/icons/copy_small.svg',
                                width: 14.82,
                                height: 17,
                              ),
                              onPressed: () {},
                            ),
                          ],
                          if (copyable != null)
                            ContextMenuButton(
                              key: const Key('CopyButton'),
                              label: 'Copy'.l10n,
                              leading: SvgLoader.asset(
                                'assets/icons/copy_small.svg',
                                width: 14.82,
                                height: 17,
                              ),
                              onPressed: () {
                                widget.onCopy?.call(copyable!);
                              },
                            ),
                          if (item.status.value == SendingStatus.sent) ...[
                            ContextMenuButton(
                              key: const Key('ReplyButton'),
                              label: 'Reply'.l10n,
                              leading: SvgLoader.asset(
                                'assets/icons/reply.svg',
                                width: 18.8,
                                height: 16,
                              ),
                              onPressed: () => widget.onReply?.call(),
                            ),
                            if (item is ChatMessage || item is ChatForward)
                              ContextMenuButton(
                                key: const Key('ForwardButton'),
                                label: 'Forward'.l10n,
                                leading: SvgLoader.asset(
                                  'assets/icons/forward.svg',
                                  width: 18.8,
                                  height: 16,
                                ),
                                onPressed: () async {
                                  List<AttachmentId> attachments = [];
                                  if (item is ChatMessage) {
                                    attachments = item.attachments
                                        .map((a) => a.id)
                                        .toList();
                                  } else if (item is ChatForward) {
                                    ChatItem nested = item.item;
                                    if (nested is ChatMessage) {
                                      attachments = nested.attachments
                                          .map((a) => a.id)
                                          .toList();
                                    }
                                  }
                                },
                              ),
                            if (widget.item.value is ChatMessage)
                              ContextMenuButton(
                                key: const Key('EditButton'),
                                label: 'Edit'.l10n,
                                leading: SvgLoader.asset(
                                  'assets/icons/edit.svg',
                                  width: 17,
                                  height: 17,
                                ),
                                onPressed: () => widget.onEdit?.call(),
                              ),
                            ContextMenuButton(
                              // key: const Key('HideForMe'),
                              // key: _deleteKey,
                              label: 'Delete'.l10n,
                              leading: SvgLoader.asset(
                                'assets/icons/delete_small.svg',
                                width: 17.75,
                                height: 17,
                              ),
                              onPressed: () async {
                                widget.onDelete?.call();
                                // await ModalPopup.show(
                                //   context: context,
                                //   child: _buildDelete2(item),
                                // );
                              },
                            ),
                          ],
                          if (item.status.value == SendingStatus.error) ...[
                            ContextMenuButton(
                              key: const Key('Resend'),
                              label: 'Resend'.l10n,
                              // leading: const Icon(Icons.send),
                              leading: SvgLoader.asset(
                                'assets/icons/send_small.svg',
                                width: 18.37,
                                height: 16,
                              ),
                              onPressed: () => widget.onResend?.call(),
                            ),
                            ContextMenuButton(
                              key: const Key('Delete'),
                              label: 'Delete'.l10n,
                              leading: SvgLoader.asset(
                                'assets/icons/delete_small.svg',
                                width: 17.75,
                                height: 17,
                              ),
                              onPressed: () async {
                                // await ModalPopup.show(
                                //   context: context,
                                //   child: _buildDelete2(item),
                                // );
                              },
                            ),
                          ],
                        ],
                        child: child,
                      ),
                    ),
                    // Row(
                    //   mainAxisSize: MainAxisSize.min,
                    //   children: [
                    //     ElevatedButton(
                    //       onPressed: () {},
                    //       child: Icon(Icons.favorite),
                    //     ),
                    //     const SizedBox(width: 8),
                    //     ElevatedButton(
                    //       onPressed: () {},
                    //       child: Icon(Icons.favorite),
                    //     ),
                    //     const SizedBox(width: 20),
                    //     Icon(Icons.face),
                    //     const SizedBox(width: 4),
                    //     Text('1235'),
                    //   ],
                    // ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _fileAttachment(Attachment e) {
    Widget leading = Container();
    if (e is FileAttachment) {
      switch (e.downloadStatus.value) {
        case DownloadStatus.inProgress:
          leading = InkWell(
            onTap: () => widget.onFileTap?.call(e),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SvgLoader.asset(
                  'assets/icons/download_cancel.svg',
                  width: 28,
                  height: 28,
                ),
                SizedBox.square(
                  dimension: 26.3,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    key: const Key('Downloading'),
                    value: e.progress.value,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
          break;

        case DownloadStatus.isFinished:
          leading = const Icon(
            Icons.file_copy,
            key: Key('Downloaded'),
            color: Color(0xFF63B4FF),
            size: 28,
          );
          break;

        case DownloadStatus.notStarted:
          leading = SvgLoader.asset(
            'assets/icons/download.svg',
            width: 28,
            height: 28,
          );
          break;
      }
    }

    leading = KeyedSubtree(key: const Key('Sent'), child: leading);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: WidgetButton(
        onPressed: e is FileAttachment
            ? e.isDownloading
                ? null
                : () => widget.onFileTap?.call(e)
            : null,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.black.withOpacity(0.03),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              const SizedBox(width: 8),
              leading,
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TODO: Must be cut WITH extension visible!!!!!!
                    Text(
                      e.filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      e.original.size == null
                          ? '... KB'
                          : '${e.original.size! ~/ 1024} KB',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaAttachment(
    int i,
    Attachment e,
    List<Attachment> media, {
    bool filled = true,
  }) {
    bool isLocal = e is LocalAttachment;

    bool isVideo;
    if (isLocal) {
      isVideo = e.file.isVideo;
    } else {
      isVideo = e is FileAttachment;
    }

    var attachment = isVideo
        ? Stack(
            alignment: Alignment.center,
            children: [
              isLocal
                  ? e.file.bytes == null
                      ? const CircularProgressIndicator()
                      : VideoThumbnail.bytes(
                          bytes: e.file.bytes!,
                          key: _galleryKeys[i],
                          height: 300,
                        )
                  : VideoThumbnail.url(
                      url: '${Config.files}${e.original.relativeRef}',
                      key: _galleryKeys[i],
                      height: 300,
                      onError: widget.onAttachmentError,
                    ),
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x80000000),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ],
          )
        : isLocal
            ? e.file.bytes == null
                ? const CircularProgressIndicator()
                : Image.memory(
                    e.file.bytes!,
                    key: _galleryKeys[i],
                    fit: BoxFit.cover,
                    height: 300,
                  )
            : Image.network(
                '${Config.files}${(e as ImageAttachment).big.relativeRef}',
                key: _galleryKeys[i],
                fit: BoxFit.cover,
                height: 300,
                errorBuilder: (_, __, ___) {
                  return InitCallback(
                    callback: () => widget.onAttachmentError?.call(),
                    child: const SizedBox(
                      height: 300,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                },
              );

    return Padding(
      padding: EdgeInsets.zero,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: isLocal
            ? null
            : () {
                List<Attachment> attachments =
                    widget.onGallery?.call() ?? media;

                int initial = attachments.indexOf(e);
                if (initial == -1) {
                  initial = 0;
                }

                List<GalleryItem> gallery = [];
                for (var o in attachments) {
                  var link = '${Config.files}${o.original.relativeRef}';
                  if (o is FileAttachment) {
                    gallery.add(GalleryItem.video(link, o.filename));
                  } else if (o is ImageAttachment) {
                    GalleryItem? item;

                    item = GalleryItem.image(
                      link,
                      o.filename,
                      onError: () async {
                        await widget.onAttachmentError?.call();
                        item?.link = '${Config.files}${o.original.relativeRef}';
                      },
                    );

                    gallery.add(item);
                  }
                }

                GalleryPopup.show(
                  context: context,
                  gallery: GalleryPopup(
                    children: gallery,
                    initial: initial,
                    initialKey: _galleryKeys[i],
                  ),
                );
              },
        child: Stack(
          alignment: Alignment.center,
          children: [
            filled
                ? Positioned.fill(child: attachment)
                : Container(
                    constraints: const BoxConstraints(minWidth: 300),
                    width: double.infinity,
                    child: attachment,
                  ),
            if (isLocal)
              ElasticAnimatedSwitcher(
                child: e.status.value == SendingStatus.sent
                    ? const Icon(
                        Icons.check_circle,
                        size: 48,
                        color: Colors.green,
                      )
                    : e.status.value == SendingStatus.sending
                        ? CircularProgressIndicator(
                            value: e.progress.value,
                            backgroundColor: Colors.white,
                            strokeWidth: 10,
                          )
                        : const Icon(
                            Icons.error,
                            size: 48,
                            color: Colors.red,
                          ),
              )
          ],
        ),
      ),
    );
  }

  /// Populates the [_galleryKeys] from the provided [ChatMessage.attachments].
  void _populateGlobalKeys(ChatItem msg) {
    if (msg is ChatMessage) {
      _galleryKeys = msg.attachments
          .where((e) =>
              e is ImageAttachment ||
              (e is FileAttachment && e.isVideo) ||
              (e is LocalAttachment && (e.file.isImage || e.file.isVideo)))
          .map((e) => GlobalKey())
          .toList();
    } else if (msg is ChatForward) {
      final ChatItem item = msg.item;
      if (item is ChatMessage) {
        _galleryKeys = item.attachments
            .where((e) =>
                e is ImageAttachment ||
                (e is FileAttachment && e.isVideo) ||
                (e is LocalAttachment && (e.file.isImage || e.file.isVideo)))
            .map((e) => GlobalKey())
            .toList();
      }
    }
  }
}
