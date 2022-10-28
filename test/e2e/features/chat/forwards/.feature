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

Feature: Chat items are forwarded correctly

  Background: User is in dialog with Bob
    Given I am Alice
    And users Bob and Charlie
    And Bob has dialog with me
    And Charlie has dialog with me
    And I am in chat with Bob

  Scenario: User forwards message
    When I fill `MessageField` field with "Wow!"
    And I tap `Send` button
    Then I wait until status of "Wow!" message is sent

    When I long press "Wow!" message
    And I tap `ForwardButton` button
    Then I wait until `ChatForwardView` is present

    And I fill `ForwardField` field with "Check this :)"
    And I tap chat with Charlie
    And I tap `SendForward` button
    And I am in chat with Charlie
    Then I wait until text "Check this :)" is present

  Scenario: User forwards message with attachment
    When I fill `MessageField` field with "You saved me, why?"
    And I tap `Send` button
    Then I wait until status of "You saved me, why?" message is sent

    When I long press "You saved me, why?" message
    And I tap `ForwardButton` button
    Then I wait until `ChatForwardView` is present

    When I fill `ForwardField` field with "Mhm... Monkey."
    And I attach "test.jpg" image
    And I tap chat with Charlie
    And I tap `SendForward` button
    And I am in chat with Charlie
    Then I wait until attachment "test.jpg" is present

  Scenario: User forwards message to multiple chats
    Given user Dave
    And Dave has dialog with me

    When I fill `MessageField` field with "Important info"
    And I tap `Send` button
    Then I wait until status of "Important info" message is sent

    When I long press "Important info" message
    And I tap `ForwardButton` button
    Then I wait until `ChatForwardView` is present

    When I fill `ForwardField` field with "!!"
    And I tap chat with Charlie
    And I tap chat with Dave
    And I tap `SendForward` button
    And I am in chat with Charlie
    Then I wait until text "!!" is present

    When I am in chat with Dave
    Then I wait until text "!!" is present
