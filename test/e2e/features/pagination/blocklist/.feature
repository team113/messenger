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

Feature: Blocklist pagination

  Scenario: Blocklist pagination works correctly
    Given user Alice
    And Alice has 16 blocked users
    And I sign in as Alice

    When I tap `MenuButton` button
    And I scroll `MenuListView` until `Blocklist` is present
    And I tap `Blocklist` button
    And I tap `ShowBlocklist` button
    Then I wait until `BlocklistView` is present
    And I see 15 blocked users

    Given I have Internet with delay of 3 seconds
    When I scroll `BlocklistView` to bottom
    Then I wait until `BlocklistLoading` is present
    Then I wait until `BlocklistLoading` is absent
    And I see 16 blocked users
