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

Feature: Leave chat

  Background: User is in group chat with Bob and Charlie
    Given I am Alice
    And users Bob and Charlie
    And I have "Group" group
    And I am in "Group" group
    And I see some messages in chat
    And I open chat's info

  Scenario: User leaves group
    When I wait until `ChatInfoScrollable` is present
    And I scroll `ChatInfoScrollable` until `LeaveChatButton` is present
    And I tap `LeaveChatButton` button
    And I tap `Proceed` button
    Then I wait until "Group" chat is absent
