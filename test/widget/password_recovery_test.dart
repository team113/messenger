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
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/api/backend/schema.dart'
    show RecoverUserPasswordErrorCode;
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/main.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/contact.dart';
import 'package:messenger/provider/hive/gallery_item.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/ui/page/auth/view.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'password_recovery_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Config.disableInfiniteAnimations = true;
  Hive.init('./test/.temp_hive/password_recovery');
  await L10n.init();

  var sessionProvider = SessionDataHiveProvider();
  var graphQlProvider = MockGraphQlProvider();
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  AuthRepository authRepository = AuthRepository(graphQlProvider);
  AuthService authService = AuthService(authRepository, sessionProvider);
  await authService.init();
  await sessionProvider.clear();

  var myUserProvider = MyUserHiveProvider();
  await myUserProvider.init();
  var galleryItemProvider = GalleryItemHiveProvider();
  await galleryItemProvider.init();
  var contactProvider = ContactHiveProvider();
  await contactProvider.init();
  var userProvider = UserHiveProvider();
  await userProvider.init();
  var chatProvider = ChatHiveProvider();
  await chatProvider.init();

  testWidgets('AuthView successfully recovers account access',
      (WidgetTester tester) async {
    Get.put(myUserProvider);
    Get.put(galleryItemProvider);
    Get.put(contactProvider);
    Get.put(userProvider);
    Get.put<GraphQlProvider>(graphQlProvider);
    Get.put(sessionProvider);
    Get.put(chatProvider);

    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );
    await authService.init();
    router = RouterState(authService);
    router.provider = MockPlatformRouteInformationProvider();
    when(router.provider!.value)
        .thenReturn(const RouteInformation(location: '/'));
    when(graphQlProvider.recoverUserPassword(
            UserLogin('login'), null, null, null))
        .thenAnswer((_) => Future.value());
    when(graphQlProvider.recoverUserPassword(
            UserLogin('emptyuser'), null, null, null))
        .thenAnswer((_) => throw const RecoverUserPasswordException(
            RecoverUserPasswordErrorCode.unknownUser));
    when(graphQlProvider.validateUserPasswordRecoveryCode(
            UserLogin('login'), null, null, null, ConfirmationCode('1234')))
        .thenAnswer((_) => Future.value());
    when(graphQlProvider.resetUserPassword(UserLogin('login'), null, null, null,
            ConfirmationCode('1234'), UserPassword('test123')))
        .thenAnswer((_) => Future.value());

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    final authView = find.byType(AuthView);
    expect(authView, findsOneWidget);

    final goToLoginButton = find.text('btn_login'.l10n);
    expect(goToLoginButton, findsOneWidget);

    await tester.tap(goToLoginButton);
    await tester.pumpAndSettle();

    final accessRecoveryTile = find.text('btn_forgot_password'.l10n);
    expect(accessRecoveryTile, findsOneWidget);

    await tester.tap(accessRecoveryTile);
    await tester.pumpAndSettle();

    final usernameField = find.byKey(const Key('RecoveryField'));
    expect(usernameField, findsOneWidget);

    await tester.enterText(usernameField, 'emptyuser');
    await tester.pumpAndSettle();

    final nextTile = find.text('btn_next'.l10n);
    expect(nextTile, findsOneWidget);

    await tester.tap(nextTile);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    final noCodeField = find.byKey(const ValueKey('RecoveryCodeField'));
    expect(noCodeField, findsNothing);

    await tester.enterText(usernameField, 'login');
    await tester.pumpAndSettle();

    await tester.tap(nextTile);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    final codeField = find.byKey(const ValueKey('RecoveryCodeField'));
    expect(codeField, findsOneWidget);

    await tester.enterText(codeField, '1234');
    await tester.pumpAndSettle();

    await tester.tap(nextTile);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    final password1 = find.byKey(const ValueKey('PasswordField'));
    expect(password1, findsOneWidget);
    final password2 = find.byKey(const ValueKey('RepeatPasswordField'));
    expect(password2, findsOneWidget);

    await tester.enterText(password1, 'test123');
    await tester.enterText(password2, 'test123');
    await tester.pumpAndSettle();

    await tester.tap(nextTile);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(password1, findsNothing);

    await tester.pumpAndSettle(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));

    verifyInOrder([
      router.provider!.value,
      graphQlProvider.recoverUserPassword(UserLogin('login'), null, null, null),
      graphQlProvider.validateUserPasswordRecoveryCode(
          UserLogin('login'), null, null, null, ConfirmationCode('1234')),
      graphQlProvider.resetUserPassword(UserLogin('login'), null, null, null,
          ConfirmationCode('1234'), UserPassword('test123')),
    ]);

    await Get.deleteAll(force: true);
  });
}
