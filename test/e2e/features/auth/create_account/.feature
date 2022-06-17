Feature: Account creation

  Scenario: User creates a new account and deletes it
    When I tap `StartChattingButton` button
    And I wait until `HomeView` is present

    Then I tap `MenuButton` button
    And I tap `MyProfileButton` button
    And I wait until `MyProfileView` is present

    Then I fill `NameField` field with "Alice"

    When I tap `PasswordExpandable` widget
    Then I fill `NewPasswordField` field with "123"
    And I fill `RepeatPasswordField` field with "123"

    Then I tap `ChangePasswordButton` button
    And I wait until `CurrentPasswordField` is present

    When I tap `DeleteAccountButton` button
    And I wait until `AlertDialog` is present
    And I tap `AlertYesButton` button

    Then I wait until `AuthView` is present
