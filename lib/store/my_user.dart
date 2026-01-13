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

import 'dart:async';
import 'dart:math';

import 'package:async/async.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';

import '/api/backend/extension/chat.dart';
import '/api/backend/extension/my_user.dart';
import '/api/backend/extension/user.dart';
import '/api/backend/schema.dart';
import '/domain/model/attachment.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/native_file.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model/user.dart';
import '/domain/model/welcome_message.dart';
import '/domain/repository/my_user.dart';
import '/domain/repository/user.dart';
import '/domain/service/disposable_service.dart';
import '/provider/drift/account.dart';
import '/provider/drift/my_user.dart';
import '/provider/gql/exceptions.dart';
import '/provider/gql/graphql.dart';
import '/util/backoff.dart';
import '/util/event_pool.dart';
import '/util/log.dart';
import '/util/new_type.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import '/util/stream_utils.dart';
import '/util/web/web_utils.dart';
import 'blocklist.dart';
import 'event/changed.dart';
import 'event/my_user.dart';
import 'model/my_user.dart';
import 'user.dart';

/// [MyUser] repository.
class MyUserRepository extends IdentityDependency
    implements AbstractMyUserRepository {
  MyUserRepository(
    this._graphQlProvider,
    this._driftMyUser,
    this._blocklistRepository,
    this._userRepository,
    this._accountLocal, {
    required super.me,
  });

  @override
  final Rx<MyUser?> myUser = Rx(null);

  @override
  final RxObsMap<UserId, Rx<MyUser>> profiles = RxObsMap();

  /// Callback that is called when [MyUser] is deleted.
  late final void Function() onUserDeleted;

  /// Callback that is called when [MyUser]'s password is changed.
  late final void Function() onPasswordUpdated;

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// Local storage of the [MyUser]s.
  final MyUserDriftProvider _driftMyUser;

  /// Storage providing the [UserId] of the currently active [MyUser].
  final AccountDriftProvider _accountLocal;

  /// Blocked [User]s repository, used to update it on the appropriate events.
  final BlocklistRepository _blocklistRepository;

  /// [User]s repository, used to put the fetched [MyUser] into it.
  final UserRepository _userRepository;

  /// [MyUserDriftProvider.watch] subscription.
  StreamSubscription? _localSubscription;

  /// [_myUserRemoteEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamQueue<MyUserEventsVersioned>? _remoteSubscription;

  /// [GraphQlProvider.keepOnline] subscription keeping the [MyUser] online.
  StreamQueue? _keepOnlineSubscription;

  /// Subscription to the [PlatformUtilsImpl.onFocusChanged] initializing and
  /// canceling the [_keepOnlineSubscription].
  StreamSubscription? _onFocusChanged;

  /// Indicator whether this [MyUserRepository] has been disposed, meaning no
  /// requests should be made.
  bool _disposed = false;

  /// [EventPool] debouncing [MyUserField] related [MyUserEvent]s handling.
  final EventPool<MyUserField> _pool = EventPool();

  /// [Timer] retrying [_initLocalSubscription] when [_accountLocal] returns no
  /// [UserId].
  Timer? _localSubscriptionRetry;

  /// Returns the currently active [DtoMyUser] from the storage.
  Future<DtoMyUser?> get _active async {
    final UserId? userId = await _accountLocal.read();
    final DtoMyUser? saved = userId != null
        ? await _driftMyUser.read(userId)
        : null;

    return saved;
  }

  @override
  Future<void> init({
    required Function() onUserDeleted,
    required Function() onPasswordUpdated,
  }) async {
    Log.debug(
      'init(onUserDeleted, onPasswordUpdated)',
      '$runtimeType($hashCode)',
    );

    this.onPasswordUpdated = onPasswordUpdated;
    this.onUserDeleted = onUserDeleted;

    if (!PlatformUtils.isDesktop) {
      _onFocusChanged = PlatformUtils.onFocusChanged.listen((focused) {
        if (focused) {
          if (_keepOnlineSubscription == null) {
            _initKeepOnlineSubscription();
          }
        } else {
          _keepOnlineSubscription?.close(immediate: true);
          _keepOnlineSubscription = null;
        }
      });
    }
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType($hashCode)');

    _disposed = true;
    _localSubscription?.cancel();
    _remoteSubscription?.close(immediate: true);
    _keepOnlineSubscription?.close(immediate: true);
    _onFocusChanged?.cancel();
    _pool.dispose();
    _localSubscriptionRetry?.cancel();

    super.onClose();
  }

  @override
  void onIdentityChanged(UserId me) async {
    super.onIdentityChanged(me);

    Log.debug('onIdentityChanged($me)', '$runtimeType');

    _localSubscription?.cancel();
    _remoteSubscription?.close(immediate: true);
    _keepOnlineSubscription?.close(immediate: true);
    _onFocusChanged?.cancel();
    _pool.dispose();
    _localSubscriptionRetry?.cancel();

    _active.then((v) => myUser.value = v?.value ?? myUser.value);

    _initProfiles();
    _initLocalSubscription();

    if (!me.isLocal) {
      _initRemoteSubscription();
    }

    if (PlatformUtils.isDesktop || await PlatformUtils.isFocused) {
      _initKeepOnlineSubscription();
    }
  }

  @override
  Future<void> updateUserName(UserName? name) async {
    Log.debug('updateUserName($name)', '$runtimeType');

    await _debounce(
      field: MyUserField.name,
      current: () => myUser.value?.name,
      saved: () async => (await _active)?.value.name,
      value: name,
      mutation: (v, _) async {
        return await Backoff.run(
          () async {
            return await _graphQlProvider.updateUserName(v);
          },
          retryIf: (e) => e.isNetworkRelated,
          retries: 10,
        );
      },
      update: (v, _) => myUser.update((u) => u?.name = v),
    );
  }

  @override
  Future<void> updateUserStatus(UserTextStatus? status) async {
    Log.debug('updateUserStatus($status)', '$runtimeType');

    await _debounce(
      field: MyUserField.name,
      current: () => myUser.value?.status,
      saved: () async => (await _active)?.value.status,
      value: status,
      mutation: (v, _) async {
        return await Backoff.run(
          () async {
            return await _graphQlProvider.updateUserStatus(v);
          },
          retryIf: (e) => e.isNetworkRelated,
          retries: 10,
        );
      },
      update: (v, _) => myUser.update((u) => u?.status = v),
    );
  }

  @override
  Future<void> updateUserBio(UserBio? bio) async {
    Log.debug('updateUserBio($bio)', '$runtimeType');

    await _debounce(
      field: MyUserField.bio,
      current: () => myUser.value?.bio,
      saved: () async => (await _active)?.value.bio,
      value: bio,
      mutation: (v, _) async {
        return await Backoff.run(
          () async {
            return await _graphQlProvider.updateUserBio(v);
          },
          retryIf: (e) => e.isNetworkRelated,
          retries: 10,
        );
      },
      update: (v, _) => myUser.update((u) => u?.bio = v),
    );
  }

  @override
  Future<void> updateUserLogin(UserLogin? login) async {
    Log.debug('updateUserLogin($login)', '$runtimeType');

    // Don't do optimism, as [login] might be occupied, thus shouldn't set the
    // login right away.
    await Backoff.run(
      () async {
        await _graphQlProvider.updateUserLogin(login);
      },
      retryIf: (e) => e.isNetworkRelated,
      retries: 10,
    );
  }

  @override
  Future<void> updateUserPresence(UserPresence presence) async {
    Log.debug('updateUserPresence($presence)', '$runtimeType');

    await _debounce(
      field: MyUserField.presence,
      current: () => myUser.value?.presence,
      saved: () async => (await _active)?.value.presence,
      value: presence,
      mutation: (v, _) async {
        return await Backoff.run(
          () async {
            return await _graphQlProvider.updateUserPresence(v ?? presence);
          },
          retryIf: (e) => e.isNetworkRelated,
          retries: 10,
        );
      },
      update: (v, _) => myUser.update((u) => u?.presence = v ?? presence),
    );
  }

  @override
  Future<void> updateWelcomeMessage({
    ChatMessageText? text,
    List<Attachment>? attachments,
  }) async {
    Log.debug(
      'updateWelcomeMessage(text: $text, attachments: $attachments)',
      '$runtimeType',
    );

    bool reset = text?.val.isEmpty == true && attachments?.isEmpty == true;

    final WelcomeMessage? previous = myUser.value?.welcomeMessage;

    myUser.update(
      (u) => u
        ?..welcomeMessage = reset
            ? null
            : WelcomeMessage(
                text: text,
                attachments: attachments ?? [],
                at: PreciseDateTime.now(),
              ),
    );

    try {
      final List<Future>? uploads = attachments
          ?.map((e) {
            if (e is LocalAttachment) {
              return e.upload.value?.future.then(
                (a) {
                  final index = attachments.indexOf(e);

                  // If `Attachment` returned is `null`, then it was canceled.
                  if (a == null) {
                    attachments.removeAt(index);
                  } else {
                    attachments[index] = a;
                  }

                  myUser.update((_) {});
                },
                onError: (_) {
                  // No-op, as failed upload attempts are handled below.
                },
              );
            }
          })
          .nonNulls
          .toList();

      await Future.wait(uploads ?? []);

      if (attachments?.whereType<LocalAttachment>().isNotEmpty == true) {
        throw const ConnectionException(
          UpdateWelcomeMessageException(
            UpdateWelcomeMessageErrorCode.unknownAttachment,
          ),
        );
      }

      // If the contents of [WelcomeMessage] are empty, then reset it.
      if ((text == null || text.val.isEmpty) &&
          (attachments == null || attachments.isEmpty == true)) {
        reset = true;
      }

      await Backoff.run(
        () async {
          await _graphQlProvider.updateWelcomeMessage(
            reset
                ? null
                : WelcomeMessageInput(
                    text: text == null
                        ? null
                        : ChatMessageTextInput(
                            kw$new: text.val.isEmpty ? null : text,
                          ),
                    attachments: attachments == null
                        ? null
                        : ChatMessageAttachmentsInput(
                            kw$new: attachments.map((e) => e.id).toList(),
                          ),
                  ),
          );
        },
        retryIf: (e) => e.isNetworkRelated,
        retries: 10,
      );
    } catch (_) {
      myUser.update((u) => u?..welcomeMessage = previous);
      rethrow;
    }
  }

  @override
  Future<void> updateUserPassword(
    UserPassword? oldPassword,
    UserPassword newPassword,
  ) async {
    Log.debug(
      'updateUserPassword(${oldPassword?.obscured}, ${newPassword.obscured})',
      '$runtimeType',
    );

    final bool? hasPassword = myUser.value?.hasPassword;

    myUser.update((u) => u?.hasPassword = true);

    try {
      await _graphQlProvider.updateUserPassword(
        confirmation: oldPassword == null
            ? null
            : MyUserCredentials(password: oldPassword),
        newPassword: newPassword,
      );
    } catch (_) {
      if (hasPassword != null) {
        myUser.update((u) => u?.hasPassword = hasPassword);
      }

      rethrow;
    }
  }

  @override
  Future<void> deleteMyUser({
    UserPassword? password,
    ConfirmationCode? confirmation,
  }) async {
    Log.debug(
      'deleteMyUser(password: ${password?.obscured}, confirmation: $confirmation)',
      '$runtimeType',
    );

    await _graphQlProvider.deleteMyUser(
      confirmation: confirmation == null && password == null
          ? null
          : MyUserCredentials(code: confirmation, password: password),
    );
  }

  @override
  Future<void> removeUserEmail(
    UserEmail email, {
    UserPassword? password,
    ConfirmationCode? confirmation,
  }) async {
    Log.debug(
      'removeUserEmail($email, password: ${password?.obscured}, confirmation: $confirmation)',
      '$runtimeType',
    );

    if (myUser.value?.emails.unconfirmed == email) {
      await _debounce(
        field: MyUserField.email,
        current: () => myUser.value?.emails.unconfirmed,
        saved: () async => (await _active)?.value.emails.unconfirmed,
        value: null,
        mutation: (value, previous) async {
          if (previous != null) {
            return await _graphQlProvider.removeUserEmail(
              previous,
              confirmation: confirmation == null && password == null
                  ? null
                  : MyUserCredentials(code: confirmation, password: password),
            );
          } else if (value != null) {
            return await _graphQlProvider.addUserEmail(
              value,
              confirmation: confirmation,
            );
          }

          return null;
        },
        update: (v, p) => myUser.update(
          (u) => p != null
              ? u?.emails.unconfirmed = null
              : u?.emails.unconfirmed = v,
        ),
      );
    } else {
      int i = myUser.value?.emails.confirmed.indexOf(email) ?? -1;

      if (i != -1) {
        myUser.update((u) => u?.emails.confirmed.remove(email));
      }

      try {
        await _graphQlProvider.removeUserEmail(
          email,
          confirmation: confirmation == null && password == null
              ? null
              : MyUserCredentials(code: confirmation, password: password),
        );
      } catch (_) {
        if (i != -1) {
          i = min(i, myUser.value?.emails.confirmed.length ?? 0);
          myUser.update((u) => myUser.value?.emails.confirmed.insert(i, email));
        }
        rethrow;
      }
    }
  }

  @override
  Future<void> removeUserPhone(
    UserPhone phone, {
    UserPassword? password,
    ConfirmationCode? confirmation,
  }) async {
    Log.debug(
      'removeUserPhone($phone, password: ${password?.obscured}, confirmation: $confirmation)',
      '$runtimeType',
    );

    if (myUser.value?.phones.unconfirmed == phone) {
      await _debounce(
        field: MyUserField.phone,
        current: () => myUser.value?.phones.unconfirmed,
        saved: () async => (await _active)?.value.phones.unconfirmed,
        value: null,
        mutation: (value, previous) async {
          if (previous != null) {
            return await _graphQlProvider.removeUserPhone(
              previous,
              confirmation: confirmation == null && password == null
                  ? null
                  : MyUserCredentials(code: confirmation, password: password),
            );
          } else if (value != null) {
            return await _graphQlProvider.addUserPhone(
              value,
              confirmation: confirmation,
            );
          }

          return null;
        },
        update: (v, p) => myUser.update(
          (u) => p != null
              ? u?.phones.unconfirmed = null
              : u?.phones.unconfirmed = v,
        ),
      );
    } else {
      int i = myUser.value?.phones.confirmed.indexOf(phone) ?? -1;

      if (i != -1) {
        myUser.update((u) => u?.phones.confirmed.remove(phone));
      }

      try {
        await _graphQlProvider.removeUserPhone(
          phone,
          confirmation: confirmation == null && password == null
              ? null
              : MyUserCredentials(code: confirmation, password: password),
        );
      } catch (_) {
        if (i != -1) {
          i = min(i, myUser.value?.phones.confirmed.length ?? 0);
          myUser.update((u) => myUser.value?.phones.confirmed.insert(i, phone));
        }
        rethrow;
      }
    }
  }

  @override
  Future<void> addUserEmail(
    UserEmail email, {
    ConfirmationCode? confirmation,
    String? locale,
  }) async {
    Log.debug(
      'addUserEmail($email, confirmation: $confirmation, locale: $locale)',
      '$runtimeType',
    );

    // TODO: Add optimism.
    final events = await _graphQlProvider.addUserEmail(
      email,
      confirmation: confirmation,
      locale: locale,
    );

    for (var e in events?.events ?? []) {
      final event = _myUserEvent(e);

      if (event is EventUserEmailAdded) {
        if (event.confirmed) {
          myUser.value?.emails.confirmed.addIf(
            myUser.value?.emails.confirmed.contains(email) == false,
            email,
          );
          if (myUser.value?.emails.unconfirmed == email) {
            myUser.value?.emails.unconfirmed = null;
          }
        } else {
          myUser.value?.emails.unconfirmed = email;
        }

        myUser.refresh();
      }
    }
  }

  @override
  Future<void> addUserPhone(
    UserPhone phone, {
    ConfirmationCode? confirmation,
    String? locale,
  }) async {
    Log.debug(
      'addUserPhone($phone, confirmation: $confirmation)',
      '$runtimeType',
    );

    await _debounce(
      field: MyUserField.phone,
      current: () => myUser.value?.phones.unconfirmed,
      saved: () async => (await _active)?.value.phones.unconfirmed,
      value: phone,
      mutation: (value, previous) async {
        if (previous != null) {
          return await _graphQlProvider.removeUserPhone(
            previous,
            confirmation: confirmation == null
                ? null
                : MyUserCredentials(code: confirmation),
          );
        } else if (value != null) {
          return await _graphQlProvider.addUserPhone(
            value,
            confirmation: confirmation,
            locale: locale,
          );
        }

        return null;
      },
      update: (v, p) => myUser.update(
        (u) => p != null
            ? u?.phones.unconfirmed = null
            : u?.phones.unconfirmed = v,
      ),
    );
  }

  @override
  Future<void> createChatDirectLink(ChatDirectLinkSlug slug) async {
    Log.debug('createChatDirectLink($slug)', '$runtimeType');

    // Don't do optimism, as [slug] might be occupied, thus shouldn't set the
    // link right away.
    await Backoff.run(
      () async {
        await _graphQlProvider.createUserDirectLink(slug);
      },
      retryIf: (e) => e.isNetworkRelated,
      retries: 10,
    );

    myUser.update(
      (u) => u?.chatDirectLink = ChatDirectLink(
        slug: slug,
        createdAt: PreciseDateTime.now(),
      ),
    );
  }

  @override
  Future<void> deleteChatDirectLink() async {
    Log.debug('deleteChatDirectLink()', '$runtimeType');

    final ChatDirectLink? link = myUser.value?.chatDirectLink;

    myUser.update((u) => u?.chatDirectLink = null);

    try {
      await Backoff.run(
        () async {
          await _graphQlProvider.deleteUserDirectLink();
        },
        retryIf: (e) => e.isNetworkRelated,
        retries: 10,
      );
    } catch (_) {
      myUser.update((u) => u?.chatDirectLink = link);
      rethrow;
    }
  }

  @override
  Future<void> updateAvatar(
    NativeFile? file, {
    CropAreaInput? crop,
    void Function(int count, int total)? onSendProgress,
  }) async {
    Log.debug(
      'updateAvatar($file, crop: $crop, onSendProgress)',
      '$runtimeType',
    );

    dio.MultipartFile? upload;

    if (file != null) {
      await file.ensureCorrectMediaType();

      upload = await file.toMultipartFile();
    }

    final UserAvatar? avatar = myUser.value?.avatar;
    if (file == null) {
      myUser.update((u) => u?.avatar = null);
    }

    try {
      await Backoff.run(
        () async {
          await _graphQlProvider.updateUserAvatar(
            upload,
            crop,
            onSendProgress: onSendProgress,
          );
        },
        retryIf: (e) => e.isNetworkRelated,
        retries: 10,
      );
    } catch (_) {
      if (file == null) {
        myUser.update((u) => u?.avatar = avatar);
      }
      rethrow;
    }
  }

  @override
  Future<void> toggleMute(MuteDuration? mute) async {
    Log.debug('toggleMute($mute)', '$runtimeType');

    await _debounce(
      field: MyUserField.muted,
      current: () => myUser.value?.muted,
      saved: () async => (await _active)?.value.muted,
      value: mute,
      mutation: (duration, _) async {
        return await Backoff.run(
          () async {
            return await _graphQlProvider.toggleMyUserMute(
              duration == null
                  ? null
                  : Muting(
                      duration: duration.forever == true
                          ? null
                          : duration.until,
                    ),
            );
          },
          retryIf: (e) => e.isNetworkRelated,
          retries: 10,
        );
      },
      update: (v, _) => myUser.update((u) => u?.muted = v),
    );
  }

  @override
  Future<void> updateCallCover(
    NativeFile? file, {
    void Function(int count, int total)? onSendProgress,
  }) async {
    Log.debug('updateCallCover($file, onSendProgress)', '$runtimeType');

    dio.MultipartFile? upload;

    if (file != null) {
      await file.ensureCorrectMediaType();

      upload = await file.toMultipartFile();
    }

    final UserCallCover? callCover = myUser.value?.callCover;
    if (file == null) {
      myUser.update((u) => u?.callCover = null);
    }

    try {
      await Backoff.run(
        () async {
          await _graphQlProvider.updateUserCallCover(
            upload,
            null,
            onSendProgress: onSendProgress,
          );
        },
        retryIf: (e) => e.isNetworkRelated,
        retries: 10,
      );
    } catch (_) {
      if (file == null) {
        myUser.update((u) => u?.callCover = callCover);
      }
      rethrow;
    }
  }

  @override
  Future<void> refresh() async {
    Log.debug('refresh()', '$runtimeType');

    final response = await Backoff.run(
      () async {
        return await _graphQlProvider.getMyUser();
      },
      retryIf: (e) => e.isNetworkRelated,
      retries: 10,
    );

    if (response.myUser != null) {
      _setMyUser(response.myUser!.toDto(), ignoreVersion: true);
    }
  }

  /// Populates the [profiles] with values stored in the [_driftMyUser].
  Future<void> _initProfiles() async {
    Log.debug('_initProfiles()', '$runtimeType');

    for (final DtoMyUser u in await _driftMyUser.accounts()) {
      profiles[u.value.id] = Rx(u.value);
    }
  }

  /// Initializes [MyUserDriftProvider.watchSingle] subscription.
  Future<void> _initLocalSubscription() async {
    _localSubscriptionRetry?.cancel();

    if (isClosed) {
      return;
    }

    Log.debug(
      '_initLocalSubscription() -> isLocal(${me.isLocal})',
      '$runtimeType($hashCode)',
    );

    if (me.isLocal) {
      _applyMyUser(
        me,
        DtoMyUser(
          MyUser(
            id: me,
            num: UserNum('0000000000000000'),
            emails: MyUserEmails(confirmed: []),
            phones: MyUserPhones(confirmed: []),
            presenceIndex: 0,
            online: true,
          ),
          MyUserVersion('0'),
        ),
      );

      return;
    }

    final UserId? id = await _accountLocal.read();
    Log.debug(
      '_initLocalSubscription() -> `_accountLocal.read()` is `$id`',
      '$runtimeType($hashCode)',
    );

    if (id == null) {
      Log.debug(
        'Unexpected `null` when getting `_accountLocal.userId` for `_initLocalSubscription`',
        '$runtimeType($hashCode)',
      );

      _localSubscriptionRetry = Timer(
        const Duration(seconds: 1),
        _initLocalSubscription,
      );

      return;
    }

    _localSubscription = _driftMyUser.watchSingle(id).listen((e) {
      Log.debug(
        '_initLocalSubscription() -> _applyMyUser(${e?.value.toJson()})',
        '$runtimeType($hashCode)',
      );
      _applyMyUser(id, e);
    });
  }

  /// Initializes [_myUserRemoteEvents] subscription.
  Future<void> _initRemoteSubscription() async {
    Log.debug('_initRemoteSubscription()', '$runtimeType');

    _remoteSubscription?.close(immediate: true);

    if (_disposed || isClosed || me.isLocal) {
      Log.debug(
        '_initRemoteSubscription() -> exiting cuz $_disposed || $isClosed || ${me.isLocal}',
        '$runtimeType',
      );

      return;
    }

    Log.debug(
      '_initRemoteSubscription() -> await WebUtils.protect(`myUserEvents`)...',
      '$runtimeType',
    );

    await WebUtils.protect(() async {
      if (_disposed || isClosed || me.isLocal) {
        return;
      }

      try {
        Log.debug(
          '_initRemoteSubscription() -> await WebUtils.protect(`myUserEvents`)... acquired!',
          '$runtimeType',
        );

        _remoteSubscription = StreamQueue(
          await _myUserRemoteEvents(() async => (await _active)?.ver),
        );

        Log.debug(
          '_initRemoteSubscription() -> await WebUtils.protect(`myUserEvents`)... acquired! and `_myUserRemoteEvents()`... awaited!',
          '$runtimeType',
        );

        if (_disposed || isClosed || me.isLocal) {
          return _remoteSubscription?.close(immediate: true);
        }

        Log.debug(
          '_initRemoteSubscription() -> await WebUtils.protect(`myUserEvents`)... acquired! await _remoteSubscription!.execute()...',
          '$runtimeType',
        );

        await _remoteSubscription!.execute(
          _myUserRemoteEvent,
          onError: (e) async {
            if (e is StaleVersionException) {
              await _blocklistRepository.reset();
            }
          },
        );
      } finally {
        Log.debug(
          '_initRemoteSubscription() -> WebUtils.protect(`myUserEvents`)... acquired! and released!',
          '$runtimeType',
        );
      }
    }, tag: 'myUserEvents');
  }

  /// Initializes the [GraphQlProvider.keepOnline] subscription.
  Future<void> _initKeepOnlineSubscription() async {
    Log.debug('_initKeepOnlineSubscription()', '$runtimeType');

    _keepOnlineSubscription?.close(immediate: true);

    if (me.isLocal) {
      return;
    }

    await WebUtils.protect(() async {
      if (isClosed) {
        return;
      }

      _keepOnlineSubscription = StreamQueue(_graphQlProvider.keepOnline());
      await _keepOnlineSubscription!.execute((_) {
        // No-op.
      });
    }, tag: 'keepOnline');
  }

  /// Saves the provided [user] to the local storage.
  Future<void> _setMyUser(DtoMyUser user, {bool ignoreVersion = false}) async {
    Log.debug('_setMyUser($user, $ignoreVersion)', '$runtimeType');

    if (ignoreVersion || user.ver >= (await _active)?.ver) {
      await _driftMyUser.upsert(user);
      _applyMyUser(user.id, user);
    }
  }

  /// Applies the provided [DtoMyUser] to the reactive [myUser] value.
  void _applyMyUser(UserId id, DtoMyUser? e) {
    final bool isCurrent =
        (e?.id ?? id) == (myUser.value?.id ?? _accountLocal.userId);

    if (e == null) {
      Log.debug(
        '_applyMyUser() -> `e` is `null`, and `isCurrent` -> $isCurrent',
        '$runtimeType($hashCode)',
      );

      if (isCurrent) {
        myUser.value = null;
      }

      profiles.remove(id);
    } else {
      final MyUser user = e.value;

      if (isCurrent) {
        // Copy [event.value], as it always contains the same [MyUser].
        final MyUser value = user.copyWith();

        // Don't update the [MyUserField]s considered locked in the [_pool], as
        // those events might've been applied optimistically during mutations
        // and await corresponding subscription events to be persisted.
        if (_pool.lockedWith(MyUserField.name, value.name)) {
          value.name = myUser.value?.name;
        }

        if (_pool.lockedWith(MyUserField.status, value.status)) {
          value.status = myUser.value?.status;
        }

        if (_pool.lockedWith(MyUserField.bio, value.bio)) {
          value.bio = myUser.value?.bio;
        }

        if (_pool.lockedWith(MyUserField.presence, value.presence)) {
          value.presence = myUser.value?.presence ?? value.presence;
        }

        if (_pool.lockedWith(MyUserField.muted, value.muted)) {
          value.muted = myUser.value?.muted;
        }

        if (_pool.lockedWith(MyUserField.email, value.emails.unconfirmed)) {
          value.emails.unconfirmed = myUser.value?.emails.unconfirmed;
        }

        if (_pool.lockedWith(MyUserField.phone, value.phones.unconfirmed)) {
          value.phones.unconfirmed = myUser.value?.phones.unconfirmed;
        }

        myUser.value = value;
        profiles[e.id]?.value = value;

        Log.debug(
          '_applyMyUser() -> `e` is `isCurrent` -> $isCurrent, thus applying -> ${myUser.value}',
          '$runtimeType($hashCode)',
        );
      }
      // This event is not of the currently active [MyUser], so just update the
      // [profiles].
      else {
        Log.debug(
          '_applyMyUser() -> `e` is NOT `isCurrent` -> $isCurrent, thus applying to existing',
          '$runtimeType($hashCode)',
        );

        final Rx<MyUser>? existing = profiles[e.id];
        if (existing == null) {
          profiles[e.id] = Rx(user);
        } else {
          existing.value = user;
        }
      }
    }
  }

  /// Handles [MyUserEvent] from the [_myUserRemoteEvents] subscription.
  Future<void> _myUserRemoteEvent(
    MyUserEventsVersioned versioned, {
    bool updateVersion = true,
  }) async {
    final DtoMyUser? userEntity = await _active;

    if (userEntity == null || versioned.ver < userEntity.ver) {
      Log.debug(
        '_myUserRemoteEvent(): ignored ${versioned.events.map((e) => e.kind)}',
        '$runtimeType',
      );
      return;
    }

    // If [updateVersion] is `true`, then those events are processed and should
    // be removed from the [_pool], or added to it otherwise to prevent events
    // overwriting each other's actions.
    if (updateVersion) {
      userEntity.ver = versioned.ver;
      versioned.events.removeWhere(_pool.processed);
    } else {
      versioned.events.forEach(_pool.add);
    }

    Log.debug(
      '_myUserRemoteEvent(): ${versioned.events.map((e) => e.kind)}',
      '$runtimeType',
    );

    for (final MyUserEvent event in versioned.events) {
      // Updates a [User] associated with this [MyUserEvent.userId].
      void put(User Function(User u) convertor) {
        final FutureOr<RxUser?> userOrFuture = _userRepository.get(
          event.userId,
        );

        if (userOrFuture is RxUser?) {
          if (userOrFuture != null) {
            _userRepository.update(convertor(userOrFuture.user.value));
          }
        } else {
          userOrFuture.then((user) {
            if (user != null) {
              _userRepository.update(convertor(user.user.value));
            }
          });
        }
      }

      switch (event.kind) {
        case MyUserEventKind.nameUpdated:
          event as EventUserNameUpdated;
          userEntity.value.name = event.name;
          put((u) => u..name = event.name);
          break;

        case MyUserEventKind.nameDeleted:
          event as EventUserNameRemoved;
          userEntity.value.name = null;
          put((u) => u..name = null);
          break;

        case MyUserEventKind.avatarUpdated:
          event as EventUserAvatarUpdated;
          userEntity.value.avatar = event.avatar;
          put((u) => u..avatar = event.avatar);
          break;

        case MyUserEventKind.avatarDeleted:
          event as EventUserAvatarRemoved;
          userEntity.value.avatar = null;
          put((u) => u..avatar = null);
          break;

        case MyUserEventKind.bioUpdated:
          event as EventUserBioUpdated;
          userEntity.value.bio = event.bio;
          put((u) => u..bio = event.bio);
          break;

        case MyUserEventKind.bioDeleted:
          event as EventUserBioRemoved;
          userEntity.value.bio = null;
          put((u) => u..bio = null);
          break;

        case MyUserEventKind.callCoverUpdated:
          event as EventUserCallCoverUpdated;
          userEntity.value.callCover = event.callCover;
          put((u) => u..callCover = event.callCover);
          break;

        case MyUserEventKind.callCoverDeleted:
          event as EventUserCallCoverRemoved;
          userEntity.value.callCover = null;
          put((u) => u..callCover = null);
          break;

        case MyUserEventKind.presenceUpdated:
          event as EventUserPresenceUpdated;
          userEntity.value.presence = event.presence;
          put((u) => u..presence = event.presence);
          break;

        case MyUserEventKind.statusUpdated:
          event as EventUserStatusUpdated;
          userEntity.value.status = event.status;
          put((u) => u..status = event.status);
          break;

        case MyUserEventKind.statusDeleted:
          event as EventUserStatusRemoved;
          userEntity.value.status = null;
          put((u) => u..status = null);
          break;

        case MyUserEventKind.loginUpdated:
          event as EventUserLoginUpdated;
          userEntity.value.login = event.login;
          break;

        case MyUserEventKind.loginDeleted:
          event as EventUserLoginRemoved;
          userEntity.value.login = null;
          break;

        case MyUserEventKind.emailAdded:
          event as EventUserEmailAdded;
          if (event.confirmed) {
            userEntity.value.emails.confirmed.addIf(
              !userEntity.value.emails.confirmed.contains(event.email),
              event.email,
            );
            if (userEntity.value.emails.unconfirmed == event.email) {
              userEntity.value.emails.unconfirmed = null;
            }
          } else {
            userEntity.value.emails.unconfirmed = event.email;
          }
          break;

        case MyUserEventKind.emailDeleted:
          event as EventUserEmailRemoved;
          if (userEntity.value.emails.unconfirmed == event.email) {
            userEntity.value.emails.unconfirmed = null;
          }
          userEntity.value.emails.confirmed.removeWhere(
            (element) => element == event.email,
          );
          break;

        case MyUserEventKind.phoneAdded:
          event as EventUserPhoneAdded;
          if (event.confirmed) {
            userEntity.value.phones.confirmed.addIf(
              !userEntity.value.phones.confirmed.contains(event.phone),
              event.phone,
            );
            if (userEntity.value.phones.unconfirmed == event.phone) {
              userEntity.value.phones.unconfirmed = null;
            }
          } else {
            userEntity.value.phones.unconfirmed = event.phone;
          }
          break;

        case MyUserEventKind.phoneDeleted:
          event as EventUserPhoneRemoved;
          if (userEntity.value.phones.unconfirmed == event.phone) {
            userEntity.value.phones.unconfirmed = null;
          }
          userEntity.value.phones.confirmed.removeWhere(
            (element) => element == event.phone,
          );
          break;

        case MyUserEventKind.passwordUpdated:
          event as EventUserPasswordUpdated;
          userEntity.value.hasPassword = true;

          if (event.userId == myUser.value?.id) {
            onPasswordUpdated();
          }
          break;

        case MyUserEventKind.userMuted:
          event as EventUserMuted;
          userEntity.value.muted = event.until;
          break;

        case MyUserEventKind.unmuted:
          event as EventUserUnmuted;
          userEntity.value.muted = null;
          break;

        case MyUserEventKind.cameOnline:
          event as EventUserCameOnline;
          userEntity.value.online = true;
          put((u) => u..online = true);
          break;

        case MyUserEventKind.cameOffline:
          event as EventUserCameOffline;
          userEntity.value.online = false;
          put(
            (u) => u
              ..online = false
              ..lastSeenAt = event.at,
          );
          break;

        case MyUserEventKind.unreadChatsCountUpdated:
          event as EventUserUnreadChatsCountUpdated;
          userEntity.value.unreadChatsCount = event.count;
          break;

        case MyUserEventKind.deleted:
          event as EventUserDeleted;

          if (event.userId == myUser.value?.id) {
            onUserDeleted();
          }
          break;

        case MyUserEventKind.directLinkDeleted:
          event as EventUserDirectLinkDeleted;
          userEntity.value.chatDirectLink = null;
          break;

        case MyUserEventKind.directLinkUpdated:
          event as EventUserDirectLinkUpdated;
          userEntity.value.chatDirectLink = event.directLink;
          break;

        case MyUserEventKind.welcomeMessageDeleted:
          event as EventUserWelcomeMessageDeleted;
          userEntity.value.welcomeMessage = null;
          put((u) => u..welcomeMessage = null);
          break;

        case MyUserEventKind.welcomeMessageUpdated:
          event as EventUserWelcomeMessageUpdated;

          final message = WelcomeMessage(
            text: event.text == null
                ? userEntity.value.welcomeMessage?.text
                : event.text?.changed,
            attachments: event.attachments == null
                ? userEntity.value.welcomeMessage?.attachments ?? []
                : event.attachments?.attachments ?? [],
            at: event.at,
          );

          userEntity.value.welcomeMessage = message;
          put((u) => u..welcomeMessage = message);
          break;
      }
    }

    await _driftMyUser.upsert(userEntity);
  }

  /// Subscribes to remote [MyUserEvent]s of the authenticated [MyUser].
  Future<Stream<MyUserEventsVersioned>> _myUserRemoteEvents(
    Future<MyUserVersion?> Function() ver,
  ) async {
    Log.debug('_myUserRemoteEvents(ver)', '$runtimeType');

    return (await _graphQlProvider.myUserEvents(ver)).asyncExpand((
      event,
    ) async* {
      Log.trace('_myUserRemoteEvents(ver): ${event.data}', '$runtimeType');

      var events = MyUserEvents$Subscription.fromJson(event.data!).myUserEvents;

      if (events.$$typename == 'SubscriptionInitialized') {
        Log.debug(
          '_myUserRemoteEvents(ver): SubscriptionInitialized',
          '$runtimeType',
        );

        events
            as MyUserEvents$Subscription$MyUserEvents$SubscriptionInitialized;
        // No-op.
      } else if (events.$$typename == 'MyUser') {
        Log.debug('_myUserRemoteEvents(ver): MyUser', '$runtimeType');

        events as MyUserEvents$Subscription$MyUserEvents$MyUser;

        _setMyUser(events.toDto());
      } else if (events.$$typename == 'MyUserEventsVersioned') {
        var mixin = events as MyUserEventsVersionedMixin;
        yield MyUserEventsVersioned(
          mixin.events.map((e) => _myUserEvent(e)).toList(),
          mixin.ver,
        );
      }
    });
  }

  /// Constructs a [MyUserEvent] from the [MyUserEventsVersionedMixin$Events].
  MyUserEvent _myUserEvent(MyUserEventsVersionedMixin$Events e) {
    Log.trace('_myUserEvent($e)', '$runtimeType');

    if (e.$$typename == 'EventUserNameUpdated') {
      final node = e as MyUserEventsVersionedMixin$Events$EventUserNameUpdated;
      return EventUserNameUpdated(node.userId, node.name);
    } else if (e.$$typename == 'EventUserNameRemoved') {
      final node = e as MyUserEventsVersionedMixin$Events$EventUserNameRemoved;
      return EventUserNameRemoved(node.userId);
    } else if (e.$$typename == 'EventUserAvatarUpdated') {
      final node =
          e as MyUserEventsVersionedMixin$Events$EventUserAvatarUpdated;
      return EventUserAvatarUpdated(node.userId, node.avatar.toModel());
    } else if (e.$$typename == 'EventUserAvatarRemoved') {
      final node =
          e as MyUserEventsVersionedMixin$Events$EventUserAvatarRemoved;
      return EventUserAvatarRemoved(node.userId);
    } else if (e.$$typename == 'EventUserBioUpdated') {
      final node = e as MyUserEventsVersionedMixin$Events$EventUserBioUpdated;
      return EventUserBioUpdated(node.userId, node.bio, node.at);
    } else if (e.$$typename == 'EventUserBioRemoved') {
      final node = e as MyUserEventsVersionedMixin$Events$EventUserBioRemoved;
      return EventUserBioRemoved(node.userId, node.at);
    } else if (e.$$typename == 'EventUserCallCoverUpdated') {
      final node =
          e as MyUserEventsVersionedMixin$Events$EventUserCallCoverUpdated;
      return EventUserCallCoverUpdated(node.userId, node.callCover.toModel());
    } else if (e.$$typename == 'EventUserCallCoverRemoved') {
      final node =
          e as MyUserEventsVersionedMixin$Events$EventUserCallCoverRemoved;
      return EventUserCallCoverRemoved(node.userId);
    } else if (e.$$typename == 'EventUserPresenceUpdated') {
      final node =
          e as MyUserEventsVersionedMixin$Events$EventUserPresenceUpdated;
      return EventUserPresenceUpdated(node.userId, node.presence);
    } else if (e.$$typename == 'EventUserStatusUpdated') {
      final node =
          e as MyUserEventsVersionedMixin$Events$EventUserStatusUpdated;
      return EventUserStatusUpdated(node.userId, node.status);
    } else if (e.$$typename == 'EventUserStatusRemoved') {
      final node =
          e as MyUserEventsVersionedMixin$Events$EventUserStatusRemoved;
      return EventUserStatusRemoved(node.userId);
    } else if (e.$$typename == 'EventUserLoginUpdated') {
      final node = e as MyUserEventsVersionedMixin$Events$EventUserLoginUpdated;
      return EventUserLoginUpdated(node.userId, node.login);
    } else if (e.$$typename == 'EventUserLoginRemoved') {
      final node = e as MyUserEventsVersionedMixin$Events$EventUserLoginRemoved;
      return EventUserLoginRemoved(node.userId, node.at);
    } else if (e.$$typename == 'EventUserEmailAdded') {
      final node = e as MyUserEventsVersionedMixin$Events$EventUserEmailAdded;
      return EventUserEmailAdded(node.userId, node.email, node.confirmed);
    } else if (e.$$typename == 'EventUserEmailRemoved') {
      final node = e as MyUserEventsVersionedMixin$Events$EventUserEmailRemoved;
      return EventUserEmailRemoved(node.userId, node.email);
    } else if (e.$$typename == 'EventUserPhoneAdded') {
      final node = e as MyUserEventsVersionedMixin$Events$EventUserPhoneAdded;
      return EventUserPhoneAdded(node.userId, node.phone, node.confirmed);
    } else if (e.$$typename == 'EventUserPhoneRemoved') {
      final node = e as MyUserEventsVersionedMixin$Events$EventUserPhoneRemoved;
      return EventUserPhoneRemoved(node.userId, node.phone);
    } else if (e.$$typename == 'EventUserPasswordUpdated') {
      final node =
          e as MyUserEventsVersionedMixin$Events$EventUserPasswordUpdated;
      return EventUserPasswordUpdated(node.userId);
    } else if (e.$$typename == 'EventUserMuted') {
      final node = e as MyUserEventsVersionedMixin$Events$EventUserMuted;
      return EventUserMuted(
        node.userId,
        node.until.$$typename == 'MuteForeverDuration'
            ? MuteDuration.forever()
            : MuteDuration.until(
                (node.until
                        as MyUserEventsVersionedMixin$Events$EventUserMuted$Until$MuteUntilDuration)
                    .until,
              ),
      );
    } else if (e.$$typename == 'EventUserCameOffline') {
      final node = e as MyUserEventsVersionedMixin$Events$EventUserCameOffline;
      return EventUserCameOffline(node.userId, node.at);
    } else if (e.$$typename == 'EventUserUnreadChatsCountUpdated') {
      final node =
          e as MyUserEventsVersionedMixin$Events$EventUserUnreadChatsCountUpdated;
      return EventUserUnreadChatsCountUpdated(node.userId, node.count);
    } else if (e.$$typename == 'EventUserDirectLinkUpdated') {
      final node =
          e as MyUserEventsVersionedMixin$Events$EventUserDirectLinkUpdated;
      return EventUserDirectLinkUpdated(
        node.userId,
        ChatDirectLink(
          slug: node.directLink.slug,
          usageCount: node.directLink.usageCount,
          createdAt: node.directLink.createdAt,
        ),
      );
    } else if (e.$$typename == 'EventUserDirectLinkDeleted') {
      final node =
          e as MyUserEventsVersionedMixin$Events$EventUserDirectLinkDeleted;
      return EventUserDirectLinkDeleted(node.userId);
    } else if (e.$$typename == 'EventUserDeleted') {
      final node = e as MyUserEventsVersionedMixin$Events$EventUserDeleted;
      return EventUserDeleted(node.userId);
    } else if (e.$$typename == 'EventUserUnmuted') {
      final node = e as MyUserEventsVersionedMixin$Events$EventUserUnmuted;
      return EventUserUnmuted(node.userId);
    } else if (e.$$typename == 'EventUserCameOnline') {
      final node = e as MyUserEventsVersionedMixin$Events$EventUserCameOnline;
      return EventUserCameOnline(node.userId);
    } else if (e.$$typename == 'EventUserWelcomeMessageDeleted') {
      final node =
          e as MyUserEventsVersionedMixin$Events$EventUserWelcomeMessageDeleted;
      return EventUserWelcomeMessageDeleted(node.userId, node.at);
    } else if (e.$$typename == 'EventUserWelcomeMessageUpdated') {
      final node =
          e as MyUserEventsVersionedMixin$Events$EventUserWelcomeMessageUpdated;
      return EventUserWelcomeMessageUpdated(
        node.userId,
        node.at,
        node.text == null ? null : ChangedChatMessageText(node.text!.changed),
        node.attachments == null
            ? null
            : ChangedChatMessageAttachments(
                node.attachments!.changed.map((e) => e.toModel()).toList(),
              ),
      );
    } else {
      throw UnimplementedError('Unknown MyUserEvent: ${e.$$typename}');
    }
  }

  /// Debounces the [mutation] execution, synchronizing the results with [_pool]
  /// for the provided [field].
  Future<void> _debounce<T>({
    required MyUserField field,
    required T? Function() current,
    required Future<T?> Function() saved,
    T? value,
    required void Function(T? value, T? previous) update,
    required Future<MyUserEventsVersionedMixin?> Function(T? value, T? previous)
    mutation,
  }) async {
    Log.debug(
      '_debounce($field, current, saved, $value, update, mutation)',
      '$runtimeType',
    );

    T? previous = current();

    update(value, previous);

    await _pool.protect(
      field,
      () async {
        try {
          final MyUserEventsVersionedMixin? response = await mutation(
            value,
            previous,
          );

          if (response != null) {
            final event = MyUserEventsVersioned(
              response.events.map(_myUserEvent).toList(),
              response.ver,
            );

            _myUserRemoteEvent(event, updateVersion: false);

            // Wait for local storage to update the [DtoMyUser] from
            // [_myUserRemoteEvent].
            await Future.delayed(Duration.zero);
          }

          previous = value;
        } catch (_) {
          update(await saved(), value);
          rethrow;
        }
      },
      values: [value, await saved()],
      repeat: () async {
        if (myUser.value != null && current() != await saved()) {
          value = current();
          return true;
        }

        return false;
      },
    );
  }
}

/// [MyUser] fields being updated via [MyUserEvent]s.
///
/// Used to update [MyUser] according to the [EventPool].
enum MyUserField { muted, name, status, bio, presence, email, phone }
