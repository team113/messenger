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

Feature: Hand up/down in call tests

  Background:
    Given I am Alice
    And user Bob
    And Bob has group with Alice
    And I am in chat with Bob
    And popup windows is disabled

  Scenario: Hand up and down
    When I tap `StartAudioCall` button
    And I tap `More` button
    And I tap `HandUp` button
    Then I wait until my hand is raised

    When I tap `HandDown` button
    And I wait until my hand is lowered

  Scenario: User hand ups and downs
    When I tap `StartAudioCall` button
    And Bob accepts call
    Then I wait until Bob is present in call

    When Bob raises hand
    Then I wait until Bob hand is raised

    When Bob lowers hand
    Then I wait until Bob hand is lowered
