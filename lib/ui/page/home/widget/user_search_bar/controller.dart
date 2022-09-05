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

import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/domain/service/user.dart';

export 'view.dart';

/// Controller of an [UserSearchBar] widget.
class UserSearchBarController extends GetxController {
  UserSearchBarController(this._userService);

  /// [User]s search results.
  final Rx<RxList<RxUser>?> searchResults = Rx(null);

  /// Recently searched [User]s.
  final RxList<RxUser> recentSearchResults = RxList<RxUser>([]);

  /// Status of the search.
  ///
  /// May be:
  /// - `searchStatus.empty`, meaning no search.
  /// - `searchStatus.loading`, meaning search is in progress.
  /// - `searchStatus.loadingMore`, meaning search is in progress after some
  ///   [searchResults] were already acquired.
  /// - `searchStatus.success`, meaning search is done and [searchResults] are
  ///   acquired.
  final Rx<RxStatus> searchStatus = Rx<RxStatus>(RxStatus.empty());

  /// [User]s service, used to search [User]s.
  final UserService _userService;

  /// Worker to react on [SearchResult.status] changes.
  Worker? _searchWorker;

  @override
  void onClose() {
    _searchWorker?.dispose();
    _searchWorker = null;
    super.onClose();
  }

  // TODO: Implement search by a [ChatDirectLinkSlug].
  /// Performs searching for [User]s based on the provided [query].
  ///
  /// Query may be an [UserNum], [UserName] or [UserLogin].
  void search(String query) {
    _searchWorker?.dispose();
    _searchWorker = null;

    if (query.isNotEmpty) {
      UserNum? num;
      UserName? name;
      UserLogin? login;

      try {
        num = UserNum(query);
      } catch (e) {
        // No-op.
      }

      try {
        name = UserName(query);
      } catch (e) {
        // No-op.
      }

      try {
        login = UserLogin(query);
      } catch (e) {
        // No-op.
      }

      if (num != null || name != null || login != null) {
        searchStatus.value = searchStatus.value.isSuccess
            ? RxStatus.loadingMore()
            : RxStatus.loading();
        final SearchResult result =
            _userService.search(num: num, name: name, login: login);

        searchResults.value = result.users;
        searchStatus.value = result.status.value;
        _searchWorker =
            ever(result.status, (RxStatus s) => searchStatus.value = s);
      }
    } else {
      searchStatus.value = RxStatus.empty();
      searchResults.value = null;
    }
  }

  /// Adds the provided [user] to the [recentSearchResults].
  void addToRecent(RxUser user) {
    recentSearchResults.removeWhere((e) => e.id == user.id);
    recentSearchResults.add(user);
    if (recentSearchResults.length >= 10) {
      recentSearchResults.removeAt(0);
    }
  }
}
