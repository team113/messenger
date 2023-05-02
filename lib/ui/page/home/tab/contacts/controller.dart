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

import 'dart:async';

import 'package:async/async.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart'
    show
        CallAlreadyJoinedException,
        CallAlreadyExistsException,
        CallIsInPopupException;
import '/domain/repository/contact.dart';
import '/domain/repository/settings.dart';
import '/domain/repository/user.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
import '/domain/service/user.dart';
import '/provider/gql/exceptions.dart'
    show FavoriteChatContactException, UnfavoriteChatContactException;
import '/routes.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/home/tab/chats/controller.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';

export 'view.dart';

/// Controller of the `HomeTab.contacts` tab.
class ContactsTabController extends GetxController {
  ContactsTabController(
    this._chatService,
    this._contactService,
    this._calls,
    this._settingsRepository,
    this._userService,
  );

  /// Reactive list of sorted [ChatContact]s.
  final RxList<RxChatContact> contacts = RxList();

  /// Reactive list of favorited [ChatContact]s.
  final RxList<RxChatContact> favorites = RxList();

  /// [SearchController] for searching [User]s and [ChatContact]s.
  final Rx<SearchController?> search = Rx(null);

  /// [ListElement]s representing the [search] results visually.
  final RxList<ListElement> elements = RxList([]);

  /// Indicator whether an ongoing reordering is happening or not.
  ///
  /// Used to discard a broken [FadeInAnimation].
  final RxBool reordering = RxBool(false);

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// Indicator whether multiple [ChatContact]s selection is active.
  final RxBool selecting = RxBool(false);

  /// Reactive list of [ChatContactId]s of the selected [ChatContact]s.
  final RxList<ChatContactId> selectedContacts = RxList();

  /// [Timer] displaying the [contacts] and [favorites] being fetched when it
  /// becomes `null`.
  late final Rx<Timer?> fetching = Rx(
    Timer(2.seconds, () => fetching.value = null),
  );

  final GlobalKey moreKey = GlobalKey();

  /// [Chat]s service used to create a dialog [Chat].
  final ChatService _chatService;

  /// Address book used to get [ChatContact]s list.
  final ContactService _contactService;

  /// [User]s service used in [SearchController].
  final UserService _userService;

  /// Call service used to start a [ChatCall].
  final CallService _calls;

  /// Settings repository maintaining the [ApplicationSettings].
  final AbstractSettingsRepository _settingsRepository;

  /// [Worker]s to [RxChatContact.user] reacting on its changes.
  final Map<ChatContactId, Worker> _rxUserWorkers = {};

  /// [Worker]s to [RxUser.user] reacting on its changes.
  final Map<UserId, Worker> _userWorkers = {};

  /// [StreamSubscription]s to the [contacts] updates.
  StreamSubscription? _contactsSubscription;

  /// [StreamSubscription]s to the [favorites] updates.
  StreamSubscription? _favoritesSubscription;

  /// Subscription for [SearchController.users] and [SearchController.contacts]
  /// changes updating the [elements].
  StreamSubscription? _searchSubscription;

  /// Returns the [RxStatus] of the [contacts] and [favorites] fetching.
  Rx<RxStatus> get status => _contactService.status;

  /// Indicates whether [contacts] should be sorted by their names or otherwise
  /// by their [User.lastSeenAt] dates.
  bool get sortByName =>
      _settingsRepository.applicationSettings.value?.sortContactsByName ?? true;

  @override
  void onInit() {
    contacts.value = _contactService.contacts.values.toList();
    favorites.value = _contactService.favorites.values.toList();
    _sortContacts();
    _sortFavorites();

    _initUsersUpdates();

    HardwareKeyboard.instance.addHandler(_escapeListener);
    if (PlatformUtils.isMobile) {
      BackButtonInterceptor.add(_onBack, ifNotYetIntercepted: true);
    }

    super.onInit();
  }

  @override
  void onClose() {
    for (RxChatContact contact in [...contacts, ...favorites]) {
      contact.user.value?.stopUpdates();
    }

    _contactsSubscription?.cancel();
    _favoritesSubscription?.cancel();
    _rxUserWorkers.forEach((_, v) => v.dispose());
    _userWorkers.forEach((_, v) => v.dispose());

    HardwareKeyboard.instance.removeHandler(_escapeListener);
    if (PlatformUtils.isMobile) {
      BackButtonInterceptor.remove(_onBack);
    }

    fetching.value?.cancel();

    super.onClose();
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
    await _contactService.deleteContact(contact.id);
  }

  /// Deletes the [selectedContacts] from the authenticated [MyUser]'s address
  /// book.
  Future<void> deleteContacts() async {
    selecting.value = false;
    router.navigation.value = !selecting.value;

    try {
      final Iterable<Future> futures =
          selectedContacts.map((e) => _contactService.deleteContact(e));
      await Future.wait(futures);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    } finally {
      selectedContacts.clear();
    }
  }

  /// Marks the specified [ChatContact] identified by its [id] as favorited.
  Future<void> favoriteContact(
    ChatContactId id, [
    ChatContactFavoritePosition? position,
  ]) async {
    try {
      await _contactService.favoriteChatContact(id, position);
    } on FavoriteChatContactException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Removes the specified [ChatContact] identified by its [id] from the
  /// favorites.
  Future<void> unfavoriteContact(ChatContactId id) async {
    try {
      await _contactService.unfavoriteChatContact(id);
    } on UnfavoriteChatContactException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Reorders a [ChatContact] from the [from] position to the [to] position.
  Future<void> reorderContact(int from, int to) async {
    double position;

    if (to <= 0) {
      position = favorites.first.contact.value.favoritePosition!.val / 2;
    } else if (to >= favorites.length) {
      position = favorites.last.contact.value.favoritePosition!.val * 2;
    } else {
      position = (favorites[to].contact.value.favoritePosition!.val +
              favorites[to - 1].contact.value.favoritePosition!.val) /
          2;
    }

    if (to > from) {
      to--;
    }

    final ChatContactId contactId = favorites[from].id;
    favorites.insert(to, favorites.removeAt(from));

    await favoriteContact(contactId, ChatContactFavoritePosition(position));
  }

  /// Toggles the [sortByName] sorting the [contacts].
  void toggleSorting() {
    _settingsRepository.setSortContactsByName(!sortByName);
    _sortContacts();
  }

  /// Enables and initializes or disables and disposes the [search].
  void toggleSearch([bool enable = true]) {
    search.value?.onClose();
    search.value?.search.focus.removeListener(_disableSearchFocusListener);
    _searchSubscription?.cancel();

    if (enable) {
      search.value = SearchController(
        _chatService,
        _userService,
        _contactService,
        categories: const [
          SearchCategory.contact,
          SearchCategory.user,
        ],
      )..onInit();

      _searchSubscription = StreamGroup.merge([
        search.value!.contacts.stream,
        search.value!.users.stream,
      ]).listen((_) {
        elements.clear();

        if (search.value?.contacts.isNotEmpty == true) {
          elements.add(const DividerElement(SearchCategory.contact));
          for (RxChatContact c in search.value!.contacts.values) {
            elements.add(ContactElement(c));
          }
        }

        if (search.value?.users.isNotEmpty == true) {
          elements.add(const DividerElement(SearchCategory.user));
          for (RxUser c in search.value!.users.values) {
            elements.add(UserElement(c));
          }
        }
      });

      search.value!.search.focus.addListener(_disableSearchFocusListener);
      search.value!.search.focus.requestFocus();
    } else {
      search.value = null;
      elements.clear();
    }
  }

  /// Toggles the [ChatContact]s selection.
  void toggleSelecting() {
    selecting.toggle();
    router.navigation.value = !selecting.value;
    selectedContacts.clear();
  }

  /// Selects or unselects the provided [contact], meaning adding or removing it
  /// from the [selectedContacts].
  void selectContact(RxChatContact contact) {
    if (selectedContacts.contains(contact.id)) {
      selectedContacts.remove(contact.id);
    } else {
      selectedContacts.add(contact.id);
    }
  }

  /// Starts a [ChatCall] with a [user] [withVideo] or not.
  ///
  /// Creates a dialog [Chat] with a [user] if it doesn't exist yet.
  Future<void> _call(User user, bool withVideo) async {
    try {
      await _calls.call(user.dialog, withVideo: withVideo);
    } on CallAlreadyJoinedException catch (e) {
      MessagePopup.error(e);
    } on CallAlreadyExistsException catch (e) {
      MessagePopup.error(e);
    } on CallIsInPopupException catch (e) {
      MessagePopup.error(e);
    }
  }

  /// Maintains an interest in updates of every [RxChatContact.user] in the
  /// [contacts] list.
  void _initUsersUpdates() {
    /// States an interest in updates of the specified [RxChatContact.user].
    void listen(RxChatContact c) {
      RxUser? rxUser = c.user.value?..listenUpdates();
      _rxUserWorkers[c.id] = ever(c.user, (RxUser? user) {
        if (rxUser?.id != user?.id) {
          rxUser?.stopUpdates();
          rxUser = user?..listenUpdates();
          _userWorkers.remove(user?.id)?.dispose();
        }

        if (user != null) {
          _populateSortingWorker(user.user);
          _sortContacts();
        }
      });

      if (c.user.value != null) {
        _populateSortingWorker(c.user.value!.user);
      }
    }

    contacts.forEach(listen);

    _contactsSubscription = _contactService.contacts.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          contacts.add(e.value!);
          _sortContacts();
          listen(e.value!);
          break;

        case OperationKind.removed:
          e.value?.user.value?.stopUpdates();
          contacts.removeWhere((c) => c.id == e.key);
          _userWorkers.remove(e.key)?.dispose();
          _rxUserWorkers.remove(e.key)?.dispose();
          break;

        case OperationKind.updated:
          _sortContacts();
          break;
      }
    });

    favorites.forEach(listen);

    _favoritesSubscription = _contactService.favorites.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          favorites.add(e.value!);
          _sortFavorites();
          listen(e.value!);
          break;

        case OperationKind.removed:
          e.value?.user.value?.stopUpdates();
          _userWorkers.remove(e.key)?.dispose();
          _rxUserWorkers.remove(e.key)?.dispose();
          favorites.removeWhere((c) => c.contact.value.id == e.key);
          break;

        case OperationKind.updated:
          _sortFavorites();
          break;
      }
    });
  }

  /// Populates a [Worker] sorting the [contacts] on the [User.online] and
  /// [User.lastSeenAt] changes of the provided [user].
  void _populateSortingWorker(Rx<User> user) {
    final User u = user.value;

    if (_userWorkers[u.id] == null) {
      bool online = u.online;
      PreciseDateTime? lastSeenAt = u.lastSeenAt;

      _userWorkers[u.id] = ever(user, (User u) {
        if (!sortByName && (online != u.online || lastSeenAt != u.lastSeenAt)) {
          online = u.online;
          lastSeenAt = u.lastSeenAt;
          _sortContacts();
        }
      });
    }
  }

  /// Sorts the [contacts] by their names or by their [User.lastSeenAt] based on
  /// the [sortByName] indicator.
  void _sortContacts() {
    contacts.sort((a, b) {
      if (sortByName == true) {
        return a.contact.value.name.val.compareTo(b.contact.value.name.val);
      } else {
        final User? userA = a.user.value?.user.value;
        final User? userB = b.user.value?.user.value;

        if (userA?.online == true && userB?.online == false) {
          return -1;
        } else if (userA?.online == false && userB?.online == true) {
          return 1;
        } else {
          if (userB?.lastSeenAt == null || userA?.lastSeenAt == null) {
            return 0;
          } else {
            return userB!.lastSeenAt!.compareTo(userA!.lastSeenAt!);
          }
        }
      }
    });
  }

  /// Sorts the [favorites] by the [ChatContact.favoritePosition].
  void _sortFavorites() {
    favorites.sort(
      (a, b) => a.contact.value.favoritePosition!
          .compareTo(b.contact.value.favoritePosition!),
    );
  }

  /// Disables the [search], if its focus is lost or its query is empty.
  void _disableSearchFocusListener() {
    if (search.value?.search.focus.hasFocus == false &&
        search.value?.search.text.isEmpty == true) {
      toggleSearch(false);
    }
  }

  /// Closes the [search]ing on the [LogicalKeyboardKey.escape] events.
  ///
  /// Intended to be used as a [HardwareKeyboard] listener.
  bool _escapeListener(KeyEvent e) {
    if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
      if (search.value != null) {
        toggleSearch(false);
        return true;
      }
    }

    return false;
  }

  /// Invokes [toggleSearch], if [search]ing.
  ///
  /// Intended to be used as a [BackButtonInterceptor] callback, thus returns
  /// `true`, if back button should be intercepted, or otherwise returns
  /// `false`.
  bool _onBack(bool _, RouteInfo __) {
    if (search.value != null) {
      toggleSearch(false);
      return true;
    }

    return false;
  }
}
