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

Feature: Chats pagination

  Scenario: Chats pagination works correctly
    Given user Alice
    And Alice has 31 groups
    And I sign in as Alice

    When I tap `CloseButton` button
    Then I wait until `Chats` is present

    Given I have Internet with delay of 3 seconds
    When I scroll `Chats` until `ChatsLoading` is present
    Then I wait until `ChatsLoading` is absent
