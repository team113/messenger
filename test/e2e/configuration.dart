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

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_gherkin/flutter_gherkin_with_driver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/api/backend/extension/credentials.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/main.dart' as app;
import 'package:messenger/provider/geo/geo.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/util/log.dart';
import 'package:messenger/util/platform_utils.dart';

import 'hook/performance.dart';
import 'hook/reset_app.dart';
import 'mock/geo.dart';
import 'mock/graphql.dart';
import 'mock/platform_utils.dart';
import 'parameters/appcast_version.dart';
import 'parameters/archived_status.dart';
import 'parameters/attachment.dart';
import 'parameters/availability_status.dart';
import 'parameters/credentials.dart';
import 'parameters/download_status.dart';
import 'parameters/enabled_status.dart';
import 'parameters/exception.dart';
import 'parameters/favorite_status.dart';
import 'parameters/fetch_status.dart';
import 'parameters/iterable_amount.dart';
import 'parameters/keys.dart';
import 'parameters/muted_status.dart';
import 'parameters/online_status.dart';
import 'parameters/position_status.dart';
import 'parameters/search_category.dart';
import 'parameters/selection_status.dart';
import 'parameters/sending_status.dart';
import 'parameters/users.dart';
import 'steps/account_is_remote.dart';
import 'steps/accounts.dart';
import 'steps/appcast.dart';
import 'steps/attach_file.dart';
import 'steps/cancel_uploading.dart';
import 'steps/change_chat_avatar.dart';
import 'steps/chat_is_favorite.dart';
import 'steps/chat_is_hidden.dart';
import 'steps/chat_is_muted.dart';
import 'steps/chats_availability.dart';
import 'steps/contact.dart';
import 'steps/contact_is_deleted.dart';
import 'steps/contact_is_favorite.dart';
import 'steps/dismiss_chat.dart';
import 'steps/dismiss_contact.dart';
import 'steps/download_file.dart';
import 'steps/drag_chat.dart';
import 'steps/drag_contact.dart';
import 'steps/favorite_group.dart';
import 'steps/go_to.dart';
import 'steps/go_to_link.dart';
import 'steps/has_blocked_users.dart';
import 'steps/has_contact.dart';
import 'steps/has_dialog.dart';
import 'steps/has_group.dart';
import 'steps/i_am_guest.dart';
import 'steps/in_chat.dart';
import 'steps/in_monolog.dart';
import 'steps/internet.dart';
import 'steps/language.dart';
import 'steps/long_press_chat.dart';
import 'steps/long_press_contact.dart';
import 'steps/long_press_message.dart';
import 'steps/long_press_widget.dart';
import 'steps/monolog_availability.dart';
import 'steps/name_is.dart';
import 'steps/open_chat_info.dart';
import 'steps/pick_file_in_picker.dart';
import 'steps/popup_windows.dart';
import 'steps/posts_images.dart';
import 'steps/reads_message.dart';
import 'steps/remove_chat_member.dart';
import 'steps/remove_message_attachment.dart';
import 'steps/rename_contact.dart';
import 'steps/reply_message.dart';
import 'steps/restart_app.dart';
import 'steps/right_click_message.dart';
import 'steps/right_click_widget.dart';
import 'steps/scroll_chat.dart';
import 'steps/scroll_until.dart';
import 'steps/see_archived_chat.dart';
import 'steps/see_avatar_title.dart';
import 'steps/see_blocked_users.dart';
import 'steps/see_chat_avatar.dart';
import 'steps/see_chat_members.dart';
import 'steps/see_chat_messages.dart';
import 'steps/see_chat_named.dart';
import 'steps/see_chat_position.dart';
import 'steps/see_chat_selection.dart';
import 'steps/see_chats.dart';
import 'steps/see_contact_dismissed.dart';
import 'steps/see_contact_position.dart';
import 'steps/see_contact_selection.dart';
import 'steps/see_contacts.dart';
import 'steps/see_dialog_position.dart';
import 'steps/see_draft.dart';
import 'steps/see_favorite_chat.dart';
import 'steps/see_favorite_contact.dart';
import 'steps/see_favorite_dialog.dart';
import 'steps/see_favorite_monolog.dart';
import 'steps/see_field_having_error.dart';
import 'steps/see_search_results.dart';
import 'steps/see_sessions.dart';
import 'steps/see_user_view.dart';
import 'steps/sees_as_online.dart';
import 'steps/sees_dialog.dart';
import 'steps/sees_muted_chat.dart';
import 'steps/sees_muted_dialog.dart';
import 'steps/select_text.dart';
import 'steps/sends_attachment.dart';
import 'steps/sends_message.dart';
import 'steps/set_credential.dart';
import 'steps/submit_field.dart';
import 'steps/tap_chat.dart';
import 'steps/tap_chat_in_search_view.dart';
import 'steps/tap_contact.dart';
import 'steps/tap_dropdown_item.dart';
import 'steps/tap_image.dart';
import 'steps/tap_message.dart';
import 'steps/tap_reply.dart';
import 'steps/tap_search_result.dart';
import 'steps/tap_text.dart';
import 'steps/tap_widget.dart';
import 'steps/tap_widget_n_times.dart';
import 'steps/text_field.dart';
import 'steps/update_app_version.dart';
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
        accountIsRemote,
        appcastIsAvailable,
        attachFile,
        blockedCountUsers,
        cancelFileDownload,
        cancelFileUpload,
        changeChatAvatar,
        chatIsFavorite,
        chatIsIndeedHidden,
        chatIsMuted,
        chatsAvailability,
        checkCopyText,
        contact,
        contactIsFavorite,
        contactIsIndeedDeleted,
        copyFromField,
        countUsers,
        deleteUser,
        dismissChat,
        dismissContact,
        downloadFile,
        dragChatDown,
        dragContactDown,
        eraseField,
        favoriteGroup,
        fillField,
        fillFieldN,
        fillFieldWithMyCredential,
        fillFieldWithRandomLogin,
        fillFieldWithUserCredential,
        goToUserLink,
        goToUserPage,
        hasContacts,
        hasDialogWithMe,
        hasDialogWithUser,
        hasFavoriteContacts,
        hasFavoriteGroups,
        hasGroupNamed,
        hasGroupNamedInArchive,
        hasGroupWithMembers,
        hasGroups,
        haveGroup1Named,
        haveGroup2,
        haveGroup2Named,
        haveGroupNamed,
        haveInternetWithDelay,
        haveInternetWithoutDelay,
        hasSession,
        iAm,
        iAmGuest,
        iAmInChatNamed,
        iAmInChatWith,
        iAmInMonolog,
        iTapChatGroup,
        iTapChatWith,
        iTapChatWithWithin,
        logout,
        longPressChat,
        longPressContact,
        longPressMessageByAttachment,
        longPressMessageByText,
        longPressMonolog,
        longPressWidget,
        monologAvailability,
        myNameIs,
        myNameIsNot,
        noInternetConnection,
        openChatInfo,
        pasteToField,
        pickFileInPicker,
        popupWindows,
        postsNAttachmentsToGroup,
        readsAllMessages,
        readsMessage,
        removeAccountInAccounts,
        removeGroupMember,
        removeMessageAttachment,
        renameContact,
        repliesToMessage,
        restartApp,
        returnToPreviousPage,
        rightClickMessage,
        rightClickWidget,
        scrollAndSee,
        scrollToBottom,
        scrollToTop,
        scrollUntilPresent,
        seeAccountInAccounts,
        seeAvatarTitleForChat,
        seeAvatarTitleInUserView,
        seeBlockedUsers,
        seeChatAsArchived,
        seeChatAsFavorite,
        seeChatAsMuted,
        seeChatAvatarAs,
        seeChatAvatarAsNone,
        seeChatInSearchResults,
        seeChatMembers,
        seeChatMessage,
        seeChatMessages,
        seeChatSelection,
        seeChatWithUserInSearchResults,
        seeContactAsDismissed,
        seeContactAsFavorite,
        seeContactPosition,
        seeContactSelection,
        seeCountChats,
        seeCountChatsOrMore,
        seeCountContacts,
        seeCountFavoriteChats,
        seeCountSessions,
        seeDialogAsFavorite,
        seeDialogAsMuted,
        seeDraftInDialog,
        seeFavoriteChatPosition,
        seeFavoriteDialogPosition,
        seeFieldHavingAnError,
        seeFieldHavingNoError,
        seeMonologAsFavorite,
        seeMonologInSearchResults,
        seeNamedChat,
        seeNoContactsDismissed,
        seesAs,
        seesDialogWithMe,
        seesNoDialogWithMe,
        seesNoDialogWithUser,
        seeTitleInUserView,
        seeUserInSearchResults,
        selectLanguage,
        selectMessageText,
        sendsAttachmentToMe,
        sendsCountMessages,
        sendsMessageToGroup,
        sendsMessageToMe,
        sendsMessageWithException,
        setCredential,
        setMyCredential,
        signInAs,
        signsOutSession,
        submitField,
        tapAccountInAccounts,
        tapChat,
        tapContact,
        tapDropdownItem,
        tapLastImageInChat,

        // TODO: Fix `gherkin` matching `tapMessage` instead.
        tapReply,

        tapMessage,
        tapText,
        tapUserInSearchResults,
        tapWidget,
        tapWidgetNTimes,
        twoContacts,
        twoUsers,
        untilAttachmentExists,
        untilAttachmentFetched,
        untilChatExists,
        untilContactExists,
        untilMessageExists,
        untilTextExists,
        untilTextExistsWithin,
        updateAppVersion,
        updateAvatar,
        updateName,
        user,
        userWithPassword,
        waitForAppToSettle,
        waitUntilAttachmentStatus,
        waitUntilFileStatus,
        waitUntilKeyExists,
        waitUntilMessageStatus,
      ]
      ..hooks = [
        ResetAppHook(),

        // [IntegrationTestWidgetsFlutterBinding.traceAction] being used is only
        // supported on Dart VM platforms.
        if (!PlatformUtils.isWeb) PerformanceHook(),
      ]
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
        AppcastVersionParameter(),
        ArchivedStatusParameter(),
        AttachmentTypeParameter(),
        AvailabilityStatusParameter(),
        CredentialsParameter(),
        DownloadStatusParameter(),
        EnabledParameter(),
        ExceptionParameter(),
        FavoriteStatusParameter(),
        ImageFetchStatusParameter(),
        IterableAmountParameter(),
        MessageSentStatusParameter(),
        MutedStatusParameter(),
        OnlineStatusParameter(),
        PositionStatusParameter(),
        SearchCategoryParameter(),
        SelectionStatusParameter(),
        UsersParameter(),
        WidgetKeyParameter(),
      ]
      ..tagExpression = 'not @disabled and not @internet'
      // ..tagExpression = '@problem'
      ..createWorld = (config) => Future.sync(() => CustomWorld());

/// Application's initialization function.
Future<void> appInitializationFn(World world) {
  PlatformUtils = PlatformUtilsMock();
  Get.put<GeoLocationProvider>(MockGeoLocationProvider());
  Get.put<GraphQlProvider>(MockGraphQlProvider());

  FlutterError.onError = (details) {
    final String exception = details.exception.toString();

    // Silence the `GlobalKey` being duplicated errors:
    // https://github.com/google/flutter.widgets/issues/137
    if (exception.contains('Duplicate GlobalKey detected in widget tree.') ||
        exception.contains('Multiple widgets used the same GlobalKey.')) {
      return;
    }

    FlutterError.presentError(details);
  };

  return Future.sync(app.main);
}

/// Creates a new [Session] for the provided [user].
Future<CustomUser> createUser({
  TestUser? user,
  CustomWorld? world,
  UserPassword? password,
}) async {
  final GraphQlProvider provider = GraphQlProvider()
    ..client.withWebSocket = false;

  final result = await provider.signUp();
  final success = result as SignUp$Mutation$CreateUser$CreateSessionOk;

  final CustomUser customUser = CustomUser(success.toModel(), success.user.num);

  if (user != null && world != null) {
    world.sessions[user.name] = [customUser];

    provider.token = success.accessToken.secret;
    await provider.updateUserName(UserName(user.name));
    if (password != null) {
      await provider.updateUserPassword(newPassword: password);
      world.sessions[user.name]?.password = password;

      final result = await provider.signIn(
        credentials: MyUserCredentials(password: password),
        identifier: MyUserIdentifier(num: customUser.userNum),
      );
      world.sessions[user.name]?.credentials = result.toModel();
    }
  }

  Log.info(
    'createUser() -> Created user `${user?.name}` with password: `$password` -> $customUser',
    'E2E',
  );

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
