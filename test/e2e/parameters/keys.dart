// ignore_for_file: constant_identifier_names
import 'package:gherkin/gherkin.dart';

/// [Key]s available in the [WidgetKeyParameter].
enum WidgetKey {
  AlertDialog,
  AlertNoButton,
  AlertYesButton,
  AuthView,
  BioField,
  ChangePasswordButton,
  ChatDirectLinkExpandable,
  ChatsButton,
  ChatsTab,
  ContactsButton,
  ContactsTab,
  CurrentPasswordField,
  DeleteAccountButton,
  EmailsExpandable,
  HomeView,
  LoginField,
  LoginNextTile,
  LoginView,
  LogoutButton,
  MenuButton,
  MenuTab,
  MonologButton,
  MyProfileButton,
  MyProfileScrollable,
  MyProfileView,
  NameField,
  NewPasswordField,
  NumCopyable,
  PasswordExpandable,
  PasswordField,
  PhonesExpandable,
  PresenceDropdown,
  RecoveryCodeField,
  RecoveryField,
  RecoveryNextTile,
  RepeatPasswordField,
  SettingsButton,
  SignInButton,
  StartChattingButton,
  UserBio,
  UserColumn,
  UsernameField,
  UserSearchBar,
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
