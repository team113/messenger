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

Feature: Deleted users are displayed in chats

  Scenario: User see chats with deleted users
    Given I am Alice
    And users Bob and Charlie
    # And I have group with Bob and Charlie
    And Bob has dialog with me
    And I wait until text "Bob" is present

    When I select "English" language

    # Then I see "Alice, Bob, Charlie" chat
    Then I see "Bob" chat

    Then Bob is deleted
    # Then I see "Alice, Deleted Account, Charlie" chat
    Then I see "Deleted Account" chat

    # Проверяем, что заголовок аватара чата с Bob по прежнему "Bob"

    # Кликаем по чату c "Bob"
    # Проверяем, что заголовок профиля "Deleted Account"
    # Проверяем, что заголовок аватара профиля Bob по прежнему "Bob"
