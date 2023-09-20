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

Feature: Search

  Scenario: Users search work correctly
    Given I am Alice
    And 31 users FindMe
    And I wait until `HomeView` is present
    And I have Internet with delay of 2 seconds

    When I tap `SearchButton` button
    And I fill `SearchField` field with "FindMe"
    Then I wait until `Search` is present

    When I scroll `SearchScrollable` until `SearchLoading` is present
    Then I wait until `SearchLoading` is absent
