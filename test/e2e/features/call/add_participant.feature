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

Feature: Add participant in call tests

  Background:
    Given I am Alice
    And user Bob
    And popup windows is disabled

  Scenario: Add participant to dialog call
    Given user Charlie
    And Bob has dialog with me
    And I am in chat with Bob

    When I tap `StartAudioCall` button
    And Bob accepts call
    And I tap `More` button
    And I tap `Participants` button
    And I tap `AddParticipants` button
    And I fill users search field with user Charlie
    And I tap Charlie in search results
    And I tap `SearchSubmitButton` button
    And Charlie accepts call
    Then I wait until Charlie is present in call

  Scenario: Add participant to group call
    Given user Charlie
    And Bob has "Test" group with me
    And I am in chat with Bob

    When I tap `StartAudioCall` button
    And Bob accepts call
    And I tap `More` button
    And I tap `Participants` button
    And I tap `AddParticipants` button
    And I fill users search field with user Charlie
    And I tap Charlie in search results
    And I tap `SearchSubmitButton` button
    And Charlie accepts call
    Then I wait until Charlie is present in call

  Scenario: Add my user to call
    Given user Charlie
    And Bob has "Test" group with Charlie
    And Bob starts call in "Test" group

    When Charlie accepts call
    And Bob adds Alice to group call
    Then I wait until `Call` is present

    When I tap `AcceptCallAudio` button
    Then I wait until Charlie is present in call
    And I wait until Bob is present in call
