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

Feature: Toggle chat muting

  Background: User is in group chat with Bob
    Given I am Alice
    And user Bob
    And I have "Alice and Bob" group with Bob

  Scenario: User mutes chat
    When I wait until text "Alice and Bob" is present
    And I long press "Alice and Bob" chat
    Then I tap `MuteChatButton` button

    When I tap `MuteForever` button
    And I tap `MuteButton` button
    Then I see "Alice and Bob" chat as muted

  Scenario: User unmute chat
    Given chat "Alice and Bob" is muted

    When I see "Alice and Bob" chat as muted
    Then I long press "Alice and Bob" chat

    When I tap `UnmuteChatButton` button
    Then I see "Alice and Bob" chat as unmuted
