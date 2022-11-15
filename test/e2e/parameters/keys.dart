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

// ignore_for_file: constant_identifier_names
import 'package:gherkin/gherkin.dart';

/// [Key]s available in the [WidgetKeyParameter].
enum WidgetKey {
  AlertDialog,
  AlertNoButton,
  AlertYesButton,
  AuthView,
  BioField,
  ChangeAvatar,
  ChangePasswordButton,
  ChatAvatar,
  ChatDirectLinkExpandable,
  ChatForwardView,
  ChatMessage,
  ChatView,
  ChatsButton,
  ChatsTab,
  CloseButton,
  ConfirmLogoutView,
  ContactsButton,
  ContactsTab,
  CurrentPasswordField,
  Delete,
  DeleteAccountButton,
  DeleteAvatar,
  DeleteForAll,
  EmailsExpandable,
  ForwardButton,
  ForwardField,
  HideForMe,
  HomeView,
  IntroductionView,
  LanguageDropdown,
  Language_enUS,
  Language_ruRU,
  LoginButton,
  LoginField,
  LoginView,
  LogoutButton,
  LogoutConfirmedButton,
  MenuButton,
  MenuTab,
  MessageField,
  MonologButton,
  MyProfileButton,
  MyProfileScrollable,
  MyProfileView,
  NameField,
  NewPasswordField,
  NumCopyable,
  PasswordExpandable,
  PasswordField,
  PasswordStage,
  PhonesExpandable,
  PresenceDropdown,
  Proceed,
  RecoveryCodeField,
  RecoveryField,
  RepeatPasswordField,
  Resend,
  SearchButton,
  SearchField,
  Send,
  SendForward,
  SetPasswordButton,
  SettingsButton,
  SignInButton,
  StartButton,
  SuccessStage,
  UsernameField,
}

/// [CustomParameter] of [WidgetKey]s representing a [Key] of a [Widget].
class WidgetKeyParameter extends CustomParameter<WidgetKey> {
  WidgetKeyParameter()
      : super(
          'key',
          RegExp(
            '`(${WidgetKey.values.map((e) => e.name).join('|')})`',
            caseSensitive: true,
          ),
          (c) => WidgetKey.values.firstWhere((e) => e.name == c),
        );
}
