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

    When I tap `MenuButton` button
    And I tap `PublicInformation` button
    And I wait until `MyProfileView` is present
    And I wait until `NameField` is present
    And I fill `NameField` field with "Alice"
    And I tap `Approve` button

    When I tap `SetPassword` button
    And I fill `NewPasswordField` field with "123"
    And I fill `RepeatPasswordField` field with "123"
    And I tap `Proceed` button
    And I tap `CloseButton` button
    Then I wait until `ChangePassword` is present

    When I tap `DangerZone` button
    And I tap `DeleteAccount` button
    And I tap `Proceed` button
    Then I wait until `AuthView` is present
