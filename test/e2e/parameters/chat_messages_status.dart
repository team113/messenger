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

import 'package:gherkin/gherkin.dart';

/// Status of the presence of messages in the [Chat].
enum ChatMessagesStatus { no, some }

/// [CustomParameter] representing a [ChatMessagesStatusParameter].
class ChatMessagesStatusParameter extends CustomParameter<ChatMessagesStatus> {
  ChatMessagesStatusParameter()
      : super(
          'messages',
          RegExp(
            '(${ChatMessagesStatus.values.map((e) => e.name).join('|')})',
            caseSensitive: false,
          ),
          (c) => ChatMessagesStatus.values.firstWhere((e) => e.name == c),
        );
}
