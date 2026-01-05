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
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/api/backend/schema.dart'
    show
        AddUserEmailErrorCode,
        AddUserPhoneErrorCode,
        CropAreaInput,
        UpdateUserAvatarErrorCode,
        UpdateUserCallCoverErrorCode,
        UserPresence;
import '/domain/model/application_settings.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/file.dart';
import '/domain/model/media_settings.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/native_file.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/domain/repository/session.dart';
import '/domain/repository/settings.dart';
import '/domain/service/auth.dart';
import '/domain/service/blocklist.dart';
import '/domain/service/chat.dart';
import '/domain/service/my_user.dart';
import '/domain/service/session.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/widget/text_field.dart';
import '/ui/worker/cache.dart';
import '/ui/worker/upgrade.dart';
import '/util/localized_exception.dart';
import '/util/media_utils.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'add_email/view.dart';
import 'crop_avatar/view.dart';
import 'welcome_field/controller.dart';

export 'view.dart';

/// Controller of the [Routes.me] page.
class MyProfileController extends GetxController {
  MyProfileController(
    this._myUserService,
    this._sessionService,
    this._settingsRepository,
    this._authService,
    this._chatService,
    this._blocklistService,
    this._upgradeWorker,
    this._cacheWorker,
  );

  /// Status of an [uploadAvatar] or [deleteAvatar] completion.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning no [uploadAvatar]/[deleteAvatar] is executing.
  /// - `status.isLoading`, meaning [uploadAvatar]/[deleteAvatar] is executing.
  final Rx<RxStatus> avatarUpload = Rx(RxStatus.empty());

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [ScrollController] to pass to a [Scrollbar] in the [ProfileTab.devices]
  /// section.
  final ScrollController devicesScrollController = ScrollController();

  /// [ItemScrollController] of the profile's [ScrollablePositionedList].
  final ItemScrollController itemScrollController = ItemScrollController();

  /// [ItemPositionsListener] of the profile's [ScrollablePositionedList].
  final ItemPositionsListener positionsListener =
      ItemPositionsListener.create();

  /// Index of the initial profile page section to show in a
  /// [ScrollablePositionedList].
  int listInitIndex = 0;

  /// [TextFieldState] of a [UserEmail] text input.
  late final TextFieldState email;

  /// [TextFieldState] of a [UserPhone] text input.
  late final TextFieldState phone;

  /// Indicator whether there's an ongoing [toggleMute] happening.
  ///
  /// Used to discard repeated toggling.
  final RxBool isMuting = RxBool(false);

  /// Indicator whether the [ProfileTab.signing] section is expanded.
  final RxBool expanded = RxBool(false);

  /// List of [DeviceDetails] of all the available devices.
  final RxList<DeviceDetails> devices = RxList<DeviceDetails>([]);

  /// Index of an item from [ProfileTab] that should be highlighted.
  final RxnInt highlightIndex = RxnInt(null);

  /// Indicator whether [MyUser.name] and [MyUser.avatar] should be displayed in
  /// the [AppBar].
  final RxBool displayName = RxBool(false);

  /// Indicator whether the [sessions] are being updated.
  final RxBool sessionsUpdating = RxBool(false);

  /// [WelcomeFieldController] for forming and editing a [WelcomeMessage].
  late final WelcomeFieldController welcome;

  /// [GlobalKey] of the [WelcomeFieldView] to prevent its state being rebuilt.
  final GlobalKey welcomeFieldKey = GlobalKey();

  /// [MyUser.name] field state.
  late final TextFieldState name = TextFieldState(
    text: myUser.value?.name?.val,
    onFocus: (s) async {
      s.error.value = null;

      if (s.text.trim().isNotEmpty) {
        try {
          UserName(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
          return;
        }
      }

      final UserName? name = UserName.tryParse(s.text);

      try {
        await updateUserName(name);
      } catch (_) {
        s.error.value = 'err_data_transfer'.l10n;
      }
    },
  );

  /// [MyUser.login] field state.
  late final TextFieldState login = TextFieldState(
    text: myUser.value?.login?.val,
    onFocus: (s) async {
      s.error.value = null;

      if (s.text.trim().isNotEmpty) {
        try {
          UserLogin(s.text.toLowerCase());
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_login_input'.l10n;
          return;
        }
      }

      final UserLogin? login = UserLogin.tryParse(s.text.toLowerCase());

      try {
        await updateUserLogin(login);
      } on UpdateUserLoginException catch (e) {
        s.error.value = e.toMessage();
      } catch (_) {
        s.error.value = 'err_data_transfer'.l10n;
      }
    },
  );

  /// [MyUser.bio] field state.
  late final TextFieldState about = TextFieldState(
    text: myUser.value?.bio?.val,
    onFocus: (s) async {
      s.error.value = null;

      if (s.text.trim().isNotEmpty) {
        try {
          UserBio(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
          return;
        }
      }

      final UserBio? bio = UserBio.tryParse(s.text);

      try {
        await updateUserBio(bio);
      } catch (_) {
        s.error.value = 'err_data_transfer'.l10n;
      }
    },
  );

  /// [MyUser.status] field state.
  late final TextFieldState status = TextFieldState(
    text: myUser.value?.status?.val,
    onFocus: (s) async {
      s.error.value = null;

      if (s.text.trim().isNotEmpty) {
        try {
          UserTextStatus(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
          return;
        }
      }

      final UserTextStatus? status = UserTextStatus.tryParse(s.text);

      try {
        await updateUserStatus(status);
      } catch (_) {
        s.error.value = 'err_data_transfer'.l10n;
      }
    },
  );

  /// Indicator whether mute/unmute hotkey is being recorded right now.
  final RxBool hotKeyRecording = RxBool(false);

  /// Service managing current [Credentials].
  final AuthService _authService;

  /// Service responsible for [MyUser] management.
  final MyUserService _myUserService;

  /// Service responsible for [Session]s management.
  final SessionService _sessionService;

  /// Settings repository, used to update the [ApplicationSettings].
  final AbstractSettingsRepository _settingsRepository;

  /// [ChatService] for uploading the [Attachment]s for [WelcomeMessage].
  final ChatService _chatService;

  /// [BlocklistService] for retrieving the [BlocklistService.count].
  final BlocklistService _blocklistService;

  /// [UpgradeWorker] for retrieving the current application version.
  final UpgradeWorker _upgradeWorker;

  /// [CacheWorker] for retrieving the [CacheWorker.downloadsDirectory].
  final CacheWorker _cacheWorker;

  /// Worker to react on [RouterState.profileSection] changes.
  Worker? _profileWorker;

  /// Worker to update [name], [login] and other fields on the [MyUser] changes.
  Worker? _myUserWorker;

  /// [StreamSubscription] for the [MediaUtilsImpl.onDeviceChange] stream
  /// updating the [devices].
  StreamSubscription? _devicesSubscription;

  /// [Duration] of the highlighting.
  static const Duration _highlightTimeout = Duration(seconds: 1);

  /// [Timer] resetting the [highlightIndex] value after the [_highlightTimeout]
  /// has passed.
  Timer? _highlightTimer;

  /// [Sentry] transaction monitoring this [MyProfileController] readiness.
  final ISentrySpan _ready = Sentry.startTransaction(
    'ui.my_profile.ready',
    'ui',
    autoFinishAfter: const Duration(minutes: 2),
  )..startChild('ready');

  /// [KeyDownEvent]s recorded during [hotKeyRecording].
  final List<KeyDownEvent> _keysRecorded = [];

  /// [Timer] disabling the [hotKeyRecording] after any [_keysRecorded] are
  /// added.
  Timer? _timer;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Returns the current [ApplicationSettings] value.
  Rx<ApplicationSettings?> get settings =>
      _settingsRepository.applicationSettings;

  /// Returns the current background's [Uint8List] value.
  Rx<Uint8List?> get background => _settingsRepository.background;

  /// Returns the current [MediaSettings] value.
  Rx<MediaSettings?> get media => _settingsRepository.mediaSettings;

  /// Returns the list of active [RxSession]s.
  RxList<RxSession> get sessions => _sessionService.sessions;

  /// Returns the current [Credentials].
  Rx<Credentials?> get credentials => _authService.credentials;

  /// Total [BlocklistRecord]s count in the blocklist of the currently
  /// authenticated [MyUser].
  RxInt get blocklistCount => _blocklistService.count;

  /// Returns the latest available fetched [Release] of application.
  Rx<Release?> get latestRelease => _upgradeWorker.latest;

  /// Returns the [Directory] the [CacheWorker] is supposed to put downloads to.
  Rx<Directory?> get downloadsDirectory => _cacheWorker.downloadsDirectory;

  /// Returns the count of [Chat]s being muted.
  int get mutedChatsCount => _chatService.paginated.values
      .where((e) => e.chat.value.muted != null)
      .length;

  @override
  void onInit() {
    if (!PlatformUtils.isMobile) {
      try {
        _devicesSubscription = MediaUtils.onDeviceChange.listen(
          (e) => devices.value = e,
        );
        MediaUtils.enumerateDevices().then((e) => devices.value = e);
      } catch (_) {
        // No-op, shouldn't break the view.
      }
    }

    listInitIndex = router.profileSection.value?.index ?? 0;

    bool ignoreWorker = false;
    bool ignorePositions = false;

    _profileWorker = ever(router.profileSection, (ProfileTab? tab) async {
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
    });

    positionsListener.itemPositions.addListener(() {
      if (!ignorePositions) {
        final ProfileTab tab = ProfileTab
            .values[positionsListener.itemPositions.value.first.index];
        if (router.profileSection.value != tab) {
          ignoreWorker = true;
          router.profileSection.value = tab;
          Future.delayed(Duration.zero, () => ignoreWorker = false);
        }
      }
    });

    phone = TextFieldState(
      approvable: true,
      onFocus: (s) {
        if (s.text.trim().isNotEmpty) {
          try {
            final phone = UserPhone(s.text.replaceAll(' ', ''));

            if (myUser.value!.phones.confirmed.contains(phone) ||
                myUser.value?.phones.unconfirmed == phone) {
              s.error.value = 'err_you_already_add_this_email'.l10n;
            }
          } on FormatException {
            s.error.value = 'err_incorrect_input'.l10n;
          }
        }
      },
      onSubmitted: (s) async {
        if (s.text.trim().isEmpty ||
            (s.error.value != null && s.resubmitOnError.isFalse)) {
          return;
        }

        final phone = UserPhone(s.text.replaceAll(' ', ''));

        s.clear();

        bool modalVisible = true;

        _myUserService
            .addUserPhone(phone, locale: L10n.chosen.value?.toString())
            .onError((e, _) {
              s.unchecked = phone.val;

              if (e is AddUserPhoneException) {
                s.error.value = e.toMessage();
                s.resubmitOnError.value = e.code == AddUserPhoneErrorCode.busy;
              } else {
                s.error.value = 'err_data_transfer'.l10n;
                s.resubmitOnError.value = true;
              }

              s.unsubmit();

              if (modalVisible) {
                Navigator.of(router.context!).pop();
              }
            });

        // await AddPhoneView.show(
        //   router.context!,
        //   timeout: true,
        //   phone: phone,
        // ).then((_) => modalVisible = false);
      },
    );

    email = TextFieldState(
      approvable: true,
      onFocus: (s) {
        if (s.text.trim().isNotEmpty) {
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
        if (s.text.trim().isEmpty ||
            (s.error.value != null && s.resubmitOnError.isFalse)) {
          return;
        }

        final email = UserEmail(s.text.toLowerCase());

        s.clear();

        bool modalVisible = true;

        _myUserService
            .addUserEmail(email, locale: L10n.chosen.value?.toString())
            .onError((e, _) {
              s.unchecked = email.val;

              if (e is AddUserEmailException) {
                s.error.value = e.toMessage();
                s.resubmitOnError.value = e.code == AddUserEmailErrorCode.busy;
              } else {
                s.error.value = 'err_data_transfer'.l10n;
                s.resubmitOnError.value = true;
              }

              s.unsubmit();

              if (modalVisible) {
                Navigator.of(router.context!).pop();
              }
            });

        await AddEmailView.show(
          router.context!,
          email: email,
          timeout: true,
        ).then((_) => modalVisible = false);
      },
    );

    scrollController.addListener(_ensureNameDisplayed);

    welcome = WelcomeFieldController(
      _chatService,
      onSubmit: () async {
        final text = welcome.field.text.trim();

        if (text.isNotEmpty || welcome.attachments.isNotEmpty) {
          final String previousText = text.toString();
          final List<Attachment> previousAttachments = welcome.attachments
              .map((e) => e.value)
              .toList();

          updateWelcomeMessage(
            text: text.isEmpty ? null : ChatMessageText(text),
            attachments: welcome.attachments.map((e) => e.value).toList(),
          ).onError((e, _) {
            welcome.field.unchecked = previousText;
            welcome.attachments.addAll(
              previousAttachments.map((e) => MapEntry(GlobalKey(), e)),
            );

            if (e is LocalizedExceptionMixin) {
              MessagePopup.error(e.toMessage());
            } else {
              MessagePopup.error('err_data_transfer'.l10n);
            }
          });

          welcome.edited.value = null;
          welcome.clear();
        }
      },
    );

    _myUserWorker = ever(myUser, (myUser) {
      if (!name.focus.hasFocus) {
        name.unchecked = myUser?.name?.val;
      }

      if (!about.focus.hasFocus) {
        about.unchecked = myUser?.bio?.val;
      }

      if (!status.focus.hasFocus) {
        status.unchecked = myUser?.status?.val;
      }

      if (!login.focus.hasFocus) {
        login.unchecked = myUser?.login?.val;
      }
    });

    super.onInit();
  }

  @override
  void onReady() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _ready.finish());
    super.onReady();
  }

  @override
  void onClose() {
    _profileWorker?.dispose();
    _devicesSubscription?.cancel();
    scrollController.dispose();
    _myUserWorker?.dispose();
    HardwareKeyboard.instance.removeHandler(_hotKeyListener);
    super.onClose();
  }

  /// Removes the currently set [background].
  Future<void> removeBackground() => _settingsRepository.setBackground(null);

  /// Opens an image choose popup and sets the selected file as a [background].
  Future<void> pickBackground() async {
    FilePickerResult? result = await PlatformUtils.pickFiles(
      type: FileType.custom,
      allowedExtensions: NativeFile.images,
      allowMultiple: false,
      withData: true,
      withReadStream: false,
      lockParentWindow: true,
    );

    if (result != null && result.files.isNotEmpty) {
      _settingsRepository.setBackground(result.files.first.bytes);
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
      await _updateAvatar(null, null);
    } finally {
      avatarUpload.value = RxStatus.empty();
    }
  }

  /// Opens the [CropAvatarView] to update the [MyUser.avatar] with the
  /// [CropAreaInput] returned from it.
  Future<void> editAvatar() async {
    final ImageFile? file = myUser.value?.avatar?.original;
    if (file == null) {
      return;
    }

    avatarUpload.value = RxStatus.loading();

    try {
      final CacheEntry cache = await CacheWorker.instance.get(
        url: file.url,
        checksum: file.checksum,
      );

      if (cache.bytes != null) {
        final CropAreaInput? crop = await CropAvatarView.show(
          router.context!,
          cache.bytes!,
        );

        if (crop != null) {
          await _updateAvatar(
            NativeFile(
              name: file.name,
              size: cache.bytes!.lengthInBytes,
              bytes: cache.bytes,
            ),
            crop,
          );
        }
      }
    } finally {
      avatarUpload.value = RxStatus.empty();
    }
  }

  /// Crops and uploads an image and sets it as [MyUser.avatar] and
  /// [MyUser.callCover].
  Future<void> uploadAvatar() async {
    try {
      final FilePickerResult? result = await PlatformUtils.pickFiles(
        type: FileType.custom,
        allowedExtensions: NativeFile.images,
        allowMultiple: false,
        withData: true,
        lockParentWindow: true,
      );

      if (result?.files.isNotEmpty == true) {
        avatarUpload.value = RxStatus.loading();

        final PlatformFile file = result!.files.first;
        final CropAreaInput? crop = await CropAvatarView.show(
          router.context!,
          file.bytes!,
        );
        if (crop == null) {
          return;
        }

        await _updateAvatar(
          NativeFile.fromPlatformFile(result.files.first),
          crop,
        );
      }
    } finally {
      avatarUpload.value = RxStatus.empty();
    }
  }

  /// Deletes the provided [email] from [MyUser.emails].
  Future<void> deleteEmail(UserEmail email) async {
    try {
      await _myUserService.removeUserEmail(email);
    } catch (_) {
      MessagePopup.error('err_data_transfer'.l10n);
      rethrow;
    }
  }

  /// Deletes the provided [phone] from [MyUser.phones].
  Future<void> deletePhone(UserPhone phone) async {
    try {
      await _myUserService.removeUserPhone(phone);
    } catch (_) {
      MessagePopup.error('err_data_transfer'.l10n);
      rethrow;
    }
  }

  /// Deletes [myUser]'s account.
  Future<void> deleteAccount() async {
    try {
      await _myUserService.deleteMyUser();
      router.auth();
      router.tab = HomeTab.chats;
    } catch (_) {
      MessagePopup.error('err_data_transfer'.l10n);
      rethrow;
    }
  }

  /// Creates a new [ChatDirectLink] with the specified [ChatDirectLinkSlug] and
  /// deletes the current active [ChatDirectLink] of the authenticated [MyUser]
  /// (if any).
  Future<void> createChatDirectLink(ChatDirectLinkSlug slug) async {
    await _myUserService.createChatDirectLink(slug);
  }

  /// Deletes the current [ChatDirectLink] of the authenticated [MyUser].
  Future<void> deleteChatDirectLink() async {
    await _myUserService.deleteChatDirectLink();
  }

  /// Updates [MyUser.name] field for the authenticated [MyUser].
  ///
  /// If [name] is null, then resets [MyUser.name] field.
  Future<void> updateUserName(UserName? name) async {
    await _myUserService.updateUserName(name);
  }

  /// Updates or resets [MyUser.status] field for the authenticated [MyUser].
  Future<void> updateUserStatus(UserTextStatus? status) async {
    await _myUserService.updateUserStatus(status);
  }

  /// Updates or resets the [MyUser.bio] field of the authenticated [MyUser].
  Future<void> updateUserBio(UserBio? bio) async {
    await _myUserService.updateUserBio(bio);
  }

  /// Updates [MyUser.login] field for the authenticated [MyUser].
  Future<void> updateUserLogin(UserLogin? login) async {
    await _myUserService.updateUserLogin(login);
  }

  /// Sets the [MediaSettings.noiseSuppression] value.
  Future<void> setNoiseSuppression(NoiseSuppressionLevelWithOff level) async {
    switch (level) {
      case NoiseSuppressionLevelWithOff.off:
        await _settingsRepository.setNoiseSuppression(enabled: false);
        break;

      case NoiseSuppressionLevelWithOff.low:
      case NoiseSuppressionLevelWithOff.moderate:
      case NoiseSuppressionLevelWithOff.high:
      case NoiseSuppressionLevelWithOff.veryHigh:
        await _settingsRepository.setNoiseSuppression(
          enabled: true,
          level: level.toLevel(),
        );
        break;
    }
  }

  /// Sets the [MediaSettings.echoCancellation] value.
  Future<void> setEchoCancellation(bool enabled) async {
    await _settingsRepository.setEchoCancellation(enabled);
  }

  /// Sets the [MediaSettings.autoGainControl] value.
  Future<void> setAutoGainControl(bool enabled) async {
    await _settingsRepository.setAutoGainControl(enabled);
  }

  /// Sets the [MediaSettings.highPassFilter] value.
  Future<void> setHighPassFilter(bool enabled) async {
    await _settingsRepository.setHighPassFilter(enabled);
  }

  /// Updates [MyUser.login] field for the authenticated [MyUser].
  Future<void> updateWelcomeMessage({
    ChatMessageText? text,
    List<Attachment>? attachments,
  }) async {
    await _myUserService.updateWelcomeMessage(
      text: text,
      attachments: attachments,
    );
  }

  /// Deletes the cache used by the application.
  Future<void> clearCache() => CacheWorker.instance.clear();

  /// Highlights the provided [tab].
  Future<void> highlight(ProfileTab? tab) async {
    highlightIndex.value = tab?.index;

    _highlightTimer?.cancel();
    _highlightTimer = Timer(_highlightTimeout, () {
      highlightIndex.value = null;
    });
  }

  /// Toggles [hotKeyRecording] on and off, storing the [_keysRecorded].
  void toggleHotKey([bool? value]) {
    if (value == false) {
      if (_keysRecorded.isNotEmpty) {
        final List<HotKeyModifier> modifiers = [];
        PhysicalKeyboardKey? lastKey;

        for (var e in _keysRecorded) {
          if (e.logicalKey.isModifier) {
            modifiers.add(e.logicalKey.asModifier!);
          } else {
            lastKey = e.physicalKey;
          }
        }

        _settingsRepository.setMuteKeys([
          ...modifiers.map((e) => e.name),
          if (lastKey != null) lastKey.usbHidUsage.toString(),
        ]);
      }
    }

    value ??= !hotKeyRecording.value;

    _timer?.cancel();
    _timer = null;
    _keysRecorded.clear();

    hotKeyRecording.value = value;

    if (hotKeyRecording.value) {
      HardwareKeyboard.instance.addHandler(_hotKeyListener);
    } else {
      HardwareKeyboard.instance.removeHandler(_hotKeyListener);
    }
  }

  /// Records the provided [event] to the [_keysRecorded], if it's not a
  /// modifier.
  bool _hotKeyListener(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (!event.logicalKey.isModifier) {
        _timer ??= Timer(
          Duration(milliseconds: 200),
          () => toggleHotKey(false),
        );
      }

      _keysRecorded.add(event);
      return true;
    }

    return false;
  }

  /// Updates [MyUser.avatar] and [MyUser.callCover] with the provided [file]
  /// and [crop].
  ///
  /// If [file] is `null`, then deletes [MyUser.avatar] and
  /// [MyUser.callCover].
  Future<void> _updateAvatar(NativeFile? file, CropAreaInput? crop) async {
    try {
      await Future.wait([
        _myUserService.updateAvatar(file, crop: crop),
        _myUserService.updateCallCover(file),
      ]);
    } on UpdateUserAvatarException catch (e) {
      switch (e.code) {
        case UpdateUserAvatarErrorCode.invalidCropCoordinates:
        case UpdateUserAvatarErrorCode.invalidCropPoints:
          MessagePopup.error('err_data_transfer'.l10n);

        case UpdateUserAvatarErrorCode.malformed:
        case UpdateUserAvatarErrorCode.unsupportedFormat:
        case UpdateUserAvatarErrorCode.invalidSize:
        case UpdateUserAvatarErrorCode.invalidDimensions:
        case UpdateUserAvatarErrorCode.artemisUnknown:
          MessagePopup.error(e);
      }
    } on UpdateUserCallCoverException catch (e) {
      switch (e.code) {
        case UpdateUserCallCoverErrorCode.invalidCropCoordinates:
        case UpdateUserCallCoverErrorCode.invalidCropPoints:
          MessagePopup.error('err_data_transfer'.l10n);

        case UpdateUserCallCoverErrorCode.malformed:
        case UpdateUserCallCoverErrorCode.unsupportedFormat:
        case UpdateUserCallCoverErrorCode.invalidSize:
        case UpdateUserCallCoverErrorCode.invalidDimensions:
        case UpdateUserCallCoverErrorCode.artemisUnknown:
          MessagePopup.error(e);
      }
    } catch (e) {
      MessagePopup.error('err_data_transfer'.l10n);
      rethrow;
    }
  }

  /// Ensures the [displayName] is either `true` or `false` based on the
  /// [scrollController].
  void _ensureNameDisplayed() {
    displayName.value = scrollController.position.pixels >= 250;
  }
}

/// Extension adding text and [Color] representations of a [UserPresence] value.
extension PresenceL10n on UserPresence {
  /// Returns text representation of a current value.
  String? localizedString() {
    switch (this) {
      case UserPresence.present:
        return 'label_presence_present'.l10n;
      case UserPresence.away:
        return 'label_presence_away'.l10n;
      case UserPresence.artemisUnknown:
        return null;
    }
  }

  /// Returns a [Color] representing this [UserPresence].
  Color? getColor() {
    final Style style = Theme.of(router.context!).style;

    return switch (this) {
      UserPresence.present => style.colors.acceptAuxiliary,
      UserPresence.away => style.colors.warning,
      UserPresence.artemisUnknown => null,
    };
  }
}

/// Extension adding indicators whether a [LogicalKeyboardKey] is a modifier.
extension on LogicalKeyboardKey {
  /// Indicates whether this [LogicalKeyboardKey] is a modifier.
  bool get isModifier => switch (this) {
    LogicalKeyboardKey.alt ||
    LogicalKeyboardKey.altLeft ||
    LogicalKeyboardKey.altRight ||
    LogicalKeyboardKey.meta ||
    LogicalKeyboardKey.metaLeft ||
    LogicalKeyboardKey.metaRight ||
    LogicalKeyboardKey.control ||
    LogicalKeyboardKey.controlLeft ||
    LogicalKeyboardKey.controlRight ||
    LogicalKeyboardKey.fn ||
    LogicalKeyboardKey.shift ||
    LogicalKeyboardKey.shiftLeft ||
    LogicalKeyboardKey.shiftRight => true,
    (_) => false,
  };

  /// Returns the [HotKeyModifier] of this [LogicalKeyboardKey], if it is a
  /// modifier.
  HotKeyModifier? get asModifier => switch (this) {
    LogicalKeyboardKey.alt ||
    LogicalKeyboardKey.altLeft ||
    LogicalKeyboardKey.altRight => HotKeyModifier.alt,
    LogicalKeyboardKey.meta ||
    LogicalKeyboardKey.metaLeft ||
    LogicalKeyboardKey.metaRight => HotKeyModifier.meta,
    LogicalKeyboardKey.control ||
    LogicalKeyboardKey.controlLeft ||
    LogicalKeyboardKey.controlRight => HotKeyModifier.control,
    LogicalKeyboardKey.fn => HotKeyModifier.fn,
    LogicalKeyboardKey.shift ||
    LogicalKeyboardKey.shiftLeft ||
    LogicalKeyboardKey.shiftRight => HotKeyModifier.shift,
    (_) => null,
  };
}
