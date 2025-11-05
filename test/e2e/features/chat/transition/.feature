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

Feature: Chat transitions

  Scenario: Chats transitions works correctly
    Given user Alice
    And Alice has "Thoughts" group

    # Send the message from the Alice to ensure nothing is cached, when we sign
    # in as Alice, or otherwise the pagination will use the cached items.
    And Alice sends "How are you?" message to "Thoughts" group
    And Alice sends 100 messages to "Thoughts" group
    And Alice replies to "How are you?" message with "I am fine" text in "Thoughts" group
    And Alice reads all messages in "Thoughts" group
    And I pause for 5 seconds

    When I sign in as Alice
    And I am in "Thoughts" group
    And I scroll `IntroductionScrollable` until `ProceedButton` is present
    And I tap `ProceedButton` button
    And I pause for 5 seconds
    And I tap "How are you?" reply of "I am fine" message
    And I pause for 5 seconds
    Then I see "How are you?" message
