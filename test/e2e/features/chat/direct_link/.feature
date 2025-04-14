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

Feature: Direct links

  Scenario: Direct link can be opened in unauthorized mode
    Given user Bob
    And Bob has its direct link set up
    And I am Alice

    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

    When I fill `MessageField` field with "For selection"
    And I tap `Send` button
    Then I wait until status of "For selection" message is sent
