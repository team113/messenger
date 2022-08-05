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

Feature: Logout confirm

  Scenario: Logout confirm is displayed and password can be set
    When I tap `StartButton` button
    Then I wait until `IntroductionView` is present
    And I copy from `NumCopyable` field
    And I tap `CloseButton` button

    When I tap `MenuButton` button
    Then I tap `LogoutButton` button

    And I wait until `ConfirmLogoutView` is present
    And I tap `SetPasswordButton` button
    Then I fill `PasswordField` field with "123"
    And I fill `RepeatPasswordField` field with "123"

    Then I tap `ChangePasswordButton` button
    And I wait until `SuccessStage` is present
    And I tap `CloseButton` button

    Then I tap `LogoutButton` button
    And I wait until `AuthView` is present

    Then I tap `SignInButton` button
    And I wait until `LoginView` is present
    And I paste to `UsernameField` field
    And I fill `PasswordField` field with "123"

    When I tap `LoginButton` button
    And I wait until `HomeView` is present