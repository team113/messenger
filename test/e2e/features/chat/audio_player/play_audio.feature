# Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

Feature: Audio playback in audio attachments

  Background: User is in any dialog
    Given I am a user in a chat dialog
    And I am currently in the chat screen
    And the app has settled

  Scenario: Play audio attachment
    When I upload an audio file
    And I tap on the audio file to play
    Then the playback state should be "playing"

  Scenario: Pause audio attachment
    When I tap on the same audio file second time
    Then the playback state should not be "playing"

  Scenario: Resume audio playback
    When I tap on the same audio third time
    Then the playback state should be "playing"

  Scenario: Seek audio playback
    When I seek the audio file to a specific position using slider
    Then the current position should change
    And the playback state should be kept same

  Scenario: Play another audio file
    Given I have already played one audio file
    When I upload and click on another audio file
    Then the new audio file should start playing
    And the previous audio file should not be playing
