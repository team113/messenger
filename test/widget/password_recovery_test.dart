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
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/fluent/extension.dart';
import 'package:messenger/fluent/fluent_localization.dart';
import 'package:messenger/main.dart';
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
  Hive.init('./test/.temp_hive/password_recovery');

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
  await LocalizationUtils.init();

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

    final goToLoginButton = find.text('btn_login'.td());
    expect(goToLoginButton, findsOneWidget);

    await tester.tap(goToLoginButton);
    await tester.pumpAndSettle();

    final recoveryTile = find.byKey(const ValueKey('RecoveryNextTile'));
    expect(recoveryTile, findsOneWidget);

    final usernameField = find.byKey(const ValueKey('RecoveryField'));
    expect(usernameField, findsOneWidget);

    await tester.enterText(usernameField, 'emptyuser');
    await tester.pumpAndSettle();

    final noCodeField = find.byKey(const ValueKey('RecoveryCodeField'));
    expect(noCodeField, findsNothing);

    await tester.enterText(usernameField, 'login');
    await tester.pumpAndSettle();

    await tester.tap(recoveryTile);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    final codeField = find.byKey(const ValueKey('RecoveryCodeField'));
    expect(codeField, findsOneWidget);

    await tester.enterText(codeField, '1234');
    await tester.pumpAndSettle();

    await tester.tap(recoveryTile);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    final password1 = find.byKey(const ValueKey('PasswordField'));
    expect(password1, findsOneWidget);
    final password2 = find.byKey(const ValueKey('RepeatPasswordField'));
    expect(password2, findsOneWidget);

    await tester.enterText(password1, 'test123');
    await tester.enterText(password2, 'test123');
    await tester.pumpAndSettle();
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0.0, -100.0));
    await tester.pumpAndSettle();
    await tester.tap(recoveryTile);

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
