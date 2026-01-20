# Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
#                       <https://github.com/team113>
# Copyright © 2025-2026 Ideas Networks Solutions S.A.,
#                       <https://github.com/tapopa>
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

Feature: Chat messages have correct sending status

  Background: User is in dialog with Bob
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait for app to settle
    And I pause for 5 seconds

  Scenario: User sends message
    When I fill `MessageField` field with "123"
    And I tap `Send` button
    Then I wait until status of "123" message is sent

  Scenario: Message status changes from `sending` to `sent`
    Given I have Internet with delay of 6 seconds

    When I fill `MessageField` field with "123"
    And I tap `Send` button

    Then I wait until status of "123" message is sending
    And I wait until status of "123" message is sent

  @internet
  Scenario: User deletes non-sent message
    Given I do not have Internet
    When I fill `MessageField` field with "123"
    And I tap `Send` button
    Then I wait until status of "123" message is error

    When I long press "123" message
    And I tap `DeleteMessageButton` button
    And I tap `Proceed` button
    Then I wait until "123" message is absent

  @internet
  Scenario: User resends message
    Given I do not have Internet
    When I fill `MessageField` field with "123"
    And I tap `Send` button
    Then I wait until status of "123" message is error

    Given I have Internet with delay of 6 seconds
    When I long press "123" message
    And I tap `Resend` button
    Then I wait until status of "123" message is sending
    And I wait until status of "123" message is sent

  @internet
  Scenario: Non-sent messages are persisted
    Given I do not have Internet
    When I fill `MessageField` field with "123"
    And I tap `Send` button
    Then I wait until status of "123" message is error
    And I pause for 5 seconds

    Given I have Internet with delay of 4 seconds
    When I restart app
    And I pause for 5 seconds
    And I am in chat with Bob
    And I pause for 1 seconds
    Then I wait until status of "123" message is error
