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

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/domain/model/attachment.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/sending_status.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/page/chat/widget/media_attachment.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/page/home/widget/init_callback.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'buttons.dart';
import 'controller.dart';
import 'more.dart';
import 'wrap_buttons.dart';

/// View for writing and editing a [ChatMessage] or a [ChatForward].
class MessageFieldView extends StatelessWidget {
  const MessageFieldView({
    super.key,
    this.controller,
    this.onChanged,
    this.onItemPressed,
    this.fieldKey,
    this.sendKey,
    this.canForward = false,
    this.canAttach = true,
    this.canSend = true,
    this.constraints,
    this.disabled = false,
    this.background,
  });

  /// Optionally provided external [MessageFieldController].
  final MessageFieldController? controller;

  /// [Key] of a [ReactiveTextField] this [MessageFieldView] has.
  final Key? fieldKey;

  /// [Key] of a send button this [MessageFieldView] has.
  final Key? sendKey;

  /// Indicator whether forwarding is possible within this [MessageFieldView].
  final bool canForward;

  /// Indicator whether [Attachment]s can be attached to this
  /// [MessageFieldView].
  final bool canAttach;

  final bool canSend;

  /// Callback, called when a [ChatItem] being a reply or edited is pressed.
  final Future<void> Function(ChatItemId id)? onItemPressed;

  /// Callback, called on the [ReactiveTextField] changes.
  final void Function()? onChanged;

  /// [BoxConstraints] replies, attachments and quotes are allowed to occupy.
  final BoxConstraints? constraints;

  final bool disabled;

  final Color? background;

  /// Returns a [ThemeData] to decorate a [ReactiveTextField] with.
  static ThemeData theme(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: BorderSide.none,
    );

    return Theme.of(context).copyWith(
      shadowColor: style.colors.onBackgroundOpacity27,
      iconTheme: IconThemeData(color: style.colors.primaryHighlight),
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
            border: border,
            errorBorder: border,
            enabledBorder: border,
            focusedBorder: border,
            disabledBorder: border,
            focusedErrorBorder: border,
            focusColor: style.colors.onPrimary,
            fillColor: style.colors.onPrimary,
            hoverColor: style.colors.transparent,
            filled: true,
            isDense: true,
            contentPadding: EdgeInsets.fromLTRB(
              15,
              PlatformUtils.isDesktop ? 30 : 23,
              15,
              0,
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return GetBuilder(
      init: controller ??
          MessageFieldController(
            Get.find(),
            Get.find(),
            canSend: canSend,
          ),
      global: false,
      builder: (MessageFieldController c) {
        return Theme(
          data: theme(context),
          child: SafeArea(
            child: Column(
              children: [
                // Container(
                //   margin: const EdgeInsets.only(bottom: 4),
                //   decoration: BoxDecoration(
                //     borderRadius: style.cardRadius,
                //     boxShadow: [
                //       CustomBoxShadow(
                //         blurRadius: 8,
                //         color: style.colors.onBackgroundOpacity13,
                //       ),
                //     ],
                //   ),
                //   child: ConditionalBackdropFilter(
                //     condition: style.cardBlur > 0,
                //     filter: ImageFilter.blur(
                //       sigmaX: style.cardBlur,
                //       sigmaY: style.cardBlur,
                //     ),
                //     borderRadius: style.cardRadius,
                //     child: Column(
                //       mainAxisSize: MainAxisSize.min,
                //       children: [
                //         Container(
                //           decoration: BoxDecoration(
                //             color: background ?? style.cardColor,
                //           ),
                //           child: Obx(() {
                //             if (c.buttons.isEmpty) {
                //               return const SizedBox();
                //             }

                //             // if (!c.field.isEmpty.value) {
                //             //   return const SizedBox();
                //             // }

                //             return const SizedBox();

                //             return Container(
                //               decoration: const BoxDecoration(
                //                 border: Border(
                //                   bottom: BorderSide(color: Color(0xFFEEEEEE)),
                //                 ),
                //               ),
                //               child: Row(
                //                 mainAxisAlignment:
                //                     MainAxisAlignment.spaceEvenly,
                //                 children: c.buttons.toList().reversed.map((e) {
                //                   return WidgetButton(
                //                     onPressed: () => e.onPressed?.call(true),
                //                     child: MouseRegion(
                //                       onEnter: (_) => e.onHovered?.call(true),
                //                       // onExit: (_) => e.onHovered?.call(false),
                //                       opaque: false,
                //                       child: SizedBox(
                //                         key: e.key,
                //                         width: 50,
                //                         height: 50,
                //                         child: Center(
                //                           child: e.icon == null
                //                               ? Transform.translate(
                //                                   offset: e.offset,
                //                                   child: SvgImage.asset(
                //                                     'assets/icons/${e.asset}.svg',
                //                                     width: e.assetWidth,
                //                                     height: e.assetHeight,
                //                                   ),
                //                                 )
                //                               : Icon(
                //                                   e.icon,
                //                                   size: 28,
                //                                   color: style.colors.primary,
                //                                 ),
                //                         ),
                //                       ),
                //                     ),
                //                   );
                //                 }).toList(),
                //               ),
                //             );
                //           }),
                //         )
                //         // _buildField(c, context),
                //       ],
                //     ),
                //   ),
                // ),
                Container(
                  key: const Key('SendField'),
                  decoration: BoxDecoration(
                    borderRadius: style.cardRadius,
                    boxShadow: [
                      CustomBoxShadow(
                        blurRadius: 8,
                        color: style.colors.onBackgroundOpacity13,
                      ),
                    ],
                  ),
                  child: ConditionalBackdropFilter(
                    condition: style.cardBlur > 0,
                    filter: ImageFilter.blur(
                      sigmaX: style.cardBlur,
                      sigmaY: style.cardBlur,
                    ),
                    borderRadius: style.cardRadius,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(c, context),
                        _buildField(c, context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Returns a visual representation of the message attachments, replies,
  /// quotes and edited message.
  Widget _buildHeader(MessageFieldController c, BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return LayoutBuilder(builder: (context, constraints) {
      return Obx(() {
        final bool grab = c.attachments.isNotEmpty
            ? (125 + 2) * c.attachments.length > constraints.maxWidth - 16
            : false;

        Widget? previews;

        // if (c.edited.value != null) {
        //   previews = SingleChildScrollView(
        //     controller: c.scrollController,
        //     child: Container(
        //       padding: const EdgeInsets.all(4),
        //       child: Dismissible(
        //         key: Key('${c.edited.value?.id}'),
        //         direction: DismissDirection.horizontal,
        //         onDismissed: (_) => c.edited.value = null,
        //         child: Padding(
        //           padding: const EdgeInsets.symmetric(vertical: 2),
        //           child: WidgetButton(
        //             onPressed: () => onItemPressed?.call(c.edited.value!.id),
        //             child: _buildPreview(
        //               context,
        //               c.edited.value!,
        //               c,
        //               onClose: () => c.edited.value = null,
        //             ),
        //           ),
        //         ),
        //       ),
        //     ),
        //   );
        // } else
        if (c.quotes.isNotEmpty) {
          previews = ReorderableListView(
            scrollController: c.scrollController,
            shrinkWrap: true,
            buildDefaultDragHandles: PlatformUtils.isMobile,
            onReorder: (int old, int to) {
              if (old < to) {
                --to;
              }

              c.quotes.insert(to, c.quotes.removeAt(old));

              HapticFeedback.lightImpact();
            },
            proxyDecorator: (child, _, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (_, child) {
                  final double t = Curves.easeInOut.transform(animation.value);
                  final double elevation = lerpDouble(0, 6, t)!;
                  final Color color = Color.lerp(
                    style.colors.transparent,
                    style.colors.onBackgroundOpacity20,
                    t,
                  )!;

                  return InitCallback(
                    callback: HapticFeedback.selectionClick,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          CustomBoxShadow(
                            color: color,
                            blurRadius: elevation,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  );
                },
                child: child,
              );
            },
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 1),
            children: c.quotes.map((e) {
              return ReorderableDragStartListener(
                key: Key('Handle_${e.item.id}'),
                enabled: !PlatformUtils.isMobile,
                index: c.quotes.indexOf(e),
                child: Dismissible(
                  key: Key('${e.item.id}'),
                  direction: DismissDirection.horizontal,
                  onDismissed: (_) {
                    c.quotes.remove(e);
                    if (c.quotes.isEmpty) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                    ),
                    child: _buildPreview(
                      context,
                      e.item,
                      c,
                      onClose: () {
                        c.quotes.remove(e);
                        if (c.quotes.isEmpty) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        } else if (c.replied.isNotEmpty) {
          previews = ReorderableListView(
            scrollController: c.scrollController,
            shrinkWrap: true,
            buildDefaultDragHandles: PlatformUtils.isMobile,
            onReorder: (int old, int to) {
              if (old < to) {
                --to;
              }

              c.replied.insert(to, c.replied.removeAt(old));

              HapticFeedback.lightImpact();
            },
            proxyDecorator: (child, _, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (_, child) {
                  final double t = Curves.easeInOut.transform(animation.value);
                  final double elevation = lerpDouble(0, 6, t)!;
                  final Color color = Color.lerp(
                    style.colors.transparent,
                    style.colors.onBackgroundOpacity20,
                    t,
                  )!;

                  return InitCallback(
                    callback: HapticFeedback.selectionClick,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          CustomBoxShadow(color: color, blurRadius: elevation),
                        ],
                      ),
                      child: child,
                    ),
                  );
                },
                child: child,
              );
            },
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 1),
            children: c.replied.map((e) {
              return ReorderableDragStartListener(
                key: Key('Handle_${e.id}'),
                enabled: !PlatformUtils.isMobile,
                index: c.replied.indexOf(e),
                child: Dismissible(
                  key: Key('${e.id}'),
                  direction: DismissDirection.horizontal,
                  onDismissed: (_) => c.replied.remove(e),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: WidgetButton(
                      onPressed: () => onItemPressed?.call(e.id),
                      child: _buildPreview(
                        context,
                        e,
                        c,
                        onClose: () => c.replied.remove(e),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }

        return ConditionalBackdropFilter(
          condition: style.cardBlur > 0,
          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
          borderRadius: BorderRadius.only(
            topLeft: style.cardRadius.topLeft,
            topRight: style.cardRadius.topRight,
          ),
          child: Container(
            color: style.colors.onPrimaryOpacity50,
            child: AnimatedSize(
              duration: 400.milliseconds,
              curve: Curves.ease,
              child: Container(
                width: double.infinity,
                padding: c.replied.isNotEmpty ||
                        c.attachments.isNotEmpty ||
                        c.edited.value != null
                    ? const EdgeInsets.fromLTRB(4, 6, 4, 6)
                    : EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (c.edited.value != null)
                      Container(
                        padding: const EdgeInsets.all(0),
                        child: Dismissible(
                          key: Key('${c.edited.value?.id}'),
                          direction: DismissDirection.horizontal,
                          onDismissed: (_) => c.edited.value = null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: WidgetButton(
                              onPressed: () =>
                                  onItemPressed?.call(c.edited.value!.id),
                              child: _buildPreview(
                                context,
                                c.edited.value!,
                                c,
                                onClose: () => c.edited.value = null,
                                edited: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (c.donation.value != null)
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Dismissible(
                          key: Key('Donation'),
                          direction: DismissDirection.horizontal,
                          onDismissed: (_) => c.donation.value = null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Container(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'G${c.donation.value}',
                                      style: TextStyle(fontSize: 21),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (previews != null)
                      ConstrainedBox(
                        constraints: this.constraints ??
                            BoxConstraints(
                              maxHeight: max(
                                100,
                                MediaQuery.of(context).size.height / 3.4,
                              ),
                            ),
                        child: Scrollbar(
                          controller: c.scrollController,
                          child: previews,
                        ),
                      ),
                    if (c.attachments.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: MouseRegion(
                          cursor: grab
                              ? SystemMouseCursors.grab
                              : MouseCursor.defer,
                          opaque: false,
                          child: ScrollConfiguration(
                            behavior: CustomScrollBehavior(),
                            child: SingleChildScrollView(
                              clipBehavior: Clip.none,
                              physics: grab
                                  ? null
                                  : const NeverScrollableScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: c.attachments
                                    .map((e) => _buildAttachment(context, e, c))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        );
      });
    });
  }

  /// Builds a visual representation of the send field itself along with its
  /// buttons.
  Widget _buildField(MessageFieldController c, BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return LayoutBuilder(builder: (context, constraints) {
      final int buttons = ((constraints.maxWidth - 220) / 50).floor() + 1;
      // final bool displayInRow = buttons >= c.buttons.length;
      final bool displayInRow = true;

      return Container(
        key: c.globalKey,
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(color: background ?? style.cardColor),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // const SizedBox(width: 26 / 2 - 3),
            WidgetButton(
              onPressed: canAttach
                  ? () {
                      c.removeEntries<MessageFieldMore>();
                      c.addEntry<MessageFieldMore>(MessageFieldMore(c));
                    }
                  : null,
              // onPressed: canAttach
              //     ? !PlatformUtils.isMobile || PlatformUtils.isWeb
              //         ? c.pickFile
              //         : () async {
              //             c.field.focus.unfocus();
              //             await AttachmentSourceSelector.show(
              //               context,
              //               onPickFile: c.pickFile,
              //               onTakePhoto: c.pickImageFromCamera,
              //               onPickMedia: c.pickMedia,
              //               onTakeVideo: c.pickVideoFromCamera,
              //             );
              //           }
              //     : null,
              child: SizedBox(
                // color: Colors.yellow,
                width: 50,
                height: 56,
                child: Center(
                  child: SvgImage.asset(
                    'assets/icons/chat_more1.svg',
                    height: 20,
                    width: 20,
                  ),
                  // child: SvgImage.asset(
                  //   'assets/icons/attach${canAttach ? '' : '_disabled'}.svg',
                  //   height: 22,
                  //   width: 22,
                  // ),
                ),
              ),
            ),

            // const SizedBox(width: 26 / 2 - 3),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 5 + (PlatformUtils.isMobile ? 0 : 8),
                  bottom: 13,
                ),
                child: Transform.translate(
                  offset: Offset(0, PlatformUtils.isMobile ? 6 : 1),
                  child: ReactiveTextField(
                    onChanged: onChanged,
                    key: fieldKey ?? const Key('MessageField'),
                    state: c.field,
                    hint: 'label_send_message_hint'.l10n,
                    minLines: 1,
                    maxLines: 7,
                    filled: false,
                    dense: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    style: style.boldBody.copyWith(fontSize: 17),
                    type: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 26 / 2 - 3),
            Obx(() {
              if (c.buttons.isEmpty ||
                  !c.field.isEmpty.value ||
                  !displayInRow) {
                return const SizedBox();
              }

              // int total = c.buttons.length;
              // if (constraints.maxWidth - 160 < 70 * c.buttons.length) {
              //   total = ((constraints.maxWidth - 220) / 70).floor() + 1;
              // }

              // return WrapButtons(
              //   constraints,
              //   buttons: c.buttons,
              // );

              int take = c.buttons.length;
              // // print(
              // // '${constraints.maxWidth} - 220 < 36 * c.buttons.length : ${constraints.maxWidth - 220 < 36 * c.buttons.length}');
              if (constraints.maxWidth - 160 < 50 * c.buttons.length) {
                take = ((constraints.maxWidth - 160) / 50).round();
                // print(3 * constraints.maxWidth / (36 * c.buttons.length));
              }

              take = max(take, 0);

              final int total = ((constraints.maxWidth - 160) / 50).round();

              SchedulerBinding.instance.addPostFrameCallback((_) {
                c.canPin.value = c.buttons.length < total;
                // print('${c.canPin} ${c.buttons.length} ${total}');
              });

              // double coef = 1;
              // if (constraints.maxWidth - 45 < 70 * c.buttons.length) {
              //   coef = 1 / (80 * c.buttons.length / constraints.maxWidth);
              // }

              return Wrap(
                children: c.buttons.take(take).toList().reversed.map((e) {
                  if (e is SendButton) {
                    return Obx(() {
                      return GestureDetector(
                        onLongPress: canForward ? c.forwarding.toggle : null,
                        child: WidgetButton(
                          onPressed: canSend
                              ? () {
                                  if (c.editing.value) {
                                    c.field.unsubmit();
                                  }
                                  c.field.submit();
                                }
                              : null,
                          child: Container(
                            // color: Colors.red,
                            // width: 50 - ((c.buttons.length - 1) * 3),
                            width: 50,
                            height: 56,
                            // margin: const EdgeInsets.only(right: 8),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: 300.milliseconds,
                                child: c.forwarding.value
                                    ? SvgImage.asset(
                                        'assets/icons/forward.svg',
                                        width: 26,
                                        height: 22,
                                      )
                                    : c.field.isEmpty.value && false
                                        ? Container(
                                            // color: Colors.red,
                                            width: 18.87,
                                            height: 23.8,
                                            child: SvgImage.asset(
                                              'assets/icons/audio_message2.svg',
                                              key: sendKey ?? const Key('Send'),
                                              // height: 18.87,
                                              width: 23.8,
                                            ),
                                          )
                                        // ? Icon(
                                        //     Icons.mic,
                                        //     color: style.colors.primary,
                                        //     size: 28,
                                        //   )
                                        // ? SvgImage.asset(
                                        //     'assets/icons/microphone_on.svg',
                                        //     key: sendKey ?? const Key('Send'),
                                        //     height: 22.85,
                                        //     width: 25.18,
                                        //   )
                                        : SvgImage.asset(
                                            'assets/icons/send${disabled ? '_disabled' : '2'}.svg',
                                            key: sendKey ?? const Key('Send'),
                                            width: 25.44,
                                            height: 21.91,
                                          ),
                              ),
                            ),
                          ),
                        ),
                      );
                    });
                  }

                  return WidgetButton(
                    onPressed: () => e.onPressed?.call(true),
                    child: MouseRegion(
                      onEnter: (_) => e.onHovered?.call(true),
                      // onExit: (_) => e.onHovered?.call(false),
                      opaque: false,
                      child: SizedBox(
                        key: e.key,
                        width: 50,
                        height: 56,
                        child: Center(
                          child: e.icon == null
                              ? Transform.translate(
                                  offset: e.offset,
                                  child: SvgImage.asset(
                                    'assets/icons/${e.asset}.svg',
                                    width: e.assetWidth,
                                    height: e.assetHeight,
                                  ),
                                )
                              : Icon(
                                  e.icon,
                                  size: 28,
                                  color: style.colors.primary,
                                ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );

              // return Row(
              //   children: c.buttons.take(take).toList().reversed.map((e) {
              //     return WidgetButton(
              //       onPressed: () => e.onPressed?.call(true),
              //       child: MouseRegion(
              //         onEnter: (_) => e.onHovered?.call(true),
              //         // onExit: (_) => e.onHovered?.call(false),
              //         opaque: false,
              //         child: SizedBox(
              //           key: e.key,
              //           width: 36 + 4 + 4,
              //           height: 56,
              //           child: Center(
              //             child: e.icon == null
              //                 ? Transform.translate(
              //                     offset: e.offset,
              //                     child: SvgImage.asset(
              //                       'assets/icons/${e.asset}.svg',
              //                       width: e.assetWidth,
              //                       height: e.assetHeight,
              //                     ),
              //                   )
              //                 : Icon(
              //                     e.icon,
              //                     size: 28,
              //                     color: style.colors.primary,
              //                   ),
              //           ),
              //         ),
              //       ),
              //     );
              //   }).toList(),
              // );
            }),
            const SizedBox(width: 3),
            // Obx(() {
            //   return GestureDetector(
            //     onLongPress: canForward ? c.forwarding.toggle : null,
            //     child: WidgetButton(
            //       onPressed: canSend
            //           ? () {
            //               if (c.editing.value) {
            //                 c.field.unsubmit();
            //               }
            //               c.field.submit();
            //             }
            //           : null,
            //       child: Container(
            //         color: Colors.red,
            //         // width: 50 - ((c.buttons.length - 1) * 3),
            //         width: 56,
            //         height: 56,
            //         // margin: const EdgeInsets.only(right: 8),
            //         child: Center(
            //           child: AnimatedSwitcher(
            //             duration: 300.milliseconds,
            //             child: c.forwarding.value
            //                 ? SvgImage.asset(
            //                     'assets/icons/forward.svg',
            //                     width: 26,
            //                     height: 22,
            //                   )
            //                 : c.field.isEmpty.value && false
            //                     ? Container(
            //                         // color: Colors.red,
            //                         width: 18.87,
            //                         height: 23.8,
            //                         child: SvgImage.asset(
            //                           'assets/icons/audio_message2.svg',
            //                           key: sendKey ?? const Key('Send'),
            //                           // height: 18.87,
            //                           width: 23.8,
            //                         ),
            //                       )
            //                     // ? Icon(
            //                     //     Icons.mic,
            //                     //     color: style.colors.primary,
            //                     //     size: 28,
            //                     //   )
            //                     // ? SvgImage.asset(
            //                     //     'assets/icons/microphone_on.svg',
            //                     //     key: sendKey ?? const Key('Send'),
            //                     //     height: 22.85,
            //                     //     width: 25.18,
            //                     //   )
            //                     : SvgImage.asset(
            //                         'assets/icons/send${disabled ? '_disabled' : '2'}.svg',
            //                         key: sendKey ?? const Key('Send'),
            //                         width: 25.44,
            //                         height: 21.91,
            //                       ),
            //           ),
            //         ),
            //       ),
            //     ),
            //   );
            // }),
            // const SizedBox(width: 26 / 2 - 3),
            // const SizedBox(width: 26 / 2 - 3),
            // Obx(() {
            //   if (c.buttons.isEmpty) {
            //     return const SizedBox();
            //   }

            //   return const SizedBox(width: 26 / 2 - 3);
            // }),
          ],
        ),
      );
    });
  }

  /// Returns a visual representation of the provided [Attachment].
  Widget _buildAttachment(
    BuildContext context,
    MapEntry<GlobalKey, Attachment> entry,
    MessageFieldController c,
  ) {
    final Attachment e = entry.value;
    final GlobalKey key = entry.key;

    final bool isImage =
        (e is ImageAttachment || (e is LocalAttachment && e.file.isImage));
    final bool isVideo = (e is FileAttachment && e.isVideo) ||
        (e is LocalAttachment && e.file.isVideo);

    const double size = 125;

    // Builds the visual representation of the provided [Attachment] itself.
    Widget content() {
      final Style style = Theme.of(context).extension<Style>()!;

      if (isImage || isVideo) {
        final Widget child = MediaAttachment(
          attachment: e,
          width: size,
          height: size,
          fit: BoxFit.cover,
        );

        final List<Attachment> attachments = c.attachments
            .where((e) {
              final Attachment a = e.value;
              return a is ImageAttachment ||
                  (a is FileAttachment && a.isVideo) ||
                  (a is LocalAttachment && (a.file.isImage || a.file.isVideo));
            })
            .map((e) => e.value)
            .toList();

        return WidgetButton(
          key: key,
          onPressed: e is LocalAttachment
              ? null
              : () {
                  final int index =
                      c.attachments.indexWhere((m) => m.value == e);
                  if (index != -1) {
                    GalleryPopup.show(
                      context: context,
                      gallery: GalleryPopup(
                        initial: index,
                        initialKey: key,
                        onTrashPressed: (int i) {
                          c.attachments
                              .removeWhere((o) => o.value == attachments[i]);
                        },
                        children: attachments.map((o) {
                          if (o is ImageAttachment ||
                              (o is LocalAttachment && o.file.isImage)) {
                            return GalleryItem.image(
                              o.original.url,
                              o.filename,
                              size: o.original.size,
                              checksum: o.original.checksum,
                            );
                          }
                          return GalleryItem.video(
                            o.original.url,
                            o.filename,
                            size: o.original.size,
                            checksum: o.original.checksum,
                          );
                        }).toList(),
                      ),
                    );
                  }
                },
          child: isVideo
              ? IgnorePointer(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      child,
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: style.colors.onBackgroundOpacity50,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: style.colors.onPrimary,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
                )
              : child,
        );
      }

      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      p.basenameWithoutExtension(e.filename),
                      style: const TextStyle(fontSize: 13),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    p.extension(e.filename),
                    style: const TextStyle(fontSize: 13),
                  )
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                'label_kb'.l10nfmt({
                  'amount': e.original.size == null
                      ? 'dot'.l10n * 3
                      : e.original.size! ~/ 1024
                }),
                style: TextStyle(fontSize: 13, color: style.colors.secondary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // Builds the [content] along with manipulation buttons and statuses.
    Widget attachment() {
      final Style style = Theme.of(context).extension<Style>()!;

      return MouseRegion(
        key: Key('Attachment_${e.id}'),
        opaque: false,
        onEnter: (_) => c.hoveredAttachment.value = e,
        onExit: (_) => c.hoveredAttachment.value = null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: style.colors.secondaryHighlight,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: content(),
              ),
              Center(
                child: SizedBox.square(
                  dimension: 30,
                  child: ElasticAnimatedSwitcher(
                    child: e is LocalAttachment
                        ? e.status.value == SendingStatus.error
                            ? Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: style.colors.onPrimary,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.error,
                                    color: style.colors.dangerColor,
                                  ),
                                ),
                              )
                            : const SizedBox()
                        : const SizedBox(),
                  ),
                ),
              ),
              if (!c.field.status.value.isLoading)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4, top: 4),
                    child: Obx(() {
                      final Widget child;

                      if (c.hoveredAttachment.value == e ||
                          PlatformUtils.isMobile) {
                        child = InkWell(
                          key: const Key('RemovePickedFile'),
                          onTap: () =>
                              c.attachments.removeWhere((a) => a.value == e),
                          child: Container(
                            width: 16,
                            height: 16,
                            margin: const EdgeInsets.only(left: 8, bottom: 8),
                            child: Container(
                              key: const Key('Close'),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: style.cardColor,
                              ),
                              alignment: Alignment.center,
                              child: SvgImage.asset(
                                'assets/icons/close_primary.svg',
                                width: 8,
                                height: 8,
                              ),
                            ),
                          ),
                        );
                      } else {
                        child = const SizedBox();
                      }

                      return AnimatedSwitcher(
                        duration: 200.milliseconds,
                        child: child,
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Dismissible(
      key: Key(e.id.val),
      direction: DismissDirection.up,
      onDismissed: (_) => c.attachments.removeWhere((a) => a.value == e),
      child: attachment(),
    );
  }

  /// Returns a visual representation of the provided [item] as a preview.
  Widget _buildPreview(
    BuildContext context,
    ChatItem item,
    MessageFieldController c, {
    void Function()? onClose,
    bool edited = false,
  }) {
    final Style style = Theme.of(context).extension<Style>()!;
    final bool fromMe = item.authorId == c.me;

    if (edited) {
      return MouseRegion(
        opaque: false,
        onEnter: (d) => c.hoveredReply.value = item,
        onExit: (d) => c.hoveredReply.value = null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          margin: const EdgeInsets.fromLTRB(2, 0, 2, 0),
          decoration: BoxDecoration(
            // color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Редактирование сообщения'.l10n,
                  style: style.boldBody.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              WidgetButton(
                key: const Key('CancelReplyButton'),
                onPressed: onClose,
                child: Text(
                  'Cancel',
                  style: style.boldBody.copyWith(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                // child: Container(
                //   width: 16,
                //   height: 16,
                //   margin: const EdgeInsets.only(right: 4, top: 4),
                //   child: Container(
                //     key: const Key('Close'),
                //     decoration: BoxDecoration(
                //       shape: BoxShape.circle,
                //       color: style.cardColor,
                //     ),
                //     alignment: Alignment.center,
                //     child: SvgImage.asset(
                //       'assets/icons/close_primary.svg',
                //       width: 8,
                //       height: 8,
                //     ),
                //   ),
                // ),
              )
            ],
          ),
        ),
      );
    }

    Widget? content;
    final List<Widget> additional = [];

    if (item is ChatMessage) {
      if (item.attachments.isNotEmpty) {
        additional.addAll(
          item.attachments.map((a) {
            final ImageAttachment? image = a is ImageAttachment ? a : null;

            return Container(
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: fromMe
                    ? style.colors.onPrimaryOpacity25
                    : style.colors.onBackgroundOpacity2,
                borderRadius: BorderRadius.circular(4),
              ),
              width: 30,
              height: 30,
              child: image == null
                  ? Icon(
                      Icons.file_copy,
                      color: fromMe
                          ? style.colors.onPrimary
                          : style.colors.secondaryHighlightDarkest,
                      size: 16,
                    )
                  : RetryImage(
                      image.small.url,
                      checksum: image.small.checksum,
                      fit: BoxFit.cover,
                      height: double.infinity,
                      width: double.infinity,
                      borderRadius: BorderRadius.circular(4),
                    ),
            );
          }).toList(),
        );
      }

      if (item.text != null && item.text!.val.isNotEmpty) {
        content = Text(
          item.text!.val,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.boldBody,
        );
      }
    } else if (item is ChatCall) {
      String title = 'label_chat_call_ended'.l10n;
      String? time;
      bool isMissed = false;

      if (item.finishReason == null && item.conversationStartedAt != null) {
        title = 'label_chat_call_ongoing'.l10n;
      } else if (item.finishReason != null) {
        title = item.finishReason!.localizedString(fromMe) ?? title;
        isMissed = item.finishReason == ChatCallFinishReason.dropped ||
            item.finishReason == ChatCallFinishReason.unanswered;

        if (item.finishedAt != null && item.conversationStartedAt != null) {
          time = item.conversationStartedAt!.val
              .difference(item.finishedAt!.val)
              .localizedString();
        }
      } else {
        title = item.authorId == c.me
            ? 'label_outgoing_call'.l10n
            : 'label_incoming_call'.l10n;
      }

      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
            child: item.withVideo
                ? SvgImage.asset(
                    'assets/icons/call_video${isMissed && !fromMe ? '_red' : ''}.svg',
                    height: 13,
                  )
                : SvgImage.asset(
                    'assets/icons/call_audio${isMissed && !fromMe ? '_red' : ''}.svg',
                    height: 15,
                  ),
          ),
          Flexible(child: Text(title, style: style.boldBody)),
          if (time != null) ...[
            const SizedBox(width: 9),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                time,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.boldBody.copyWith(
                  color: style.colors.secondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      );
    } else if (item is ChatForward) {
      // TODO: Implement `ChatForward`.
      content = Text('label_forwarded_message'.l10n, style: style.boldBody);
    } else if (item is ChatInfo) {
      // TODO: Implement `ChatInfo`.
      content = Text(item.action.toString(), style: style.boldBody);
    } else {
      content = Text('err_unknown'.l10n, style: style.boldBody);
    }

    final Widget expanded;

    if (edited) {
      expanded = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 12),
          SvgImage.asset('assets/icons/edit.svg', width: 17, height: 17),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(width: 2, color: style.colors.primary),
                ),
              ),
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'label_edit'.l10n,
                    style: style.boldBody.copyWith(color: style.colors.primary),
                  ),
                  if (content != null) ...[
                    const SizedBox(height: 2),
                    DefaultTextStyle.merge(maxLines: 1, child: content),
                  ],
                  if (additional.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: additional),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      expanded = FutureBuilder<RxUser?>(
        future: c.getUser(item.authorId),
        builder: (context, snapshot) {
          final Color color = snapshot.data?.user.value.id == c.me
              ? style.colors.primary
              : style.colors.userColors[
                  (snapshot.data?.user.value.num.val.sum() ?? 3) %
                      style.colors.userColors.length];

          return Container(
            key: Key('Reply_${c.replied.indexOf(item)}'),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(width: 2, color: color)),
            ),
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                snapshot.data != null
                    ? Obx(() {
                        return Text(
                          snapshot.data!.user.value.name?.val ??
                              snapshot.data!.user.value.num.val,
                          style: style.boldBody.copyWith(color: color),
                        );
                      })
                    : Text(
                        'dot'.l10n * 3,
                        style: style.boldBody.copyWith(
                          color: style.colors.primary,
                        ),
                      ),
                if (content != null) ...[
                  const SizedBox(height: 2),
                  DefaultTextStyle.merge(maxLines: 1, child: content),
                ],
                if (additional.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: additional),
                ],
              ],
            ),
          );
        },
      );
    }

    return MouseRegion(
      opaque: false,
      onEnter: (d) => c.hoveredReply.value = item,
      onExit: (d) => c.hoveredReply.value = null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(2, 0, 2, 0),
        decoration: BoxDecoration(
          color: style.colors.secondaryHighlight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: expanded),
            Obx(() {
              final Widget child;

              if (c.hoveredReply.value == item ||
                  PlatformUtils.isMobile ||
                  true) {
                child = WidgetButton(
                  key: const Key('CancelReplyButton'),
                  onPressed: onClose,
                  child: Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 4, top: 4),
                    child: Container(
                      key: const Key('Close'),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: style.cardColor,
                      ),
                      alignment: Alignment.center,
                      child: SvgImage.asset(
                        'assets/icons/close_primary.svg',
                        width: 8,
                        height: 8,
                      ),
                    ),
                  ),
                );
              } else {
                child = const SizedBox();
              }

              return AnimatedSwitcher(duration: 200.milliseconds, child: child);
            }),
          ],
        ),
      ),
    );
  }
}
