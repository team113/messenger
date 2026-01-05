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

Feature: Searching deleted monolog

  Scenario: User searches deleted monolog and sees it
    Given I am Alice
    And I have my login set up
    And I have my direct link set up
    And I wait until `ChatMonolog` is present

    When I long press monolog
    And I tap `HideChatButton` button
    And I tap `Proceed` button
    Then I wait until `ChatMonolog` is absent

    When I fill `SearchField` field with "Alice"
    Then I see monolog in search results

    When I fill `SearchField` field with "Notes"
    Then I see monolog in search results

    When I fill `SearchField` field with my num
    Then I see monolog in search results

# When I fill `SearchField` field with my login
# Then I see monolog in search results

# When I fill `SearchField` field with my direct link
# Then I see monolog in search results
