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

Feature: Attachments refetching

  Scenario: User sees image refetched in chat
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And Bob sends "test.jpg" attachment to me
    And I have Internet with delay of 4 seconds

    When I am in chat with Bob
    Then I wait until "test.jpg" attachment is fetching
    And I wait until "test.jpg" attachment is fetched
