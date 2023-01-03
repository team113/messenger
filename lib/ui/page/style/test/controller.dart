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

import 'package:get/get.dart';

class StyleController extends GetxController {
  final RxList<ListElement> elements = RxList();
}

class ChatItem {
  const ChatItem(this.string);
  final String string;
}

abstract class ListElement {
  const ListElement();
}

class ChatMessageElement extends ListElement {
  const ChatMessageElement(this.item);
  final Rx<ChatItem> item;
}

class ChatCallElement extends ListElement {
  const ChatCallElement(this.item);
  final Rx<ChatItem> item;
}

class ChatMemberInfoElement extends ListElement {
  const ChatMemberInfoElement(this.item);
  final Rx<ChatItem> item;
}

class ChatForwardElement extends ListElement {
  const ChatForwardElement(this.forwards, this.note);
  final RxList<Rx<ChatItem>> forwards;
  final Rx<ChatItem>? note;
}

class DateTimeElement extends ListElement {
  const DateTimeElement(this.item);
  final Rx<ChatItem> item;
}
