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
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/notification.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/main.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/contact.dart';
import 'package:messenger/provider/hive/gallery_item.dart';
import 'package:messenger/provider/hive/media_settings.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/ui/page/auth/view.dart';
import 'package:messenger/ui/page/home/view.dart';
import 'package:messenger/ui/worker/background/background.dart';

import '../mock/graphql_provider.dart';
import '../mock/route_information_provider.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await L10n.init();

  Hive.init('./test/.temp_hive/auth_widget');

  var sessionProvider = SessionDataHiveProvider();
  var graphQlProvider = _FakeGraphQlProvider();
  AuthRepository authRepository = AuthRepository(graphQlProvider);
  AuthService authService = AuthService(authRepository, sessionProvider);
  await authService.init();
  await sessionProvider.clear();

  var myUserProvider = MyUserHiveProvider();
  await myUserProvider.init(userId: const UserId('me'));
  var galleryItemProvider = GalleryItemHiveProvider();
  await galleryItemProvider.init(userId: const UserId('me'));
  var contactProvider = ContactHiveProvider();
  await contactProvider.init(userId: const UserId('me'));
  var userProvider = UserHiveProvider();
  await userProvider.init(userId: const UserId('me'));
  var chatProvider = ChatHiveProvider();
  await chatProvider.init(userId: const UserId('me'));
  var settingsProvider = MediaSettingsHiveProvider();
  await settingsProvider.init(userId: const UserId('me'));
  var applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init(userId: const UserId('me'));

  testWidgets('AuthView logins a user and redirects to HomeView',
      (WidgetTester tester) async {
    Get.put(myUserProvider);
    Get.put(galleryItemProvider);
    Get.put(contactProvider);
    Get.put(userProvider);
    Get.put<GraphQlProvider>(graphQlProvider);
    Get.put(sessionProvider);
    Get.put(chatProvider);
    Get.put(settingsProvider);
    Get.put(NotificationService());
    Get.put(BackgroundWorker(sessionProvider));

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );
    await authService.init();
    router = RouterState(authService);
    router.provider = MockedPlatformRouteInformationProvider();

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    final authView = find.byType(AuthView);
    expect(authView, findsOneWidget);

    final goToLoginButton = find.text('btn_login'.l10n);
    expect(goToLoginButton, findsOneWidget);

    await tester.tap(goToLoginButton);
    await tester.pumpAndSettle();

    final loginTile = find.byKey(const ValueKey('LoginNextTile'));
    expect(loginTile, findsOneWidget);

    final usernameField = find.byKey(const ValueKey('UsernameField'));
    expect(usernameField, findsOneWidget);
    await tester.enterText(usernameField, 'user');
    await tester.pumpAndSettle();

    await tester.tap(loginTile);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    final passwordField = find.byKey(const Key('PasswordField'));
    expect(passwordField, findsOneWidget);

    await tester.enterText(passwordField, 'password');
    await tester.pumpAndSettle();

    await tester.tap(loginTile);
    await tester.pump(const Duration(seconds: 5));

    await tester.runAsync(() {
      return Future.delayed(const Duration(seconds: 2));
    });
    await tester.pumpAndSettle(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
    final homeView = find.byType(HomeView);
    expect(homeView, findsOneWidget);

    await tester.runAsync(() => Future.delayed(const Duration(seconds: 15)));
    await Get.deleteAll(force: true);
  });
}

class _FakeGraphQlProvider extends MockedGraphQlProvider {
  @override
  AccessToken? token;

  @override
  Future<void> Function(AuthorizationException)? authExceptionHandler;

  @override
  Future<bool> checkUserIdentifiable(UserLogin? login, UserNum? num,
      UserEmail? email, UserPhone? phone) async {
    return (login?.val == 'user');
  }

  @override
  void reconnect() {}

  var userData = {
    'id': 'me',
    'num': '1234567890123456',
    'login': 'login',
    'name': 'name',
    'bio': 'bio',
    'emails': {'confirmed': [], 'unconfirmed': null},
    'phones': {'confirmed': []},
    'gallery': {'nodes': []},
    'hasPassword': true,
    'unreadChatsCount': 0,
    'ver': '0',
    'presence': 'AWAY',
    'online': {'__typename': 'UserOnline'},
  };

  @override
  Future<SignIn$Mutation$CreateSession$CreateSessionOk> signIn(
      UserPassword password,
      UserLogin? username,
      UserNum? num,
      UserEmail? email,
      UserPhone? phone,
      bool remember) async {
    if (username == null && num == null && email == null && phone == null) {
      throw Exception('Username or num or email or phone must not be null');
    }

    return SignIn$Mutation$CreateSession$CreateSessionOk.fromJson(
      {
        'session': {
          'token': 'token',
          'expireAt': DateTime.now().add(const Duration(days: 1)).toString(),
          'ver': '0',
        },
        'remembered': {
          'token': 'token',
          'expireAt': DateTime.now().add(const Duration(days: 1)).toString(),
          'ver': '30066501444801094020394372057490153134',
        },
        'user': userData
      },
    );
  }

  @override
  Future<Stream<QueryResult>> recentChatsTopEvents(int count) async {
    return Future.value(const Stream.empty());
  }

  @override
  Future<Stream<QueryResult<Object?>>> keepOnline() {
    return Future.value(const Stream.empty());
  }
}
