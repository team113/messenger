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

Feature: Failure sent messages are correctly edited and sent.

  Background: User is in dialog with Bob
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait for app to settle

  Scenario: User changes text of the message when edit failure message
    Given I do not have Internet
    When I fill `MessageField` field with "Hello"
    And I tap `Send` button
    Then I wait until status of "Hello" message is error

    Given I have Internet without delay
    When I long press "Hello" message
    And I tap `EditMessageButton` button
    And I fill `MessageField` field with "Hi"
    And I tap `Send` button
    Then I wait until status of "Hi" message is sent
