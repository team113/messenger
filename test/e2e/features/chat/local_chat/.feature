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

Feature: Local chats

  Background: User is in local dialog with Bob
    Given I am Alice
    And user Bob
    And I am in chat with Bob
    And Bob has no dialog with me

  Scenario: Message can be posted in local chat
    When I fill `MessageField` field with "Hello, my local friend"
    And I tap `Send` button
    Then I wait until status of "Hello, my local friend" message is sent
    And Bob has dialog with me

  Scenario: Call can be made in local chat
    When I tap `AudioCall` button
    Then Bob has dialog with me
