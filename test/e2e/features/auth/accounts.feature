# Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

Feature: Accounts

  @auth
  Scenario: User can switch accounts
    Given I am Alice
    And user Bob with their password set
    And I wait until `HomeView` is present
    And my name is indeed Alice

    When I tap `MenuButton` button
    And I tap `AccountsButton` button
    And I tap `AddAccountButton` button
    And I tap `StartButton` button
    Then I wait for app to settle
    And I wait until `IntroductionView` is present
    And my name is not Alice

    When I tap `ProceedButton` button
    And I tap `MenuButton` button
    And I tap `AccountsButton` button
    And I tap `AddAccountButton` button
    And I tap `SignInButton` button
    And I tap `PasswordButton` button
    And I fill `UsernameField` field with Bob's num
    And I fill `PasswordField` field with "123"
    And I tap `LoginButton` button
    Then I wait for app to settle
    And my name is indeed Bob
    And I pause for 1 second
