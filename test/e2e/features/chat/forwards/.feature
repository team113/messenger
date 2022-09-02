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

Feature: Chat messages are forwarded correctly

  Background: User is in dialog with Bob
    Given I am Alice
    And users Bob and Charlie
    And Bob has dialog with me
    And Charlie has dialog with me
    And I am in chat with Bob
    And I wait until `ChatView` is present

    Scenario: User forwards message
    When I fill `MessageField` field with "Message to forward"
    And I tap `Send` button
    Then I wait until status of "Message to forward" message is sent

    Then I long press "Message to forward" message
    And I tap `ForwardButton` button
    Then I wait until `ChatForwardView` is present
    Then I fill `ForwardMessageField` field with "Forward comment"
    And I select chat with Charlie to forward
    And I tap `SendForward` button

    Then I am in chat with Charlie
    And I wait until text "Forward comment" is present

  Scenario: User forwards message with attachment
    When I fill `MessageField` field with "Message to forward"
    And I tap `Send` button
    Then I wait until status of "Message to forward" message is sent

    Then I long press "Message to forward" message
    And I tap `ForwardButton` button
    Then I wait until `ChatForwardView` is present
    Then I fill `ForwardMessageField` field with "Forward comment"
    And I attach "test.jpg" image to forwards
    And I select chat with Charlie to forward
    And I tap `SendForward` button

    Then I am in chat with Charlie
    And I wait until `ChatView` is present
    And I wait until attachment "test.jpg" is present

  Scenario: User forwards message to multiply chats
    Given user Dave
    And Dave has dialog with me

    When I fill `MessageField` field with "Message to forward"
    And I tap `Send` button
    Then I wait until status of "Message to forward" message is sent

    Then I long press "Message to forward" message
    And I tap `ForwardButton` button
    Then I wait until `ChatForwardView` is present
    Then I fill `ForwardMessageField` field with "Forward comment"
    And I select chat with Charlie to forward
    And I select chat with Dave to forward
    And I tap `SendForward` button

    Then I am in chat with Charlie
    And I wait until `ChatView` is present
    And I wait until text "Forward comment" is present

    Then I am in chat with Dave
    And I wait until `ChatView` is present
    And I wait until text "Forward comment" is present
