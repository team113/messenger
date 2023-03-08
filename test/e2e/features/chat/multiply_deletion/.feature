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

Feature: Multiple deletion of chats

  Background: User is in group chat with Bob and group chat with Charlie
    Given I am Alice
    And users Bob and Charlie
    And I have "Alice and Bob" group with Bob
    And I have "Alice and Charlie" group with Charlie

  Scenario: User selects and deletes chats
    When I long press "Alice and Bob" chat
    And I tap `SelectChatButton` button
    Then I see "Alice and Bob" chat as unselected
    And I see "Alice and Charlie" chat as unselected

    When I tap "Alice and Bob" chat
    Then I see "Alice and Bob" chat as selected
    When I tap "Alice and Charlie" chat
    Then I see "Alice and Charlie" chat as selected

    When I tap `DeleteChats` button
    And I tap `Proceed` button
    Then I wait until "Alice and Bob" chat is absent
    And I wait until "Alice and Charlie" chat is absent
