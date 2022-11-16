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

import 'package:flutter/material.dart';
import 'package:flutter_gherkin/flutter_gherkin_with_driver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/main.dart' as app;
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/util/platform_utils.dart';

import 'hook/reset_app.dart';
import 'mock/graphql.dart';
import 'mock/platform_utils.dart';
import 'parameters/attachment.dart';
import 'parameters/download_status.dart';
import 'parameters/keys.dart';
import 'parameters/muted_status.dart';
import 'parameters/online_status.dart';
import 'parameters/retry_image.dart';
import 'parameters/sending_status.dart';
import 'parameters/users.dart';
import 'steps/attach_file.dart';
import 'steps/change_chat_avatar.dart';
import 'steps/chat_is_muted.dart';
import 'steps/download_file.dart';
import 'steps/go_to.dart';
import 'steps/has_dialog.dart';
import 'steps/has_group.dart';
import 'steps/in_chat_with.dart';
import 'steps/internet.dart';
import 'steps/long_press_chat.dart';
import 'steps/long_press_message.dart';
import 'steps/long_press_widget.dart';
import 'steps/open_chat_info.dart';
import 'steps/restart_app.dart';
import 'steps/scroll_chat.dart';
import 'steps/see_draft.dart';
import 'steps/sees_as.dart';
import 'steps/sees_muted_chat.dart';
import 'steps/sends_attachment.dart';
import 'steps/sends_message.dart';
import 'steps/tap_dropdown_item.dart';
import 'steps/tap_text.dart';
import 'steps/tap_widget.dart';
import 'steps/text_field.dart';
import 'steps/updates_bio.dart';
import 'steps/users.dart';
import 'steps/wait_until_attachment.dart';
import 'steps/wait_until_attachment_status.dart';
import 'steps/wait_until_file_status.dart';
import 'steps/wait_until_message_status.dart';
import 'steps/wait_until_retry_image.dart';
import 'steps/wait_until_text.dart';
import 'steps/wait_until_text_within.dart';
import 'steps/wait_until_widget.dart';
import 'world/custom_world.dart';

/// Configuration of a Gherkin test suite.
final FlutterTestConfiguration gherkinTestConfiguration =
    FlutterTestConfiguration()
      ..stepDefinitions = [
        attachFile,
        cancelFileDownload,
        changeChatAvatar,
        chatIsMuted,
        copyFromField,
        doNotHaveInternetFor,
        downloadFile,
        fillField,
        fillFieldN,
        goToUserPage,
        hasDialogWithMe,
        haveGroupNamed,
        haveInternetWithoutDelay,
        iAm,
        iAmInChatNamed,
        iAmInChatWith,
        longPressChat,
        longPressMessageByAttachment,
        longPressMessageByText,
        longPressWidget,
        noInternetConnection,
        openChatInfo,
        pasteToField,
        restartApp,
        returnToPreviousPage,
        scrollAndSee,
        seeChatAsMuted,
        seesAs,
        seeDraftInDialog,
        sendsAttachmentToMe,
        sendsMessageToMe,
        signInAs,
        tapDropdownItem,
        tapText,
        tapWidget,
        twoUsers,
        untilAttachmentExists,
        untilTextExists,
        untilTextExistsWithin,
        updateBio,
        user,
        waitUntilAttachmentStatus,
        waitUntilFileStatus,
        untilAttachmentLoaded,
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
        DownloadStatusParameter(),
        MutedStatusParameter(),
        OnlineStatusParameter(),
        RetryImageParameter(),
        SendingStatusParameter(),
        UsersParameter(),
        WidgetKeyParameter(),
      ]
      ..createWorld = (config) => Future.sync(() => CustomWorld());

/// Application's initialization function.
Future<void> appInitializationFn(World world) {
  PlatformUtils = PlatformUtilsMock();
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

/// Extension adding an ability to find the [Widget]s without skipping the
/// offstage to [AppDriverAdapter].
extension SkipOffstageExtension on AppDriverAdapter {
  /// Finds the [Widget] by its [key] without skipping the offstage.
  Finder findByKeySkipOffstage(String key) =>
      find.byKey(Key(key), skipOffstage: false);

  /// Finds the [Widget] by its [text] without skipping the offstage.
  Finder findByTextSkipOffstage(String text) =>
      find.text(text, skipOffstage: false);
}
