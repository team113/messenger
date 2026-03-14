# Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

Feature: Audio Player functionality

  Background: User is in dialog with Bob
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait for app to settle

  @audio
  Scenario: Play and pause audio
    Given Bob sends "test.mp3" attachment to me
    And I wait until attachment "test.mp3" is present

    When I toggle play for "test.mp3" audio
    Then I see "test.mp3" audio is playing
    And I see "test.mp3" audio slider position changes while playing

    When I toggle play for "test.mp3" audio
    Then I see "test.mp3" audio is paused

  @audio
  Scenario: Exclusive playback - only one audio plays at a time
    Given Bob sends "first.mp3" attachment to me
    And Bob sends "second.mp3" attachment to me
    And I wait until attachment "first.mp3" is present
    And I wait until attachment "second.mp3" is present

    When I toggle play for "first.mp3" audio
    Then I see "first.mp3" audio is playing

    When I toggle play for "second.mp3" audio
    Then I see "second.mp3" audio is playing
    And I see "first.mp3" audio is paused

  @audio
  Scenario: Audio continues playing after navigating out and back
    Given Bob sends "test.mp3" attachment to me
    And I wait until attachment "test.mp3" is present

    When I toggle play for "test.mp3" audio
    And I return to previous page
    And I am in chat with Bob

    Then I see "test.mp3" audio is playing
    And I see "test.mp3" audio slider position changes while playing
