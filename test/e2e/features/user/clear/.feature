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

Feature: Clear dialog

  Scenario: User clears dialog
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I pause for 2 seconds
    And I see some messages in chat

    When I go to Bob's page
    And I scroll `UserScrollable` to bottom
    And I pause for 1 seconds
    And I tap `ClearHistoryButton` button
    And I tap `Proceed` button
    And I pause for 1 seconds
    And I am in chat with Bob
    And I pause for 1 seconds
    Then I see no messages in chat
