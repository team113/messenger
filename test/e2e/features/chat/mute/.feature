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

Feature: Chat muting and unmuting

  Background: User is in group chat with Bob
    Given I am Alice
    And user Bob
    And I have "Alice and Bob" group with Bob
    And I wait until text "Alice and Bob" is present

  Scenario: User mutes chat
    When I long press "Alice and Bob" chat
    And I tap `MuteChatButton` button
    And I tap `MuteForever` button
    And I tap `Proceed` button
    Then I see "Alice and Bob" chat as muted

  Scenario: User unmutes chat
    When "Alice and Bob" chat is muted
    Then I see "Alice and Bob" chat as muted

    When I long press "Alice and Bob" chat
    And I tap `UnmuteChatButton` button
    Then I see "Alice and Bob" chat as unmuted
