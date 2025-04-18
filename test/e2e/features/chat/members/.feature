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

Feature: Chat members

  Background: User is in group chat with Bob
    Given I am Alice
    And I pause for 1 second
    And users Bob and Charlie
    And I have "Alice and Bob" group with Bob
    And I am in "Alice and Bob" group
    And I open chat's info

  Scenario: User removes a member
    When I wait until text "Bob" is present
    And I scroll `ChatInfoScrollable` until `DeleteMemberButton` is present
    And I tap `DeleteMemberButton` button
    And I tap `Proceed` button
    Then I wait until text "Bob" is absent

  Scenario: User adds a member
    Given Charlie has dialog with me
    When I scroll `ChatInfoScrollable` until `AddMemberButton` is present
    And I tap `AddMemberButton` button
    Then I wait until `SearchView` is present

    When I fill `SearchTextField` field with Charlie's num
    And I tap user Charlie in search results
    And I tap `SearchSubmitButton` button
    Then I wait until text "Charlie" is present

  Scenario: User gets removed
    When I wait until text "Alice and Bob" is present
    And Bob removes Alice from "Alice and Bob" group
    Then I wait until text "Alice and Bob" is absent
