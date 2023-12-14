# Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

Feature: Chat transitions

  Scenario: Chats transitions works correctly
    Given user Alice
    And Alice has "Test" group
    And Alice sends "first message" message to "Test" group
    And Alice sends 100 messages to "Test" group
    And Alice replies "first message" message in "Test" group
    And Alice reads all messages in "Test" group
    And I sign in as Alice
    And I am in "Test" group

    When I tap `CloseButton` button
    And I tap "first message" reply
    Then I see "first message" message
