import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import '../../../../../config.dart';
import '../../../../../domain/repository/chat.dart';
import '../../../../../l10n/l10n.dart';
import '../../../../../routes.dart';
import '../../../../../themes.dart';
import '../../../../../util/platform_utils.dart';
import '../../../../../util/recognizers.dart';
import '../../../../widget/progress_indicator.dart';
import '../../../../widget/selected_dot.dart';
import '../../../../widget/widget_button.dart';
import 'controller.dart';
import 'widget/recent_chat.dart';

class ChatsWidget extends StatelessWidget {
  const ChatsWidget({required this.c, super.key});

  final ChatsTabController c;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final bool isCheck = c.chats.none((e) {
      return (!e.id.isLocal || e.chat.value.isMonolog) &&
          !e.chat.value.isHidden &&
          !e.hidden.value;
    });

    if (isCheck && false) {
      if (c.status.value.isLoadingMore) {
        return Center(
          key: UniqueKey(),
          child: ColoredBox(
            key: const Key('Loading'),
            color: style.colors.almostTransparent,
            child: const CustomProgressIndicator(),
          ),
        );
      }

      return KeyedSubtree(
        key: UniqueKey(),
        child: Center(
          key: const Key('NoChats'),
          child: Text('label_no_chats'.l10n),
        ),
      );
    }

    return Obx(() {
          final List<RxChat> calls = [];
          final List<RxChat> favorites = [];
          final List<RxChat> chats = [];

          for (var e in c.chats) {
            if ((!e.id.isLocal ||
                e.messages.isNotEmpty ||
                e.chat.value.isMonolog) &&
                !e.chat.value.isHidden &&
                !e.hidden.value) {
              if (e.chat.value.ongoingCall != null) {
                calls.add(e.rx);
              }

              if (e.chat.value.favoritePosition !=
                  null) {
                favorites.add(e.rx);
              }

              chats.add(e.rx);
            }
          }

          // Builds a [RecentChatTile] from the provided
          // [RxChat].
          Widget tile(RxChat e, {
            Widget Function(Widget)? avatarBuilder,
          }) {
            final bool selected = c.selectedChats.contains(
              e.id,
            );

            return RecentChatTile(
              e,
              key: e.chat.value.isMonolog
                  ? const Key('ChatMonolog')
                  : Key('RecentChat_${e.id}'),
              me: c.me,
              blocked: e.blocked,
              selected: c.selecting.value ? selected : null,
              getUser: c.getUser,
              avatarBuilder: c.selecting.value
                  ? (child) =>
                  WidgetButton(
                    onPressed: () =>
                        router.dialog(e.chat.value, c.me),
                    child: child,
                  )
                  : avatarBuilder,
              onJoin: () => c.joinCall(e.id),
              onDrop: () => c.dropCall(e.id),
              onLeave: e.chat.value.isMonolog
                  ? null
                  : () => c.leaveChat(e.id),
              onHide: () => c.hideChat(e.id),
              onMute:
              e.chat.value.isMonolog ||
                  e.chat.value.id.isLocal
                  ? null
                  : () => c.muteChat(e.id),
              onUnmute:
              e.chat.value.isMonolog ||
                  e.chat.value.id.isLocal
                  ? null
                  : () => c.unmuteChat(e.id),
              onFavorite:
              e.chat.value.id.isLocal &&
                  !e.chat.value.isMonolog
                  ? null
                  : () => c.favoriteChat(e.id),
              onUnfavorite:
              e.chat.value.id.isLocal &&
                  !e.chat.value.isMonolog
                  ? null
                  : () => c.unfavoriteChat(e.id),
              onSelect: c.toggleSelecting,

              // TODO: Uncomment, when contacts are implemented.
              // onContact: (b) => b
              //     ? c.addToContacts(e)
              //     : c.removeFromContacts(e),
              // inContacts: e.chat.value.isDialog
              //     ? () => c.inContacts(e)
              //     : null,
              onTap: c.selecting.value
                  ? () => c.selectChat(e)
                  : null,
              onDismissed: () => c.dismiss(e),
              enableContextMenu: !c.selecting.value,
              trailing: c.selecting.value
                  ? [
                SelectedDot(
                  selected: selected,
                  size: 20,
                ),
              ]
                  : null,
              hasCall: c.status.value.isLoadingMore
                  ? false
                  : null,
              onPerformDrop: (f) => c.sendFiles(e.id, f),
            );
          }

          return SliverPadding(
            padding: EdgeInsets.only(
              bottom: 4,
              left: 10,
              right: 10,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                ...chats.mapIndexed((i, e) {
                  return AnimationConfiguration.staggeredList(
                    position:
                    calls.length +
                        favorites.length +
                        i,
                    duration: const Duration(
                      milliseconds: 375,
                    ),
                    child: SlideAnimation(
                      horizontalOffset: 50,
                      child: FadeInAnimation(
                        child: tile(e),
                      ),
                    ),
                  );
                }),
                if (c.hasNext.isTrue ||
                    c.status.value.isLoadingMore)
                  Center(
                    child: CustomProgressIndicator(
                      key: const Key('ChatsLoading'),
                      value:
                      Config.disableInfiniteAnimations
                          ? 0
                          : null,
                    ),
                  ),
              ]),
            ),
          );

          return CustomScrollView(
            controller: c.scrollController,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(
                  top: 4,
                  left: 10,
                  right: 10,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed(
                    calls.mapIndexed((i, e) {
                      return AnimationConfiguration.staggeredList(
                        position: i,
                        duration: const Duration(
                          milliseconds: 375,
                        ),
                        child: SlideAnimation(
                          horizontalOffset: 50,
                          child: FadeInAnimation(
                            child: tile(e),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(
                  left: 10,
                  right: 10,
                ),
                sliver: SliverReorderableList(
                  onReorderStart: (_) =>
                  c.reordering.value = true,
                  proxyDecorator: (child, _, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (_, Widget? child) {
                        final double t = Curves.easeInOut
                            .transform(animation.value);
                        final double elevation = lerpDouble(
                          0,
                          6,
                          t,
                        )!;
                        final Color color = Color.lerp(
                          style.colors.transparent,
                          style.colors.onBackgroundOpacity20,
                          t,
                        )!;

                        return Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              CustomBoxShadow(
                                color: color,
                                blurRadius: elevation,
                              ),
                            ],
                            borderRadius: style.cardRadius
                                .copyWith(
                              topLeft: Radius.circular(
                                style
                                    .cardRadius
                                    .topLeft
                                    .x *
                                    1.75,
                              ),
                            ),
                          ),
                          child: child,
                        );
                      },
                      child: child,
                    );
                  },
                  itemBuilder: (_, i) {
                    final RxChat chat = favorites[i];

                    return KeyedSubtree(
                      key: Key(chat.id.val),
                      child: Obx(() {
                        final Widget child = tile(
                          chat,
                          avatarBuilder: (child) {
                            if (PlatformUtils.isMobile) {
                              return ReorderableDelayedDragStartListener(
                                key: Key(
                                  'ReorderHandle_${chat.id.val}',
                                ),
                                index: i,
                                child: child,
                              );
                            }

                            return RawGestureDetector(
                              gestures: {
                                DisableSecondaryButtonRecognizer:
                                GestureRecognizerFactoryWithHandlers<
                                    DisableSecondaryButtonRecognizer
                                >(
                                      () =>
                                      DisableSecondaryButtonRecognizer(),
                                      (_) {},
                                ),
                              },
                              child: ReorderableDragStartListener(
                                key: Key(
                                  'ReorderHandle_${chat.id.val}',
                                ),
                                index: i,
                                child: GestureDetector(
                                  onLongPress: () {},
                                  child: child,
                                ),
                              ),
                            );
                          },
                        );

                        // Ignore the animation, if there's
                        // an ongoing reordering happening.
                        if (c.reordering.value) {
                          return child;
                        }

                        return AnimationConfiguration.staggeredList(
                          position: calls.length + i,
                          duration: const Duration(
                            milliseconds: 375,
                          ),
                          child: SlideAnimation(
                            horizontalOffset: 50,
                            child: FadeInAnimation(
                              child: child,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                  itemCount: favorites.length,
                  onReorder: (a, b) {
                    c.reorderChat(a, b);
                    c.reordering.value = false;
                  },
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: 4,
                  left: 10,
                  right: 10,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    ...chats.mapIndexed((i, e) {
                      return AnimationConfiguration.staggeredList(
                        position:
                        calls.length +
                            favorites.length +
                            i,
                        duration: const Duration(
                          milliseconds: 375,
                        ),
                        child: SlideAnimation(
                          horizontalOffset: 50,
                          child: FadeInAnimation(
                            child: tile(e),
                          ),
                        ),
                      );
                    }),
                    if (c.hasNext.isTrue ||
                        c.status.value.isLoadingMore)
                      Center(
                        child: CustomProgressIndicator(
                          key: const Key('ChatsLoading'),
                          value:
                          Config.disableInfiniteAnimations
                              ? 0
                              : null,
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          );
        });
  }
}
