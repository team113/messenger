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

@disabled
Feature: Chat members pagination

  Scenario: Chat members pagination works correctly
    Given user Alice
    And Alice has "Members" group with 16 members
    And I sign in as Alice
    And I pause for 2 seconds
    And I am in "Members" group
    And I pause for 5 seconds

    When I open chat's info
    And I pause for 10 seconds
    Then I see 15 chat members

    Given I have Internet with delay of 3 seconds
    When I scroll `ChatInfoScrollable` until `ChatMembers` is present
    And I scroll `ChatMembers` until `MembersLoading` is present
    Then I wait until `MembersLoading` is absent
    And I see 16 chat members
