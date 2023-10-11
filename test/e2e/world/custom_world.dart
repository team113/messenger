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

import 'package:flutter/services.dart' show ClipboardData;
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/contact.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';

/// [FlutterWidgetTesterWorld] storing a custom state during a single test.
class CustomWorld extends FlutterWidgetTesterWorld {
  /// [Map] of [Session]s simulating [User]s identified by their names.
  final Map<String, CustomUser> sessions = {};

  /// [Map] of group [Chat]s identified by their names.
  final Map<String, ChatId> groups = {};

  /// [Map] of [ChatContact]s identified by their names.
  final Map<String, ChatContactId> contacts = {};

  /// [ClipboardData] currently stored in this [CustomWorld].
  ClipboardData? clipboard;

  /// [UserId] of the currently authenticated [MyUser].
  UserId? me;
}

/// [Session] with some additional info about the [User] it represents.
class CustomUser {
  CustomUser(this.credentials, this.userNum);

  /// [Credentials] of this [CustomUser].
  final Credentials credentials;

  /// [UserNum] of this [CustomUser].
  final UserNum userNum;

  /// ID of the [Chat]-dialog with the authenticated [MyUser].
  ChatId? dialog;

  /// [UserId] of this [CustomUser].
  UserId get userId => credentials.userId;

  /// Returns the [AccessToken] of this [CustomUser].
  AccessToken get token => credentials.session.token;
}
