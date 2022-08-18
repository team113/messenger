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

// ignore_for_file: avoid_print

import 'package:flutter_gherkin/flutter_gherkin_with_driver.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/main.dart' as app;
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/util/platform_utils.dart';

import 'hook/reset_app.dart';
import 'parameters/chat.dart';
import 'parameters/keys.dart';
import 'parameters/online_status.dart';
import 'parameters/users.dart';
import 'steps/go_to.dart';
import 'steps/has_dialog.dart';
import 'steps/in_chat_with.dart';
import 'steps/sees_as.dart';
import 'steps/sends_message.dart';
import 'steps/tap_dropdown_item.dart';
import 'steps/tap_widget.dart';
import 'steps/text_field.dart';
import 'steps/updates_bio.dart';
import 'steps/users.dart';
import 'steps/wait_until_text_exists.dart';
import 'steps/wait_until_widget.dart';
import 'world/custom_world.dart';

/// Configuration of a Gherkin test suite.
final FlutterTestConfiguration gherkinTestConfiguration =
    FlutterTestConfiguration()
      ..stepDefinitions = [
        copyFromField,
        fillField,
        goToUserPage,
        hasChatWithMe,
        iAm,
        iAmInChatWith,
        pasteToField,
        seesAs,
        sendsMessageToMe,
        signInAs,
        tapDropdownItem,
        tapWidget,
        twoUsers,
        untilTextExists,
        updateBio,
        user,
        waitUntilKeyExists,
      ]
      ..hooks = [ResetAppHook()]
      ..reporters = [
        StdoutReporter(MessageLevel.verbose)
          ..setWriteLineFn(print)
          ..setWriteFn(print),
        ProgressReporter()
          ..setWriteLineFn(print)
          ..setWriteFn(print),
        TestRunSummaryReporter()
          ..setWriteLineFn(print)
          ..setWriteFn(print),
        FlutterDriverReporter(logInfoMessages: true),
        if (!PlatformUtils.isWeb) JsonReporter(),
      ]
      ..semanticsEnabled = false
      ..defaultTimeout = const Duration(seconds: 30)
      ..customStepParameterDefinitions = [
        ChatTypeParameter(),
        OnlineStatusParameter(),
        UsersParameter(),
        WidgetKeyParameter(),
      ]
      ..createWorld = (config) => Future.sync(() => CustomWorld());

/// Application's initialization function.
Future<void> appInitializationFn(World world) => Future.sync(app.main);

/// Creates a new [Session] for an [User] identified by the provided [name].
Future<Session> createUser(
  TestUser user,
  CustomWorld world, {
  UserPassword? password,
}) async {
  final provider = GraphQlProvider();
  final result = await provider.signUp();

  world.sessions[user.name] = CustomUser(
    Session(
      result.createUser.session.token,
      result.createUser.session.expireAt,
    ),
    result.createUser.user.id,
    result.createUser.user.num,
  );

  provider.token = result.createUser.session.token;
  await provider.updateUserName(UserName(user.name));
  if (password != null) {
    await provider.updateUserPassword(null, password);
  }
  provider.disconnect();
  return Session(
    result.createUser.session.token,
    result.createUser.session.expireAt,
  );
}
