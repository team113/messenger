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

// ignore_for_file: constant_identifier_names
import 'package:gherkin/gherkin.dart';

/// [Key]s available in the [WidgetKeyParameter].
enum WidgetKey {
  AccountsButton,
  AddAccountButton,
  AddEmail,
  AddMemberButton,
  AddPhone,
  AddToContactsButton,
  AddToFavoriteButton,
  AlertDialog,
  AlertNoButton,
  AlertYesButton,
  Approve,
  AudioCall,
  AuthView,
  Block,
  Blocklist,
  BlocklistLoading,
  BlocklistView,
  CancelSelecting,
  ChangeAvatar,
  ChangeLanguage,
  ChangePassword,
  ChangePasswordButton,
  ChatAvatar,
  ChatDirectLinkExpandable,
  ChatForwardView,
  ChatInfoScrollable,
  ChatMembers,
  ChatMessage,
  ChatMonolog,
  Chats,
  ChatsButton,
  ChatsLoading,
  ChatsMenu,
  ChatsTab,
  ChatView,
  ClearHistoryButton,
  CloseButton,
  ConfirmAccountDeletion,
  ConfirmationCode,
  ConfirmationPhone,
  ConfirmDelete,
  ConfirmedEmail,
  ConfirmedPhone,
  ConfirmLogoutButton,
  ConfirmLogoutView,
  Connected,
  Contacts,
  ContactsButton,
  ContactsLoading,
  ContactsMenu,
  ContactsTab,
  CopyButton,
  CurrentPasswordField,
  CurrentSession,
  DangerZone,
  Delete,
  DeleteAccount,
  DeleteAvatar,
  DeleteButton,
  DeleteChats,
  DeleteContacts,
  DeleteEmail,
  DeleteForAll,
  DeleteMemberButton,
  DeletePhone,
  DeleteSessionButton,
  DeleteWelcomeMessage,
  Devices,
  EditNameButton,
  Email,
  EmailsExpandable,
  EraseScrollable,
  EraseView,
  ExpandSigning,
  FavoriteChatButton,
  FavoriteContactButton,
  ForwardButton,
  ForwardField,
  GalleryPopup,
  HideChatButton,
  HideForMe,
  HomeView,
  IntroductionScrollable,
  IntroductionView,
  KeepCredentialsSwitch,
  Language_en,
  Language_ru,
  Language,
  LeftButton,
  LoginAndPassword,
  LoginButton,
  LoginField,
  LoginView,
  LogoutButton,
  MembersLoading,
  MenuButton,
  MenuListView,
  MenuTab,
  MessageField,
  MonologButton,
  MoreButton,
  MuteChatButton,
  MuteChatsButton,
  Muted,
  MyProfileButton,
  MyProfileScrollable,
  MyProfileView,
  NameField,
  NewPasswordField,
  NoLeftButton,
  NoMessages,
  NoRightButton,
  NotConnected,
  NoWelcomeMessage,
  NumCopyable,
  OkButton,
  PasswordButton,
  PasswordExpandable,
  PasswordField,
  PasswordStage,
  Phone,
  PhonesExpandable,
  PostWelcomeMessage,
  PresenceDropdown,
  Proceed,
  ProceedButton,
  PublicInformation,
  RecoveryCodeField,
  RecoveryField,
  RegisterButton,
  RemoveAccount,
  RenameChatField,
  RepeatPasswordField,
  Resend,
  Restore,
  RightButton,
  SaveNameButton,
  Search,
  SearchButton,
  SearchField,
  SearchItemsButton,
  SearchLoading,
  SearchScrollable,
  SearchSubmitButton,
  SearchTextField,
  SearchView,
  Select,
  SelectChatsButton,
  SelectContactsButton,
  Selected,
  Send,
  SendForward,
  SetPassword,
  SetPasswordButton,
  SettingsButton,
  ShowBlocklist,
  SignInButton,
  Signing,
  SkipButton,
  StartButton,
  SuccessStage,
  Unblock,
  UnconfirmedEmail,
  UnconfirmedPhone,
  UnfavoriteChatButton,
  UnfavoriteContactButton,
  UnmuteChatButton,
  UnmuteChatsButton,
  Unmuted,
  Unselected,
  UpgradePopup,
  UsernameField,
  UserScrollable,
  VerifyEmail,
  VerifyPhone,
  WelcomeMessage,
  WelcomeMessageField,
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
