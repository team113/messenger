import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../../themes.dart';
import '../../../../widget/progress_indicator.dart';
import '../../../../widget/selected_tile.dart';
import '../../../call/search/controller.dart';
import 'controller.dart';

class GroupCreatingWidget extends StatelessWidget {
  const GroupCreatingWidget({required this.c, super.key});

  final ChatsTabController c;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;
    final RxStatus? searchStatus = c.search.value?.searchStatus.value;

    if (c.search.value?.query.isNotEmpty == true &&
        c.search.value?.recent.isEmpty == true &&
        c.search.value?.contacts.isEmpty == true &&
        c.search.value?.users.isEmpty == true) {
      if ((searchStatus?.isSuccess ?? false) &&
          !(searchStatus?.isLoadingMore ?? false)) {
        return Center(
          key: UniqueKey(),
          child: Text(
            'label_nothing_found'.l10n,
            style: style.fonts.small.regular.onBackground,
          ),
        );
      }

      return Center(
        key: UniqueKey(),
        child: ColoredBox(
          color: style.colors.almostTransparent,
          child: const CustomProgressIndicator(),
        ),
      );
    }

    return Scrollbar(
      controller: c.search.value!.scrollController,
      child: ListView.builder(
        key: const Key('GroupCreating'),
        controller: c.search.value!.scrollController,
        itemCount: c.elements.length,
        itemBuilder: (context, i) {
          final ListElement element = c.elements[i];
          Widget child;

          if (element is RecentElement) {
            child = Obx(() {
              return SelectedTile(
                user: element.user,
                selected:
                    c.search.value?.selectedRecent.contains(element.user) ??
                    false,
                onTap: () => c.search.value?.select(recent: element.user),
              );
            });
          } else if (element is ContactElement) {
            child = Obx(() {
              return SelectedTile(
                contact: element.contact,
                selected:
                    c.search.value?.selectedContacts.contains(
                      element.contact,
                    ) ??
                    false,
                onTap: () => c.search.value?.select(contact: element.contact),
              );
            });
          } else if (element is UserElement) {
            child = Obx(() {
              return SelectedTile(
                user: element.user,
                selected:
                    c.search.value?.selectedUsers.contains(element.user) ??
                    false,
                onTap: () => c.search.value?.select(user: element.user),
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
            final String text;

            switch (element.category) {
              case SearchCategory.recent:
                text = 'label_recent'.l10n;
                break;

              case SearchCategory.contact:
                text = 'label_user'.l10n;
                break;

              case SearchCategory.user:
                text = 'label_user'.l10n;
                break;

              case SearchCategory.chat:
                text = 'label_chat'.l10n;
                break;
            }

            child = Center(
              child: Container(
                margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
                width: double.infinity,
                child: Center(
                  child: Text(
                    text,
                    style: style.fonts.normal.regular.onBackground,
                  ),
                ),
              ),
            );
          } else {
            child = const SizedBox();
          }

          if (i == c.elements.length - 1 &&
              ((searchStatus?.isLoadingMore ?? false) ||
                  (searchStatus?.isLoading ?? false))) {
            child = Column(children: [child, const CustomProgressIndicator()]);
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: child,
          );
        },
      ),
    );
  }
}
