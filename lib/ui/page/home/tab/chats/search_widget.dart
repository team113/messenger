import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_notifier.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../../../domain/repository/chat.dart';
import '../../../../../l10n/l10n.dart';
import '../../../../../themes.dart';
import '../../../../widget/animated_delayed_switcher.dart';
import '../../../../widget/progress_indicator.dart';
import 'controller.dart';
import 'widget/recent_chat.dart';
import 'widget/search_user_tile.dart';

class SearchWidget extends StatelessWidget {
  const SearchWidget({required this.c, super.key});

  final ChatsTabController c;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;
    final RxStatus? searchStatus = c.search.value?.searchStatus.value;

    if (((searchStatus?.isLoading ?? false) ||
            (searchStatus?.isLoadingMore ?? false)) &&
        c.elements.isEmpty) {
      return Center(
        key: UniqueKey(),
        child: ColoredBox(
          key: const Key('Loading'),
          color: style.colors.almostTransparent,
          child: const CustomProgressIndicator(),
        ),
      );
    }

    if (c.elements.isEmpty) {
      return AnimatedDelayedSwitcher(
        key: UniqueKey(),
        delay: const Duration(milliseconds: 300),
        child: Center(
          key: const Key('NothingFound'),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'label_nothing_found'.l10n,
              style: style.fonts.small.regular.onBackground,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scrollbar(
      controller: c.search.value!.scrollController,
      child: AnimationLimiter(
        key: const Key('Search'),
        child: ListView.builder(
          key: const Key('SearchScrollable'),
          controller: c.search.value!.scrollController,
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
                margin: EdgeInsets.fromLTRB(8, i == 0 ? 0 : 8, 8, 3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                width: double.infinity,
                child: Center(
                  child: Text(
                    element.category.name.capitalized,
                    style: style.fonts.normal.regular.onBackground,
                  ),
                ),
              );
            } else {
              child = const SizedBox();
            }

            if (i == c.elements.length - 1) {
              if ((searchStatus?.isLoadingMore ?? false) ||
                  (searchStatus?.isLoading ?? false)) {
                child = Column(
                  children: [
                    child,
                    const CustomProgressIndicator(key: Key('SearchLoading')),
                  ],
                );
              }
            }

            return AnimationConfiguration.staggeredList(
              position: i,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                horizontalOffset: 50,
                child: FadeInAnimation(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: i == 0 ? 3 : 0,
                      bottom: i == c.elements.length - 1 ? 4 : 0,
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
