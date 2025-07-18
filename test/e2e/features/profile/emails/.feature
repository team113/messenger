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

Feature: User email

  Scenario: User adds, confirms and deletes email
    Given I am Alice
    And I wait until `HomeView` is present

    When I tap `MenuButton` button
    And I tap `Signing` button
    And I tap `AddEmailButton` button
    And I fill `EmailField` field with "example@gmail.com"
    And I tap `Proceed` button
    And I tap `CloseButton` button
    Then I wait until `UnconfirmedEmail` is present

    When I tap `VerifyEmailButton` button
    And I wait until `ConfirmationCode` is present
    And I fill `ConfirmationCode` field with "1234"
    And I tap `Proceed` button
    And I tap `CloseButton` button
    Then I wait until `ConfirmedEmail_0` is present

    When I tap `DeleteEmail_0` button
    And I tap `Proceed` button
    And I fill `PasswordField` field with "123"
    And I tap `Proceed` button
    And I tap `CloseButton` button
    Then I wait until `ConfirmedEmail_0` is absent
