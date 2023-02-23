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

// ignore_for_file: constant_identifier_names
import 'package:gherkin/gherkin.dart';

/// [Key]s available in the [WidgetKeyParameter].
enum WidgetKey {
  AddEmail,
  AddMemberButton,
  AddPhone,
  AlertDialog,
  AlertNoButton,
  AlertYesButton,
  Approve,
  AudioCall,
  AuthView,
  BioField,
  Block,
  ChangeAvatar,
  ChangeLanguage,
  ChangePassword,
  ChangePasswordButton,
  ChatAvatar,
  ChatDirectLinkExpandable,
  ChatForwardView,
  ChatMessage,
  ChatView,
  ChatsButton,
  ChatsTab,
  CloseButton,
  ConfirmLogoutButton,
  ConfirmLogoutView,
  ConfirmationCode,
  ConfirmationPhone,
  ConfirmedEmail,
  ConfirmedPhone,
  ContactsButton,
  ContactsTab,
  CurrentPasswordField,
  DangerZone,
  Delete,
  DeleteAccount,
  DeleteAvatar,
  DeleteEmail,
  DeleteForAll,
  DeleteMemberButton,
  DeletePhone,
  Email,
  EmailsExpandable,
  FavoriteChatButton,
  FavoriteContactButton,
  ForwardButton,
  ForwardField,
  HideForMe,
  HomeView,
  IntroductionView,
  Language,
  Language_en,
  Language_ru,
  LoginButton,
  LoginField,
  LoginView,
  LogoutButton,
  MenuButton,
  MenuTab,
  MessageField,
  MonologButton,
  MuteChatButton,
  MuteMyUserSwitch,
  Muted,
  MyProfileButton,
  MyProfileScrollable,
  MyProfileView,
  NameField,
  NewPasswordField,
  NumCopyable,
  PasswordExpandable,
  PasswordField,
  PasswordStage,
  Phone,
  PhonesExpandable,
  PresenceDropdown,
  Proceed,
  PublicInformation,
  RecoveryCodeField,
  RecoveryField,
  RepeatPasswordField,
  Resend,
  SearchButton,
  SearchField,
  SearchSubmitButton,
  SearchTextField,
  SearchView,
  Send,
  SendForward,
  SetPassword,
  SetPasswordButton,
  SettingsButton,
  SignInButton,
  Signing,
  StartButton,
  SuccessStage,
  Unblock,
  UnconfirmedEmail,
  UnconfirmedPhone,
  UnfavoriteChatButton,
  UnfavoriteContactButton,
  UnmuteChatButton,
  Unmuted,
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
