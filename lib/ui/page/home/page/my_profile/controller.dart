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

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/ui/page/home/page/chat/message_field/controller.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/application_settings.dart';
import '/domain/model/gallery_item.dart';
import '/domain/model/image_gallery_item.dart';
import '/domain/model/media_settings.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/native_file.dart';
import '/domain/model/user.dart';
import '/domain/repository/settings.dart';
import '/domain/repository/user.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/ui/widget/text_field.dart';
import '/util/media_utils.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

export 'view.dart';

/// Controller of the [Routes.me] page.
class MyProfileController extends GetxController {
  MyProfileController(
    this._myUserService,
    this._settingsRepo,
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

  /// [ItemScrollController] of the profile's [ScrollablePositionedList].
  final ItemScrollController itemScrollController = ItemScrollController();

  /// [ItemPositionsListener] of the profile's [ScrollablePositionedList].
  final ItemPositionsListener positionsListener =
      ItemPositionsListener.create();

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

  final TextFieldState allMessageCost = TextFieldState(text: '0.00');
  final TextFieldState allCallCost = TextFieldState(text: '0.00');

  final TextFieldState contactMessageCost = TextFieldState(text: '0.00');
  final TextFieldState contactCallCost = TextFieldState(text: '0.00');

  /// Indicator whether there's an ongoing [toggleMute] happening.
  ///
  /// Used to discard repeated toggling.
  final RxBool isMuting = RxBool(false);

  /// List of [MediaDeviceDetails] of all the available devices.
  final RxList<MediaDeviceDetails> devices = RxList<MediaDeviceDetails>([]);

  /// [GlobalKey] of an [AvatarWidget] displayed used to open a [GalleryPopup].
  final GlobalKey avatarKey = GlobalKey();

  final RxBool verified = RxBool(false);
  final RxBool hintVerified = RxBool(false);

  final Rx<ChatMessage?> welcome = Rx(null);

  late final MessageFieldController send;

  /// Service responsible for [MyUser] management.
  final MyUserService _myUserService;

  final ChatService _chatService;

  /// Settings repository, used to update the [ApplicationSettings].
  final AbstractSettingsRepository _settingsRepo;

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

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Returns the current [ApplicationSettings] value.
  Rx<ApplicationSettings?> get settings => _settingsRepo.applicationSettings;

  /// Returns the current background's [Uint8List] value.
  Rx<Uint8List?> get background => _settingsRepo.background;

  /// Returns the current [MediaSettings] value.
  Rx<MediaSettings?> get media => _settingsRepo.mediaSettings;

  /// Returns the [User]s blacklisted by the authenticated [MyUser].
  RxList<RxUser> get blacklist => _myUserService.blacklist;

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

    verified.value =
        _myUserService.myUser.value?.emails.confirmed.isNotEmpty == true;

    _myUserWorker = ever(
      _myUserService.myUser,
      (MyUser? v) {
        if (!name.focus.hasFocus &&
            !name.changed.value &&
            name.editable.value) {
          name.unchecked = v?.name?.val;
        }
        if (!login.focus.hasFocus &&
            !login.changed.value &&
            login.editable.value) {
          login.unchecked = v?.login?.val;
        }
        if (!link.focus.hasFocus &&
            !link.changed.value &&
            link.editable.value) {
          link.unchecked = v?.chatDirectLink?.slug.val;
        }

        verified.value = v?.emails.confirmed.isNotEmpty == true;
      },
    );

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

    allMessageCost.isFocused.listen((b) {
      if (b) {
        allMessageCost.unchecked = allMessageCost.text.replaceAll('.00', '');
      } else if (allMessageCost.text.isNotEmpty) {
        if (!allMessageCost.text.contains('.')) {
          allMessageCost.text = '${allMessageCost.text}.00';
        }
      }
    });

    allCallCost.isFocused.listen((b) {
      if (b) {
        allCallCost.unchecked = allCallCost.text.replaceAll('.00', '');
      } else if (allCallCost.text.isNotEmpty) {
        if (!allCallCost.text.contains('.')) {
          allCallCost.text = '${allCallCost.text}.00';
        }
      }
    });

    contactMessageCost.isFocused.listen((b) {
      if (b) {
        contactMessageCost.unchecked =
            contactMessageCost.text.replaceAll('.00', '');
      } else if (contactMessageCost.text.isNotEmpty) {
        if (!contactMessageCost.text.contains('.')) {
          contactMessageCost.text = '${contactMessageCost.text}.00';
        }
      }
    });

    contactCallCost.isFocused.listen((b) {
      if (b) {
        contactCallCost.unchecked = contactCallCost.text.replaceAll('.00', '');
      } else if (contactCallCost.text.isNotEmpty) {
        if (!contactCallCost.text.contains('.')) {
          contactCallCost.text = '${contactCallCost.text}.00';
        }
      }
    });

    send = MessageFieldController(
      _chatService,
      null,
      onSubmit: () async {
        welcome.value = ChatMessage(
          welcome.value?.id ?? ChatItemId.local(),
          welcome.value?.chatId ?? const ChatId('123'),
          welcome.value?.authorId ?? myUser.value!.id,
          welcome.value?.at ?? PreciseDateTime.now(),
          text: ChatMessageText(send.field.text),
          attachments: send.attachments.map((e) => e.value).toList(),
        );

        send.editing.value = false;
        send.clear();
      },
    );

    super.onInit();
  }

  @override
  void onClose() {
    _myUserWorker?.dispose();
    _profileWorker?.dispose();
    _devicesSubscription?.cancel();
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

  /// Uploads an image and sets it as [MyUser.avatar] and [MyUser.callCover].
  Future<void> uploadAvatar() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withReadStream: true,
      );

      if (result != null) {
        avatarUpload.value = RxStatus.loading();

        final List<Future> futures = [];
        for (var e in List<ImageGalleryItem>.from(
          myUser.value?.gallery ?? [],
          growable: false,
        ).map((e) => e.id)) {
          futures.add(_myUserService.deleteGalleryItem(e));
        }

        List<Future<ImageGalleryItem?>> uploads = result.files
            .map((e) => NativeFile.fromPlatformFile(e))
            .map((e) => _myUserService.uploadGalleryItem(e))
            .toList();
        ImageGalleryItem? item = (await Future.wait(uploads)).firstOrNull;
        if (item != null) {
          futures.add(_updateAvatar(item.id));
        }

        await Future.wait(futures);
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

  /// Sets the [ApplicationSettings.loadImages] value.
  Future<void> setLoadImages(bool enabled) =>
      _settingsRepo.setLoadImages(enabled);

  /// Updates [MyUser.avatar] and [MyUser.callCover] with an [ImageGalleryItem]
  /// with the provided [id].
  ///
  /// If [id] is `null`, then deletes the [MyUser.avatar] and
  /// [MyUser.callCover].
  Future<void> _updateAvatar(GalleryItemId? id) async {
    try {
      await _myUserService.updateAvatar(id);
      await _myUserService.updateCallCover(id);
    } on UpdateUserAvatarException catch (e) {
      MessagePopup.error(e);
    } on UpdateUserCallCoverException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
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
    switch (this) {
      case Presence.present:
        return Colors.green;
      case Presence.away:
        return Colors.orange;
      case Presence.artemisUnknown:
        return null;
    }
  }
}
