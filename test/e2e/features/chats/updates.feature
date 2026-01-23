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

Feature: Chats update in real-time

  @disabled
  @chats
  Scenario: Alice sees chats and messages from Bob and Charlie
    Given I am Alice
    And users Bob and Charlie

    Then I wait until `HomeView` is present
    And I wait until `ChatsTab` is present

    Given Bob has dialog with me
    And Charlie has dialog with me
    And Bob sends "Hello, world" message to me
    And Charlie sends "Nice boat" message to me
    Then I wait until text "Bob" is present
    And I wait until text "Hello, world" is present
# And I wait until text "Charlie" is present
# And I wait until text "Nice boat" is present
