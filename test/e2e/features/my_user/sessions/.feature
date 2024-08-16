# Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

Feature: MyUser's sessions

  Scenario: Alice sees her other sessions being created and deleted
    Given I am Alice

    When I wait until `HomeView` is present
    And I tap `MenuButton` button
    And I scroll `MenuListView` until `Devices` is present
    And I tap `Devices` button
    Then I see 1 active sessions
    And I wait until `CurrentSession` is present

    When Alice has another active session
    Then I see 2 active sessions

    When Alice signs out of another active sessions
    Then I see 1 active sessions
    And I wait until `CurrentSession` is present
