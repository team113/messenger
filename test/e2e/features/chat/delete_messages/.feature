# Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

Feature: Chat items are deleted correctly

  Background: User is in dialog with Bob
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

  Scenario: User deletes message
    When I fill `MessageField` field with "For deletion"
    And I tap `Send` button
    Then I wait until status of "For deletion" message is sent

    When I long press "For deletion" message
    And I tap `Delete` button
    And I tap `DeleteForAll` button
    And I tap `Proceed` button
    Then I wait until text "For deletion" is absent

  Scenario: User hides message
    When I fill `MessageField` field with "For hiding"
    And I tap `Send` button
    Then I wait until status of "For hiding" message is sent

    When I long press "For hiding" message
    And I tap `Delete` button
    And I tap `HideForMe` button
    And I tap `Proceed` button
    Then I wait until text "For hiding" is absent
