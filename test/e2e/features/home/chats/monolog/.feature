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

Feature: Searching deleted monolog

  Scenario: User searches deleted monolog and sees it
    Given I am Alice
    And Alice sets her login
    And I wait until `ChatMonolog` is present
    And I long press monolog
    And I tap `HideChatButton` button
    And I tap `Proceed` button
    And I wait until `ChatMonolog` is absent
    And I tap `SearchButton` button

    When I fill `SearchField` field with "Alice"
    Then I see monolog in search results

    When I fill `SearchField` field with "Notes"
    Then I see monolog in search results

    When I fill `SearchField` field with "id" of Alice
    Then I see monolog in search results

    When I fill `SearchField` field with "login" of Alice
    Then I see monolog in search results
