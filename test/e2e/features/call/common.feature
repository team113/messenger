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
    And popup windows is disabled

  Scenario: Outgoing dialog call changes state correctly
    Given Bob has dialog with Alice
    And I am in chat with Bob

    When I tap `StartAudioCall` button
    Then I wait until `Call` is present
    And I wait until `ActiveCall` is absent

    When Bob accepts call
    Then I wait until `ActiveCall` is present
    And I wait until Bob is present in call

  Scenario: Outgoing group call changes state correctly
    Given Bob has group with Alice
    And I am in chat with Bob

    When I tap `StartAudioCall` button
    Then I wait until `Call` is present
    And I wait until `ActiveCall` is present

    When Bob accepts call
    Then I wait until Bob is present in call

  Scenario: Join to active group call
    Given Bob has group with Alice

    When Bob starts call
    And I tap `DeclineCall` button
    Then I wait until `Call` is absent

    When I tap `JoinCallButton` button
    And I wait until `ActiveCall` is present
    And I wait until Bob is present in call

  Scenario: Incoming dialog call changes state correctly
    Given Bob has dialog with Alice

    When Bob starts call
    And I tap `AcceptCallAudio` button
    Then I wait until `ActiveCall` is present
    And I wait until Bob is present in call

  Scenario: Incoming group call changes state correctly
    Given Bob has group with Alice

    When Bob starts call
    And I tap `AcceptCallAudio` button
    Then I wait until `ActiveCall` is present
    And I wait until Bob is present in call

  Scenario: More panel is opening and closing
    Given Bob has group with Alice
    And I am in chat with Bob

    When I tap `StartAudioCall` button
    And I tap `More` button
    Then I wait until `MorePanel` is present

    When I tap `More` button
    Then I wait until `MorePanel` is absent

  Scenario: Call settings is opening and closing
    Given Bob has group with Alice
    And I am in chat with Bob

    When I tap `StartAudioCall` button
    And I tap `More` button
    And I tap `Settings` button
    Then I wait until `CallSettings` is present

    When I tap `CloseButton` button
    Then I wait until `CallSettings` is absent
