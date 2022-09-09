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
