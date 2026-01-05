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

Feature: User sessions

  Scenario: User deletes session
    Given I am Alice
    And Alice has another active session

    When I tap `MenuButton` button
    And I scroll `MenuListView` until `Devices` is present
    And I tap `Devices` button
    Then I see 2 active sessions

    When I tap `TerminateSession_0` button
    And I tap `ProceedButton` button
    Then I wait until `PasswordField` is present

    When I fill `PasswordField` field with "123"
    And I tap `ProceedButton` button
    Then I see 1 active session
