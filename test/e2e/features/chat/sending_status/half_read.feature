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

Feature: Half read status of messages in group chats

  Background: User is in group chat with Bob and Charlie
    Given I am Alice
    And users Bob and Charlie
    And I have "Group" group with Bob and Charlie
    And I am in "Group" group

  Scenario: User sees messages half read
    When I fill `MessageField` field with "123"
    And I tap `Send` button
    Then I wait until status of "123" message is sent

    When Bob reads "123" message
    Then I wait until status of "123" message is half read

    When Charlie reads "123" message
    Then I wait until status of "123" message is read
