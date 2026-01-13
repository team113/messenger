# Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
#                       <https://github.com/team113>
# Copyright © 2025-2026 Ideas Networks Solutions S.A.,
#                       <https://github.com/tapopa>
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

Feature: Chats searching
  Background: I am guest
    Given I am guest
    And user Bob

  Scenario: User and chat can be found
    Given user Charlie
    And I have "Example" group with Bob

    When I fill `SearchField` field with "Example"
    Then I see chat "Example" in search results

    When I fill `SearchField` field with "Bob"
    Then I see user Bob in search results

  Scenario: Dialog can be found by direct link
    Given Bob has dialog with me
    And Bob has his direct link set up

    When I fill `SearchField` field with Bob's direct link
    Then I see user Bob in search results
