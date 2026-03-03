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

import 'dart:ui';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';

import '/config.dart';
import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/bottom_padded_row.dart';
import '/ui/widget/allow_overflow.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animated_delayed_switcher.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/selected_dot.dart';
import '/ui/widget/selected_tile.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import '/util/recognizers.dart';
import 'controller.dart';
import 'widget/recent_chat.dart';
import 'widget/search_user_tile.dart';

/// View of the [HomeTab.chats] tab.
class ChatsTabView extends StatelessWidget {
  const ChatsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      key: const Key('ChatsTab'),
      init: ChatsTabController(
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
      builder: (ChatsTabController c) {
        return Stack(
          children: [
            Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: CustomAppBar(
                title: _title(context, c),
                actions: [_more(context, c)],
              ),
              body: SlidableAutoCloseBehavior(
                child: ContextMenuInterceptor(child: _body(context, c)),
              ),
            ),
            Obx(() {
              if (c.creatingStatus.value.isLoading) {
                return SafeAnimatedSwitcher(
                  duration: 200.milliseconds,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: style.colors.onBackgroundOpacity20,
                    child: const Center(child: CustomProgressIndicator()),
                  ),
                );
              }

              return const SizedBox();
            }),
          ],
        );
      },
    );
  }

  /// Builds a [BottomPaddedRow] for selecting the [Chat]s.
  static Widget selectingBuilder(BuildContext context, ChatsTabController c) {
    final style = Theme.of(context).style;

    return BottomPaddedRow(
      spacer: (_) {
        return Container(
          decoration: BoxDecoration(color: style.colors.onBackgroundOpacity13),
          width: 1,
          height: 24,
        );
      },
      children: [
        WidgetButton(
          onPressed: c.readAll,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6.5, 10, 6.5),
              child: Text(
                'btn_read_all'.l10n,
                style: style.fonts.normal.regular.primary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        WidgetButton(
          onPressed: c.selectedChats.isEmpty
              ? null
              : () => _archiveChats(context, c),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6.5, 10, 6.5),
              child: Text(
                c.archivedOnly.value ? 'btn_unhide'.l10n : 'btn_hide'.l10n,
                style: style.fonts.normal.regular.primary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        WidgetButton(
          key: const Key('DeleteChatsButton'),
          onPressed: c.selectedChats.isEmpty
              ? null
              : () => _hideChats(context, c),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6.5, 10, 6.5),
              child: Text(
                'btn_delete'.l10n,
                style: style.fonts.normal.regular.danger,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a [BottomPaddedRow] for creating a [Chat]-group.
  static Widget createGroupBuilder(BuildContext context, ChatsTabController c) {
    final style = Theme.of(context).style;

    return BottomPaddedRow(
      spacer: (_) {
        return Container(
          decoration: BoxDecoration(color: style.colors.onBackgroundOpacity13),
          width: 1,
          height: 24,
        );
      },
      children: [
        WidgetButton(
          onPressed: c.closeGroupCreating,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6.5, 10, 6.5),
              child: Text(
                'btn_cancel'.l10n,
                style: style.fonts.normal.regular.primary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        WidgetButton(
          onPressed: c.creatingStatus.value.isEmpty ? c.createGroup : null,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6.5, 10, 6.5),
              child: Text(
                'btn_create'.l10n,
                style: style.fonts.normal.regular.primary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Returns a title to build in an [AppBar].
  Widget _title(BuildContext context, ChatsTabController c) {
    return Obx(() {
      final Widget label;
      final bool padded;

      if (c.groupCreating.value) {
        padded = false;
        label = Padding(
          key: Key('CreateGroup'),
          padding: const EdgeInsets.only(left: 22),
          child: Text('label_create_group'.l10n),
        );
      } else if (c.selecting.value) {
        padded = false;
        label = Padding(
          key: Key('SelectChats'),
          padding: const EdgeInsets.only(left: 22),
          child: Text(
            'label_selected'.l10nfmt({'count': c.selectedChats.length}),
          ),
        );
      } else if (c.archivedOnly.value) {
        padded = c.synchronizing;

        label = Row(
          key: Key('ArchivedChats'),
          children: [
            WidgetButton(
              onPressed: c.toggleArchive,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  padded ? 0 : 16,
                  18,
                  padded ? 0 : 16,
                ),
                child: SvgIcon(SvgIcons.back),
              ),
            ),
            Expanded(child: Text('label_hidden_chats'.l10n)),
          ],
        );
      } else {
        padded = false;
        label = Padding(
          key: Key('Chats'),
          padding: const EdgeInsets.only(left: 22),
          child: Text('label_chats'.l10n),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AnimatedSizeAndFade(
              sizeDuration: const Duration(milliseconds: 300),
              fadeDuration: const Duration(milliseconds: 300),
              alignment: Alignment.centerLeft,
              child: label,
            ),
          ),
          AnimatedPadding(
            duration: Duration(milliseconds: 250),
            padding: padded ? EdgeInsets.only(left: 22) : EdgeInsets.zero,
            child: _synchronization(context, c),
          ),
        ],
      );
    });
  }

  /// Returns a `More` action button to build in [_appBar].
  Widget _more(BuildContext context, ChatsTabController c) {
    return Obx(() {
      final Widget moreButton = ContextMenuRegion(
        key: const Key('ChatsMenu'),
        selector: c.moreKey,
        alignment: Alignment.topRight,
        enablePrimaryTap: true,
        enableSecondaryTap: false,
        enableLongTap: false,
        margin: const EdgeInsets.only(bottom: 4, right: 0),
        actions: [
          ContextMenuButton(
            key: const Key('SelectChatsButton'),
            label: 'btn_select'.l10n,
            onPressed: c.toggleSelecting,
            trailing: const SvgIcon(SvgIcons.select),
            inverted: const SvgIcon(SvgIcons.selectWhite),
          ),
          if (!c.isSupport)
            ContextMenuButton(
              key: const Key('CreateGroupButton'),
              label: 'btn_create_group'.l10n,
              onPressed: c.startGroupCreating,
              trailing: const SvgIcon(SvgIcons.group),
              inverted: const SvgIcon(SvgIcons.groupWhite),
            ),
          ContextMenuDivider(),
          ContextMenuButton(
            key: const Key('ArchiveChatsButton'),
            label: 'btn_hidden_chats'.l10n,
            onPressed: c.toggleArchive,
            trailing: const SvgIcon(SvgIcons.visibleOff),
            inverted: const SvgIcon(SvgIcons.visibleOffWhite),
            spacer: c.archivedOnly.value
                ? Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: const SvgIcon(SvgIcons.sentBlue),
                  )
                : null,
            spacerInverted: c.archivedOnly.value
                ? Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: const SvgIcon(SvgIcons.sentWhite),
                  )
                : null,
          ),
          if (!c.isSupport) ...[
            ContextMenuDivider(),
            ContextMenuButton(
              key: const Key('MonologChatButton'),
              label: 'label_chat_monolog'.l10n,
              onPressed: () => router.chat(c.monolog),
              trailing: const SvgIcon(SvgIcons.notesSmall),
              inverted: const SvgIcon(SvgIcons.notesSmallWhite),
            ),
          ],
        ],
        child: AnimatedButton(
          decorator: (child) {
            return Container(
              key: c.moreKey,
              padding: const EdgeInsets.only(left: 12, right: 18),
              height: double.infinity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: child,
              ),
            );
          },
          child: const SvgIcon(SvgIcons.more),
        ),
      );

      final Widget closeButton = AnimatedButton(
        key: const Key('CloseSelectingButton'),
        onPressed: () {
          if (c.selecting.value) {
            c.toggleSelecting();
          } else if (c.groupCreating.value) {
            c.closeGroupCreating();
          }
        },
        decorator: (child) {
          return Container(
            padding: const EdgeInsets.only(left: 9, right: 16),
            height: double.infinity,
            child: child,
          );
        },
        child: SizedBox(
          width: 29.17,
          child: SafeAnimatedSwitcher(
            duration: 250.milliseconds,
            child: const SvgIcon(
              SvgIcons.closePrimary,
              key: Key('CloseSearch'),
            ),
          ),
        ),
      );

      return Row(
        children: [
          if (c.selecting.value || c.groupCreating.value)
            closeButton
          else
            moreButton,
        ],
      );
    });
  }

  /// Returns a [Text] indicating that synchronization is happening.
  Widget _synchronization(BuildContext context, ChatsTabController c) {
    final style = Theme.of(context).style;

    return Obx(() {
      final Widget synchronization;

      if (!c.connected.value) {
        synchronization = Padding(
          padding: const EdgeInsets.only(left: 22, top: 2),
          child: Center(
            child: Text(
              'label_waiting_for_connection'.l10n,
              style: style.fonts.small.regular.secondary,
              key: const Key('NotConnected'),
            ),
          ),
        );
      } else if (c.fetching.value == null && c.status.value.isLoadingMore) {
        synchronization = Padding(
          padding: const EdgeInsets.only(left: 22, top: 2),
          child: Center(
            child: Text(
              'label_synchronization'.l10n,
              style: style.fonts.small.regular.secondary,
              key: const Key('Synchronization'),
            ),
          ),
        );
      } else {
        synchronization = const SizedBox.shrink(key: Key('Connected'));
      }

      return SafeAnimatedSwitcher(
        duration: 250.milliseconds,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AllowOverflow(
            child: AnimatedSizeAndFade(
              sizeDuration: const Duration(milliseconds: 300),
              fadeDuration: const Duration(milliseconds: 300),
              child: synchronization,
            ),
          ),
        ),
      );
    });
  }

  /// Returns the body of this tab.
  Widget _body(BuildContext context, ChatsTabController c) {
    final style = Theme.of(context).style;

    return Obx(() {
      List<Widget>? slivers;

      if (c.status.value.isLoading) {
        slivers = [
          SliverFillRemaining(
            child: Center(child: CustomProgressIndicator.primary()),
          ),
        ];
      }
      // Group creating.
      else if (c.groupCreating.isTrue) {
        final RxStatus status = c.search.searchStatus.value;

        if (c.search.query.isNotEmpty &&
            c.search.recent.isEmpty &&
            c.search.contacts.isEmpty &&
            c.search.users.isEmpty) {
          if (status.isSuccess && !status.isLoadingMore) {
            slivers = [SliverFillRemaining(child: _notFound(context))];
          }

          slivers ??= [
            SliverFillRemaining(
              child: Center(
                key: UniqueKey(),
                child: ColoredBox(
                  color: style.colors.almostTransparent,
                  child: const CustomProgressIndicator(),
                ),
              ),
            ),
          ];
        }

        slivers ??= [
          SliverList.builder(
            itemCount: c.elements.length,
            itemBuilder: (_, i) {
              final ListElement element = c.elements[i];
              Widget child;

              if (element is RecentElement) {
                child = Obx(() {
                  return SelectedTile(
                    user: element.user,
                    selected: c.search.selectedRecent.contains(element.user),
                    onTap: () => c.search.select(recent: element.user),
                  );
                });
              } else if (element is ContactElement) {
                child = Obx(() {
                  return SelectedTile(
                    contact: element.contact,
                    selected: c.search.selectedContacts.contains(
                      element.contact,
                    ),
                    onTap: () => c.search.select(contact: element.contact),
                  );
                });
              } else if (element is UserElement) {
                child = Obx(() {
                  return SelectedTile(
                    user: element.user,
                    selected: c.search.selectedUsers.contains(element.user),
                    onTap: () => c.search.select(user: element.user),
                  );
                });
              } else if (element is MyUserElement) {
                child = Obx(() {
                  return SelectedTile(
                    myUser: c.myUser.value,
                    selected: true,
                    subtitle: [
                      const SizedBox(height: 5),
                      Text(
                        'label_you'.l10n,
                        style: style.fonts.small.regular.onPrimary,
                      ),
                    ],
                  );
                });
              } else if (element is DividerElement) {
                child = Container(
                  margin: EdgeInsets.fromLTRB(10, i == 0 ? 0 : 8, 8, 3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  width: double.infinity,
                  child: Text(
                    element.category.l10n,
                    style: style.fonts.medium.regular.onBackground,
                  ),
                );
              } else {
                child = const SizedBox();
              }

              if (i == c.elements.length - 1 &&
                  (status.isLoadingMore || status.isLoading)) {
                child = Column(
                  children: [child, const CustomProgressIndicator()],
                );
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: child,
              );
            },
          ),
        ];
      }
      // Search results.
      else if (!c.search.search.isEmpty.value) {
        final RxStatus status = c.search.searchStatus.value;
        final bool isLoading = status.isLoading || status.isLoadingMore;

        if (c.elements.isEmpty) {
          if (!isLoading) {
            slivers = [SliverFillRemaining(child: _notFound(context))];
          }

          slivers ??= [
            SliverFillRemaining(
              key: UniqueKey(),
              child: Center(
                child: ColoredBox(
                  key: const Key('Loading'),
                  color: style.colors.almostTransparent,
                  child: const CustomProgressIndicator(),
                ),
              ),
            ),
          ];
        }

        slivers ??= [
          SliverList.builder(
            itemCount: c.elements.length,
            itemBuilder: (_, i) {
              final ListElement element = c.elements[i];
              Widget child;

              if (element is ChatElement) {
                final RxChat chat = element.chat;
                child = Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Obx(() {
                    return RecentChatTile(
                      chat,
                      key: Key('SearchChat_${chat.id}'),
                      me: c.me,
                      blocked: chat.blocked,
                      getUser: c.getUser,
                      onJoin: () => c.joinCall(chat.id),
                      onDrop: () => c.dropCall(chat.id),
                      hasCall: c.status.value.isLoadingMore ? false : null,
                      onPerformDrop: (e) => c.sendFiles(chat.id, e),
                    );
                  }),
                );
              } else if (element is ContactElement) {
                child = SearchUserTile(
                  key: Key('SearchContact_${element.contact.id}'),
                  contact: element.contact,
                  onTap: () => c.openChat(contact: element.contact),
                );
              } else if (element is UserElement) {
                child = SearchUserTile(
                  key: Key('SearchUser_${element.user.id}'),
                  user: element.user,
                  onTap: () => c.openChat(user: element.user),
                );
              } else if (element is DividerElement) {
                child = Container(
                  margin: EdgeInsets.fromLTRB(10, i == 0 ? 0 : 8, 8, 3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  width: double.infinity,
                  child: Text(
                    element.category.l10n,
                    style: style.fonts.medium.regular.onBackground,
                  ),
                );
              } else {
                child = const SizedBox();
              }

              if (i == c.elements.length - 1) {
                if (isLoading) {
                  child = Column(
                    children: [
                      child,
                      const CustomProgressIndicator(key: Key('SearchLoading')),
                    ],
                  );
                }
              }

              return Padding(
                padding: EdgeInsets.only(
                  top: i == 0 ? 4 : 0,
                  bottom: i == c.elements.length - 1 ? 4 : 0,
                ),
                child: child,
              );
            },
          ),
        ];
      }
      // Archive.
      else if (c.archivedOnly.value) {
        final List<RxChat> chats = [];

        for (ChatEntry e in c.archived) {
          final bool notLocalOrHasMessages =
              !e.id.isLocal ||
              e.messages.isNotEmpty ||
              e.chat.value.isMonolog ||
              e.chat.value.isSupport;

          if (notLocalOrHasMessages &&
              !e.chat.value.isHidden &&
              e.chat.value.isArchived) {
            chats.add(e.rx);
          }
        }

        if (chats.isEmpty) {
          if (c.status.value.isLoadingMore) {
            slivers = [
              SliverFillRemaining(
                child: Center(
                  key: UniqueKey(),
                  child: ColoredBox(
                    key: const Key('Loading'),
                    color: style.colors.almostTransparent,
                    child: const CustomProgressIndicator(),
                  ),
                ),
              ),
            ];
          }

          slivers ??= [
            SliverFillRemaining(
              key: UniqueKey(),
              child: Padding(
                key: const Key('NoChats'),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SvgIcon(SvgIcons.notFound),
                    const SizedBox(height: 16),
                    Text(
                      'label_no_chats'.l10n,
                      style: style.fonts.medium.regular.secondary,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ];
        }

        slivers ??= [
          SliverList.builder(
            itemCount: chats.length,
            itemBuilder: (_, i) {
              final RxChat chat = chats[i];

              Widget child = Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: _tile(c, chat),
              );

              if (i == chats.length - 1) {
                child = Column(
                  children: [
                    child,
                    if (c.archive.hasNext.isTrue || c.archive.nextLoading.value)
                      const CustomProgressIndicator(key: Key('ArchiveLoading')),
                  ],
                );
              }

              return Padding(
                padding: EdgeInsets.only(
                  top: i == 0 ? 4 : 0,
                  bottom: i == chats.length - 1 ? 4 : 0,
                ),
                child: child,
              );
            },
          ),
        ];
      }
      // Chats.
      else {
        final List<RxChat> calls = [];
        final List<RxChat> favorites = [];
        final List<RxChat> chats = [];

        for (ChatEntry e in c.chats) {
          final bool notLocalOrHasMessages =
              !e.id.isLocal ||
              e.messages.isNotEmpty ||
              e.chat.value.isMonolog ||
              e.chat.value.isSupport;

          if (notLocalOrHasMessages &&
              !e.chat.value.isHidden &&
              !e.chat.value.isArchived) {
            if (e.chat.value.ongoingCall != null) {
              calls.add(e.rx);
            } else if (e.chat.value.favoritePosition != null) {
              favorites.add(e.rx);
            } else {
              chats.add(e.rx);
            }
          }
        }

        // If recent chats are completely empty, then display the "no chats".
        if (calls.isEmpty && favorites.isEmpty && chats.isEmpty) {
          if (c.status.value.isLoadingMore) {
            slivers = [
              SliverFillRemaining(
                key: UniqueKey(),
                child: Center(
                  child: ColoredBox(
                    key: const Key('Loading'),
                    color: style.colors.almostTransparent,
                    child: const CustomProgressIndicator(),
                  ),
                ),
              ),
            ];
          }

          slivers ??= [
            SliverFillRemaining(
              key: UniqueKey(),
              child: Padding(
                key: const Key('NoChats'),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SvgIcon(SvgIcons.notFound),
                    const SizedBox(height: 16),
                    Text(
                      'label_no_chats'.l10n,
                      style: style.fonts.medium.regular.secondary,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ];
        }

        slivers ??= [
          SliverPadding(
            padding: EdgeInsets.only(left: 10, right: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed(
                calls.map((e) => _tile(c, e)).toList(),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            sliver: SliverReorderableList(
              proxyDecorator: (child, _, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (_, Widget? child) {
                    final double t = Curves.easeInOut.transform(
                      animation.value,
                    );
                    final double elevation = lerpDouble(0, 6, t)!;
                    final Color color = Color.lerp(
                      style.colors.transparent,
                      style.colors.onBackgroundOpacity20,
                      t,
                    )!;

                    return Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          CustomBoxShadow(color: color, blurRadius: elevation),
                        ],
                        borderRadius: style.cardRadius.copyWith(
                          topLeft: Radius.circular(
                            style.cardRadius.topLeft.x * 1.75,
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
                    return _tile(
                      c,
                      chat,
                      avatarBuilder: (child) {
                        if (PlatformUtils.isMobile) {
                          return ReorderableDelayedDragStartListener(
                            key: Key('ReorderHandle_${chat.id.val}'),
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
                                  () => DisableSecondaryButtonRecognizer(),
                                  (_) {},
                                ),
                          },
                          child: ReorderableDragStartListener(
                            key: Key('ReorderHandle_${chat.id.val}'),
                            index: i,
                            child: GestureDetector(
                              onLongPress: () {},
                              child: child,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                );
              },
              itemCount: favorites.length,
              onReorder: c.reorderChat,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(bottom: 4, left: 10, right: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                ...chats.map((e) => _tile(c, e)),
                if (c.hasNext.isTrue || c.status.value.isLoadingMore)
                  Center(
                    child: CustomProgressIndicator(
                      key: const Key('ChatsLoading'),
                      value: Config.disableInfiniteAnimations ? 0 : null,
                    ),
                  ),
              ]),
            ),
          ),
        ];
      }

      return CustomScrollView(
        controller: c.scrollController,
        slivers: [
          SliverPersistentHeader(
            pinned: !c.search.search.isEmpty.value,
            delegate: _Search(c),
          ),
          ...slivers,
        ],
      );
    });
  }

  /// Builds a [RecentChatTile] from the provided [RxChat].
  Widget _tile(
    ChatsTabController c,
    RxChat e, {
    Widget Function(Widget)? avatarBuilder,
  }) {
    final bool selected = c.selectedChats.contains(e.id);

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
          ? (child) => WidgetButton(
              onPressed: () => router.dialog(e.chat.value, c.me),
              child: child,
            )
          : avatarBuilder,
      onJoin: () => c.joinCall(e.id),
      onDrop: () => c.dropCall(e.id),
      onLeave: e.chat.value.isMonolog ? null : () => c.leaveChat(e.id),
      onHide: () => c.hideChat(e.id),
      onArchive: () => c.archiveChat(e.id, !e.chat.value.isArchived),
      onMute: e.chat.value.isMonolog || e.chat.value.id.isLocal
          ? null
          : () => c.muteChat(e.id),
      onUnmute: e.chat.value.isMonolog || e.chat.value.id.isLocal
          ? null
          : () => c.unmuteChat(e.id),
      onFavorite: e.chat.value.id.isLocal && !e.chat.value.isMonolog
          ? null
          : () => c.favoriteChat(e.id),
      onUnfavorite: e.chat.value.id.isLocal && !e.chat.value.isMonolog
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
      onTap: c.selecting.value ? () => c.selectChat(e) : null,
      onDismissed: () async =>
          await c.archiveChat(e.id, !e.chat.value.isArchived),
      enableContextMenu: !c.selecting.value,
      trailing: c.selecting.value ? [SelectedDot(selected: selected)] : null,
      hasCall: c.status.value.isLoadingMore ? false : null,
      onPerformDrop: (f) => c.sendFiles(e.id, f),
    );
  }

  /// Builds a "not found" column with an icon.
  Widget _notFound(BuildContext context) {
    final style = Theme.of(context).style;

    return AnimatedDelayedSwitcher(
      key: UniqueKey(),
      delay: const Duration(milliseconds: 300),
      child: Center(
        key: const Key('NothingFound'),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const SvgIcon(SvgIcons.notFound),
              const SizedBox(height: 16),
              Text(
                'label_nothing_found'.l10n,
                style: style.fonts.medium.regular.secondary,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens a popup window to confirm archiving or unarchiving the selected
  /// chats.
  static Future<void> _archiveChats(
    BuildContext context,
    ChatsTabController c,
  ) async {
    final bool? result = await MessagePopup.alert(
      c.archivedOnly.value ? 'label_show_chats'.l10n : 'label_hide_chats'.l10n,
      description: [
        TextSpan(
          text: c.archivedOnly.value
              ? 'label_show_chats_modal_description'.l10n
              : 'label_hide_chats_modal_description'.l10n,
        ),
      ],
      button: (context) => MessagePopup.primaryButton(
        context,
        label: c.archivedOnly.value ? 'btn_unhide'.l10n : 'btn_hide'.l10n,
        icon: c.archivedOnly.value
            ? SvgIcons.visibleOffWhite
            : SvgIcons.visibleOnWhite,
      ),
    );

    if (result == true) {
      await c.archiveChats(!c.archivedOnly.value);
    }
  }

  /// Opens a confirmation popup hiding the selected chats.
  static Future<void> _hideChats(
    BuildContext context,
    ChatsTabController c,
  ) async {
    final bool? result = await MessagePopup.alert(
      'label_delete_chats'.l10n,
      description: [TextSpan(text: 'label_to_restore_chats_use_search'.l10n)],
      button: MessagePopup.deleteButton,
    );

    if (result == true) {
      await c.hideChats();
    }
  }
}

/// [SliverPersistentHeaderDelegate] building a [ReactiveTextField] representing
/// a search field.
class _Search extends SliverPersistentHeaderDelegate {
  _Search(this.c);

  final ChatsTabController c;

  @override
  double get maxExtent => 52;

  @override
  double get minExtent => 52;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final style = Theme.of(context).style;

    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(
        color: style.colors.secondaryHighlightDark,
        width: 0.5,
      ),
    );

    final ThemeData theme = Theme.of(context).copyWith(
      shadowColor: style.colors.onBackgroundOpacity27,
      iconTheme: IconThemeData(color: style.colors.primaryHighlight),
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
        hintStyle: style.fonts.medium.regular.secondary.copyWith(
          color: style.colors.secondaryHighlightDarkest,
        ),
        border: border,
        errorBorder: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: style.colors.primary, width: 1),
        ),
        disabledBorder: border,
        focusedErrorBorder: border,
        focusColor: style.colors.onBackground,
        hoverColor: style.colors.transparent,
        isDense: true,
      ),
    );

    return SizedBox(
      key: c.searchKey,
      height: maxExtent,
      child: Theme(
        data: theme,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
          color: style.sidebarColor,
          child: Stack(
            children: [
              ReactiveTextField(
                key: const Key('SearchField'),
                fillColor: style.colors.onPrimary,
                state: c.search.search,
                hint: 'label_search'.l10n,
                maxLines: 1,
                prefix: SizedBox(width: 24),
                dense: true,
                padding: PlatformUtils.isIOS || PlatformUtils.isAndroid
                    ? EdgeInsets.fromLTRB(8, 11, 8, 11)
                    : EdgeInsets.fromLTRB(8, 15, 8, 15),
                style: style.fonts.normal.regular.onBackground,
                onChanged: () => c.search.query.value = c.search.search.text,
              ),
              Positioned(
                left: 12,
                top: 12,
                child: const SvgIcon(SvgIcons.searchGrey),
              ),
              Positioned(
                right: 12,
                top: 15,
                child: Obx(() {
                  final Widget child;

                  if (c.search.search.isEmpty.value) {
                    child = const SizedBox();
                  } else {
                    child = WidgetButton(
                      key: Key('ClearSearchButton'),
                      onPressed: c.clearSearch,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: const SvgIcon(SvgIcons.searchExit),
                      ),
                    );
                  }

                  return AnimatedSwitcher(
                    duration: Duration(milliseconds: 250),
                    child: child,
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
