// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' hide OAuthProvider, User;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:medea_jason/medea_jason.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/account.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/balance.dart';
import 'package:messenger/domain/service/blocklist.dart';
import 'package:messenger/domain/service/user.dart';
import 'package:messenger/ui/page/home/page/my_profile/add_email/controller.dart';
import 'package:messenger/ui/page/login/controller.dart';
import 'package:messenger/ui/widget/phone_field.dart';
import 'package:messenger/util/log.dart';
import 'package:messenger/util/obs/obs.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/application_settings.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/media_settings.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/native_file.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/settings.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/worker/cache.dart';
import '/ui/page/home/page/chat/message_field/controller.dart';
import '/ui/widget/text_field.dart';
import '/util/media_utils.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'add_phone/view.dart';

export 'view.dart';

/// Controller of the [Routes.me] page.
class MyProfileController extends GetxController {
  MyProfileController(
    this._myUserService,
    this._settingsRepo,
    this._chatService,
    this._blocklistService,
    this._userService,
    this._authService,
    this._balanceService,
  );

  /// Status of an [uploadAvatar] or [deleteAvatar] completion.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning no [uploadAvatar]/[deleteAvatar] is executing.
  /// - `status.isLoading`, meaning [uploadAvatar]/[deleteAvatar] is executing.
  final Rx<RxStatus> avatarUpload = Rx(RxStatus.empty());

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [ItemScrollController] of the profile's [ScrollablePositionedList].
  final ItemScrollController itemScrollController = ItemScrollController();

  /// [ItemPositionsListener] of the profile's [ScrollablePositionedList].
  final ItemPositionsListener positionsListener =
      ItemPositionsListener.create();

  final ScrollController paidScrollController = ScrollController();
  final ScrollController blocklistScrollController = ScrollController();

  /// Index of the initial profile page section to show in a
  /// [ScrollablePositionedList].
  int listInitIndex = 0;

  /// [MyUser.name]'s field state.
  late final TextFieldState name;

  /// [MyUser.num]'s copyable state.
  late final TextFieldState num;

  /// [MyUser.chatDirectLink]'s copyable state.
  late final TextFieldState link;

  /// [MyUser.login]'s field state.
  late final TextFieldState login;

  /// [MyUser.status]'s field state.
  late final TextFieldState status;

  late final TextFieldState allMessageCost;
  late final TextFieldState allCallCost;

  late final TextFieldState contactMessageCost;
  late final TextFieldState contactCallCost;

  late final TextFieldState donateCost;
  final RxInt donatePrice = RxInt(0);

  late final TextFieldState email = TextFieldState(
    approvable: true,
    onChanged: (s) {
      s.error.value = null;

      if (s.text.isNotEmpty) {
        try {
          final email = UserEmail(s.text);

          if (myUser.value!.emails.confirmed.contains(email) ||
              myUser.value?.emails.unconfirmed == email) {
            s.error.value = 'err_you_already_add_this_email'.l10n;
          }
        } catch (e) {
          s.error.value = 'err_incorrect_email'.l10n;
        }
      }
    },
    onSubmitted: (s) async {
      if (s.text.isEmpty || s.error.value != null) {
        return;
      }

      final email = UserEmail(s.text);
      s.clear();

      _myUserService.addUserEmail(email).onError((e, _) {
        s.unchecked = email.val;
        s.error.value = 'err_data_transfer'.l10n;
        s.unsubmit();
      });

      await AddEmailView.show(router.context!, email: email, timeout: true);
    },
  );

  late final PhoneFieldState phone = PhoneFieldState(
    approvable: true,
    onChanged: (s) {
      s.error.value = null;

      if (s.phone?.nsn.isNotEmpty == true) {
        try {
          final email = UserPhone(s.phone!.international);

          if (myUser.value!.phones.confirmed.contains(email) ||
              myUser.value?.phones.unconfirmed == email) {
            s.error.value = 'err_you_already_add_this_phone'.l10n;
          }
        } catch (e) {
          s.error.value = 'err_incorrect_phone'.l10n;
        }
      }
    },
    onSubmitted: (s) async {
      if (s.phone?.nsn.isNotEmpty != true || s.error.value != null) {
        return;
      }

      final number = s.phone;
      final phone = UserPhone(number!.international);
      s.clear();

      _myUserService.addUserPhone(phone).onError((e, _) {
        s.unchecked = number;
        s.error.value = 'err_data_transfer'.l10n;
        s.unsubmit();
      });

      await AddPhoneView.show(router.context!, phone: phone, timeout: true);
    },
  );

  /// Indicator whether there's an ongoing [toggleMute] happening.
  ///
  /// Used to discard repeated toggling.
  final RxBool isMuting = RxBool(false);

  /// List of [MediaDeviceDetails] of all the available devices.
  final RxList<DeviceDetails> devices = RxList<DeviceDetails>([]);

  /// Index of an item from [ProfileTab] that should be highlighted.
  final RxnInt highlightIndex = RxnInt(null);

  /// [GlobalKey] of an [AvatarWidget] displayed used to open a [GalleryPopup].
  final GlobalKey avatarKey = GlobalKey();

  final GlobalKey welcomeFieldKey = GlobalKey();

  final RxBool verified = RxBool(false);
  final RxBool hintVerified = RxBool(false);

  final Rx<ChatMessage?> welcome = Rx(null);

  late final MessageFieldController send;

  final RxSet<(OAuthProvider, UserCredential)> providers = RxSet();

  final RxBool linkEditing = RxBool(false);
  final RxBool moneyEditing = RxBool(false);
  final RxBool donateEditing = RxBool(false);

  late final RxBool verificationEditing = RxBool(!verified.value);

  final RxBool displayName = RxBool(false);

  /// Service responsible for [MyUser] management.
  final MyUserService _myUserService;

  final ChatService _chatService;

  /// Settings repository, used to update the [ApplicationSettings].
  final AbstractSettingsRepository _settingsRepo;

  /// [BlocklistService] maintaining the blocked [User]s.
  final BlocklistService _blocklistService;

  final UserService _userService;
  final AuthService _authService;
  final BalanceService _balanceService;

  /// Reactive list of sorted blocked [RxUser]s.
  final RxList<RxUser> blocklist = RxList();

  late final Rx<VerifiedPerson?> person =
      Rx(_balanceService.person.value?.copyWith());

  /// [StreamSubscription] to react on the [BlocklistService.blocklist] updates.
  late final StreamSubscription _blocklistSubscription;

  /// Returns the [RxStatus] of the [blocklist] fetching and initialization.
  Rx<RxStatus> get blocklistStatus => _blocklistService.status;

  /// [Timer] to set the `RxStatus.empty` status of the [name] field.
  Timer? _nameTimer;

  /// [Timer] to set the `RxStatus.empty` status of the [link] field.
  Timer? _linkTimer;

  /// [Timer] to set the `RxStatus.empty` status of the [login] field.
  Timer? _loginTimer;

  /// [Timer] to set the `RxStatus.empty` status of the [status] field.
  Timer? _statusTimer;

  /// Worker to react on [myUser] changes.
  Worker? _myUserWorker;

  /// Worker to react on [RouterState.profileSection] changes.
  Worker? _profileWorker;

  /// [StreamSubscription] for the [MediaUtils.onDeviceChange] stream updating
  /// the [devices].
  StreamSubscription? _devicesSubscription;

  /// [Duration] of the highlighting.
  static const Duration _highlightTimeout = Duration(seconds: 1);

  /// [Timer] resetting the [highlightIndex] value after the [_highlightTimeout]
  /// has passed.
  Timer? _highlightTimer;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Returns the current [ApplicationSettings] value.
  Rx<ApplicationSettings?> get settings => _settingsRepo.applicationSettings;

  /// Returns the current background's [Uint8List] value.
  Rx<Uint8List?> get background => _settingsRepo.background;

  /// Returns the current [MediaSettings] value.
  Rx<MediaSettings?> get media => _settingsRepo.mediaSettings;

  List<UserEmail> get emails => [
        // UserEmail('dummy1@example.com'),
        // UserEmail('dummy2@example.com'),
        // UserEmail('unverified@example.com'),
      ];
  List<UserPhone> get phones => [
        // UserPhone('+1234567890'),
        // UserPhone('+1234567890'),
        // UserPhone('+0234567890'),
      ];

  RxList<Account> get accounts => _authService.accounts;

  final RxBool expanded = RxBool(false);

  final RxInt allMessagePrice = RxInt(0);
  final RxInt allCallPrice = RxInt(0);
  final RxInt contactMessagePrice = RxInt(0);
  final RxInt contactCallPrice = RxInt(0);

  @override
  void onInit() {
    if (!PlatformUtils.isMobile) {
      _devicesSubscription =
          MediaUtils.onDeviceChange.listen((e) => devices.value = e);
      MediaUtils.enumerateDevices().then((e) => devices.value = e);
    }

    listInitIndex = router.profileSection.value?.index ?? 0;

    bool ignoreWorker = false;
    bool ignorePositions = false;

    _profileWorker = ever(
      router.profileSection,
      (ProfileTab? tab) async {
        if (ignoreWorker) {
          ignoreWorker = false;
        } else {
          ignorePositions = true;
          await itemScrollController.scrollTo(
            index: tab?.index ?? 0,
            duration: 200.milliseconds,
            curve: Curves.ease,
          );
          Future.delayed(Duration.zero, () => ignorePositions = false);

          highlight(tab);
        }
      },
    );

    positionsListener.itemPositions.addListener(() {
      if (!ignorePositions) {
        final ItemPosition? position =
            positionsListener.itemPositions.value.firstOrNull;

        if (position != null) {
          final ProfileTab tab = ProfileTab.values[position.index];
          if (router.profileSection.value != tab) {
            ignoreWorker = true;
            router.profileSection.value = tab;
            Future.delayed(Duration.zero, () => ignoreWorker = false);
          }
        }
      }
    });

    verified.value = true;
    // _myUserService.myUser.value?.emails.confirmed.isNotEmpty == true;

    // _myUserWorker = ever(
    //   _myUserService.myUser,
    //   (MyUser? v) {
    //     if (!name.focus.hasFocus &&
    //         !name.changed.value &&
    //         name.editable.value) {
    //       name.unchecked = v?.name?.val;
    //     }
    //     if (!login.focus.hasFocus &&
    //         !login.changed.value &&
    //         login.editable.value) {
    //       login.unchecked = v?.login?.val;
    //     }
    //     if (!link.focus.hasFocus &&
    //         !link.changed.value &&
    //         link.editable.value) {
    //       link.unchecked = v?.chatDirectLink?.slug.val;
    //     }

    //     verified.value = v?.emails.confirmed.isNotEmpty == true;
    //   },
    // );

    name = TextFieldState(
      text: myUser.value?.name?.val,
      approvable: true,
      onChanged: (s) async {
        s.error.value = null;
        try {
          if (s.text.isNotEmpty) {
            UserName(s.text);
          }
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      },
      onSubmitted: (s) async {
        s.error.value = null;
        try {
          if (s.text.isNotEmpty) {
            UserName(s.text);
          }
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }

        if (s.error.value == null) {
          _nameTimer?.cancel();
          s.editable.value = false;
          s.status.value = RxStatus.loading();
          try {
            await _myUserService
                .updateUserName(s.text.isNotEmpty ? UserName(s.text) : null);
            s.status.value = RxStatus.empty();
          } catch (e) {
            s.error.value = 'err_data_transfer'.l10n;
            s.status.value = RxStatus.empty();
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );

    num = TextFieldState(
      text: myUser.value?.num.val.replaceAllMapped(
        RegExp(r'.{4}'),
        (match) => '${match.group(0)} ',
      ),
      editable: false,
    );

    link = TextFieldState(
      text: myUser.value?.chatDirectLink?.slug.val ??
          ChatDirectLinkSlug.generate(10).val,
      approvable: true,
      submitted: myUser.value?.chatDirectLink != null,
      onChanged: (s) {
        s.error.value = null;

        try {
          ChatDirectLinkSlug(s.text);
        } on FormatException {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      },
      onSubmitted: (s) async {
        ChatDirectLinkSlug? slug;
        try {
          slug = ChatDirectLinkSlug(s.text);
        } on FormatException {
          s.error.value = 'err_incorrect_input'.l10n;
        }

        if (slug == null || slug == myUser.value?.chatDirectLink?.slug) {
          return;
        }

        if (s.error.value == null) {
          _linkTimer?.cancel();
          s.editable.value = false;
          s.status.value = RxStatus.loading();

          try {
            await _myUserService.createChatDirectLink(slug);
            s.status.value = RxStatus.success();
            await Future.delayed(const Duration(seconds: 1));
            s.status.value = RxStatus.empty();
          } on CreateChatDirectLinkException catch (e) {
            s.status.value = RxStatus.empty();
            s.error.value = e.toMessage();
          } catch (e) {
            s.status.value = RxStatus.empty();
            MessagePopup.error(e);
            s.unsubmit();
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );

    login = TextFieldState(
      text: myUser.value?.login?.val,
      approvable: true,
      onChanged: (s) async {
        s.error.value = null;

        if (s.text.isEmpty) {
          s.unchecked = myUser.value?.login?.val ?? '';
          s.status.value = RxStatus.empty();
          return;
        }

        try {
          UserLogin(s.text.toLowerCase());
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_login_input'.l10n;
        }
      },
      onSubmitted: (s) async {
        if (s.error.value == null) {
          _loginTimer?.cancel();
          s.editable.value = false;
          s.status.value = RxStatus.loading();
          try {
            await _myUserService
                .updateUserLogin(UserLogin(s.text.toLowerCase()));
            s.status.value = RxStatus.success();
            _loginTimer = Timer(
              const Duration(milliseconds: 1500),
              () => s.status.value = RxStatus.empty(),
            );
          } on UpdateUserLoginException catch (e) {
            s.error.value = e.toMessage();
            s.status.value = RxStatus.empty();
          } catch (e) {
            s.error.value = 'err_data_transfer'.l10n;
            s.status.value = RxStatus.empty();
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );

    status = TextFieldState(
      text: myUser.value?.status?.val ?? '',
      approvable: true,
      onChanged: (s) {
        s.error.value = null;

        try {
          if (s.text.isNotEmpty) {
            UserTextStatus(s.text);
          }
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      },
      onSubmitted: (s) async {
        try {
          if (s.text.isNotEmpty) {
            UserTextStatus(s.text);
          }
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }

        if (s.error.value == null) {
          _statusTimer?.cancel();
          s.editable.value = false;
          s.status.value = RxStatus.loading();
          try {
            await _myUserService.updateUserStatus(
              s.text.isNotEmpty ? UserTextStatus(s.text) : null,
            );
            s.status.value = RxStatus.success();
            _statusTimer = Timer(
              const Duration(milliseconds: 1500),
              () => s.status.value = RxStatus.empty(),
            );
          } catch (e) {
            s.error.value = 'err_data_transfer'.l10n;
            s.status.value = RxStatus.empty();
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );

    allMessageCost = TextFieldState(
      approvable: true,
      text: '',
      onSubmitted: (s) {
        allMessagePrice.value =
            int.tryParse(s.text.replaceAll(RegExp(r'\s+'), '')) ?? 0;
      },
    );

    allCallCost = TextFieldState(
      approvable: true,
      text: '',
      onSubmitted: (s) {
        allCallPrice.value =
            int.tryParse(s.text.replaceAll(RegExp(r'\s+'), '')) ?? 0;
      },
    );

    contactMessageCost = TextFieldState(
      approvable: true,
      text: '',
      onSubmitted: (s) {
        contactMessagePrice.value =
            int.tryParse(s.text.replaceAll(RegExp(r'\s+'), '')) ?? 0;
      },
    );

    contactCallCost = TextFieldState(
      approvable: true,
      text: '',
      onSubmitted: (s) {
        contactCallPrice.value =
            int.tryParse(s.text.replaceAll(RegExp(r'\s+'), '')) ?? 0;
      },
    );

    donateCost = TextFieldState(
      approvable: true,
      text: '',
      onSubmitted: (s) {
        donatePrice.value =
            int.tryParse(s.text.replaceAll(RegExp(r'\s+'), '')) ?? 0;
        donateEditing.value = false;
      },
    );

    send = MessageFieldController(
      _chatService,
      null,
      null,
      _settingsRepo,
      onSubmit: ({bool onlyDonation = false}) async {
        welcome.value = ChatMessage(
          welcome.value?.id ?? ChatItemId.local(),
          welcome.value?.chatId ?? const ChatId('123'),
          User(
            welcome.value?.author.id ?? myUser.value!.id,
            welcome.value?.author.num ?? myUser.value!.num,
          ),
          welcome.value?.at ?? PreciseDateTime.now(),
          text: ChatMessageText(send.field.text),
          attachments: send.attachments.map((e) => e.value).toList(),
        );

        send.editing.value = false;
        send.clear();
      },
    );

    blocklist.value = _blocklistService.blocklist.values.toList();
    _sortBlocklist();

    _blocklistSubscription = _blocklistService.blocklist.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          blocklist.add(e.value!);
          _sortBlocklist();
          break;

        case OperationKind.removed:
          blocklist.removeWhere((c) => c.id == e.key);
          break;

        case OperationKind.updated:
          // No-op, as [blocklist] is never updated.
          break;
      }
    });

    scrollController.addListener(_ensureNameIsDisplayed);

    super.onInit();
  }

  @override
  Future<void> onReady() async {
    await _blocklistService.around();
    super.onReady();
  }

  void _ensureNameIsDisplayed() {
    displayName.value = scrollController.position.pixels >= 250;
  }

  @override
  void onClose() {
    _myUserWorker?.dispose();
    _profileWorker?.dispose();
    _devicesSubscription?.cancel();
    scrollController.removeListener(_ensureNameIsDisplayed);
    _blocklistSubscription.cancel();
    super.onClose();
  }

  /// Removes the currently set [background].
  Future<void> removeBackground() => _settingsRepo.setBackground(null);

  /// Opens an image choose popup and sets the selected file as a [background].
  Future<void> pickBackground() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
      withReadStream: false,
    );

    if (result != null && result.files.isNotEmpty) {
      _settingsRepo.setBackground(result.files.first.bytes);
    }
  }

  /// Toggles [MyUser.muted] status.
  Future<void> toggleMute(bool enabled) async {
    if (!isMuting.value) {
      isMuting.value = true;

      try {
        await _myUserService.toggleMute(
          enabled ? null : MuteDuration.forever(),
        );
      } on ToggleMyUserMuteException catch (e) {
        MessagePopup.error(e);
      } catch (e) {
        MessagePopup.error(e);
        rethrow;
      } finally {
        isMuting.value = false;
      }
    }
  }

  /// Deletes the [MyUser.avatar] and [MyUser.callCover].
  Future<void> deleteAvatar() async {
    avatarUpload.value = RxStatus.loading();
    try {
      await _updateAvatar(null);
    } finally {
      avatarUpload.value = RxStatus.empty();
    }
  }

  Future<void> verify() async {
    _balanceService.person.value = person.value?.copyWith();
    verified.value = true;
  }

  /// Uploads an image and sets it as [MyUser.avatar] and [MyUser.callCover].
  Future<void> uploadAvatar() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result?.files.isNotEmpty == true) {
        avatarUpload.value = RxStatus.loading();
        await _updateAvatar(NativeFile.fromPlatformFile(result!.files.first));
      }
    } finally {
      avatarUpload.value = RxStatus.empty();
    }
  }

  /// Deletes the provided [email] from [MyUser.emails].
  Future<void> deleteEmail(UserEmail email) async {
    try {
      await _myUserService.deleteUserEmail(email);
    } catch (_) {
      MessagePopup.error('err_data_transfer'.l10n);
      rethrow;
    }
  }

  /// Deletes the provided [phone] from [MyUser.phones].
  Future<void> deletePhone(UserPhone phone) async {
    try {
      await _myUserService.deleteUserPhone(phone);
    } catch (_) {
      MessagePopup.error('err_data_transfer'.l10n);
      rethrow;
    }
  }

  /// Deletes [myUser]'s account.
  Future<void> deleteAccount() async {
    try {
      await _myUserService.deleteMyUser();
      router.go(Routes.auth);
      router.tab = HomeTab.chats;
    } catch (_) {
      MessagePopup.error('err_data_transfer'.l10n);
      rethrow;
    }
  }

  Future<void> setLeaveWhenAlone(bool enabled) =>
      _settingsRepo.setLeaveWhenAlone(enabled);

  Future<void> setBalanceTabEnabled(bool enabled) =>
      _settingsRepo.setBalanceTabEnabled(enabled);

  Future<void> setPublicsTabEnabled(bool enabled) =>
      _settingsRepo.setPublicsTabEnabled(enabled);

  Future<void> setCacheMaxSize(int size) =>
      CacheWorker.instance.setMaxSize(size);

  /// Creates a new [ChatDirectLink] with the specified [ChatDirectLinkSlug] and
  /// deletes the current active [ChatDirectLink] of the authenticated [MyUser]
  /// (if any).
  Future<void> createChatDirectLink(ChatDirectLinkSlug slug) async {
    await _myUserService.createChatDirectLink(slug);
  }

  Future<void> deleteChatDirectLink() async {
    await _myUserService.deleteChatDirectLink();
  }

  /// Updates [MyUser.name] field for the authenticated [MyUser].
  ///
  /// If [name] is null, then resets [MyUser.name] field.
  Future<void> updateUserName(UserName? name) async {
    await _myUserService.updateUserName(name);
  }

  /// Updates or resets the [MyUser.bio] field of the authenticated [MyUser].
  Future<void> updateUserBio(UserBio? bio) async {
    await _myUserService.updateUserBio(bio);
  }

  /// Updates or resets the [MyUser.status] field of the authenticated
  /// [MyUser].
  Future<void> updateUserStatus(UserTextStatus? status) async {
    print('updateUserStatus(${status?.val})');
    await _myUserService.updateUserStatus(status);
  }

  /// Updates [MyUser.login] field for the authenticated [MyUser].
  ///
  /// Throws [UpdateUserLoginException].
  Future<void> updateUserLogin(UserLogin login) async {
    await _myUserService.updateUserLogin(login);
  }

  /// Deletes the cache used by the application.
  Future<void> clearCache() => CacheWorker.instance.clear();

  /// Sets the [ApplicationSettings.workWithUsTabEnabled] value.
  Future<void> setWorkWithUsTabEnabled(bool enabled) =>
      _settingsRepo.setWorkWithUsTabEnabled(enabled);

  /// Removes the [user] from the blocklist of the authenticated [MyUser].
  Future<void> unblock(RxUser user) async {
    await _userService.unblockUser(user.id);
  }

  /// Logs out the current session and go to the [Routes.auth] page.
  Future<String> logout() => _authService.logout();

  /// Updates [MyUser.avatar] and [MyUser.callCover] with the provided [file].
  ///
  /// If [file] is `null`, then deletes the [MyUser.avatar] and
  /// [MyUser.callCover].
  Future<void> _updateAvatar(NativeFile? file) async {
    try {
      await Future.wait([
        _myUserService.updateAvatar(file),
        _myUserService.updateCallCover(file)
      ]);
    } on UpdateUserAvatarException catch (e) {
      MessagePopup.error(e);
    } on UpdateUserCallCoverException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Highlights the provided [tab].
  Future<void> highlight(ProfileTab? tab) async {
    highlightIndex.value = tab?.index;

    _highlightTimer?.cancel();
    _highlightTimer = Timer(_highlightTimeout, () {
      highlightIndex.value = null;
    });
  }

  Rx<UserCredential?> credentials = Rx(null);

  Future<void> continueWithGoogle() async {
    if (kDebugMode) {
      try {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');

        final auth = FirebaseAuth.instanceFor(app: router.firebase!);

        final UserCredential credential;
        if (PlatformUtils.isWeb) {
          credential = await auth.signInWithPopup(googleProvider);
        } else {
          credential = await auth.signInWithProvider(googleProvider);
        }

        providers.add((OAuthProvider.google, credential));
      } catch (e) {
        if (e.toString() != 'popup_closed') {
          MessagePopup.error(e);
        }
      }

      return;
    }

    try {
      final googleUser =
          await GoogleSignIn(clientId: Config.googleClientId).signIn();

      final googleAuth = await googleUser?.authentication;

      if (googleAuth != null) {
        final creds = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final auth = FirebaseAuth.instanceFor(app: router.firebase!);

        providers.add(
          (OAuthProvider.google, await auth.signInWithCredential(creds)),
        );
      }
    } catch (e) {
      Log.error(e.toString());
    }
  }

  Future<void> continueWithApple() async {
    try {
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');

      final auth = FirebaseAuth.instanceFor(app: router.firebase!);

      final UserCredential credential;
      if (PlatformUtils.isWeb) {
        credential = await auth.signInWithPopup(appleProvider);
      } else {
        credential = await auth.signInWithProvider(appleProvider);
      }

      providers.add((OAuthProvider.apple, credential));
    } catch (e) {
      Log.error(e.toString());
    }
  }

  Future<void> continueWithGitHub() async {
    try {
      final githubProvider = GithubAuthProvider();
      githubProvider.addScope('email');

      final auth = FirebaseAuth.instanceFor(app: router.firebase!);

      final UserCredential credential;
      if (PlatformUtils.isWeb) {
        credential = await auth.signInWithPopup(githubProvider);
      } else {
        credential = await auth.signInWithProvider(githubProvider);
      }

      providers.add((OAuthProvider.github, credential));
    } catch (e) {
      Log.error(e.toString());
    }
  }

  /// Sorts the [blocklist] by the [User.isBlocked] value.
  void _sortBlocklist() {
    blocklist.sort(
      (a, b) {
        if (a.user.value.isBlocked == null || b.user.value.isBlocked == null) {
          return 0;
        }

        return b.user.value.isBlocked!.at.compareTo(a.user.value.isBlocked!.at);
      },
    );
  }
}

/// Extension adding text and [Color] representations of a [Presence] value.
extension PresenceL10n on Presence {
  /// Returns text representation of a current value.
  String? localizedString() {
    switch (this) {
      case Presence.present:
        return 'label_presence_present'.l10n;
      case Presence.away:
        return 'label_presence_away'.l10n;
      case Presence.artemisUnknown:
        return null;
    }
  }

  /// Returns a [Color] representing this [Presence].
  Color? getColor() {
    final Style style = Theme.of(router.context!).style;

    return switch (this) {
      Presence.present => style.colors.acceptAuxiliary,
      Presence.away => style.colors.warning,
      Presence.artemisUnknown => null,
    };
  }
}
