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

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:messenger/api/backend/schema.dart'
    show CreateChatDirectLinkErrorCode, Presence;
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/gallery_item.dart';
import 'package:messenger/domain/model/image_gallery_item.dart';
import 'package:messenger/domain/model/native_file.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/dropdown.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/page/home/page/my_profile/controller.dart';

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/domain/service/call.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/util/message_popup.dart';
import '/util/web/web_utils.dart';
import 'confirm/view.dart';

export 'view.dart';

/// Controller of the `HomeTab.menu` tab.
class MenuTabController extends GetxController {
  MenuTabController(this._authService, this._myUserService, this._callService);

  /// Timeout of a [resendPhone] action.
  final RxInt resendPhoneTimeout = RxInt(0);

  /// Timeout of a [resendEmail] action.
  final RxInt resendEmailTimeout = RxInt(0);

  /// [UserEmail]s that are being deleted.
  final RxList<UserEmail> emailsOnDeletion = RxList<UserEmail>([]);

  /// [UserPhone]s that are being deleted.
  final RxList<UserPhone> phonesOnDeletion = RxList<UserPhone>([]);

  /// Indicator whether resend phone confirmation code button should be visible
  /// or not.
  final RxBool showEmailCodeButton = RxBool(false);

  /// Indicator whether resend email confirmation code button should be visible
  /// or not.
  final RxBool showPhoneCodeButton = RxBool(false);

  /// [MyUser.name]'s field state.
  late final TextFieldState name;

  /// [MyUser.bio]'s field state.
  late final TextFieldState bio;

  /// [MyUser.presence]'s dropdown state.
  late final DropdownFieldState<Presence> presence;

  /// [MyUser.num]'s copyable state.
  late final TextFieldState num;

  /// [MyUser.chatDirectLink]'s copyable state.
  late final TextFieldState link;

  /// [MyUser.login]'s field state.
  late final TextFieldState login;

  /// A new [UserEmail]'s field state.
  late final TextFieldState email;

  /// A new [UserEmail] confirmation code field state.
  late final TextFieldState emailCode;

  /// A new [UserPhone] confirmation code field state.
  late final TextFieldState phoneCode;

  /// A new [UserPhone]'s field state.
  late final TextFieldState phone;

  /// State of a current [myUser]'s password field.
  late final TextFieldState oldPassword;

  /// State of a new [myUser]'s password field.
  late final TextFieldState newPassword;

  /// State of a repeated new [myUser]'s password field.
  late final TextFieldState repeatPassword;

  /// Status of the [MyUser.avatar] update.
  final Rx<RxStatus> avatarStatus = Rx<RxStatus>(RxStatus.empty());

  /// Delete status of the [ImageGalleryItem].
  final Rx<RxStatus> deleteGalleryStatus = Rx<RxStatus>(RxStatus.empty());

  final AuthService _authService;
  final CallService _callService;

  /// [Timer] to set the `RxStatus.empty` status of the [name] field.
  Timer? _nameTimer;

  /// [Timer] to set the `RxStatus.empty` status of the [link] field.
  Timer? _linkTimer;

  /// [Timer] to set the `RxStatus.empty` status of the [bio] field.
  Timer? _bioTimer;

  /// [Timer] to set the `RxStatus.empty` status of the [presence] field.
  Timer? _presenceTimer;

  /// [Timer] to set the `RxStatus.empty` status of the [login] field.
  Timer? _loginTimer;

  /// [Timer] to set the `RxStatus.empty` status of the [addGalleryStatus].
  Timer? _addGalleryTimer;

  /// [Timer] to set the `RxStatus.empty` status of the [deleteGalleryStatus].
  Timer? _deleteGalleryTimer;

  /// [Timer] to set the `RxStatus.empty` status of the [avatarStatus].
  Timer? _avatarTimer;

  /// [Timer] to decrease [resendPhoneTimeout].
  Timer? _resendPhoneTimer;

  /// [Timer] to decrease [resendEmailTimeout].
  Timer? _resendEmailTimer;

  /// Worker to react on [myUser] changes.
  Worker? _worker;

  /// Service managing [MyUser].
  final MyUserService _myUserService;

  /// Current [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  UserId? get me => _authService.userId;

  onInit() {
    _worker = ever(
      _myUserService.myUser,
      (MyUser? v) {
        if (!name.focus.hasFocus) {
          name.unchecked = v?.name?.val;
        }
        if (!bio.focus.hasFocus) {
          bio.unchecked = v?.bio?.val;
        }
        if (!presence.focus.hasFocus) {
          presence.unchecked = v?.presence;
        }
        if (!login.focus.hasFocus) {
          login.unchecked = v?.login?.val;
        }
        if (!link.focus.hasFocus) {
          link.unchecked = v?.chatDirectLink?.slug.val;
        }
      },
    );

    name = TextFieldState(
      text: myUser.value?.name?.val,
      onChanged: (s) async {
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
            s.status.value = RxStatus.success();
            _nameTimer = Timer(const Duration(seconds: 1),
                () => s.status.value = RxStatus.empty());
          } catch (e) {
            s.error.value = e.toString();
            s.status.value = RxStatus.empty();
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );

    email = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        s.unsubmit();
      },
      onSubmitted: (s) async {
        UserEmail? email;
        try {
          email = UserEmail(s.text);

          if (myUser.value!.emails.confirmed.contains(email) ||
              myUser.value?.emails.unconfirmed == email) {
            s.error.value = 'err_you_already_add_this_email'.l10n;
          }
        } on FormatException {
          s.error.value = 'err_incorrect_input'.l10n;
        }

        if (s.error.value == null) {
          s.editable.value = false;
          s.status.value = RxStatus.loading();

          try {
            await _myUserService.addUserEmail(email!);
            MessagePopup.success('label_email_confirmation_code_was_sent'.l10n);
            _setResendEmailTimer(true);
            s.clear();
          } on FormatException {
            s.error.value = 'err_incorrect_input'.l10n;
          } on AddUserEmailException catch (e) {
            s.error.value = e.toMessage();
          } catch (e) {
            MessagePopup.error(e);
            s.unsubmit();
            rethrow;
          } finally {
            s.editable.value = true;
            s.status.value = RxStatus.empty();
          }
        }
      },
    );

    phone = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        s.unsubmit();
      },
      onSubmitted: (s) async {
        UserPhone? phone;
        try {
          phone = UserPhone(s.text);

          if (_myUserService.myUser.value!.phones.confirmed.contains(phone) ||
              _myUserService.myUser.value?.phones.unconfirmed == phone) {
            s.error.value = 'err_you_already_add_this_phone'.l10n;
          }
        } catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }

        if (s.error.value == null) {
          s.editable.value = false;
          s.status.value = RxStatus.loading();

          try {
            await _myUserService.addUserPhone(phone!);
            MessagePopup.success('label_phone_confirmation_code_was_send'.l10n);
            _setResendPhoneTimer(true);
            s.clear();
          } on FormatException {
            s.error.value = 'err_incorrect_input'.l10n;
          } on AddUserPhoneException catch (e) {
            s.error.value = e.toMessage();
          } catch (e) {
            MessagePopup.error(e);
            s.unsubmit();
            rethrow;
          } finally {
            s.editable.value = true;
            s.status.value = RxStatus.empty();
          }
        }
      },
    );

    bio = TextFieldState(
      text: myUser.value?.bio?.val,
      onChanged: (s) async {
        s.error.value = null;
        try {
          if (s.text.isNotEmpty) {
            UserBio(s.text);
          }
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }

        if (s.error.value == null) {
          _bioTimer?.cancel();
          s.editable.value = false;
          s.status.value = RxStatus.loading();
          try {
            await _myUserService
                .updateUserBio(s.text.isNotEmpty ? UserBio(s.text) : null);
            s.status.value = RxStatus.success();
            _bioTimer = Timer(const Duration(seconds: 1),
                () => s.status.value = RxStatus.empty());
          } catch (e) {
            s.error.value = e.toString();
            s.status.value = RxStatus.empty();
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );

    presence = DropdownFieldState(
      value: myUser.value?.presence,
      items: Presence.values.getRange(0, Presence.values.length - 1).toList(),
      stringify: (s) => s?.localizedString() ?? '',
      onChanged: (s) async {
        if (myUser.value?.presence != s.value) {
          _presenceTimer?.cancel();
          s.status.value = RxStatus.loading();
          s.error.value = null;
          s.editable.value = false;
          await Future.delayed(1.seconds);
          try {
            await _myUserService.updateUserPresence(presence.value!);
            s.status.value = RxStatus.success();
            _presenceTimer = Timer(const Duration(seconds: 1),
                () => s.status.value = RxStatus.empty());
          } catch (e) {
            s.error.value = e.toString();
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
      text: myUser.value?.chatDirectLink?.slug.val,
      onChanged: (s) {
        s.error.value = null;
        s.status.value = RxStatus.empty();
        s.unsubmit();
      },
      onSubmitted: (s) async {
        ChatDirectLinkSlug? slug;
        try {
          slug = ChatDirectLinkSlug(s.text);
        } on FormatException {
          s.error.value = 'err_incorrect_input'.l10n;
        }

        if (slug == myUser.value?.chatDirectLink?.slug) {
          return;
        }

        if (s.error.value == null) {
          _linkTimer?.cancel();
          s.editable.value = false;
          s.status.value = RxStatus.loading();

          try {
            await _myUserService.createChatDirectLink(slug!);
            s.status.value = RxStatus.success();
            _linkTimer = Timer(const Duration(seconds: 1),
                () => s.status.value = RxStatus.empty());
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
      onChanged: (s) async {
        s.error.value = null;
        try {
          UserLogin(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }

        if (s.error.value == null) {
          _loginTimer?.cancel();
          s.editable.value = false;
          s.status.value = RxStatus.loading();
          try {
            await _myUserService.updateUserLogin(UserLogin(s.text));
            s.status.value = RxStatus.success();
            _loginTimer = Timer(const Duration(seconds: 1),
                () => s.status.value = RxStatus.empty());
          } on UpdateUserLoginException catch (e) {
            s.error.value = e.toMessage();
            s.status.value = RxStatus.empty();
          } catch (e) {
            s.error.value = e.toString();
            s.status.value = RxStatus.empty();
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );

    emailCode = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        s.unsubmit();
      },
      onSubmitted: (s) async {
        if (s.text.isEmpty) {
          s.error.value = 'err_input_empty'.l10n;
        }

        if (s.error.value == null) {
          s.editable.value = false;
          s.status.value = RxStatus.loading();
          try {
            await _myUserService.confirmEmailCode(ConfirmationCode(s.text));
            showEmailCodeButton.value = false;
            s.clear();
          } on FormatException {
            s.error.value = 'err_incorrect_input'.l10n;
          } on ConfirmUserEmailException catch (e) {
            showEmailCodeButton.value = false;
            s.error.value = e.toMessage();
          } catch (e) {
            MessagePopup.error(e);
            s.unsubmit();
            rethrow;
          } finally {
            s.editable.value = true;
            s.status.value = RxStatus.empty();
          }
        }
      },
    );

    phoneCode = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        s.unsubmit();
      },
      onSubmitted: (s) async {
        if (s.text.isEmpty) {
          s.error.value = 'err_input_empty'.l10n;
        }

        if (s.error.value == null) {
          s.editable.value = false;
          s.status.value = RxStatus.loading();
          try {
            await _myUserService.confirmPhoneCode(ConfirmationCode(s.text));
            showPhoneCodeButton.value = false;
            s.clear();
          } on FormatException {
            s.error.value = 'err_incorrect_input'.l10n;
          } on ConfirmUserPhoneException catch (e) {
            showPhoneCodeButton.value = false;
            s.error.value = e.toMessage();
          } catch (e) {
            MessagePopup.error(e);
            s.unsubmit();
            rethrow;
          } finally {
            s.editable.value = true;
            s.status.value = RxStatus.empty();
          }
        }
      },
    );

    oldPassword = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        newPassword.error.value = null;
        repeatPassword.error.value = null;
        try {
          UserPassword(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      },
    );
    newPassword = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        repeatPassword.error.value = null;
        try {
          UserPassword(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      },
    );
    repeatPassword = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        newPassword.error.value = null;
        if (s.text != newPassword.text && newPassword.isValidated) {
          s.error.value = 'err_passwords_mismatch'.l10n;
        }
      },
    );

    super.onInit();
  }

  @override
  void onClose() {
    _setResendEmailTimer(false);
    _setResendPhoneTimer(false);
    _worker?.dispose();
    super.onClose();
  }

  /// Determines whether the [logout] action may be invoked or not.
  ///
  /// Shows a confirmation popup if there's any ongoing calls.
  Future<bool> confirmLogout() async {
    if (_callService.calls.isNotEmpty || WebUtils.containsCalls()) {
      if (await MessagePopup.alert('alert_are_you_sure_want_to_log_out'.l10n) !=
          true) {
        return false;
      }
    }

    // TODO: [MyUserService.myUser] might still be `null` here.
    if (_myUserService.myUser.value?.hasPassword != true) {
      if (await ConfirmLogoutView.show(router.context!) != true) {
        return false;
      }
    }

    return true;
  }

  /// Logs out the current session and go to the [Routes.auth] page.
  Future<String> logout() => _authService.logout();

  Future<void> setPresence(Presence presence) async {
    await _myUserService.updateUserPresence(presence);
  }

  /// Validates and updates current [myUser]'s password with the one specified
  /// in the [newPassword] and [repeatPassword] fields.
  Future<void> changePassword() async {
    if (myUser.value?.hasPassword == true) {
      oldPassword.focus.unfocus();
      oldPassword.submit();
    }

    newPassword.focus.unfocus();
    newPassword.submit();
    repeatPassword.focus.unfocus();
    repeatPassword.submit();

    if (myUser.value?.hasPassword == true) {
      if (!oldPassword.isValidated || oldPassword.text.isEmpty) {
        oldPassword.error.value = 'err_current_password_empty'.l10n;
        return;
      }

      if (oldPassword.error.value != null) {
        return;
      }
    }

    if (newPassword.error.value == null && repeatPassword.error.value == null) {
      if (!newPassword.isValidated || newPassword.text.isEmpty) {
        newPassword.error.value = 'err_new_password_empty'.l10n;
        return;
      }

      if (!repeatPassword.isValidated || repeatPassword.text.isEmpty) {
        repeatPassword.error.value = 'err_repeat_password_empty'.l10n;
        return;
      }

      if (repeatPassword.text != newPassword.text) {
        repeatPassword.error.value = 'err_passwords_mismatch'.l10n;
        return;
      }

      oldPassword.editable.value = false;
      newPassword.editable.value = false;
      repeatPassword.editable.value = false;
      repeatPassword.status.value = RxStatus.loading();
      try {
        await _myUserService.updateUserPassword(
          oldPassword:
              myUser.value!.hasPassword ? UserPassword(oldPassword.text) : null,
          newPassword: UserPassword(newPassword.text),
        );
        repeatPassword.status.value = RxStatus.success();
        await Future.delayed(1.seconds);
        oldPassword.clear();
        newPassword.clear();
        repeatPassword.clear();
      } on UpdateUserPasswordException catch (e) {
        oldPassword.error.value = e.toMessage();
      } catch (e) {
        repeatPassword.error.value = e.toString();
        rethrow;
      } finally {
        repeatPassword.status.value = RxStatus.empty();
        oldPassword.editable.value = true;
        newPassword.editable.value = true;
        repeatPassword.editable.value = true;
      }
    }
  }

  /// Resend [ConfirmationCode] to [UserEmail] specified in the [email] field to
  /// [MyUser.emails].
  Future<void> resendEmail() async {
    try {
      await _myUserService.resendEmail();
      _setResendEmailTimer(true);
      MessagePopup.success('label_email_confirmation_code_was_sent'.l10n);
    } on ResendUserEmailConfirmationException catch (e) {
      emailCode.error.value = e.toMessage();
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Resend [ConfirmationCode] to [UserPhone] specified in the [phone] field to
  /// [MyUser.phones].
  Future<void> resendPhone() async {
    try {
      await _myUserService.resendPhone();
      _setResendPhoneTimer(true);
      MessagePopup.success('label_phone_confirmation_code_was_send'.l10n);
    } on ResendUserPhoneConfirmationException catch (e) {
      email.error.value = e.toMessage();
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Deletes [email] address from [MyUser.emails].
  Future<void> deleteUserEmail(UserEmail email) async {
    if (await MessagePopup.alert(
            'alert_are_you_sure_want_to_delete_email'.l10n) ==
        true) {
      emailsOnDeletion.addIf(!emailsOnDeletion.contains(email), email);
      UserEmail? unconfirmed = myUser.value?.emails.unconfirmed;
      try {
        await _myUserService.deleteUserEmail(email);
      } finally {
        if (unconfirmed == email) {
          emailCode.clear();
          showEmailCodeButton.value = false;
        }
        emailsOnDeletion.remove(email);
      }
    }
  }

  /// Deletes [phone] number from [MyUser.phones].
  Future<void> deleteUserPhone(UserPhone phone) async {
    if (await MessagePopup.alert(
            'alert_are_you_sure_want_to_delete_phone'.l10n) ==
        true) {
      phonesOnDeletion.addIf(!phonesOnDeletion.contains(phone), phone);
      UserPhone? unconfirmed = myUser.value?.phones.unconfirmed;
      try {
        await _myUserService.deleteUserPhone(phone);
      } finally {
        if (unconfirmed == phone) {
          phoneCode.clear();
          showPhoneCodeButton.value = false;
        }
        phonesOnDeletion.remove(phone);
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

  final Rx<RxStatus> avatarUpload = Rx(RxStatus.empty());

  Future<void> uploadAvatar() async {
    try {
      print('[uploadAvatar] picking files...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withReadStream: false,
      );
      print(
          '[uploadAvatar] files picked, result: $result (${result?.files.length}');

      if (result != null) {
        avatarUpload.value = RxStatus.loading();

        List<Future> deletes = [];

        for (ImageGalleryItem item in myUser.value?.gallery ?? []) {
          deletes.add(_myUserService.deleteGalleryItem(item.id));
        }

        List<Future<ImageGalleryItem?>> futures = result.files
            .map((e) => NativeFile.fromPlatformFile(e))
            .map((e) => _myUserService.uploadGalleryItem(e))
            .toList();
        ImageGalleryItem? item = (await Future.wait(futures)).firstOrNull;
        if (item != null) {
          _updateAvatar(item.id);
        }
      }
    } on DioError catch (e) {
      if (e.response?.data != null) {
        MessagePopup.error(e.response?.data);
      } else {
        MessagePopup.error(e);
      }

      rethrow;
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    } finally {
      avatarUpload.value = RxStatus.empty();
    }
  }

  /// Opens a file choose popup and uploads the selected images to the
  /// [MyUser.gallery]
  Future<void> pickGalleryItem() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withReadStream: true,
    );

    if (result != null) {
      // _uploadGalleryItems(result.files);
    }
  }

  /// Uploads the specified [details] files to the [MyUser.gallery].
  Future<void> dropFiles(DropDoneDetails details) async {
    List<PlatformFile> files = [];
    for (var file in details.files) {
      files.add(PlatformFile(
        path: file.path,
        name: file.name,
        size: await file.length(),
        readStream: file.openRead(),
      ));
    }
    // await _uploadGalleryItems(files);
  }

  /// Deletes [ImageGalleryItem] at the [galleryIndex] from [MyUser.gallery].
  Future<void> deleteGalleryItem(ImageGalleryItem? galleryItem) async {
    try {
      if (await MessagePopup.alert('alert_are_you_sure'.l10n) == true) {
        _deleteGalleryTimer?.cancel();
        deleteGalleryStatus.value = RxStatus.loading();
        if (galleryItem != null) {
          await _myUserService.deleteGalleryItem(galleryItem.id);
        }
        deleteGalleryStatus.value = RxStatus.success();
      }
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    } finally {
      _deleteGalleryTimer = Timer(const Duration(seconds: 1),
          () => deleteGalleryStatus.value = RxStatus.empty());
    }
  }

  /// Deletes [myUser]'s account.
  Future<void> deleteAccount() async {
    if (await MessagePopup.alert('alert_are_you_sure'.l10n) == true) {
      await _myUserService.deleteMyUser();
    }
  }

  /// Generates a new [MyUser.chatDirectLink].
  Future<void> generateLink() async {
    if (link.editable.isFalse) return;

    _linkTimer?.cancel();
    link.editable.value = false;
    link.status.value = RxStatus.loading();

    bool generated = false;
    while (!generated) {
      ChatDirectLinkSlug slug = ChatDirectLinkSlug.generate(10);

      try {
        await _myUserService.createChatDirectLink(slug);
        link.text = slug.val;
        link.status.value = RxStatus.success();
        link.error.value = null;
        _linkTimer = Timer(const Duration(seconds: 1),
            () => link.status.value = RxStatus.empty());
        generated = true;
      } on CreateChatDirectLinkException catch (e) {
        if (e.code != CreateChatDirectLinkErrorCode.occupied) {
          link.status.value = RxStatus.empty();
          link.error.value = e.toMessage();
          generated = true;
        }
      } catch (e) {
        link.status.value = RxStatus.empty();
        link.editable.value = true;
        rethrow;
      }
    }

    link.editable.value = true;
  }

  /// Deletes [MyUser.chatDirectLink].
  Future<void> deleteLink() async {
    if (link.editable.isFalse) return;

    _linkTimer?.cancel();
    link.editable.value = false;
    link.status.value = RxStatus.loading();

    try {
      await _myUserService.deleteChatDirectLink();
      link.status.value = RxStatus.success();
      link.error.value = null;
      link.unchecked = '';
      _linkTimer = Timer(const Duration(seconds: 1),
          () => link.status.value = RxStatus.empty());
    } on DeleteChatDirectLinkException catch (e) {
      link.status.value = RxStatus.empty();
      link.error.value = e.toMessage();
    } catch (e) {
      link.status.value = RxStatus.empty();
      rethrow;
    } finally {
      link.editable.value = true;
    }
  }

  /// Puts the [MyUser.chatDirectLink] into the clipboard and shows a snackbar.
  void copyLink() {
    Clipboard.setData(
      ClipboardData(
        text:
            '${Config.origin}${Routes.chatDirectLink}/${myUser.value?.chatDirectLink!.slug.val}',
      ),
    );

    MessagePopup.success('label_copied_to_clipboard'.l10n);
  }

  /// Updates [MyUser.avatar] and [MyUser.callCover] with an [ImageGalleryItem]
  /// with the provided [id].
  ///
  /// If [id] is `null`, then deletes the [MyUser.avatar] and
  /// [MyUser.callCover].
  Future<void> _updateAvatar(GalleryItemId? id) async {
    try {
      _avatarTimer?.cancel();
      avatarStatus.value = RxStatus.loading();
      await _myUserService.updateAvatar(id);
      await _myUserService.updateCallCover(id);
      avatarStatus.value = RxStatus.success();
    } on UpdateUserAvatarException catch (e) {
      MessagePopup.error(e);
    } on UpdateUserCallCoverException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    } finally {
      _avatarTimer = Timer(const Duration(seconds: 1),
          () => avatarStatus.value = RxStatus.empty());
    }
  }

  /// Starts or stops [resendEmailTimer] based on [enabled] value.
  void _setResendEmailTimer([bool enabled = true]) {
    if (enabled) {
      resendEmailTimeout.value = 30;
      _resendEmailTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          resendEmailTimeout.value--;
          if (resendEmailTimeout.value <= 0) {
            resendEmailTimeout.value = 0;
            _resendEmailTimer?.cancel();
            _resendEmailTimer = null;
          }
        },
      );
    } else {
      resendEmailTimeout.value = 0;
      _resendEmailTimer?.cancel();
      _resendEmailTimer = null;
    }
  }

  /// Starts or stops [resendPhoneTimer] based on [enabled] value.
  void _setResendPhoneTimer([bool enabled = true]) {
    if (enabled) {
      resendPhoneTimeout.value = 30;
      _resendPhoneTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          resendPhoneTimeout.value--;
          if (resendPhoneTimeout.value <= 0) {
            resendPhoneTimeout.value = 0;
            _resendPhoneTimer?.cancel();
            _resendPhoneTimer = null;
          }
        },
      );
    } else {
      resendPhoneTimeout.value = 0;
      _resendPhoneTimer?.cancel();
      _resendPhoneTimer = null;
    }
  }
}
