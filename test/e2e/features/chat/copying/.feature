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

Feature: Text messages selection and copying

  Scenario: User copies text of a message
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

    When I fill `MessageField` field with "For selection"
    And I tap `Send` button
    Then I wait until status of "For selection" message is sent

    When I long press "For selection" message
    And I tap `CopyButton` button
    Then copied text is "For selection"

    When I select "For selection" text from 2 to 10 symbols
    And I long press "For selection" message
    And I tap `CopyButton` button
    Then copied text is "r select"

    When I tap "For selection" message
    And I long press "For selection" message
    And I tap `CopyButton` button
    Then copied text is "For selection"
