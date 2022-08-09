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

Feature: Calls test

  Scenario: Outgoing dialog call changes state correctly
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in dialog with Bob
    And I wait until `StartAudioCall` is present

    Then I tap `StartAudioCall` button
    And I wait until `Call` is present
    And Bob accept call
    And I wait until `ActiveCall` is present
    And I wait until Bob is present in call

  Scenario: Outgoing group call changes state correctly
    Given I am Alice
    And user Bob
    And Bob has group with me
    And I am in group with Bob
    And I wait until `StartAudioCall` is present

    Then I tap `StartAudioCall` button
    And I wait until `Call` is present
    And Bob accept call
    And I wait until `ActiveCall` is present
    And I wait until Bob is present in call

  Scenario: Incoming dialog call changes state correctly
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in dialog with Bob

    Then Bob start call
    And I wait until `Call` is present
    And I tap `AcceptCallAudio` button
    And I wait until `ActiveCall` is present
    And I wait until Bob is present in call

  Scenario: Incoming group call changes state correctly
    Given I am Alice
    And user Bob
    And Bob has group with me
    And I am in group with Bob

    Then Bob start call
    And I wait until `Call` is present
    And I tap `AcceptCallAudio` button
    And I wait until `ActiveCall` is present
    And I wait until Bob is present in call

  Scenario: Drop active dialog call
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in dialog with Bob

    Then Bob start call
    And I wait until `Call` is present
    And I tap `AcceptCallAudio` button
    And I wait until `ActiveCall` is present
    Then I wait until `EndCall` is present
    And I tap `EndCall` button
    And I wait until `Call` is absent

  Scenario: Drop active group call
    Given I am Alice
    And user Bob
    And Bob has group with me
    And I am in group with Bob

    Then Bob start call
    And I wait until `Call` is present
    And I tap `AcceptCallAudio` button
    And I wait until `ActiveCall` is present
    Then I wait until `EndCall` is present
    And I tap `EndCall` button
    And I wait until `Call` is absent

  Scenario: Decline incoming dialog call
    Given I am Alice
    And user Bob
    And Bob has group with me
    And I am in group with Bob

    Then Bob start call
    And I wait until `Call` is present
    And I tap `DeclineCall` button
    And I wait until `Call` is absent

  Scenario: Decline incoming group call
    Given I am Alice
    And user Bob
    And Bob has group with me
    And I am in group with Bob

    Then Bob start call
    And I wait until `Call` is present
    And I tap `DeclineCall` button
    And I wait until `Call` is absent

  Scenario: User call to decline incoming dialog call
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in dialog with Bob
    And I wait until `StartAudioCall` is present

    Then I tap `StartAudioCall` button
    And I wait until `Call` is present
    And Bob decline call
    And I wait until `Call` is absent

  Scenario: User leave active dialog call
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in dialog with Bob
    And I wait until `StartAudioCall` is present

    Then I tap `StartAudioCall` button
    And I wait until `Call` is present
    And Bob accept call
    And I wait until `ActiveCall` is present
    And I wait until Bob is present in call
    Then Bob leave call
    And I wait until `Call` is absent

  Scenario: User leave active group call
    Given I am Alice
    And user Bob
    And Bob has group with me
    And I am in group with Bob
    And I wait until `StartAudioCall` is present

    Then I tap `StartAudioCall` button
    And I wait until `Call` is present
    And Bob accept call
    And I wait until `ActiveCall` is present
    And I wait until Bob is present in call
    Then Bob leave call
    And I wait until Bob is absent in call
