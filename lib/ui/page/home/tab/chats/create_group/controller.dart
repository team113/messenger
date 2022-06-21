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

import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
import '/domain/service/user.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';

export 'view.dart';

/// Controller of the group creation overlay.
class CreateGroupController extends GetxController {
  CreateGroupController(
      this.pop, this._chatService, this._contactService, this._userService);

  /// Status of a [createGroup] completion.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning no [createGroup] is executing.
  /// - `status.isLoading`, meaning [createGroup] is executing.
  /// - `status.isError`, meaning [createGroup] got an error.
  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.empty());

  /// Reactive list of the selected [ChatContact]s.
  final RxList<Rx<ChatContact>> selectedContacts = RxList<Rx<ChatContact>>([]);

  /// Reactive list of the selected [User]s.
  final RxList<User> selectedUsers = RxList<User>([]);

  /// Name to assign to the created [Chat]-group.
  String groupChatName = '';

  /// [Chat]s service used to create a group [Chat].
  final ChatService _chatService;

  /// [ChatContact]s service used to get [contacts] list.
  final ContactService _contactService;

  /// [User]s service fetching the [User]s in [getUser] method.
  final UserService _userService;

  /// Pops the [CreateGroupView] this controller is bound to.
  final Function() pop;

  /// Returns the current reactive map of [ChatContact]s.
  RxObsMap<ChatContactId, Rx<ChatContact>> get contacts =>
      _contactService.contacts;

  /// Creates a group [Chat] with [selectedContacts] and [groupChatName].
  Future<void> createGroup() async {
    status.value = RxStatus.loading();
    try {
      ChatName? chatName;
      if (groupChatName.isNotEmpty) {
        chatName = ChatName(groupChatName);
      }

      var chat = (await _chatService.createGroupChat(
        [
          ...selectedContacts.expand((e) => e.value.users.map((u) => u.id)),
          ...selectedUsers.map((e) => e.id),
        ],
        name: chatName,
      ));

      router.chat(chat.chat.value.id);
      pop();
    } on CreateGroupChatException catch (e) {
      status.value = RxStatus.error(e.toMessage());
    } on FormatException catch (_) {
      status.value = RxStatus.empty();
      MessagePopup.error('err_incorrect_chat_name'.tr);
    } catch (e) {
      status.value = RxStatus.empty();
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Returns an [User] from [UserService] by the provided [id].
  Future<Rx<User>?> getUser(UserId id) => _userService.get(id);

  /// Selects or unselects the provided [contact].
  void selectContact(Rx<ChatContact> contact) {
    if (selectedContacts.contains(contact)) {
      selectedContacts.remove(contact);
    } else {
      selectedContacts.add(contact);
    }
  }

  /// Selects the specified [user].
  void selectUser(User user) {
    if (!selectedUsers.any((u) => u.id.val == user.id.val)) {
      selectedUsers.add(user);
    }
  }

  /// Unselects the specified [user].
  void unselectUser(User user) {
    if (selectedUsers.contains(user)) {
      selectedUsers.remove(user);
    }
  }
}
