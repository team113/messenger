import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart'
    show
        CallAlreadyJoinedException,
        CallAlreadyExistsException,
        CallIsInPopupException;
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/domain/service/call.dart';
import '/domain/service/contact.dart';
import '/domain/service/user.dart';
import '/provider/gql/exceptions.dart' show UpdateChatContactNameException;
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';

export 'view.dart';

/// Controller of the `HomeTab.contacts` tab.
class ContactsTabController extends GetxController {
  ContactsTabController(
    this._chatRepository,
    this._contactService,
    this._userService,
    this._calls,
  );

  /// [TextFieldState] of a [ChatContact.name].
  late TextFieldState contactName;

  /// [ChatContactId] of a [ChatContact] to rename.
  final Rx<ChatContactId?> contactToChangeNameOf = Rx<ChatContactId?>(null);

  /// [Chat] repository used to create a dialog [Chat].
  final AbstractChatRepository _chatRepository;

  /// Address book used to get [ChatContact]s list.
  final ContactService _contactService;

  /// [User]s service fetching the [User]s in [getUser] method.
  final UserService _userService;

  /// Call service used to start a [ChatCall].
  final CallService _calls;

  /// Returns current reactive [ChatContact]s map.
  RxObsMap<ChatContactId, Rx<ChatContact>> get contacts =>
      _contactService.contacts;

  /// Returns the current reactive favorite [ChatContact]s map.
  RxMap<ChatContactId, Rx<ChatContact>> get favorites =>
      _contactService.favorites;

  /// List of [StreamSubscription] that indicates interest of this controller
  ///  in [User]s updates
  List<StreamSubscription?>? _usersSubscriptions;

  /// Indicates whether [ContactService] is ready to be used.
  RxBool get contactsReady => _contactService.isReady;

  @override
  void onInit() {
    contactName = TextFieldState(
      onChanged: (s) async {
        s.error.value = null;

        Rx<ChatContact>? contact = contacts.values.firstWhereOrNull(
                (e) => e.value.id == contactToChangeNameOf.value) ??
            favorites.values.firstWhereOrNull(
                (e) => e.value.id == contactToChangeNameOf.value);
        if (contact == null) return;

        if (contact.value.name.val == s.text) {
          contactToChangeNameOf.value = null;
          return;
        }

        UserName? name;

        try {
          name = UserName(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.tr;
        }

        if (s.error.value == null) {
          try {
            s.status.value = RxStatus.loading();
            s.editable.value = false;

            await _contactService.changeContactName(
              contactToChangeNameOf.value!,
              name!,
            );

            s.clear();
            contactToChangeNameOf.value = null;
          } on UpdateChatContactNameException catch (e) {
            s.error.value = e.toMessage();
          } catch (e) {
            s.error.value = e.toString();
            rethrow;
          } finally {
            s.editable.value = true;
            s.status.value = RxStatus.empty();
          }
        }
      },
      onSubmitted: (s) {
        var contact = contacts.values.firstWhereOrNull(
                (e) => e.value.id == contactToChangeNameOf.value) ??
            favorites.values.firstWhereOrNull(
                (e) => e.value.id == contactToChangeNameOf.value);
        if (contact?.value.name.val == s.text) {
          contactToChangeNameOf.value = null;
          return;
        }
      },
    );
    _subscribeForUsersUpdates();
    super.onInit();
  }

  /// Starts an audio [ChatCall] with a [to] [User].
  Future<void> startAudioCall(User to) => _call(to, false);

  /// Starts a video [ChatCall] with a [to] [User].
  Future<void> startVideoCall(User to) => _call(to, true);

  /// Adds a [user] to the [ContactService]'s address book.
  void addToContacts(User user) {
    _contactService.createChatContact(user);
  }

  /// Removes a [contact] from the [ContactService]'s address book.
  Future<void> deleteFromContacts(ChatContact contact) async {
    if (await MessagePopup.alert('alert_are_you_sure'.tr) == true) {
      await _contactService.deleteContact(contact.id);
    }
  }

  /// Returns an [User] from the [UserService] by the provided [id].
  Future<RxUser?> getUser(UserId id) => _userService.get(id);

  /// Starts a [ChatCall] with a [user] [withVideo] or not.
  ///
  /// Creates a dialog [Chat] with a [user] if it doesn't exist yet.
  Future<void> _call(User user, bool withVideo) async {
    Chat? dialog = user.dialog;
    dialog ??= (await _chatRepository.createDialogChat(user.id)).chat.value;
    try {
      await _calls.call(dialog.id, withVideo: withVideo);
    } on CallAlreadyJoinedException catch (e) {
      MessagePopup.error(e);
    } on CallAlreadyExistsException catch (e) {
      MessagePopup.error(e);
    } on CallIsInPopupException catch (e) {
      MessagePopup.error(e);
    }
  }

  /// Fills [_usersSubscriptions] list by [StreamSubscription]s of users that
  /// are aviable in [contacts]
  Future<void> _subscribeForUsersUpdates() async {
    _usersSubscriptions = [];
    for (var contact in contacts.values) {
      for (var user in contact.value.users) {
        _usersSubscriptions!
            .add((await getUser(user.id))?.updates.listen((event) {}));
      }
    }
  }
}
