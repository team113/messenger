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

Feature: Common call tests

  Background:
    Given I am Alice
    And user Bob
    And popup windows are disabled

  Scenario: Join to active group call
    Given I have "Test" group with Bob

    When Bob starts call in "Test" group
    And I tap `DeclineCall` button
    Then I wait until `Call` is absent

    When I tap `JoinCallButton` button
    And I wait until `ActiveCall` is present
    And I wait until Bob is present in call

  Scenario: More panel is opening and closing
    Given I have "Test" group with Bob
    And I am in chat with Bob

    When I tap `AudioCall` button
    And I tap `More` button
    Then I wait until `MorePanel` is present

    When I tap `More` button
    Then I wait until `MorePanel` is absent

  Scenario: Call settings is opening and closing
    Given I have "Test" group with Bob
    And I am in chat with Bob

    When I tap `AudioCall` button
    And I tap `More` button
    And I tap `Settings` button
    Then I wait until `CallSettings` is present

    When I tap `CloseButton` button
    Then I wait until `CallSettings` is absent
