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

Feature: Inside call tests

  Scenario: End active dialog call
    Given I am Alice
    And user Bob
    And Bob has dialog with me

    Then Bob start call
    And I wait until `Call` is present
    Then I tap `AcceptCallAudio` button
    And I wait until `ActiveCall` is present
    And I wait until `EndCall` is present
    Then I tap `EndCall` button
    And I wait until `Call` is absent

  Scenario: End active group call
    Given I am Alice
    And user Bob
    And Bob has group with me

    Then Bob start call
    And I wait until `Call` is present
    Then I tap `AcceptCallAudio` button
    And I wait until `ActiveCall` is present
    And I wait until `EndCall` is present
    Then I tap `EndCall` button
    And I wait until `Call` is absent

  Scenario: Dialog call ends when user leaves
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait until `StartAudioCall` is present

    Then I tap `StartAudioCall` button
    And I wait until `Call` is present
    Then Bob accept call
    And I wait until `ActiveCall` is present
    And I wait until Bob is present in call
    Then Bob leave call
    And I wait until `Call` is absent

  Scenario: Group call doesn't ends when user leaves
    Given I am Alice
    And user Bob
    And Bob has group with me
    And I am in chat with Bob
    And I wait until `StartAudioCall` is present

    Then I tap `StartAudioCall` button
    Then Bob accept call
    And I wait until `ActiveCall` is present
    And I wait until Bob is present in call
    Then Bob leave call
    And I wait until Bob is absent in call
    And I wait until `Call` is present

  Scenario: More panel is opening and closing
    Given I am Alice
    And user Bob
    And Bob has group with me
    And I am in chat with Bob
    And I wait until `StartAudioCall` is present

    Then I tap `StartAudioCall` button
    And I wait until `More` is present
    Then I tap `More` button
    And I wait until `ButtonsPanel` is present
    Then I tap `More` button
    And I wait until `ButtonsPanel` is absent

  Scenario: Call settings is opening and closing
    Given I am Alice
    And user Bob
    And Bob has group with me
    And I am in chat with Bob
    And I wait until `StartAudioCall` is present

    Then I tap `StartAudioCall` button
    And I wait until `More` is present
    Then I tap `More` button
    And I wait until `Settings` is present
    Then I tap `Settings` button
    And I wait until `CallSettings` is present
    Then I tap `CloseSettings` button
    And I wait until `CallSettings` is absent

  Scenario: Add participant dialog is opening and closing
    Given I am Alice
    And user Bob
    And Bob has group with me
    And I am in chat with Bob
    And I wait until `StartAudioCall` is present

    Then I tap `StartAudioCall` button
    And I wait until `More` is present
    Then I tap `More` button
    And I wait until `AddParticipant` is present
    Then I tap `AddParticipant` button
    And I wait until `AddGroupMembers` is present
    Then I tap `CloseAddGroupMember` button
    And I wait until `CloseAddGroupMember` is absent

  Scenario: Hand up and down
    Given I am Alice
    And user Bob
    And Bob has group with me
    And I am in chat with Bob
    And I wait until `StartAudioCall` is present

    Then I tap `StartAudioCall` button
    And I wait until `More` is present
    Then I tap `More` button
    And I wait until `HandUp` is present
    Then I tap `HandUp` button
    And I wait until my hand is raise
    Then I tap `HandDown` button
    And I wait until my hand is lower

  Scenario: User hand up and down
    Given I am Alice
    And user Bob
    And Bob has group with me
    And I am in chat with Bob
    And I wait until `StartAudioCall` is present

    Then I tap `StartAudioCall` button
    Then Bob accept call
    And I wait until Bob is present in call
    Then Then Bob raise hand
    And I wait until Bob hand is raise
    Then Then Bob lower hand
    And I wait until Bob hand is lower

  Scenario: Move call from dialog to group
    Given I am Alice
    And user Bob
    And user Charlie
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait until `StartAudioCall` is present

    Then I tap `StartAudioCall` button
    Then Bob accept call
    And I wait until `More` is present
    Then I tap `More` button
    And I wait until `AddParticipant` is present
    Then I tap `AddParticipant` button
    And I wait until `UserSearchBar` is present
    Then I fill `UserSearchBar` field with user Charlie
    And I wait until Charlie is present in search
    Then I tap Charlie in search
    And I tap `AddDialogMembersButton` button
