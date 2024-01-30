// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/provider/hive/blocklist.dart';
import 'package:messenger/provider/hive/blocklist_sorting.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/provider/hive/credentials.dart';
import 'package:messenger/provider/hive/session_data.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/blocklist.dart';
import 'package:messenger/store/model/my_user.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/user.dart';

import '../mock/graphql_provider.dart';

void main() async {
  Hive.init('./test/.temp_hive/profile_unit');
  var myUserProvider = MyUserHiveProvider();
  await myUserProvider.init();
  var userProvider = UserHiveProvider();
  await userProvider.init();
  var blockedUsersProvider = BlocklistHiveProvider();
  await blockedUsersProvider.init();
  var sessionProvider = SessionDataHiveProvider();
  await sessionProvider.init();
  var blocklistSortingProvider = BlocklistSortingHiveProvider();
  await blocklistSortingProvider.init();

  test('MyProfile test', () async {
    Get.reset();

    final getStorage = CredentialsHiveProvider();
    await getStorage.init();

    final graphQlProvider = FakeGraphQlProvider();

    Get.put(AuthService(AuthRepository(graphQlProvider), getStorage));

    UserRepository userRepository =
        Get.put(UserRepository(graphQlProvider, userProvider));

    BlocklistRepository blocklistRepository = Get.put(
      BlocklistRepository(
        graphQlProvider,
        blockedUsersProvider,
        blocklistSortingProvider,
        userRepository,
        sessionProvider,
      ),
    );

    var profileService = Get.put(
      MyUserService(
        Get.find(),
        MyUserRepository(
          graphQlProvider,
          myUserProvider,
          blocklistRepository,
          userRepository,
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 1));

    assert(profileService.myUser.value == profileService.myUser.value);
  });
}

class FakeGraphQlProvider extends MockedGraphQlProvider {
  int version = 0;

  @override
  AccessToken? token = const AccessToken('aaaaaaaaaaa');

  Map<String, dynamic> userData = {
    'id': 'id',
    'num': '1234567890123456',
    'login': null,
    'name': null,
    'emails': {'confirmed': []},
    'phones': {'confirmed': []},
    'chatDirectLink': null,
    'hasPassword': false,
    'unreadChatsCount': 0,
    'ver': '0',
    'presence': 'AWAY',
    'online': {'__typename': 'UserOnline'},
  };

  var blocklist = {
    'edges': [],
    'pageInfo': {
      'endCursor': 'endCursor',
      'hasNextPage': false,
      'startCursor': 'startCursor',
      'hasPreviousPage': false,
    }
  };

  @override
  Stream<QueryResult> myUserEvents(MyUserVersion? Function()? getVer) {
    return Stream.fromIterable([
      QueryResult.internal(
        parserFn: (_) => null,
        source: null,
        data: {
          'myUserEvents': {'__typename': 'MyUser', ...userData},
        },
      )
    ]);
  }

  @override
  Stream<QueryResult<Object?>> keepOnline() {
    return const Stream.empty();
  }

  @override
  Future<GetBlocklist$Query$Blocklist> getBlocklist({
    BlocklistCursor? after,
    BlocklistCursor? before,
    int? first,
    int? last,
  }) {
    return Future.value(GetBlocklist$Query$Blocklist.fromJson(blocklist));
  }
}
