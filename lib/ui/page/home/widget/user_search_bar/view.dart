import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/ui/page/home/widget/avatar.dart';
import 'controller.dart';

/// [FloatingSearchBar] for [User]s searching.
class UserSearchBar extends StatelessWidget {
  UserSearchBar({
    Key? key,
    required this.body,
    this.onUserTap,
    FloatingSearchBarController? searchController,
    this.onTrailingTap,
    this.trailingIcon,
  })  : searchController = searchController ?? FloatingSearchBarController(),
        super(key: key);

  /// [FloatingSearchBar]'s body.
  final Widget body;

  /// [FloatingSearchBar]'s controller.
  late final FloatingSearchBarController searchController;

  /// Callback, called when an [User]'s [ListTile] is pressed.
  final Function(User)? onUserTap;

  /// Callback, called when the [trailingIcon] is pressed.
  ///
  /// Only meaningful if [trailingIcon] is specified.
  final Function(User)? onTrailingTap;

  /// Trailing icon of an [User]'s [ListTile].
  final Icon? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      key: const Key('UserSearchBarView'),
      init: UserSearchBarController(Get.find()),
      builder: (UserSearchBarController c) => Obx(
        () => FloatingSearchBar(
          hint: 'label_search'.tr,
          controller: searchController,
          scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
          transitionDuration: const Duration(milliseconds: 500),
          transitionCurve: Curves.easeInOut,
          physics: const BouncingScrollPhysics(),
          axisAlignment: 0.0,
          openAxisAlignment: 0.0,
          borderRadius: const BorderRadius.all(Radius.circular(32)),
          width: 600,
          progress: c.searchStatus.value.isLoading ||
              c.searchStatus.value.isLoadingMore,
          debounceDelay: const Duration(milliseconds: 400),
          onQueryChanged: (query) => c.search(query),
          transition: CircularFloatingSearchBarTransition(),
          automaticallyImplyBackButton: false,
          actions: [
            FloatingSearchBarAction.searchToClear(showIfClosed: false),
          ],
          builder: (context, transition) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Material(
                elevation: 4.0,
                child: Obx(
                  () => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: c.searchStatus.value.isSuccess
                        ? [
                            const SizedBox(height: 10),
                            ...c.searchResults.isEmpty
                                ? [
                                    ListTile(
                                        title:
                                            Text('label_search_not_found'.tr))
                                  ]
                                : c.searchResults
                                    .map((e) => _user(e, c))
                                    .toList(),
                            const SizedBox(height: 10),
                          ]
                        : c.recentSearchResults.isEmpty
                            ? [
                                SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: Text('label_search_hint'.tr),
                                  ),
                                )
                              ]
                            : [
                                ListTile(title: Text('label_search_recent'.tr)),
                                ...c.recentSearchResults
                                    .map((e) => _user(e, c))
                                    .toList()
                                    .reversed,
                                const SizedBox(height: 10),
                              ],
                  ),
                ),
              ),
            );
          },
          body: Column(
            children: [
              const SizedBox(height: 60),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns a [ListTile] with the information of the provided [User].
  Widget _user(RxUser rxUser, UserSearchBarController c) => ListTile(
        key: ValueKey(rxUser.user.value.id.val),
        leading: AvatarWidget.fromUser(rxUser.user.value),
        title: Text(rxUser.user.value.name?.val ?? rxUser.user.value.num.val),
        trailing: trailingIcon == null
            ? null
            : IconButton(
                onPressed: () {
                  onTrailingTap?.call(rxUser.user.value);
                  c.addToRecent(rxUser);
                  searchController.clear();
                  searchController.close();
                },
                icon: trailingIcon!,
              ),
        onTap: () {
          onUserTap?.call(rxUser.user.value);
          c.addToRecent(rxUser);
          searchController.clear();
          searchController.close();
        },
      );
}
