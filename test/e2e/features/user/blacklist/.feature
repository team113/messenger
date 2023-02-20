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

Feature: Blacklist

  Scenario: Blacklisted user cannot send me a message
    Given I am Alice
    And user Bob
    And I have dialog with Bob
    And I wait until `HomeView` is present

    When I go to Bob's page
    And I tap `Block` button
    And I tap `Proceed` button
    Then Bob sends message to me and receives blacklisted exception

    When I tap `Unblock` button
    Then Bob sends message to me and receives no exception
