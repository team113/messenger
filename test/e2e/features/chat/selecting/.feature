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

Feature: Messages selection

  Background: User is in dialogue
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I pause for 5 seconds

  Scenario: User selects and forwards messages
    Given I have "Forwards" group

    When I fill `MessageField` field with "01"
    And I tap `Send` button
    And I fill `MessageField` field with "02"
    And I tap `Send` button
    And I fill `MessageField` field with "03"
    And I tap `Send` button
    Then I wait until status of "01" message is sent
    And I wait until status of "02" message is sent
    And I wait until status of "03" message is sent

    When I right click "01" message
    And I tap `Select` button
    And I tap "02" message
    And I tap "03" message
    And I tap `ForwardButton` button
    Then I wait until `ChatForwardView` is present

    And I tap on "Forwards" chat
    And I tap `SendForward` button
    And I am in "Forwards" group
    Then I wait until status of "01" message is read
    And I wait until status of "02" message is read
    And I wait until status of "03" message is read

  Scenario: User selects and deletes messages
    When I fill `MessageField` field with "01"
    And I tap `Send` button
    And I fill `MessageField` field with "02"
    And I tap `Send` button
    And I fill `MessageField` field with "03"
    And I tap `Send` button
    Then I wait until status of "01" message is sent
    And I wait until status of "02" message is sent
    And I wait until status of "03" message is sent

    When I right click "01" message
    And I tap `Select` button
    And I tap "02" message
    And I tap "03" message
    And I tap `DeleteButton` button
    And I tap `Proceed` button
    Then I wait until "01" message is absent
    And I wait until "02" message is absent
    And I wait until "03" message is absent
    And I pause for 5 seconds
