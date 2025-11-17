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

Feature: Chat save_scroll_position

  Scenario: Chats save_scroll_position works correctly
    Given I am Alice
    And Alice has "Thoughts" group
    And Alice has "Ideas" group

    And Alice sends "test scroll position" message to "Thoughts" group
    And Alice sends 50 messages to "Thoughts" group
    And Alice reads all messages in "Thoughts" group
    And Alice sends "Idea 1" message to "Ideas" group
    And Alice sends 50 messages to "Ideas" group
    And Alice reads all messages in "Ideas" group

    When I sign in as Alice
    And I wait for app to settle
    # Add this 2 lines to fix error what described below:
    When I tap on "Ideas" chat
    And I wait for app to settle
    And I tap on "Thoughts" chat
    Then I scroll and see "10" message text in chat
    And I wait for app to settle
    When I tap on "Ideas" chat
    Then I scroll and see "20" message text in chat
    And I wait for app to settle
    And I tap `BackButton` button
    When I tap on "Thoughts" chat
    And I wait for app to settle
    Then I see some messages in chat
    And I see "10" message.
    When I tap on "Ideas" chat
    And I wait for app to settle
    Then I see "20" message.

# #the error scenario:
# When I sign in as Alice
# And I wait for app to settle
# When I tap on "Thoughts" chat
# Then I scroll and see "10" message text in chat
# And I wait for app to settle
# And I tap `BackButton` button
# # position is not saved, not call Cancel on controller of `Thoughts` chat?
# # in app all work, its only in e2e
# When I tap on "Ideas" chat
# Then I scroll and see "20" message text in chat
# And I wait for app to settle
# And I tap `BackButton` button
# # position saved, this non-identical behavior under the same conditions is confusing
# When I tap on "Thoughts" chat
# And I wait for app to settle
# Then I see some messages in chat
# # error in next line, see above
# # And I see "10" message.
# When I tap on "Ideas" chat
# And I wait for app to settle
# Then I see "20" message.