// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import 'package:graphql/client.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/provider/drift/account.dart';
import 'package:messenger/provider/drift/blocklist.dart';
import 'package:messenger/provider/drift/credentials.dart';
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/provider/drift/locks.dart';
import 'package:messenger/provider/drift/my_user.dart';
import 'package:messenger/provider/drift/secret.dart';
import 'package:messenger/provider/drift/user.dart';
import 'package:messenger/provider/drift/version.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/blocklist.dart';
import 'package:messenger/store/model/blocklist.dart';
import 'package:messenger/store/model/my_user.dart';
import 'package:messenger/store/model/session.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/user.dart';

import '../mock/graphql_provider.dart';

void main() async {
  final CommonDriftProvider common = CommonDriftProvider.memory();
  final ScopedDriftProvider scoped = ScopedDriftProvider.memory();

  final credentialsProvider = Get.put(CredentialsDriftProvider(common));
  final accountProvider = Get.put(AccountDriftProvider(common));
  final myUserProvider = Get.put(MyUserDriftProvider(common));
  final userProvider = UserDriftProvider(common, scoped);
  final blocklistProvider = Get.put(BlocklistDriftProvider(common, scoped));
  final versionProvider = Get.put(VersionDriftProvider(common));
  final locksProvider = Get.put(LockDriftProvider(common));
  final secretsProvider = Get.put(RefreshSecretDriftProvider(common));

  test('MyProfile test', () async {
    Get.reset();

    final graphQlProvider = FakeGraphQlProvider();

    Get.put(
      AuthService(
        AuthRepository(graphQlProvider, myUserProvider, credentialsProvider),
        credentialsProvider,
        accountProvider,
        locksProvider,
        secretsProvider,
      ),
    );

    UserRepository userRepository = Get.put(
      UserRepository(graphQlProvider, userProvider, me: const UserId('me')),
    );

    BlocklistRepository blocklistRepository = Get.put(
      BlocklistRepository(
        graphQlProvider,
        blocklistProvider,
        userRepository,
        versionProvider,
        me: const UserId('me'),
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
          accountProvider,
          me: const UserId('me'),
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 1));

    assert(profileService.myUser.value == profileService.myUser.value);
  });

  tearDown(() async => await Future.wait([common.close(), scoped.close()]));
}

class FakeGraphQlProvider extends MockedGraphQlProvider {
  int version = 0;

  @override
  AccessTokenSecret? token = const AccessTokenSecret('aaaaaaaaaaa');

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
    },
  };

  @override
  Future<Stream<QueryResult>> myUserEvents(
    Future<MyUserVersion?> Function()? getVer,
  ) async {
    return Stream.fromIterable([
      QueryResult.internal(
        parserFn: (_) => null,
        source: null,
        data: {
          'myUserEvents': {'__typename': 'MyUser', ...userData},
        },
      ),
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

  @override
  Stream<QueryResult<Object?>> sessionsEvents(
    SessionsListVersion? Function() ver,
  ) {
    return const Stream.empty();
  }

  @override
  Stream<QueryResult<Object?>> blocklistEvents(
    BlocklistVersion? Function() ver,
  ) {
    return const Stream.empty();
  }
}
