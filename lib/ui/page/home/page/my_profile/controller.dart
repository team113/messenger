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
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/api/backend/schema.dart'
    show AddUserEmailErrorCode, AddUserPhoneErrorCode, Presence;
import '/domain/model/application_settings.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/media_settings.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/native_file.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/domain/repository/settings.dart';
import '/domain/service/auth.dart';
import '/domain/service/chat.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/widget/text_field.dart';
import '/ui/worker/cache.dart';
import '/util/localized_exception.dart';
import '/util/media_utils.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'add_email/view.dart';
import 'add_phone/controller.dart';
import 'welcome_field/controller.dart';

export 'view.dart';

/// Controller of the [Routes.me] page.
class MyProfileController extends GetxController {
  MyProfileController(
    this._myUserService,
    this._settingsRepo,
    this._authService,
    this._chatService,
  );

  /// Status of an [uploadAvatar] or [deleteAvatar] completion.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning no [uploadAvatar]/[deleteAvatar] is executing.
  /// - `status.isLoading`, meaning [uploadAvatar]/[deleteAvatar] is executing.
  final Rx<RxStatus> avatarUpload = Rx(RxStatus.empty());

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [FlutterListViewController]
  final FlutterListViewController listController = FlutterListViewController();

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

  /// Service managing current [Credentials].
  final AuthService _authService;

  /// Service responsible for [MyUser] management.
  final MyUserService _myUserService;

  /// Settings repository, used to update the [ApplicationSettings].
  final AbstractSettingsRepository _settingsRepo;

  /// [ChatService] for uploading the [Attachment]s for [WelcomeMessage].
  final ChatService _chatService;

  /// Worker to react on [RouterState.profileSection] changes.
  Worker? _profileWorker;

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

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Returns the current [ApplicationSettings] value.
  Rx<ApplicationSettings?> get settings => _settingsRepo.applicationSettings;

  /// Returns the current background's [Uint8List] value.
  Rx<Uint8List?> get background => _settingsRepo.background;

  /// Returns the current [MediaSettings] value.
  Rx<MediaSettings?> get media => _settingsRepo.mediaSettings;

  /// Returns the list of active [Session]s.
  RxList<Session> get sessions => _myUserService.sessions;

  /// Returns the current [Credentials].
  Rx<Credentials?> get credentials => _authService.credentials;

  @override
  void onInit() {
    if (!PlatformUtils.isMobile) {
      try {
        _devicesSubscription =
            MediaUtils.onDeviceChange.listen((e) => devices.value = e);
        MediaUtils.enumerateDevices().then((e) => devices.value = e);
      } catch (_) {
        // No-op, shouldn't break the view.
      }
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
          await listController.sliverController.animateToIndex(
            tab?.index ?? 0,
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
        if (s.text.isNotEmpty) {
          try {
            final phone = UserPhone(s.text.replaceAll(' ', ''));

            if (myUser.value!.phones.confirmed.contains(phone) ||
                myUser.value?.phones.unconfirmed == phone) {
              s.error.value = 'err_you_already_add_this_phone'.l10n;
            }
          } on FormatException {
            s.error.value = 'err_incorrect_phone'.l10n;
          }
        }
      },
      onSubmitted: (s) async {
        if (s.text.isEmpty ||
            (s.error.value != null && s.resubmitOnError.isFalse)) {
          return;
        }

        final phone = UserPhone(s.text.replaceAll(' ', ''));

        s.clear();

        bool modalVisible = true;

        _myUserService
            .addUserPhone(
          phone,
          locale: L10n.chosen.value?.toString(),
        )
            .onError(
          (e, __) {
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
          },
        );

        await AddPhoneView.show(
          router.context!,
          timeout: true,
          phone: phone,
        ).then((_) => modalVisible = false);
      },
    );

    email = TextFieldState(
      approvable: true,
      onFocus: (s) {
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
        if (s.text.isEmpty ||
            (s.error.value != null && s.resubmitOnError.isFalse)) {
          return;
        }

        final email = UserEmail(s.text.toLowerCase());

        s.clear();

        bool modalVisible = true;

        _myUserService
            .addUserEmail(
          email,
          locale: L10n.chosen.value?.toString(),
        )
            .onError((e, __) {
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
          final List<Attachment> previousAttachments =
              welcome.attachments.map((e) => e.value).toList();

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
      lockParentWindow: true,
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

  /// Uploads an image and sets it as [MyUser.avatar] and [MyUser.callCover].
  Future<void> uploadAvatar() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
        lockParentWindow: true,
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

  /// Updates or resets the [MyUser.bio] field of the authenticated [MyUser].
  Future<void> updateUserBio(UserBio? bio) async {
    await _myUserService.updateUserBio(bio);
  }

  /// Updates [MyUser.login] field for the authenticated [MyUser].
  Future<void> updateUserLogin(UserLogin? login) async {
    await _myUserService.updateUserLogin(login);
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

  /// Sets the [ApplicationSettings.workWithUsTabEnabled] value.
  Future<void> setWorkWithUsTabEnabled(bool enabled) =>
      _settingsRepo.setWorkWithUsTabEnabled(enabled);

  /// Highlights the provided [tab].
  Future<void> highlight(ProfileTab? tab) async {
    highlightIndex.value = tab?.index;

    _highlightTimer?.cancel();
    _highlightTimer = Timer(_highlightTimeout, () {
      highlightIndex.value = null;
    });
  }

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

  /// Ensures the [displayName] is either `true` or `false` based on the
  /// [scrollController].
  void _ensureNameDisplayed() {
    displayName.value = scrollController.position.pixels >= 250;
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
