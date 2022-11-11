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
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/call/search/newview.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'create_group/controller.dart';
import 'widget/recent_chat.dart';

/// View of the `HomeTab.chats` tab.
class ChatsTabView extends StatelessWidget {
  const ChatsTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Style style = Theme.of(context).extension<Style>()!;

    Widget tile({
      RxUser? user,
      RxChatContact? contact,
      void Function()? onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: ContactTile(
          contact: contact,
          user: user,
          darken: 0,
          onTap: () {
            onTap?.call();
          },
        ),
      );
    }

    return GetBuilder(
      key: const Key('ChatsTab'),
      init: ChatsTabController(Get.find(), Get.find(), Get.find(), Get.find()),
      builder: (ChatsTabController c) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            title: Obx(() {
              Widget child;

              if (c.searching.value) {
                child = Theme(
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Transform.translate(
                      offset: const Offset(0, 1),
                      child: NewSearchView(
                        title: 'label_search'.l10n,
                        categories: const [
                          SearchCategory.chats,
                          SearchCategory.contacts,
                          SearchCategory.users,
                        ],
                        searchStatus: c.searchStatus,
                        onResultsUpdated: (v, q) {
                          c.searchResult.value = v;
                          c.searchQuery.value = q;
                          c.populate();
                        },
                        autoFocus: true,
                      ),
                    ),
                  ),
                );
              } else {
                child = Text('label_chats'.l10n, key: const Key('2'));
              }

              return AnimatedSwitcher(
                duration: 250.milliseconds,
                child: child,
              );
            }),
            leading: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 12),
                child: Obx(() {
                  return AnimatedSwitcher(
                    duration: 250.milliseconds,
                    child: WidgetButton(
                      onPressed: c.searching.value
                          ? null
                          : () => c.searching.value = true,
                      child: SvgLoader.asset(
                        'assets/icons/search.svg',
                        width: 17.77,
                      ),
                    ),
                  );
                }),
              ),
            ],
            actions: [
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 18),
                child: Obx(() {
                  Widget child;

                  if (c.searching.value) {
                    child = WidgetButton(
                      key: const Key('CloseSearch'),
                      onPressed: () => c.searching.value = false,
                      child: SvgLoader.asset(
                        'assets/icons/close_primary.svg',
                        height: 15,
                      ),
                    );
                  } else {
                    child = WidgetButton(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const CreateGroupView(),
                      ),
                      child: SvgLoader.asset('assets/icons/group.svg',
                          height: 18.44),
                    );
                  }

                  return SizedBox(
                    width: 21.77,
                    child: AnimatedSwitcher(
                      duration: 250.milliseconds,
                      child: child,
                    ),
                  );
                }),
              ),
            ],
          ),
          body: Obx(() {
            if (c.chatsReady.value) {
              Widget? center;

              if (c.searching.isTrue) {
                if (c.searchStatus.value.isSuccess &&
                    (c.searchResult.value == null ||
                        c.searchResult.value?.isEmpty == true)) {
                  center = Center(child: Text('label_nothing_found'.l10n));
                } else if (c.searchStatus.value.isLoading &&
                    (c.searchResult.value == null ||
                        c.searchResult.value?.isEmpty == true)) {
                  center = const Center(child: CircularProgressIndicator());
                } else {
                  center = ListView.builder(
                    controller: ScrollController(),
                    itemCount: c.elements.length,
                    itemBuilder: (_, i) {
                      ListElement element = c.elements[i];
                      Widget child = const SizedBox();

                      if (element is ChatElement) {
                        final RxChat chat = element.chat;
                        child = Padding(
                          padding: const EdgeInsets.only(
                            left: 10,
                            right: 10,
                          ),
                          child: RecentChatTile(
                            chat,
                            me: c.me,
                            getUser: c.getUser,
                            onJoin: () => c.joinCall(chat.id),
                            onDrop: () => c.dropCall(chat.id),
                            onLeave: () => c.leaveChat(chat.id),
                            onHide: () => c.hideChat(chat.id),
                            inCall: () => c.inCall(chat.id),
                          ),
                        );
                      } else if (element is ContactElement) {
                        child = tile(
                          contact: element.contact,
                          onTap: () {
                            c.openChat(
                              contact: element.contact,
                            );
                          },
                        );
                      } else if (element is UserElement) {
                        child = tile(
                          user: element.user,
                          onTap: () {
                            c.openChat(user: element.user);
                          },
                        );
                      } else if (element is DividerElement) {
                        child = Center(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(
                              10,
                              2,
                              10,
                              2,
                            ),
                            padding: const EdgeInsets.fromLTRB(
                              12,
                              10,
                              12,
                              6,
                            ),
                            width: double.infinity,
                            child: Center(
                              child: Text(
                                element.category.name.capitalizeFirst!,
                                style: style.systemMessageTextStyle.copyWith(
                                  color: Colors.black,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: EdgeInsets.only(
                          top: i == 0 ? 3 : 0,
                          bottom: i == c.elements.length - 1 ? 4 : 0,
                        ),
                        child: child,
                      );
                    },
                  );
                }
              } else {
                if (c.chats.isEmpty) {
                  center = Center(child: Text('label_no_chats'.l10n));
                } else {
                  center = ListView.builder(
                    controller: ScrollController(),
                    itemCount: c.chats.length,
                    itemBuilder: (_, i) {
                      final RxChat chat = c.chats[i];
                      return AnimationConfiguration.staggeredList(
                        position: i,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          horizontalOffset: 50,
                          child: FadeInAnimation(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: RecentChatTile(
                                chat,
                                me: c.me,
                                getUser: c.getUser,
                                onJoin: () => c.joinCall(chat.id),
                                onDrop: () => c.dropCall(chat.id),
                                onLeave: () => c.leaveChat(chat.id),
                                onHide: () => c.hideChat(chat.id),
                                inCall: () => c.inCall(chat.id),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: ContextMenuInterceptor(
                  child: AnimationLimiter(
                    child: center,
                  ),
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          }),
        );
      },
    );
  }
}
