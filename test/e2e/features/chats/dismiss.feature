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

Feature: Chats dismissing

  @chats
  Scenario: Chats can be dismissed
    Given I am Alice
    And I have "01" group
    And I have "02" group
    And I wait until "01" chat is present
    And I wait until "02" chat is present
    And I wait for app to settle

    When I dismiss "01" chat
    Then I wait until "01" chat is absent

    When I dismiss "02" chat
    Then I wait until "02" chat is absent
    And I pause for 5 seconds
