// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import 'parameters/chat_messages_status.dart';
import 'parameters/download_status.dart';
import 'parameters/exception.dart';
import 'parameters/favorite_status.dart';
import 'parameters/fetch_status.dart';
import 'parameters/keys.dart';
import 'parameters/muted_status.dart';
import 'parameters/online_status.dart';
import 'parameters/position_status.dart';
import 'parameters/search_category.dart';
import 'parameters/selection_status.dart';
import 'parameters/sending_status.dart';
import 'parameters/users.dart';
import 'steps/attach_file.dart';
import 'steps/change_chat_avatar.dart';
import 'steps/chat_is_favorite.dart';
import 'steps/chat_is_muted.dart';
import 'steps/contact.dart';
import 'steps/contact_is_favorite.dart';
import 'steps/download_file.dart';
import 'steps/drag_chat.dart';
import 'steps/drag_contact.dart';
import 'steps/go_to.dart';
import 'steps/has_dialog.dart';
import 'steps/has_group.dart';
import 'steps/in_chat_with.dart';
import 'steps/internet.dart';
import 'steps/long_press_chat.dart';
import 'steps/long_press_contact.dart';
import 'steps/long_press_message.dart';
import 'steps/long_press_widget.dart';
import 'steps/open_chat_info.dart';
import 'steps/restart_app.dart';
import 'steps/scroll_chat.dart';
import 'steps/scroll_until.dart';
import 'steps/see_chat_avatar.dart';
import 'steps/see_chat_messages.dart';
import 'steps/see_chat_position.dart';
import 'steps/see_chat_selection.dart';
import 'steps/see_contact_position.dart';
import 'steps/see_contact_selection.dart';
import 'steps/see_draft.dart';
import 'steps/see_favorite_chat.dart';
import 'steps/see_favorite_contact.dart';
import 'steps/see_search_results.dart';
import 'steps/sees_as_online.dart';
import 'steps/sees_dialog.dart';
import 'steps/sees_muted_chat.dart';
import 'steps/sends_attachment.dart';
import 'steps/sends_message.dart';
import 'steps/tap_chat.dart';
import 'steps/tap_chat_in_search_view.dart';
import 'steps/tap_contact.dart';
import 'steps/tap_dropdown_item.dart';
import 'steps/tap_search_result.dart';
import 'steps/tap_text.dart';
import 'steps/tap_widget.dart';
import 'steps/text_field.dart';
import 'steps/update_avatar.dart';
import 'steps/updates_name.dart';
import 'steps/users.dart';
import 'steps/wait_to_settle.dart';
import 'steps/wait_until_attachment.dart';
import 'steps/wait_until_attachment_fetched.dart';
import 'steps/wait_until_attachment_status.dart';
import 'steps/wait_until_chat.dart';
import 'steps/wait_until_contact.dart';
import 'steps/wait_until_file_status.dart';
import 'steps/wait_until_message.dart';
import 'steps/wait_until_message_status.dart';
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
        chatIsFavorite,
        chatIsMuted,
        contact,
        contactIsFavorite,
        copyFromField,
        downloadFile,
        dragChatDown,
        dragContactDown,
        fillField,
        fillFieldN,
        goToUserPage,
        hasDialogWithMe,
        haveGroupNamed,
        haveInternetWithDelay,
        haveInternetWithoutDelay,
        iAm,
        iAmInChatNamed,
        iAmInChatWith,
        iTapChatWith,
        longPressChat,
        longPressContact,
        longPressMessageByAttachment,
        longPressMessageByText,
        longPressWidget,
        noInternetConnection,
        openChatInfo,
        pasteToField,
        restartApp,
        returnToPreviousPage,
        scrollAndSee,
        scrollUntilPresent,
        seeChatAsFavorite,
        seeChatAsMuted,
        seeChatAvatarAs,
        seeChatAvatarAsNone,
        seeChatInSearchResults,
        seeChatMessages,
        seeChatPosition,
        seeChatSelection,
        seeContactAsFavorite,
        seeContactPosition,
        seeContactSelection,
        seeDraftInDialog,
        seeUserInSearchResults,
        seesAs,
        seesDialogWithMe,
        seesNoDialogWithMe,
        sendsAttachmentToMe,
        sendsMessageToMe,
        sendsMessageWithException,
        signInAs,
        tapChat,
        tapContact,
        tapDropdownItem,
        tapText,
        tapUserInSearchResults,
        tapWidget,
        twoContacts,
        twoUsers,
        untilAttachmentExists,
        untilAttachmentFetched,
        untilChatExists,
        untilContactExists,
        untilMessageExists,
        untilTextExists,
        untilTextExistsWithin,
        updateAvatar,
        updateName,
        user,
        waitForAppToSettle,
        waitUntilAttachmentStatus,
        waitUntilFileStatus,
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
        ChatMessagesStatusParameter(),
        DownloadStatusParameter(),
        ExceptionParameter(),
        FavoriteStatusParameter(),
        ImageFetchStatusParameter(),
        MutedStatusParameter(),
        OnlineStatusParameter(),
        PositionStatusParameter(),
        SearchCategoryParameter(),
        SelectionStatusParameter(),
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
Future<CustomUser> createUser(
  TestUser user,
  CustomWorld world, {
  UserPassword? password,
}) async {
  final provider = GraphQlProvider();
  final result = await provider.signUp();

  final CustomUser customUser = CustomUser(
    Session(
      result.createUser.session.token,
      result.createUser.session.expireAt,
    ),
    result.createUser.user.id,
    result.createUser.user.num,
  );

  world.sessions[user.name] = customUser;

  provider.token = result.createUser.session.token;
  await provider.updateUserName(UserName(user.name));
  if (password != null) {
    await provider.updateUserPassword(null, password);
  }
  provider.disconnect();

  return customUser;
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
