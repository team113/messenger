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

  Scenario: User sees chats with deleted users
    Given I am Alice
    And I have "English" language set
    And users Bob and Charlie
    And I have group with Bob and Charlie
    And I wait until text "Alice, Bob, Charlie" is present
    And Bob has dialog with me
    And I wait until text "Bob" is present
    And I see "Alice, Bob, Charlie" chat
    And I see "Bob" chat
    And I see avatar title as "Bo" for "Bob" chat

    When Bob deletes their account
    Then I see "Alice, Deleted Account, Charlie" chat
    And I see "Deleted Account" chat
    And I see avatar title as "Bo" for "Deleted Account" chat

    When I tap "Bob" chat
    And I go to Bob's page
    Then I see avatar title as "Bo" in user profile
    And I see title as "Deleted Account" in user profile
