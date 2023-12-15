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

    Background: User deletes monolog
        Given I am Alice
        And I wait until `ChatMonolog` is present
        And I am in monolog
        And I open chat's info
        And I tap `MoreButton` button
        And I tap `HideChatButton` button
        And I tap `Proceed` button
        And I wait until `ChatMonolog` is absent
        Then I tap `SearchButton` button

    Scenario Outline: User searches deleted local monolog
        When I fill `SearchField` field with <query>
        Then I see monolog in search results

        Examples:
            | query   |
            | "Alice" |
            | "Notes" |




