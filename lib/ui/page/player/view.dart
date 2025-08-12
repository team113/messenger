// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import '/domain/model/user.dart';
import '/domain/repository/paginated.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/fit_wrap.dart';
import '/ui/page/home/page/chat/widget/media_attachment.dart';
import '/ui/page/home/page/chat/widget/video/widget/centered_play_pause.dart';
import '/ui/page/home/page/chat/widget/video/widget/custom_play_pause.dart';
import '/ui/page/home/page/chat/widget/video/widget/position.dart';
import '/ui/page/home/page/chat/widget/video/widget/video_progress_bar.dart';
import '/ui/page/home/page/chat/widget/video/widget/video_volume_bar.dart'
    show ProgressBarColors, VideoVolumeBar;
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
import 'controller.dart';
import 'widget/video_playback.dart';

class PlayerView extends StatelessWidget {
  const PlayerView({
    super.key,
    required this.source,
    this.initialKey,
    this.initialIndex = 0,
    this.onReply,
    this.onShare,
    this.onReact,
  });

  final Paginated<String, MediaItem> source;
  final String? initialKey;
  final int initialIndex;
  final void Function(MediaItem)? onReply;
  final void Function(MediaItem)? onShare;
  final void Function(MediaItem, String)? onReact;

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget gallery,
  }) async {
    final ModalRoute<T> route;

    if (context.isMobile) {
      final style = Theme.of(context).style;

      route = MaterialPageRoute<T>(
        builder: (BuildContext context) {
          return Material(
            type: MaterialType.canvas,
            color: style.colors.onBackground,
            child: Scaffold(
              backgroundColor: style.colors.onBackground,
              body: CustomSafeArea(child: gallery),
            ),
          );
        },
      );
    } else {
      route = RawDialogRoute<T>(
        barrierColor: Color(0xF20C0C0C),
        barrierDismissible: true,
        pageBuilder: (_, __, ___) {
          return CustomSafeArea(
            child: Material(type: MaterialType.transparency, child: gallery),
          );
        },
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (_, Animation<double> animation, __, Widget child) {
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
                  _content(context, c),
                  _interface(context, c, constraints),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, PlayerController c) {
    return Obx(() {
      return PageView(
        physics: c.viewportIsTransformed.value
            ? NeverScrollableScrollPhysics()
            : null,
        controller: c.vertical,
        scrollDirection: Axis.vertical,
        children: [...c.posts.map((e) => _post(context, c, e))],
      );
    });
  }

  Widget _post(BuildContext context, PlayerController c, Post post) {
    return PageView(
      physics: c.viewportIsTransformed.value
          ? NeverScrollableScrollPhysics()
          : null,
      controller: post.horizontal,
      children: [...post.items.map((e) => _attachment(context, c, post, e))],
    );
  }

  Widget _attachment(
    BuildContext context,
    PlayerController c,
    Post post,
    PostItem item,
  ) {
    final Attachment attachment = item.attachment;

    if (attachment is ImageAttachment) {
      return InteractiveViewer(
        transformationController: c.transformationController,
        onInteractionStart: (_) {
          c.viewportIsTransformed.value = true;
        },
        onInteractionEnd: (e) {
          c.viewportIsTransformed.value =
              c.transformationController.value.forward.z > 1;
        },
        child: Center(
          child: RetryImage(
            attachment.original.url,
            width: double.infinity,
            height: double.infinity,
            checksum: attachment.original.checksum,
            fit: BoxFit.contain,
            onForbidden: () async => await c.reload(post),
          ),
        ),
      );
    } else if (attachment is FileAttachment) {
      if (attachment.isVideo) {
        return VideoPlayback(
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

    return Center(child: Text('Unsupported'));
  }

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
            if (!c.interface.value) {
              return SizedBox();
            }

            return _bottom(context, c, constraints);
          }),
        ),

        Align(
          alignment: Alignment.topCenter,
          child: Obx(() {
            if (!c.interface.value) {
              return SizedBox();
            }

            return _top(context, c, constraints);
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
                onEnd: () => c.displaySide.value = c.side.value,
                child: _side(context, c, constraints),
              );
            }),
          ),
        ),
      ],
    );
  }

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
          // Closes the video on a tap outside [AspectRatio].
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: c.playPause,
            onDoubleTap: c.toggleFullscreen,
            onLongPress: () => c.interface.value = false,

            // Required for the [GestureDetector]s to take the full
            // width and height.
            child: const SizedBox(
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          if (video != null) ...[
            // Play/pause button.
            MouseRegion(
              hitTestBehavior: HitTestBehavior.translucent,
              cursor: SystemMouseCursors.click,
              child: Obx(() {
                if (video.isBuffering.value) {
                  return const Center(child: CustomProgressIndicator());
                }

                return CenteredPlayPause(
                  show: c.interface.value && !video.isPlaying.value,
                  isCompleted: video.isCompleted.value,
                  isPlaying: video.isPlaying.value,
                  onPressed: c.playPause,
                );
              }),
            ),

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

  Widget _top(
    BuildContext context,
    PlayerController c,
    BoxConstraints constraints,
  ) {
    final style = Theme.of(context).style;
    final bool isMobile = context.isMobile;

    return Container(
      height: 60,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Color(0x4B333333)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          WidgetButton(
            onPressed: Navigator.of(context).pop,
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
          if (!isMobile) ...[
            Opacity(
              opacity: PlatformUtils.isWeb && !PlatformUtils.isMobile ? 1 : 0.5,
              child: WidgetButton(
                onPressed: PlatformUtils.isWeb && !PlatformUtils.isMobile
                    ? c.openPopup
                    : null,
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
                  ? () {
                      c.displaySide.value = true;
                      c.side.toggle();

                      if (isMobile) {
                        final ReactivePlayerController? video =
                            c.item?.video.value;
                        video?.pause();
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
          ContextMenuRegion(
            actions: [
              ContextMenuButton(label: 'Find in chat', onPressed: () {}),
              ContextMenuButton(
                label: 'btn_save'.l10n,
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
              ContextMenuButton(
                label: 'Hide interface',
                onPressed: c.interface.toggle,
              ),
            ],
            enablePrimaryTap: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: SvgIcon(SvgIcons.moreWhite),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _bottom(
    BuildContext context,
    PlayerController c,
    BoxConstraints constraints,
  ) {
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
              padding: const EdgeInsets.fromLTRB(0, 0, 16, 57 + 16),
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
              bottom: 44,
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

  Widget _description(BuildContext context, PlayerController c) {
    final style = Theme.of(context).style;

    return Obx(() {
      final MediaItem? item = c.source.items[c.key.value];
      final ChatItem? message = item?.item;

      if (message == null) {
        return SizedBox();
      }

      final User user = message.author;
      final String? text = message is ChatMessage ? message.text?.val : null;

      return WidgetButton(
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
                              user.online && user.presence == Presence.present,
                          isAway: user.online && user.presence == Presence.away,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.title,
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
                                      style:
                                          style.fonts.normal.regular.onPrimary,
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
      );
    });
  }

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

  Widget _bar(
    BuildContext context,
    PlayerController c,
    BoxConstraints constraints,
  ) {
    final bool isMobile = context.isMobile;

    return AnimatedContainer(
      duration: Duration(milliseconds: 250),
      padding: const EdgeInsets.all(5),
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
              child: Opacity(opacity: 0, child: _description(context, c)),
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
            // _cancelAndRestartTimer();
            if (controller.volume.value == 0) {
              controller.setVolume(c.latestVolume ?? 0.5);
            } else {
              c.latestVolume = controller.volume.value;
              controller.setVolume(0.0);
            }
          },
          child: SvgIcon(SvgIcons.volume),
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

  Widget _mobileBar(
    BuildContext context,
    PlayerController c,
    BoxConstraints constraints,
  ) {
    return Obx(() {
      final Post? post = c.post;
      final ChatItemId? itemId = post?.itemId;
      final ReactivePlayerController? video = c.item?.video.value;

      final bool canReact = itemId != null && onReact != null;
      final bool canReply = itemId != null && onReply != null;
      final bool canShare = itemId != null && onShare != null;

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
              child: SvgIcon(SvgIcons.volume),
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
                      // onReply?.call(itemId);
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
                      // onShare?.call(item);
                    }
                  : null,
              child: SvgIcon(SvgIcons.videoShare),
            ),
          ),
        ],
      );
    });
  }

  Widget _buttons(
    BuildContext context,
    PlayerController c,
    BoxConstraints constraints,
  ) {
    final style = Theme.of(context).style;

    final bool hasLabels = constraints.maxWidth > 700;
    final MediaItem? item = c.source.items[c.key.value];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: c.hasPreviousPage ? 1 : 0.5,
          child: WidgetButton(
            onPressed: c.hasPreviousPage ? c.previous : null,
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
        ),

        SizedBox(width: 20),

        Opacity(
          opacity: c.hasNextPage ? 1 : 0.5,
          child: WidgetButton(
            onPressed: c.hasNextPage ? c.next : null,
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
        ),

        SizedBox(width: 20),

        Opacity(
          opacity: item != null && onShare != null ? 1 : 0.5,
          child: WidgetButton(
            onPressed: item != null && onShare != null
                ? () => onShare?.call(item)
                : null,
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
        ),

        SizedBox(width: 20),

        Opacity(
          opacity: item != null && onReply != null ? 1 : 0.5,
          child: WidgetButton(
            onPressed: item != null && onReply != null
                ? () {
                    onReply?.call(item);
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
        ),

        SizedBox(width: 20),

        WidgetButton(
          onPressed: c.toggleFullscreen,
          child: SvgIcon(SvgIcons.videoExpand),
        ),
      ],
    );
  }

  Widget _side(
    BuildContext context,
    PlayerController c,
    BoxConstraints constraints,
  ) {
    final style = Theme.of(context).style;
    final bool isMobile = context.isMobile;

    final width = isMobile ? constraints.maxWidth : constraints.maxWidth / 5;

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
      width: width,
      decoration: BoxDecoration(
        color: isMobile ? style.colors.background : Color(0x4B333333),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
            child: Row(
              children: [
                if (isMobile) ...[
                  WidgetButton(
                    onPressed: () => c.side.value = false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 18, 16, 18),
                      child: Row(children: [SvgIcon(SvgIcons.back)]),
                    ),
                  ),
                  AvatarWidget(radius: AvatarRadius.medium),
                  SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isMobile) ...[
                        Text(
                          'tester',
                          style: style.fonts.medium.regular.onBackground,
                        ),
                      ] else ...[
                        Text(
                          'Gallery',
                          style: style.fonts.medium.regular.onPrimary,
                        ),
                      ],
                      SizedBox(height: 2),
                      Text(
                        'Media: ${c.source.length}',
                        style: style.fonts.small.regular.secondary,
                      ),
                    ],
                  ),
                ),
                ContextMenuRegion(
                  actions: [
                    ContextMenuButton(
                      label: 'Photos: $photos',
                      onPressed: () {},
                      spacer: selectedSpacer,
                      spacerInverted: selectedInverted,
                    ),
                    ContextMenuButton(
                      label: 'Videos: $videos',
                      onPressed: () {},
                      spacer: selectedSpacer,
                      spacerInverted: selectedInverted,
                    ),
                    ContextMenuButton(
                      label: 'Clips: $videos',
                      onPressed: c.interface.toggle,
                      spacer: selectedSpacer,
                      spacerInverted: selectedInverted,
                    ),
                  ],
                  enablePrimaryTap: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    child: isMobile
                        ? SvgIcon(SvgIcons.more)
                        : SvgIcon(SvgIcons.moreWhite),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Obx(() {
              final medias = c.posts.mapIndexed((i, e) {
                return WidgetButton(
                  onPressed: () {
                    if (isMobile) {
                      c.side.value = false;
                    }

                    c.vertical.animateToPage(
                      i,
                      duration: Duration(milliseconds: 250),
                      curve: Curves.ease,
                    );
                  },
                  child: Obx(() {
                    final selected = c.index.value == i;

                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        MediaAttachment(
                          attachment: e.items.first.attachment,
                          fit: BoxFit.cover,
                          width: isMobile
                              ? constraints.maxWidth
                              : constraints.maxWidth / 5,
                          height: isMobile
                              ? constraints.maxWidth
                              : constraints.maxWidth / 5,
                          onError: () async => await c.reload(e),
                        ),
                        if (!isMobile && selected)
                          Container(
                            width: max(2, min(constraints.maxWidth / 100, 10)),
                            height: isMobile ? null : constraints.maxWidth / 5,
                            decoration: BoxDecoration(
                              color: style.colors.primary,
                            ),
                          ),
                      ],
                    );
                  }),
                );
              });

              if (isMobile) {
                return FitWrap(
                  maxSize: constraints.maxWidth / 3,
                  spacing: 2,
                  alignment: WrapAlignment.start,
                  children: medias.toList(),
                );
              }

              return ScrollablePositionedList.builder(
                key: c.scrollableKey,
                scrollController: c.scrollController,
                itemScrollController: c.itemScrollController,
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

class MediaAuthor {
  MediaAuthor({required this.builder});

  factory MediaAuthor.fromRxUser(RxUser user) {
    return MediaAuthor(
      builder: (_) {
        return Obx(() {
          return Row(
            children: [
              AvatarWidget.fromRxUser(user, radius: AvatarRadius.small),
              Text(user.title),
            ],
          );
        });
      },
    );
  }

  factory MediaAuthor.fromUser(User user) {
    return MediaAuthor(
      builder: (_) {
        return Row(
          children: [
            AvatarWidget.fromUser(
              user,
              radius: AvatarRadius.small,
              isOnline: user.online && user.presence == Presence.present,
              isAway: user.online && user.presence == Presence.away,
            ),
            SizedBox(width: 8),
            Text(user.title),
          ],
        );
      },
    );
  }

  final Widget Function(BuildContext context) builder;
}
