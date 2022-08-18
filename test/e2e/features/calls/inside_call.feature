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

  Background:
    Given I am Alice
    And user Bob

  Scenario: End active dialog call
    Given Bob has dialog with Alice

    When Bob start call
    And I tap `AcceptCallAudio` button
    Then I wait until `ActiveCall` is present

    When I tap `EndCall` button
    Then I wait until `Call` is absent

  Scenario: End active group call
    Given Bob has group with Alice

    When Bob start call
    And I tap `AcceptCallAudio` button
    Then I wait until `ActiveCall` is present

    When I tap `EndCall` button
    Then I wait until `Call` is absent

  Scenario: Dialog call ends when user leaves
    Given Bob has dialog with Alice
    And I am in chat with Bob

    When I tap `StartAudioCall` button
    And Bob accept call
    Then I wait until `ActiveCall` is present
    And I wait until Bob is present in call

    When Bob leave call
    Then I wait until `Call` is absent

  Scenario: Group call doesn't ends when user leaves
    Given Bob has group with Alice
    And I am in chat with Bob

    When I tap `StartAudioCall` button
    And Bob accept call
    Then I wait until `ActiveCall` is present
    And I wait until Bob is present in call

    When Bob leave call
    Then I wait until Bob is absent in call
    And I wait until `ActiveCall` is present

  Scenario: More panel is opening and closing
    Given Bob has group with Alice
    And I am in chat with Bob

    When I tap `StartAudioCall` button
    And I tap `More` button
    Then I wait until `ButtonsPanel` is present

    When I tap `More` button
    Then I wait until `ButtonsPanel` is absent

  Scenario: Call settings is opening and closing
    Given Bob has group with Alice
    And I am in chat with Bob

    When I tap `StartAudioCall` button
    And I tap `More` button
    And I tap `Settings` button
    Then I wait until `CallSettings` is present

    When I tap `CloseSettings` button
    Then I wait until `CallSettings` is absent

  Scenario: Add participant dialog is opening and closing
    Given Bob has group with Alice
    And I am in chat with Bob

    When I tap `StartAudioCall` button
    And I tap `More` button
    And I tap `AddParticipant` button
    Then I wait until `AddGroupMembers` is present

    When I tap `CloseAddGroupMember` button
    Then I wait until `CloseAddGroupMember` is absent

  Scenario: Hand up and down
    Given Bob has group with Alice
    And I am in chat with Bob

    When I tap `StartAudioCall` button
    And I tap `More` button
    And I tap `HandUp` button
    Then I wait until my hand is raise

    When I tap `HandDown` button
    And I wait until my hand is lower

  Scenario: User hand up and down
    Given Bob has group with Alice
    And I am in chat with Bob

    When I tap `StartAudioCall` button
    And Bob accept call
    Then I wait until Bob is present in call

    When Bob raise hand
    Then I wait until Bob hand is raise

    When Bob lower hand
    Then I wait until Bob hand is lower

  Scenario: Add user to dialog call
    Given user Charlie
    And Bob has dialog with Alice
    And I am in chat with Bob

    When I tap `StartAudioCall` button
    And Bob accept call
    And I tap `More` button
    And I tap `AddParticipant` button
    And I fill users search field with user Charlie
    And I tap Charlie in search results
    And I tap `AddDialogMembersButton` button
    And Charlie accept call
    Then I wait until Charlie is present in call

  Scenario: Add user to group call
    Given user Charlie
    And Bob has group with Alice
    And I am in chat with Bob

    When I tap `StartAudioCall` button
    And Bob accept call
    And I tap `More` button
    And I tap `AddParticipant` button
    And I fill users search field with user Charlie
    And I tap Charlie in search results
    And I tap `AddGroupMembersButton` button
    And Charlie accept call
    Then I wait until Charlie is present in call

  Scenario: Add my user to call
    Given user Charlie
    And Bob has group with Charlie
    And Bob start call

    When Charlie accept call
    And Bob add Alice to group call
    Then I wait until `Call` is present

    When I tap `AcceptCallAudio` button
    Then I wait until Charlie is present in call
    And I wait until Bob is present in call
