# Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

Feature: Account recovery

  Scenario: User can restore access to their account
    When I tap `SignInButton` button
    Then I wait until `LoginView` is present

    When I tap `PasswordButton` button
    Then I wait until `SignInWithPassword` is present

    When I fill `UsernameField` field with "alice"
    And I tap `ForgotPassword` button
    Then I wait until `Recovery` is present
    And I wait until `RecoveryField` is present

    When I tap `Proceed` button
    Then I wait until `RecoveryCode` is present
    And I wait until `RecoveryCodeField` is present

    When I fill `RecoveryCodeField` field with "4321"
    And I tap `Proceed` button
    Then I see `RecoveryCodeField` having an error

    When I fill `RecoveryCodeField` field with "1234"
    And I see `RecoveryCodeField` having no error
    And I tap `Proceed` button
    Then I wait until `RecoveryPassword` is present

    When I fill `PasswordField` field with "123"
    And I fill `RepeatPasswordField` field with "123"
    And I tap `Proceed` button
    Then I wait until `SignIn` is present
    And I pause for 2 seconds
