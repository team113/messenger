# Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

Feature: Cancel call tests

  Background:
    Given I am Alice
    And user Bob
    And popup windows are disabled

  Scenario: Cancel outgoing dialog call
    Given Bob has dialog with me
    And I am in chat with Bob

    When I tap `AudioCall` button
    Then I wait until `Call` is present

    When I tap `EndCall` button
    Then I wait until `Call` is absent

  Scenario: User cancels outgoing dialog call
    Given Bob has dialog with me

    When Bob starts call in dialog with me
    Then I wait until `Call` is present

    When Bob cancels call
    Then I wait until `Call` is absent

  Scenario: User cancels outgoing group call
    Given I have "Test" group with Bob

    When Bob starts call in "Test" group
    Then I wait until `Call` is present

    When Bob cancels call
    Then I wait until `Call` is absent
