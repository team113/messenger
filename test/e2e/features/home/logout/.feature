# Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
#                       <https://github.com/team113>
# Copyright © 2025-2026 Ideas Networks Solutions S.A.,
#                       <https://github.com/tapopa>
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

Feature: Logout confirmation

  Scenario: Confirmation is displayed when password isn't set
    When I wait until `IntroductionView` is present
    And I tap `GuestButton` button
    Then I wait until `GuestCreatedScreen` is present
    And my account is indeed remote

    When I copy from `NumCopyable` field
    And I tap `ProceedButton` button
    And I tap `MenuButton` button
    And I scroll `MenuListView` until `LogoutButton` is present
    And I tap `LogoutButton` button
    Then I wait until `ConfirmLogoutView` is present

    When I tap `SetPasswordButton` button
    And I fill `PasswordField` field with "123"
    And I fill `RepeatPasswordField` field with "123"
    And I tap `ChangePasswordButton` button
    Then I wait until `SuccessStage` is present
    And I tap `CloseButton` button

    When I tap `LogoutButton` button
    And I tap `KeepCredentialsSwitch` button
    And I tap `ConfirmLogoutButton` button
    Then I wait until `IntroductionView` is present

    When I tap `SignInButton` button
    Then I wait until `SignInScreen` is present

    When I tap `PasswordButton` button
    Then I wait until `SignInWithPasswordScreen` is present

    When I paste to `UsernameField` field
    And I fill `PasswordField` field with "123"
    And I tap `LoginButton` button
    Then I wait until `HomeView` is present
    And I pause for 2 seconds
    And my account is indeed remote
