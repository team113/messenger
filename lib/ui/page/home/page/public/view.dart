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

import 'dart:async';
import 'dart:ui';
import 'dart:io';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/sending_status.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/call/widget/conditional_backdrop.dart';
import 'package:messenger/ui/page/call/widget/round_button.dart';
import 'package:messenger/ui/page/home/page/chat/controller.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';
import 'package:messenger/ui/page/home/page/chat/widget/my_dismissible.dart';
import 'package:messenger/ui/page/home/page/chat/widget/swipeable_status.dart';
import 'package:messenger/ui/page/home/page/chat/widget/video_thumbnail/video_thumbnail.dart';
import 'package:messenger/ui/page/home/page/my_profile/view.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/page/home/widget/gallery_popup.dart';
import 'package:messenger/ui/widget/animations.dart';
import 'package:messenger/ui/widget/menu_interceptor/menu_interceptor.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';

import 'controller.dart';
import 'widget/post.dart';

class PublicView extends StatefulWidget {
  const PublicView(this.id, {Key? key}) : super(key: key);

  final ChatId id;

  @override
  State<PublicView> createState() => _PublicViewState();
}

class _PublicViewState extends State<PublicView>
    with SingleTickerProviderStateMixin {
  /// [AnimationController] of [SwipeableStatus]es.
  late final AnimationController _animation;

  @override
  void initState() {
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: PublicController(
        widget.id,
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
      tag: widget.id.val,
      builder: (PublicController c) {
        return Obx(() {
          if (c.status.value.isEmpty) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(child: Text('label_no_chat_found'.l10n)),
            );
          } else if (!c.status.value.isSuccess) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          Style style = Theme.of(context).extension<Style>()!;

          return Scaffold(
            appBar: CustomAppBar(
              title: Row(
                children: [
                  Material(
                    elevation: 6,
                    type: MaterialType.circle,
                    shadowColor: const Color(0x55000000),
                    color: Colors.white,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => router.chatInfo(widget.id, Routes.public),
                      child: Center(
                        child: AvatarWidget.fromRxChat(
                          c.chat,
                          radius: 17,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: InkWell(
                      splashFactory: NoSplash.splashFactory,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () => router.chatInfo(widget.id, Routes.public),
                      child: DefaultTextStyle.merge(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.chat!.title.value,
                              style: const TextStyle(color: Colors.black),
                            ),
                            Text(
                              c.chat?.chat.value.isDialog == true
                                  ? '1 follower'
                                  : '${c.chat!.members.length} follower(s)',
                              style: Theme.of(context).textTheme.caption,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              leading: [StyledBackButton(color: style.green)],
              automaticallyImplyLeading: false,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: WidgetButton(
                    onPressed: () {},
                    child: SvgLoader.asset(
                      'assets/icons/search_green.svg',
                      width: 17.77,
                    ),
                    // onPressed: () => MyProfileView.show(context),
                    // onPressed: () => router.chatInfo(widget.id, Routes.public),
                    // child: SvgLoader.asset(
                    //   'assets/icons/chat_settings.svg',
                    //   width: 22,
                    //   height: 22,
                    // ),
                  ),
                ),
              ],
            ),
            body: Obx(() {
              if (c.status.value.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (c.chat!.messages.isEmpty) {
                return const Center(child: Text('No messages yet'));
              }

              return Scaffold(
                body: Listener(
                  onPointerSignal: (s) {
                    if (s is PointerScrollEvent) {
                      if (s.scrollDelta.dy.abs() < 3 &&
                          (s.scrollDelta.dx.abs() > 3 ||
                              c.horizontalScrollTimer.value != null)) {
                        double value =
                            _animation.value + s.scrollDelta.dx / 100;
                        _animation.value = value.clamp(0, 1);

                        if (_animation.value == 0 || _animation.value == 1) {
                          _resetHorizontalScroll(c, 100.milliseconds);
                        } else {
                          _resetHorizontalScroll(c);
                        }
                      }
                    }
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: (d) {
                      double value = _animation.value - d.delta.dx / 100;
                      _animation.value = value.clamp(0, 1);
                    },
                    onHorizontalDragEnd: (d) {
                      if (_animation.value >= 0.5) {
                        _animation.forward();
                      } else {
                        _animation.reverse();
                      }
                    },
                    child: ContextMenuInterceptor(
                      child: Obx(() {
                        return FlutterListView(
                          physics: c.horizontalScrollTimer.value == null
                              ? const BouncingScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          delegate: FlutterListViewDelegate(
                            (context, i) {
                              ListElement element =
                                  c.elements.values.elementAt(i);

                              if (element is ChatMessageElement ||
                                  element is ChatCallElement ||
                                  element is ChatMemberInfoElement) {
                                Rx<ChatItem> e;

                                if (element is ChatMessageElement) {
                                  e = element.item;
                                } else if (element is ChatCallElement) {
                                  e = element.item;
                                } else if (element is ChatMemberInfoElement) {
                                  e = element.item;
                                } else {
                                  throw Exception('Unreachable');
                                }

                                return PostWidget(
                                  animation: _animation,
                                  item: e,
                                  me: c.me,
                                  getUser: c.getUser,
                                  onGallery: c.calculateGallery,
                                  onDelete: () => c.deleteMessage(e.value),
                                  onAttachmentError: () async {
                                    await c.chat?.updateAttachments(e.value);
                                    await Future.delayed(
                                      Duration.zero,
                                    );
                                  },
                                );
                              } else if (element is ChatForwardElement) {
                                return Container();
                              } else if (element is DateTimeElement) {
                                // return _timeLabel(element.id.at.val);
                              }

                              return Container();
                            },
                            childCount: c.elements.length,
                            keepPosition: true,
                            onItemKey: (i) =>
                                c.elements.values.elementAt(i).id.toString(),
                            onItemSticky: (i) => c.elements.values.elementAt(i)
                                is DateTimeElement,
                            // initIndex: c.initIndex,
                            // initOffset: c.initOffset,
                            initOffsetBasedOnBottom: false,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              );
            }),
            floatingActionButton: false && context.isNarrow
                ? SizedBox.square(
                    dimension: 50,
                    child: FloatingActionButton(
                      onPressed: () {
                        if (router.navigation.value == null) {
                          router.navigation.value = Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                            child: _sendField(context, c),
                          );
                        } else {
                          router.navigation.value = null;
                        }
                      },
                      backgroundColor: const Color(0xFF63B4FF),
                      child: Obx(() {
                        return router.navigation.value == null
                            ? const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 36,
                              )
                            : const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 32,
                              );
                      }),
                    ),
                  )
                : null,
            bottomNavigationBar: false && context.isNarrow
                ? null
                : Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                    child: _sendField(context, c),
                  ),
          );
        });
      },
    );
  }

  Widget _sendField(BuildContext context, PublicController c) {
    Style style = Theme.of(context).extension<Style>()!;
    const double iconSize = 22;

    return Theme(
      data: Theme.of(context).copyWith(
        shadowColor: const Color(0x55000000),
        iconTheme: const IconThemeData(color: Colors.blue),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          focusColor: Colors.white,
          fillColor: Colors.white,
          hoverColor: Colors.transparent,
          filled: true,
          isDense: true,
          contentPadding: EdgeInsets.fromLTRB(
            15,
            PlatformUtils.isDesktop ? 30 : 23,
            15,
            0,
          ),
        ),
      ),
      child: Container(
        key: const Key('SendField'),
        decoration: BoxDecoration(
          borderRadius: style.cardRadius,
          boxShadow: const [
            CustomBoxShadow(
              blurRadius: 8,
              color: Color(0x22000000),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              bool grab =
                  (125 + 2) * c.attachments.length > constraints.maxWidth - 16;
              return Stack(
                children: [
                  Obx(() {
                    bool expanded = c.attachments.isNotEmpty;

                    return ConditionalBackdropFilter(
                      condition: style.cardBlur > 0,
                      filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                      borderRadius: BorderRadius.only(
                        topLeft: style.cardRadius.topLeft,
                        topRight: style.cardRadius.topRight,
                      ),
                      child: AnimatedSizeAndFade(
                        fadeDuration: 400.milliseconds,
                        sizeDuration: 400.milliseconds,
                        fadeInCurve: Curves.ease,
                        fadeOutCurve: Curves.ease,
                        sizeCurve: Curves.ease,
                        child: !expanded
                            ? const SizedBox(height: 1, width: double.infinity)
                            : Container(
                                key: const Key('Attachments'),
                                width: double.infinity,
                                color: const Color(0xFFFFFFFF).withOpacity(0.4),
                                padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (c.attachments.isNotEmpty)
                                      const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: MouseRegion(
                                        cursor: grab
                                            ? SystemMouseCursors.grab
                                            : MouseCursor.defer,
                                        opaque: false,
                                        child: ScrollConfiguration(
                                          behavior: MyCustomScrollBehavior(),
                                          child: SingleChildScrollView(
                                            clipBehavior: Clip.none,
                                            physics: grab
                                                ? null
                                                : const NeverScrollableScrollPhysics(),
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: c.attachments
                                                  .map(
                                                    (e) => _buildAttachment(
                                                      context,
                                                      c,
                                                      e,
                                                      grab,
                                                    ),
                                                  )
                                                  .toList(),
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
                  }),
                ],
              );
            }),
            ConditionalBackdropFilter(
              condition: style.cardBlur > 0,
              filter: ImageFilter.blur(
                sigmaX: style.cardBlur,
                sigmaY: style.cardBlur,
              ),
              borderRadius: BorderRadius.only(
                topLeft: c.attachments.isEmpty
                    ? style.cardRadius.topLeft
                    : Radius.zero,
                topRight: c.attachments.isEmpty
                    ? style.cardRadius.topRight
                    : Radius.zero,
                bottomLeft: style.cardRadius.bottomLeft,
                bottomRight: style.cardRadius.bottomLeft,
              ),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                decoration: BoxDecoration(color: style.cardColor),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!PlatformUtils.isMobile || PlatformUtils.isWeb)
                      WidgetButton(
                        onPressed: c.pickFile,
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Center(
                            child: SizedBox(
                              width: iconSize,
                              height: iconSize,
                              child: SvgLoader.asset(
                                'assets/icons/attach_green.svg',
                                height: iconSize,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      WidgetButton(
                        onPressed: () {
                          ModalPopup.show(
                            context: context,
                            mobileConstraints: const BoxConstraints(),
                            mobilePadding:
                                const EdgeInsets.fromLTRB(8, 0, 8, 0),
                            desktopConstraints:
                                const BoxConstraints(maxWidth: 400),
                            child: _attachmentSelection(c),
                          );
                        },
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Center(
                            child: SizedBox(
                              width: iconSize,
                              height: iconSize,
                              child: SvgLoader.asset(
                                'assets/icons/attach_green.svg',
                                height: iconSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 5 + (PlatformUtils.isMobile ? 0 : 8),
                          bottom: 13,
                        ),
                        child: Transform.translate(
                          offset: Offset(0, PlatformUtils.isMobile ? 6 : 1),
                          child: ReactiveTextField(
                            key: const Key('MessageField'),
                            state: c.send,
                            hint: 'Write a post',
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
                    const SizedBox(width: 0),
                    WidgetButton(
                      onPressed: c.send.submit,
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: SizedBox(
                              key: const Key('Send'),
                              width: 25.18,
                              height: 22.85,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 0),
                                child: SvgLoader.asset(
                                  'assets/icons/send_green.svg',
                                  height: 22.85,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a centered [time] label.
  Widget _timeLabel(DateTime time) {
    Style style = Theme.of(context).extension<Style>()!;
    return Column(
      children: [
        const SizedBox(height: 16 * 1.5 / 2),
        SwipeableStatus(
          animation: _animation,
          asStack: true,
          padding: const EdgeInsets.only(right: 8),
          crossAxisAlignment: CrossAxisAlignment.center,
          swipeable: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(DateFormat('dd.MM.yy').format(time)),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: style.systemMessageBorder,
                color: style.systemMessageColor,
                // border: style.cardBorder,
                // color: const Color(0xFFF8F8F8),
              ),
              child: Text(
                time.toRelative(),
                style: const TextStyle(color: Color(0xFF888888)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16 * 1.5 / 2),
      ],
    );
  }

  /// Returns a visual representation of the provided [Attachment].
  Widget _buildAttachment(
    BuildContext context,
    PublicController c,
    Attachment e, [
    bool grab = false,
  ]) {
    bool isImage =
        (e is ImageAttachment || (e is LocalAttachment && e.file.isImage));
    bool isVideo = (e is FileAttachment && e.isVideo) ||
        (e is LocalAttachment && e.file.isVideo);

    const double size = 125;

    Widget _content() {
      if (isImage || isVideo) {
        Widget child;

        if (isImage) {
          if (e is LocalAttachment) {
            if (e.file.bytes == null) {
              if (e.file.path == null) {
                child = const Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(),
                  ),
                );
              } else {
                if (e.file.isSvg) {
                  child = SvgLoader.file(
                    File(e.file.path!),
                    width: size,
                    height: size,
                  );
                } else {
                  child = Image.file(
                    File(e.file.path!),
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                  );
                }
              }
            } else {
              if (e.file.isSvg) {
                child = SvgLoader.bytes(
                  e.file.bytes!,
                  width: size,
                  height: size,
                );
              } else {
                child = Image.memory(
                  e.file.bytes!,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                );
              }
            }
          } else {
            child = Image.network(
              '${Config.files}${e.original.relativeRef}',
              fit: BoxFit.cover,
              width: size,
              height: size,
            );
          }
        } else {
          if (e is LocalAttachment) {
            if (e.file.bytes == null) {
              child = const Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(),
                ),
              );
            } else {
              child = VideoThumbnail.bytes(bytes: e.file.bytes!);
            }
          } else {
            child = VideoThumbnail.url(
              url: '${Config.files}${e.original.relativeRef}',
            );
          }
        }

        return WidgetButton(
          // key: c.attachmentKeys[i],
          onPressed: () {
            List<Attachment> attachments = c.attachments.where((e) {
              return e is ImageAttachment ||
                  (e is FileAttachment && e.isVideo) ||
                  (e is LocalAttachment && (e.file.isImage || e.file.isVideo));
            }).toList();

            int index = attachments.indexOf(e);
            if (index != -1) {
              GalleryPopup.show(
                context: context,
                gallery: GalleryPopup(
                  initial: attachments.indexOf(e),
                  initialKey: e.key,
                  onTrashPressed: (int i) {
                    Attachment a = attachments[i];
                    c.attachments.removeWhere((o) => o == a);
                  },
                  children: attachments.map((o) {
                    final String link =
                        '${Config.files}${o.original.relativeRef}';
                    if (o is ImageAttachment ||
                        (o is LocalAttachment && o.file.isImage)) {
                      return GalleryItem.image(link, o.filename);
                    }
                    return GalleryItem.video(link, o.filename);
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
                  ),
                )
              : child,
        );
      }

      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                e.filename,
                style: const TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
                // TODO: Cut the file in way for the extension to be displayed.
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                e.original.size == null
                    ? '... KB'
                    : '${e.original.size! ~/ 1024} KB',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF888888),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    Widget _attachment() {
      Style style = Theme.of(context).extension<Style>()!;
      return MouseRegion(
        key: Key(e.id.val),
        opaque: false,
        onEnter: (_) => c.hoveredAttachment.value = e,
        onExit: (_) => c.hoveredAttachment.value = null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFFF5F5F5),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _content(),
              ),
              Center(
                child: SizedBox(
                  height: 30,
                  width: 30,
                  child: ElasticAnimatedSwitcher(
                    child: e is LocalAttachment
                        ? e.status.value == SendingStatus.error
                            ? Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Center(
                                  child: Icon(Icons.error, color: Colors.red),
                                ),
                              )
                            : const SizedBox()
                        : const SizedBox(),
                  ),
                ),
              ),
              if (!c.send.status.value.isLoading)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4, top: 4),
                    child: Obx(() {
                      return AnimatedSwitcher(
                        duration: 200.milliseconds,
                        child: (c.hoveredAttachment.value == e ||
                                PlatformUtils.isMobile)
                            ? InkWell(
                                key: const Key('RemovePickedFile'),
                                onTap: () => c.attachments.remove(e),
                                child: Container(
                                  width: 15,
                                  height: 15,
                                  margin:
                                      const EdgeInsets.only(left: 8, bottom: 8),
                                  child: Container(
                                    key: const Key('Close'),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      // color: Colors.black.withOpacity(0.05),
                                      color: style.cardColor,
                                    ),
                                    child: Center(
                                      child: SvgLoader.asset(
                                        'assets/icons/close_primary.svg',
                                        width: 7,
                                        height: 7,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return MyDismissible(
      key: Key(e.id.val),
      direction: MyDismissDirection.up,
      onDismissed: (_) => c.attachments.remove(e),
      child: _attachment(),
    );
  }

  Widget _attachmentSelection(PublicController c) {
    return Builder(builder: (context) {
      Widget button({
        required String text,
        IconData? icon,
        Widget? child,
        void Function()? onPressed,
      }) {
        // TEXT MUST SCALE HORIZONTALLY!!!!!!!!
        return RoundFloatingButton(
          text: text,
          withBlur: false,
          onPressed: () {
            onPressed?.call();
            Navigator.of(context).pop();
          },
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black,
          ),
          autoSizeText: true,
          color: const Color(0xFF63B4FF),
          child: SizedBox(
            width: 60,
            height: 60,
            child: child ?? Icon(icon, color: Colors.white, size: 30),
          ),
        );
      }

      bool isAndroid = PlatformUtils.isAndroid;

      List<Widget> children = [
        button(
          text: isAndroid ? 'Фото' : 'Камера',
          onPressed: c.pickImageFromCamera,
          child: SvgLoader.asset(
            'assets/icons/make_photo.svg',
            width: 60,
            height: 60,
          ),
        ),
        if (isAndroid)
          button(
            text: 'Видео',
            onPressed: c.pickVideoFromCamera,
            child: SvgLoader.asset(
              'assets/icons/video_on.svg',
              width: 60,
              height: 60,
            ),
          ),
        button(
          text: 'Галерея',
          onPressed: c.pickMedia,
          child: SvgLoader.asset(
            'assets/icons/gallery.svg',
            width: 60,
            height: 60,
          ),
        ),
        button(
          text: 'Файл',
          onPressed: c.pickFile,
          child: SvgLoader.asset(
            'assets/icons/file.svg',
            width: 60,
            height: 60,
          ),
        ),
      ];

      // MAKE SIZE MINIMUM.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: children,
          ),
          const SizedBox(height: 40),
          OutlinedRoundedButton(
            key: const Key('CloseButton'),
            title: Text('btn_close'.l10n),
            onPressed: Navigator.of(context).pop,
            color: const Color(0xFFEEEEEE),
          ),
          const SizedBox(height: 10),
        ],
      );
    });
  }

  /// Cancels a [_horizontalScrollTimer] and starts it again with the provided
  /// [duration].
  ///
  /// Defaults to 150 milliseconds if no [duration] is provided.
  void _resetHorizontalScroll(PublicController c, [Duration? duration]) {
    c.horizontalScrollTimer.value?.cancel();
    c.horizontalScrollTimer.value = Timer(duration ?? 150.milliseconds, () {
      if (_animation.value >= 0.5) {
        _animation.forward();
      } else {
        _animation.reverse();
      }
      c.horizontalScrollTimer.value = null;
    });
  }
}
