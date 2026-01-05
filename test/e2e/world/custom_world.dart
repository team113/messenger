// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:async';

import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:flutter/services.dart' show ClipboardData;
import 'package:messenger/api/backend/extension/credentials.dart';
import 'package:messenger/api/backend/schema.graphql.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/contact.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/provider/gql/graphql.dart';

/// [FlutterWidgetTesterWorld] storing a custom state during a single test.
class CustomWorld extends FlutterWidgetTesterWorld {
  /// [Map] of [Session]s simulating [User]s identified by their names.
  final Map<String, List<CustomUser>> sessions = {};

  /// [Map] of group [Chat]s identified by their names.
  final Map<String, ChatId> groups = {};

  /// [Map] of [ChatContact]s identified by their names.
  final Map<String, ChatContactId> contacts = {};

  /// [ClipboardData] currently stored in this [CustomWorld].
  ClipboardData? clipboard;

  /// [UserId] of the currently authenticated [MyUser].
  UserId? me;

  /// [UserLogin] being a random one.
  UserLogin? randomLogin;
}

/// Extension adding quick access to the first [CustomUser] in the [List].
extension CustomUserHelpers on List<CustomUser> {
  /// Returns the [UserId] of the first [CustomUser].
  UserId get userId => first.userId;

  /// Returns the [AccessTokenSecret] of the first [CustomUser].
  AccessTokenSecret? get token => firstOrNull?.token;

  /// Returns the [UserNum] of the first [CustomUser].
  UserNum get userNum => first.userNum;

  /// Returns the [Credentials] of the first [CustomUser].
  FutureOr<Credentials> get credentials => first.credentials;

  /// Returns the [ChatId] of the first [CustomUser].
  ChatId? get dialog => firstOrNull?.dialog;

  /// Sets the [ChatId] of the first [CustomUser] to the [chatId].
  set dialog(ChatId? chatId) => firstOrNull?.dialog = chatId;

  /// Returns the [UserPassword] of the first [CustomUser].
  UserPassword? get password => firstOrNull?.password;

  /// Sets the [UserPassword] of the first [CustomUser] to the [value].
  set password(UserPassword? value) => firstOrNull?.password = value;

  /// sets the [Credentials] of the first [CustomUser] to the [creds].
  set credentials(FutureOr<Credentials?> creds) =>
      firstOrNull?.credentials = creds;
}

/// [Session] with some additional info about the [User] it represents.
class CustomUser {
  CustomUser(Credentials this._credentials, this.userNum)
    : userId = _credentials.userId;

  /// [UserNum] of this [CustomUser].
  final UserNum userNum;

  /// [UserId] of this [CustomUser].
  final UserId userId;

  /// [ChatDirectLinkSlug] of this [CustomUser], if any.
  ChatDirectLinkSlug? slug;

  /// [UserPassword] this [CustomUser] uses, if any.
  UserPassword? password;

  /// ID of the [Chat]-dialog with the authenticated [MyUser].
  ChatId? dialog;

  /// [Credentials] of this [CustomUser].
  ///
  /// Might be `null`, if authorization of this [CustomUser] is lost.
  Credentials? _credentials;

  /// Sets the [Credentials] to the provided [creds].
  set credentials(FutureOr<Credentials?> creds) {
    if (creds is Credentials?) {
      _credentials = creds;
    } else {
      creds.then((v) => _credentials = v);
    }
  }

  /// Returns the [Credentials] of this [CustomUser].
  FutureOr<Credentials> get credentials {
    if (_credentials == null) {
      return Future(() async {
        final GraphQlProvider provider = GraphQlProvider()
          ..client.withWebSocket = false;

        final response = await provider.signIn(
          identifier: MyUserIdentifier(num: userNum),
          credentials: MyUserCredentials(
            password: password ?? UserPassword('123'),
          ),
        );
        _credentials = response.toModel();

        provider.disconnect();

        return _credentials!;
      });
    }

    return _credentials!;
  }

  /// Returns the [AccessToken] of this [CustomUser].
  AccessTokenSecret? get token => _credentials?.access.secret;

  @override
  String toString() {
    return 'CustomUser($userId, $userNum, slug: $slug, password: $password, dialog: $dialog)';
  }
}
