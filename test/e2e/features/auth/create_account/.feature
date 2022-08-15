# Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

Feature: Account creation

  Scenario: User creates a new account and deletes it
    When I tap `StartButton` button
    And I wait until `IntroductionView` is present
    And I tap `CloseButton` button

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
