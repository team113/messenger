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

import 'dart:math';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:collection/collection.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '/api/backend/schema.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/file.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/paginated.dart';
import '/domain/service/chat.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/media_attachment.dart';
import '/ui/page/home/page/chat/widget/video/widget/centered_play_pause.dart';
import '/ui/page/home/page/chat/widget/video/widget/custom_play_pause.dart';
import '/ui/page/home/page/chat/widget/video/widget/position.dart';
import '/ui/page/home/page/chat/widget/video/widget/video_progress_bar.dart';
import '/ui/page/home/page/chat/widget/video/widget/video_volume_bar.dart'
    show ProgressBarColors, VideoVolumeBar;
import '/ui/page/home/page/user/controller.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/safe_area/safe_area.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/get.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'controller.dart';
import 'gallery/view.dart';
import 'widget/notification.dart';
import 'widget/video_playback.dart';

/// View for displaying [Post]s.
class PlayerView extends StatelessWidget {
  const PlayerView({
    super.key,
    required this.source,
    this.resourceId,
    this.initialKey,
    this.initialIndex = 0,
    this.onReply,
    this.onShare,
    this.onReact,
    this.onScrollTo,
  });

  /// [Paginated] of [MediaItem]s being the source of [Post]s.
  final Paginated<String, MediaItem> source;

  /// [ResourceId] from where the [source] is coming from.
  final ResourceId? resourceId;

  /// Initial [Post.id] of the [PlayerController.vertical] controller.
  final String? initialKey;

  /// Initial index of a [Post.horizontal] controller.
  final int initialIndex;

  /// Callback, called when reply of the [Post] is called.
  final void Function(Post)? onReply;

  /// Callback, called when share of the [Post] is called.
  final void Function(Post)? onShare;

  /// Callback, called when react of the [Post] is called.
  final void Function(Post, String)? onReact;

  /// Callback, called when scroll to the [Post] is called.
  final void Function(Post)? onScrollTo;

  /// Displays the provided [gallery] in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget gallery,
  }) async {
    final style = Theme.of(context).style;

    final ModalRoute<T> route;

    if (context.isMobile) {
      route = MaterialPageRoute<T>(
        builder: (BuildContext context) {
          return Material(
            type: MaterialType.canvas,
            color: style.colors.onBackground,
            child: Scaffold(
              backgroundColor: style.colors.onBackground,
              body: gallery,
            ),
          );
        },
      );
    } else {
      route = RawDialogRoute<T>(
        barrierColor: style.colors.backgroundGallery,
        barrierDismissible: true,
        pageBuilder: (_, _, _) {
          return CustomSafeArea(
            child: Material(type: MaterialType.transparency, child: gallery),
          );
        },
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (_, Animation<double> animation, _, Widget child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.linear),
            child: child,
          );
        },
      );
    }

    router.obscuring.add(route);

    try {
      return await Navigator.of(context, rootNavigator: true).push<T>(route);
    } finally {
      router.obscuring.remove(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: PlayerController(
        Get.find(),
        Get.findOrNull<ChatService>(),
        initialKey: initialKey ?? '',
        initialIndex: initialIndex,
        source: source,
        shouldClose: Navigator.of(context).pop,
        resourceId: resourceId,
      ),
      builder: (PlayerController c) {
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  _content(context, c, constraints),
                  _interface(context, c, constraints),

                  // Mouse activity detector for desktop platforms.
                  if (!PlatformUtils.isMobile)
                    Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerHover: (_) => c.keepActive(),
                      onPointerMove: (_) => c.keepActive(),
                      onPointerDown: (_) => c.keepActive(),
                      onPointerUp: (_) => c.keepActive(),
                      onPointerSignal: (_) => c.keepActive(),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Builds the visual representation of the [Post]s list.
  Widget _content(
    BuildContext context,
    PlayerController c,
    BoxConstraints constraints,
  ) {
    return Obx(() {
      return PageView.builder(
        physics: c.viewportIsTransformed.value
            ? NeverScrollableScrollPhysics()
            : null,
        controller: c.vertical,
        scrollDirection: Axis.vertical,
        itemCount: c.posts.length,
        itemBuilder: (context, i) {
          return FractionallySizedBox(
            heightFactor: 1 / c.vertical.viewportFraction,
            child: _post(context, c, constraints, c.posts.elementAt(i)),
          );
        },
        // children: [...c.posts.map((e) => _post(context, c, e))],
      );
    });
  }

  /// Builds the visual representation of the [Post.items] list.
  Widget _post(
    BuildContext context,
    PlayerController c,
    BoxConstraints constraints,
    Post post,
  ) {
    return Obx(() {
      return PageView(
        physics: c.viewportIsTransformed.value
            ? NeverScrollableScrollPhysics()
            : null,
        controller: post.horizontal.value,
        children: [
          ...post.items.map(
            (e) => _attachment(context, c, constraints, post, e),
          ),
        ],
      );
    });
  }

  /// Builds the [item] visual representation.
  Widget _attachment(
    BuildContext context,
    PlayerController c,
    BoxConstraints constraints,
    Post post,
    PostItem item,
  ) {
    final Attachment attachment = item.attachment;

    Widget? child;
    bool isVideo = false;

    if (attachment is ImageAttachment) {
      double aspect = 1;

      final StorageFile file = attachment.original;
      if (file is ImageFile) {
        aspect = (file.width ?? 1) / (file.height ?? 1);

        if (aspect < 1) {
          if (constraints.biggest.aspectRatio < aspect) {
            aspect = (file.height ?? 1) / (file.width ?? 1);
          }
        } else {
          if (constraints.biggest.aspectRatio > aspect) {
            aspect = (file.height ?? 1) / (file.width ?? 1);
          }
        }
      }

      child = RetryImage(
        attachment.original.url,
        width: aspect >= 1 ? double.infinity : null,
        height: aspect >= 1 ? null : double.infinity,
        checksum: attachment.original.checksum,
        thumbhash: attachment.big.thumbhash,
        fit: BoxFit.contain,
        onForbidden: () async => await c.reload(post),
      );
    } else if (attachment is FileAttachment) {
      if (attachment.isVideo) {
        isVideo = true;

        child = VideoPlayback(
          attachment.original.url,
          checksum: attachment.original.checksum,
          volume: c.settings.value?.videoVolume,
          onVolumeChanged: c.setVideoVolume,
          onError: () async => await c.reload(post),
          loop: true,
          autoplay: false,
          onController: (e) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              item.video.value?.dispose();

              if (e == null) {
                item.video.value = null;
              } else {
                item.video.value = ReactivePlayerController(e);

                if (c.index.value == c.posts.indexOf(post)) {
                  item.video.value?.play();
                }
              }
            });
          },
        );
      }
    }

    if (child != null) {
      child = Stack(
        alignment: Alignment.center,
        children: [
          MouseRegion(
            hitTestBehavior: HitTestBehavior.translucent,
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (WebUtils.isPopup) {
                  WebUtils.closeWindow();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          MouseRegion(
            hitTestBehavior: HitTestBehavior.translucent,
            cursor: isVideo
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: c.playPause,
              onDoubleTap: c.toggleFullscreen,
              onLongPress: c.interface.toggle,
              child: child,
            ),
          ),
          Obx(() {
            final ReactivePlayerController? video = c.item?.video.value;

            if (video != null) {
              if (video.isBuffering.value) {
                return const SizedBox();
              }

              return CenteredPlayPause(
                show: c.interface.value && !video.isPlaying.value,
                isCompleted: video.isCompleted.value,
                isPlaying: video.isPlaying.value,
                onPressed: c.playPause,
              );
            }

            return const SizedBox();
          }),
        ],
      );
    }

    if (child != null) {
      return ContextMenuRegion(
        actions: [
          if (!isVideo)
            ContextMenuButton(
              label: 'btn_copy'.l10n,
              trailing: const SvgIcon(SvgIcons.copy19),
              inverted: const SvgIcon(SvgIcons.copy19White),
              onPressed: () async => await c.copy(post, item),
            ),

          if (!PlatformUtils.isWeb && PlatformUtils.isMobile) ...[
            ContextMenuButton(
              label: 'btn_save_to_gallery'.l10n,
              trailing: const SvgIcon(SvgIcons.download19),
              inverted: const SvgIcon(SvgIcons.download19White),
              onPressed: () async => await c.saveToGallery(item),
            ),
          ] else ...[
            ContextMenuButton(
              label: 'btn_download'.l10n,
              trailing: const SvgIcon(SvgIcons.download19),
              inverted: const SvgIcon(SvgIcons.download19White),
              onPressed: () async => await c.download(item),
            ),

            if (!PlatformUtils.isWeb && PlatformUtils.isDesktop)
              ContextMenuButton(
                label: 'btn_download_as'.l10n,
                trailing: const SvgIcon(SvgIcons.download19),
                inverted: const SvgIcon(SvgIcons.download19White),
                onPressed: () async => await c.downloadAs(item),
              ),
          ],
        ],
        child: InteractiveViewer(
          transformationController: c.transformationController,
          onInteractionStart: (_) {
            c.viewportIsTransformed.value = true;
          },
          onInteractionEnd: (e) {
            c.viewportIsTransformed.value =
                c.transformationController.value.forward.z > 1;
          },
          child: child,
        ),
      );
    }

    return SizedBox();
  }

  /// Builds the interface to display over the [_content].
  Widget _interface(
    BuildContext context,
    PlayerController c,
    BoxConstraints constraints,
  ) {
    final bool isMobile = context.isMobile;

    return Stack(
      children: [
        _overlay(context, c, constraints),

        Align(
          alignment: Alignment.bottomCenter,
          child: Obx(() {
            return AnimatedOpacity(
              duration: Duration(milliseconds: 250),
              opacity: c.interface.value ? 1 : 0,
              child: _bottom(context, c, constraints),
            );
          }),
        ),

        Align(
          alignment: Alignment.topCenter,
          child: Obx(() {
            return AnimatedOpacity(
              duration: Duration(milliseconds: 250),
              opacity: c.interface.value ? 1 : 0,
              child: _top(context, c, constraints),
            );
          }),
        ),

        Padding(
          padding: EdgeInsets.fromLTRB(
            0,
            isMobile ? 0 : 60,
            0,
            isMobile ? 0 : 55,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Obx(() {
              return AnimatedSlide(
                duration: Duration(milliseconds: 200),
                curve: Curves.ease,
                offset: Offset(c.side.value ? 0 : 1, 0),
                child: _side(context, c, constraints),
              );
            }),
          ),
        ),

        // If there's any notifications to show, display them.
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 64),
            child: Obx(() {
              if (c.notifications.isEmpty) {
                return const SizedBox();
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: c.notifications.reversed.take(3).map((e) {
                  return PlayerNotificationWidget(
                    e,
                    onClose: () => c.notifications.remove(e),
                  );
                }).toList(),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Builds the [DotsDecorator] displaying the [Post.horizontal] item.
  Widget _dots(BuildContext context, PlayerController c) {
    final style = Theme.of(context).style;

    return Obx(() {
      final Post? post = c.post;
      if (post == null || post.items.length < 2) {
        return SizedBox();
      }

      return Obx(() {
        return AnimatedOpacity(
          duration: Duration(milliseconds: 200),
          opacity: c.expanded.value ? 0 : 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
            child: Container(
              height: 20,
              padding: EdgeInsets.fromLTRB(4, 2, 4, 2),
              decoration: BoxDecoration(
                color: style.colors.onBackgroundOpacity20,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DotsIndicator(
                dotsCount: post.items.length,
                position: post.index.value.toDouble(),
                animate: true,
                mainAxisSize: MainAxisSize.min,
                onTap: (i) => post.horizontal.value.jumpToPage(i),
                decorator: DotsDecorator(
                  spacing: EdgeInsets.fromLTRB(2, 1, 2, 1),
                  color: style.colors.secondary,
                  activeColor: style.colors.onPrimary,
                ),
              ),
            ),
          ),
        );
      });
    });
  }

  /// Builds an overlay to display over the current [Post].
  Widget _overlay(
    BuildContext context,
    PlayerController c,
    BoxConstraints constraints,
  ) {
    final style = Theme.of(context).style;

    final bool isMobile = context.isMobile;

    return Obx(() {
      final ReactivePlayerController? video = c.item?.video.value;

      return Stack(
        children: [
          if (video != null) ...[
            if (isMobile) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTapDown: (_) => video.setRate(0.5),
                  onTapUp: (_) => video.setRate(1),
                  onDoubleTap: () {
                    final int seconds = video.position.value.inSeconds;
                    video.seekTo(Duration(seconds: max(seconds - 5, 0)));
                  },
                  child: Container(
                    height: double.infinity,
                    width: constraints.maxWidth / 6,
                    color: style.colors.transparent,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTapDown: (_) => video.setRate(2),
                  onTapUp: (_) => video.setRate(1),
                  onDoubleTap: () {
                    final int seconds = video.position.value.inSeconds;
                    video.seekTo(
                      Duration(
                        seconds: min(
                          seconds + 5,
                          video.duration.value.inSeconds,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: double.infinity,
                    width: constraints.maxWidth / 6,
                    color: style.colors.transparent,
                  ),
                ),
              ),
            ],
          ],

          Obx(() {
            if (!c.source.nextLoading.value) {
              return SizedBox();
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: CustomProgressIndicator.primary(),
              ),
            );
          }),

          Obx(() {
            if (!c.source.previousLoading.value) {
              return SizedBox();
            }

            return Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Align(
                alignment: Alignment.topCenter,
                child: CustomProgressIndicator.primary(),
              ),
            );
          }),
        ],
      );
    });
  }

  /// Builds the top header of the [_interface].
  Widget _top(
    BuildContext context,
    PlayerController c,
    BoxConstraints constraints,
  ) {
    final style = Theme.of(context).style;
    final bool isMobile = context.isMobile;

    final EdgeInsets padding = MediaQuery.paddingOf(context);

    return Container(
      height: 60 + padding.top,
      padding: EdgeInsets.fromLTRB(
        5 + padding.left,
        padding.top,
        5 + padding.right,
        0,
      ),
      decoration: BoxDecoration(color: Color(0x4B333333)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          WidgetButton(
            onPressed: () {
              if (WebUtils.isPopup) {
                WebUtils.closeWindow();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Row(
                children: [
                  SvgIcon(SvgIcons.arrowLeft),
                  SizedBox(width: 12),
                  if (!isMobile)
                    Text(
                      'btn_close'.l10n,
                      style: style.fonts.small.regular.onPrimary,
                    ),
                ],
              ),
            ),
          ),
          Spacer(),
          const SizedBox(width: 12),
          if (PlatformUtils.isWeb &&
              !PlatformUtils.isMobile &&
              !WebUtils.isPopup) ...[
            Opacity(
              opacity: resourceId?.chatId != null ? 1 : 0.5,
              child: WidgetButton(
                onPressed: resourceId?.chatId != null ? c.openPopup : null,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: SvgIcon(SvgIcons.mediaPopup),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Opacity(
            opacity: c.source.length > 1 ? 1 : 0.5,
            child: WidgetButton(
              onPressed: c.source.length > 1
                  ? () async {
                      if (isMobile) {
                        final ReactivePlayerController? video =
                            c.item?.video.value;
                        video?.pause();

                        await GalleryView.show(context, controller: c);
                      } else {
                        c.side.toggle();
                      }
                    }
                  : null,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 250),
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                decoration: BoxDecoration(
                  color: c.side.value ? style.colors.onPrimaryOpacity25 : null,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SvgIcon(SvgIcons.mediaGallery),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Obx(() {
            return ContextMenuRegion(
              actions: [
                if (onScrollTo != null)
                  ContextMenuButton(
                    label: 'btn_find_in_chat'.l10n,
                    trailing: const SvgIcon(SvgIcons.chat19),
                    inverted: const SvgIcon(SvgIcons.chat19White),
                    onPressed: () {
                      final Post? post = c.post;
                      if (post != null) {
                        onScrollTo?.call(post);
                        Navigator.of(context).pop();
                      }
                    },
                  ),

                ContextMenuButton(
                  label: 'btn_save'.l10n,
                  trailing: const SvgIcon(SvgIcons.copy19),
                  inverted: const SvgIcon(SvgIcons.copy19White),
                  onPressed: () async {
                    final PostItem? item = c.item;

                    if (item != null) {
                      if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
                        await c.saveToGallery(item);
                      } else {
                        await c.download(item);
                      }
                    }
                  },
                ),
                if (c.interface.value)
                  ContextMenuButton(
                    label: 'btn_hide_interface'.l10n,
                    trailing: const SvgIcon(SvgIcons.hideControls),
                    inverted: const SvgIcon(SvgIcons.hideControlsWhite),
                    onPressed: c.interface.toggle,
                  ),
              ],
              enablePrimaryTap: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 21, 24, 21),
                child: SvgIcon(SvgIcons.moreWhite),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Builds the bottom header of the [_interface].
  Widget _bottom(
    BuildContext context,
    PlayerController c,
    BoxConstraints constraints,
  ) {
    final EdgeInsets padding = MediaQuery.of(context).padding;

    return Obx(() {
      final ReactivePlayerController? video = c.item?.video.value;

      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          _bar(context, c, constraints),

          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                0,
                0,
                16 + padding.right,
                57 + 16 + padding.bottom,
              ),
              child: _position(context, c),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dots(context, c),
                Padding(
                  padding: const EdgeInsets.only(bottom: 57 + 12),
                  child: _description(context, c),
                ),
              ],
            ),
          ),

          if (video != null)
            Positioned(
              bottom: 44 + padding.bottom,
              left: 0,
              right: 0,
              child: Obx(() {
                return ProgressBar(
                  handleHeight: 1,
                  buffer: video.buffered.firstOrNull?.end ?? Duration.zero,
                  duration: video.duration.value,
                  position: video.position.value,
                  isPlaying: video.isPlaying.value,
                  onPause: video.pause,
                  onPlay: video.play,
                  seekTo: video.seekTo,
                );
              }),
            ),
        ],
      );
    });
  }

  /// Builds an expandable [Post.description] with its meta data.
  Widget _description(
    BuildContext context,
    PlayerController c, {
    bool bottom = true,
  }) {
    final style = Theme.of(context).style;

    return Obx(() {
      final MediaItem? item = c.source.items[c.key.value];
      final ChatItem? message = item?.item;

      if (message == null) {
        return SizedBox();
      }

      final User user = message.author;
      final String? text = message is ChatMessage ? message.text?.val : null;

      final EdgeInsets padding = MediaQuery.of(context).padding;

      return Padding(
        padding: EdgeInsets.fromLTRB(
          padding.left,
          0,
          padding.right,
          bottom ? padding.bottom : 0,
        ),
        child: WidgetButton(
          onPressed: c.expanded.toggle,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Row(
                        children: [
                          AvatarWidget.fromUser(
                            user,
                            radius: AvatarRadius.small,
                            isOnline:
                                user.online &&
                                user.presence == UserPresence.present,
                            isAway:
                                user.online &&
                                user.presence == UserPresence.away,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              user.title(),
                              style: style.fonts.medium.bold.onPrimary,
                            ),
                          ),
                          Opacity(opacity: 0, child: _position(context, c)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        text != null ? 8 : 0,
                        20,
                        4,
                      ),
                      child: Obx(() {
                        return AnimatedSizeAndFade(
                          fadeDuration: Duration(milliseconds: 250),
                          sizeDuration: Duration(milliseconds: 250),
                          fadeInCurve: Curves.ease,
                          fadeOutCurve: Curves.ease,
                          alignment: Alignment.center,
                          child: c.expanded.value
                              ? Column(
                                  key: Key('Expanded'),
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (text != null)
                                      Text(
                                        text,
                                        style: style
                                            .fonts
                                            .normal
                                            .regular
                                            .onPrimary,
                                        maxLines: null,
                                      ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          message.at.val.toRelative(),
                                          style: style
                                              .fonts
                                              .normal
                                              .regular
                                              .onPrimary
                                              .copyWith(
                                                color: style
                                                    .colors
                                                    .onPrimaryOpacity50,
                                              ),
                                        ),
                                        Spacer(),
                                        Opacity(
                                          opacity: 0,
                                          child: _position(context, c),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : text == null
                              ? SizedBox(width: double.infinity)
                              : Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    key: Key('Short'),
                                    text,
                                    style: style.fonts.normal.regular.onPrimary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Opacity(opacity: 0, child: _position(context, c)),
            ],
          ),
        ),
      );
    });
  }

  /// Builds a [Text] with current position of [ReactivePlayerController], if
  /// any is visible right now.
  Widget _position(BuildContext context, PlayerController c) {
    final style = Theme.of(context).style;

    return Obx(() {
      final ReactivePlayerController? video = c.item?.video.value;
      if (video == null) {
        return SizedBox();
      }

      return Text(
        '${video.position.value.hhMmSs()} / ${video.duration.value.hhMmSs()}',
        style: style.fonts.normal.regular.onPrimary,
      );
    });
  }

  /// Builds an expandable [_mobileBar] or [_desktopBar].
  Widget _bar(
    BuildContext context,
    PlayerController c,
    BoxConstraints constraints,
  ) {
    final bool isMobile = context.isMobile;

    final EdgeInsets padding = MediaQuery.paddingOf(context);

    return AnimatedContainer(
      duration: Duration(milliseconds: 250),
      padding: EdgeInsets.fromLTRB(5, 5, 5, 5 + padding.bottom),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: c.expanded.value
              ? [
                  Color.fromRGBO(0, 0, 0, 0.0),
                  Color.fromRGBO(0, 0, 0, 0.50),
                  Color.fromRGBO(0, 0, 0, 0.50),
                ]
              : [
                  Color.fromRGBO(51, 51, 51, 0.30),
                  Color.fromRGBO(51, 51, 51, 0.30),
                  Color.fromRGBO(51, 51, 51, 0.30),
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.15, 1],
        ),
      ),
      margin: EdgeInsets.only(top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSizeAndFade.showHide(
            show: c.expanded.value,
            fadeDuration: Duration(milliseconds: 250),
            sizeDuration: Duration(milliseconds: 250),
            fadeInCurve: Curves.ease,
            fadeOutCurve: Curves.ease,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16 + 12 + 16, 0, 0),
              child: Opacity(
                opacity: 0,
                child: _description(context, c, bottom: false),
              ),
            ),
          ),
          SizedBox(
            height: 57 - 12,
            child: isMobile
                ? _mobileBar(context, c, constraints)
                : _desktopBar(context, c, constraints),
          ),
        ],
      ),
    );
  }

  /// Builds the volume controls for the [controller].
  Widget _volume(
    BuildContext context,
    PlayerController c,
    ReactivePlayerController controller,
  ) {
    final style = Theme.of(context).style;

    return Row(
      children: [
        WidgetButton(
          onPressed: () {
            if (controller.volume.value == 0) {
              controller.setVolume(c.latestVolume ?? 0.5);
            } else {
              c.latestVolume = controller.volume.value;
              controller.setVolume(0.0);
            }
          },
          child: Obx(() {
            return SvgIcon(
              controller.volume.value == 0
                  ? SvgIcons.volumeMuted
                  : SvgIcons.volume,
            );
          }),
        ),
        SizedBox(width: 12),
        Expanded(
          child: VideoVolumeBar(
            volume: controller.volume.value,
            onSetVolume: controller.setVolume,
            handleHeight: 8,
            colors: ProgressBarColors(
              played: style.colors.onPrimary,
              handle: style.colors.onPrimary,
              buffered: style.colors.secondaryLight,
              background: style.colors.onPrimaryOpacity50,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a bottom controls for desktop-styled [_bottom].
  Widget _desktopBar(
    BuildContext context,
    PlayerController c,
    BoxConstraints constraints,
  ) {
    return Obx(() {
      final ReactivePlayerController? video = c.item?.video.value;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 7),
          if (video != null) ...[
            CustomPlayPause(
              video.isPlaying.value,
              height: 48,
              onTap: c.playPause,
            ),
            const SizedBox(width: 12),
            CurrentPosition(
              position: video.position.value,
              duration: video.duration.value,
            ),
            const SizedBox(width: 36),
            SizedBox(width: 100, child: _volume(context, c, video)),
          ],
          const SizedBox(width: 12),
          Spacer(),
          const SizedBox(width: 12),
          _buttons(context, c, constraints),
          const SizedBox(width: 12),
        ],
      );
    });
  }

  /// Builds a bottom controls for mobile-styled [_bottom].
  Widget _mobileBar(
    BuildContext context,
    PlayerController c,
    BoxConstraints constraints,
  ) {
    return Obx(() {
      final Post? post = c.post;
      final ChatItem? item = post?.item;
      final ReactivePlayerController? video = c.item?.video.value;

      final bool canReact = item != null && onReact != null;
      final bool canReply = item != null && onReply != null;
      final bool canShare = item != null && onShare != null;

      return Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Opacity(
            opacity: video == null ? 0.5 : 1,
            child: WidgetButton(
              onPressed: video == null
                  ? null
                  : () {
                      if (video.volume.value == 0) {
                        video.setVolume(c.latestVolume ?? 0.5);
                      } else {
                        c.latestVolume = video.volume.value;
                        video.setVolume(0.0);
                      }
                    },
              child: SizedBox(
                width: 24,
                child: video == null
                    ? SvgIcon(SvgIcons.volume)
                    : Obx(() {
                        return SvgIcon(
                          video.volume.value == 0
                              ? SvgIcons.volumeMuted
                              : SvgIcons.volume,
                        );
                      }),
              ),
            ),
          ),

          Opacity(
            opacity: canReact ? 1 : 0.5,
            child: WidgetButton(
              onPressed: canReact
                  ? () {
                      // TODO: Toggle reactions.
                    }
                  : null,
              child: SvgIcon(SvgIcons.videoReact),
            ),
          ),

          Opacity(
            opacity: canReply ? 1 : 0.5,
            child: WidgetButton(
              onPressed: canReply
                  ? () {
                      onReply?.call(post!);
                      Navigator.of(context).pop();
                    }
                  : null,
              child: SvgIcon(SvgIcons.videoReply),
            ),
          ),

          Opacity(
            opacity: canShare ? 1 : 0.5,
            child: WidgetButton(
              onPressed: canShare
                  ? () {
                      onShare?.call(post!);
                    }
                  : null,
              child: SvgIcon(SvgIcons.videoShare),
            ),
          ),
        ],
      );
    });
  }

  /// Builds the buttons controlling the previous/next scrolling, etc.
  Widget _buttons(
    BuildContext context,
    PlayerController c,
    BoxConstraints constraints,
  ) {
    final style = Theme.of(context).style;

    final bool hasLabels = constraints.maxWidth > 700;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() {
          return Opacity(
            opacity: c.hasPreviousPage.value ? 1 : 0.5,
            child: WidgetButton(
              onPressed: c.hasPreviousPage.value ? c.previous : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgIcon(SvgIcons.videoPrevious),
                  if (hasLabels) ...[
                    SizedBox(width: 6),
                    Text(
                      'btn_previous'.l10n,
                      style: style.fonts.small.regular.onPrimary,
                    ),
                  ],
                ],
              ),
            ),
          );
        }),

        SizedBox(width: 20),

        Obx(() {
          return Opacity(
            opacity: c.hasNextPage.value ? 1 : 0.5,
            child: WidgetButton(
              onPressed: c.hasNextPage.value ? c.next : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgIcon(SvgIcons.videoNext),
                  if (hasLabels) ...[
                    SizedBox(width: 6),
                    Text(
                      'btn_next'.l10n,
                      style: style.fonts.small.regular.onPrimary,
                    ),
                  ],
                ],
              ),
            ),
          );
        }),

        SizedBox(width: 20),

        Obx(() {
          final Post? post = c.posts.elementAtOrNull(c.index.value);
          final ChatItem? item = post?.item;
          final bool canShare = post != null && item != null && onShare != null;

          return Opacity(
            opacity: canShare ? 1 : 0.5,
            child: WidgetButton(
              onPressed: canShare ? () => onShare?.call(post) : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgIcon(SvgIcons.videoShare),
                  if (hasLabels) ...[
                    SizedBox(width: 6),
                    Text(
                      'btn_share'.l10n,
                      style: style.fonts.small.regular.onPrimary,
                    ),
                  ],
                ],
              ),
            ),
          );
        }),

        SizedBox(width: 20),

        Obx(() {
          final Post? post = c.posts.elementAtOrNull(c.index.value);
          final ChatItem? item = post?.item;
          final bool canReply = post != null && item != null && onReply != null;

          return Opacity(
            opacity: canReply ? 1 : 0.5,
            child: WidgetButton(
              onPressed: canReply
                  ? () {
                      onReply?.call(post);
                      Navigator.of(context).pop();
                    }
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgIcon(SvgIcons.videoReply),
                  if (hasLabels) ...[
                    SizedBox(width: 6),
                    Text(
                      'btn_reply'.l10n,
                      style: style.fonts.small.regular.onPrimary,
                    ),
                  ],
                ],
              ),
            ),
          );
        }),

        SizedBox(width: 20),

        WidgetButton(
          onPressed: c.toggleFullscreen,
          child: SvgIcon(SvgIcons.videoExpand),
        ),
      ],
    );
  }

  /// Builds a side gallery.
  Widget _side(
    BuildContext context,
    PlayerController c,
    BoxConstraints constraints,
  ) {
    final style = Theme.of(context).style;

    final Widget selectedSpacer = Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: SvgIcon(SvgIcons.sentBlue),
    );

    final Widget selectedInverted = Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: SvgIcon(SvgIcons.sentWhite),
    );

    final int photos = c.source.values
        .expand((e) => e.attachments)
        .whereType<ImageAttachment>()
        .length;

    final int videos = c.source.values
        .expand((e) => e.attachments)
        .whereType<FileAttachment>()
        .length;

    return Container(
      height: constraints.maxHeight,
      width: constraints.maxWidth / 5,
      decoration: BoxDecoration(color: Color(0x4B333333)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'btn_gallery'.l10n,
                      style: style.fonts.medium.regular.onPrimary,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'label_media_semicolon_amount'.l10nfmt({
                        'amount': c.posts.length,
                      }),
                      style: style.fonts.small.regular.secondary,
                    ),
                  ],
                ),
              ),
              Obx(() {
                return ContextMenuRegion(
                  actions: [
                    ContextMenuButton(
                      label: 'label_photos_semicolon_amount'.l10nfmt({
                        'amount': photos,
                      }),
                      onPressed: c.includePhotos.toggle,
                      spacer: c.includePhotos.value ? selectedSpacer : null,
                      spacerInverted: c.includePhotos.value
                          ? selectedInverted
                          : null,
                    ),
                    ContextMenuButton(
                      label: 'label_videos_semicolon_amount'.l10nfmt({
                        'amount': videos,
                      }),
                      onPressed: c.includeVideos.toggle,
                      spacer: c.includeVideos.value ? selectedSpacer : null,
                      spacerInverted: c.includeVideos.value
                          ? selectedInverted
                          : null,
                    ),
                  ],
                  enablePrimaryTap: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                    child: SvgIcon(SvgIcons.moreWhite),
                  ),
                );
              }),
            ],
          ),
          Expanded(
            child: Obx(() {
              final Iterable<Widget> medias = c.posts
                  .where((e) {
                    final PostItem? item = e.items.firstOrNull;
                    if (item == null) {
                      return false;
                    }

                    if (item.attachment is ImageAttachment) {
                      return c.includePhotos.value;
                    } else {
                      return c.includeVideos.value;
                    }
                  })
                  .mapIndexed((i, e) {
                    return WidgetButton(
                      onPressed: () {
                        c.vertical.animateToPage(
                          i,
                          duration: Duration(milliseconds: 250),
                          curve: Curves.ease,
                        );
                      },
                      child: Obx(() {
                        final bool selected = c.index.value == i;

                        final PostItem? item = e.items.firstOrNull;
                        if (item == null) {
                          return const SizedBox();
                        }

                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            MediaAttachment(
                              attachment: item.attachment,
                              fit: BoxFit.cover,
                              width: constraints.maxWidth / 5,
                              height: constraints.maxWidth / 5,
                              onError: () async => await c.reload(e),
                            ),
                            if (selected)
                              Container(
                                width: max(
                                  2,
                                  min(constraints.maxWidth / 100, 10),
                                ),
                                height: constraints.maxWidth / 5,
                                decoration: BoxDecoration(
                                  color: style.colors.primary,
                                ),
                              ),
                          ],
                        );
                      }),
                    );
                  });

              if (medias.isEmpty) {
                return Center(
                  child: Text(
                    'label_nothing_found'.l10n,
                    style: style.fonts.small.regular.secondary,
                  ),
                );
              }

              return ScrollablePositionedList.builder(
                key: c.scrollableKey,
                scrollController: c.scrollController,
                itemScrollController: c.itemScrollController,
                itemPositionsListener: c.itemPositionsListener,
                itemCount: medias.length,
                itemBuilder: (_, i) {
                  if (i == -1) {
                    return SizedBox();
                  }

                  return medias.elementAt(i);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Resource ID that [Post]s are coming from in [PlayerView].
class ResourceId {
  const ResourceId({this.chatId});

  /// [ChatId] of the resource.
  final ChatId? chatId;
}

/// Resource that [Post]s are coming from in [PlayerView].
class Resource {
  /// [RxChat] of the resource.
  final Rx<RxChat?> chat = Rx(null);
}
