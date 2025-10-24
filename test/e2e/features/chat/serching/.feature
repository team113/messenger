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

Feature: Chat item searching

  Scenario: Chat item can be searched and jumped to
    Given user Alice
    And Alice has "Thoughts" group

    And Alice sends "Deep thought..." message to "Thoughts" group
    And Alice sends 100 messages to "Thoughts" group
    And Alice reads all messages in "Thoughts" group

    When I sign in as Alice
    And I scroll `IntroductionScrollable` until `ProceedButton` is present
    And I tap `ProceedButton` button
    And I pause for 5 seconds
    And I am in "Thoughts" group
    And I pause for 5 seconds
    And I tap `MoreButton` button
    And I tap `SearchItemsButton` button
    And I fill `SearchItemsField` field with "vacation"
    Then I wait until `NoMessages` is present

    When I fill `SearchItemsField` field with "thought"
    Then I see "Deep thought..." message

    When I tap "Deep thought..." message
    Then I see "0" message
