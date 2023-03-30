# Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
#                       <https://github.com/team113>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License v3.0 as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
# more details.
#
# You should have received a copy of the GNU Affero General Public License v3.0
# along with this program. If not, see
# <https://www.gnu.org/licenses/agpl-3.0.html>.

Feature: Chat monolog

  Background: User has a local chat monolog
    Given I am Alice
    And I wait until `ChatMonolog` is present
    And chat monolog is indeed local
    And I am in monolog chat

  Scenario: Message can be posted in local chat monolog
    When I fill `MessageField` field with "Hello, my chat monolog"
    And I tap `Send` button
    Then I wait until status of "Hello, my chat monolog" message is sent
    And chat monolog is indeed remote

  Scenario: Call can be made in local chat monolog
    When I tap `AudioCall` button
    Then chat monolog is indeed remote

  Scenario: User adds local chat monolog to favorites
    When I open chat's info
    And I tap `FavoriteChatButton` button
    Then chat monolog is indeed remote
    And I see chat monolog as favorite

  Scenario: User renames local chat monolog
    When I open chat's info
    And I fill `RenameChatField` field with "My chat monolog"
    And I tap `Approve` button
    Then chat monolog is indeed remote

  Scenario: User hides local chat monolog
    When I open chat's info
    And I tap `HideChatButton` button
    And I tap `Proceed` button
    Then chat monolog is indeed remote
    And I wait until `ChatMonolog` is absent

    When I tap `MenuButton` button
    And I tap `PublicInformation` button
    And I copy from `NumCopyable` field
    And I scroll `MenuListView` until `LogoutButton` is present
    And I tap `LogoutButton` button
    And I tap `ConfirmLogoutButton` button
    Then I wait until `AuthView` is present

    When I tap `SignInButton` button
    And I wait until `LoginView` is present
    And I paste to `UsernameField` field
    And I fill `PasswordField` field with "123"
    And I tap `LoginButton` button
    Then I wait until `HomeView` is present
    And I wait until `ChatMonolog` is absent
