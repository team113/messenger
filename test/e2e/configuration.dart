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

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_gherkin/flutter_gherkin_with_driver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/api/backend/schema.graphql.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/main.dart' as app;
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/util/platform_utils.dart';

import 'hook/reset_app.dart';
import 'parameters/attachment_type.dart';
import 'parameters/keys.dart';
import 'parameters/online_status.dart';
import 'parameters/sending_status.dart';
import 'parameters/users.dart';
import 'steps/attach_file.dart';
import 'steps/fill_field.dart';
import 'steps/has_dialog.dart';
import 'steps/in_chat_with.dart';
import 'steps/internet.dart';
import 'steps/long_press_message.dart';
import 'steps/long_press_widget.dart';
import 'steps/restart_app.dart';
import 'steps/sees_as.dart';
import 'steps/sends_message.dart';
import 'steps/tap_text.dart';
import 'steps/tap_widget.dart';
import 'steps/users.dart';
import 'steps/wait_until_file_status.dart';
import 'steps/wait_until_image_status.dart';
import 'steps/wait_until_message_status.dart';
import 'steps/wait_until_text_exists.dart';
import 'steps/wait_until_widget.dart';
import 'world/custom_world.dart';

/// Configuration of a Gherkin test suite.
final FlutterTestConfiguration gherkinTestConfiguration =
    FlutterTestConfiguration()
      ..stepDefinitions = [
        attachFile,
        fillField,
        hasDialogWithMe,
        hasInternetWithDelay,
        iAm,
        iAmInChatWith,
        longPressMessage,
        longPressWidget,
        noInternetConnection,
        restartApp,
        seesAs,
        sendsMessageToMe,
        signInAs,
        tapText,
        tapWidget,
        twoUsers,
        untilTextExists,
        user,
        waitUntilFileStatus,
        waitUntilImageStatus,
        waitUntilKeyExists,
        waitUntilMessageStatus,
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
        AttachmentTypeParameter(),
        OnlineStatusParameter(),
        SendingStatusParameter(),
        UsersParameter(),
        WidgetKeyParameter(),
      ]
      ..createWorld = (config) => Future.sync(() => CustomWorld());

/// Application's initialization function.
Future<void> appInitializationFn(World world) {
  Get.put<GraphQlProvider>(MockGraphQlProvider());
  return Future.sync(app.main);
}

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

/// Extension adding ability to find widget with `skipOffstage`: `false`.
extension SkipOffstageExtension on AppDriverAdapter {
  /// Finds widget by provided [key] with `skipOffstage`: `false`.
  Finder findByKeySkipOffstage(String key) =>
      find.byKey(Key(key), skipOffstage: false);
}

/// Mocked [GraphQlProvider].
class MockGraphQlProvider extends GraphQlProvider {
  MockGraphQlProvider({this.delay, this.hasError = false}) : super();

  /// Delay of requests.
  Duration? delay;

  /// Indicator whether methods throws exceptions.
  bool hasError;

  @override
  Future<ChatEventsVersionedMixin?> postChatMessage(
    ChatId chatId, {
    ChatMessageText? text,
    List<AttachmentId>? attachments,
    ChatItemId? repliesTo,
  }) async {
    if (hasError) {
      throw PostChatMessageException(PostChatMessageErrorCode.artemisUnknown);
    }

    if (delay != null) {
      await Future.delayed(delay!);
    }

    return super.postChatMessage(
      chatId,
      text: text,
      attachments: attachments,
      repliesTo: repliesTo,
    );
  }

  @override
  Future<UploadAttachment$Mutation$UploadAttachment$UploadAttachmentOk>
      uploadAttachment(
    dio.MultipartFile? attachment, {
    void Function(int count, int total)? onSendProgress,
  }) async {
    if (hasError) {
      await Future.delayed(delay!);
      throw UploadAttachmentException(UploadAttachmentErrorCode.artemisUnknown);
    }

    if (delay != null) {
      await Future.delayed(delay!);
    }

    return super.uploadAttachment(
      attachment,
      onSendProgress: onSendProgress,
    );
  }
}
