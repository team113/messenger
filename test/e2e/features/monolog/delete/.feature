# Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

Feature: Delete monolog

  Background: User has a local monolog
    Given I am Alice
    And I am in monolog

  Scenario: User delete monolog
    When I open chat's info
    And I scroll `ChatInfoScrollable` to bottom
    And I pause for 1 seconds
    And I tap `DeleteDialogButton` button
    And I tap `Proceed` button
    And I return to previous page
    And I pause for 1 seconds
    Then Monolog is indeed hidden
