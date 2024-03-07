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

Feature: Audio attachments can be played, paused and seeked

  Background:
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

  Scenario: Audio attachment can be played
    When Bob sends "test.mp3" attachment to me
    Then I wait until attachment "test.mp3" is present

    When I play "test.mp3" audio file
    Then audio "test.mp3" is playing

  # Scenario: Audio attachment can be paused
  #   When I pause "test.mp3" audio file
  #   Then audio "test.mp3" is paused

  # Scenario: Audio attachment can be seek
  #   When I seek "test.mp3" audio file
  #   Then audio "test.mp3" playback position is changed

  # Scenario: I can see audio attachment duration
  #   When I play "test.mp3" audio file
  #   Then I can see "test.mp3" audio duration near the slider

  # Scenario: I can see current playback position of the slider
  #   When I play "test.mp3" audio file
  #   Then I can see "test.mp3" audio playback position is changing over time
