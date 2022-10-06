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

Feature: Chat avatar update and remove

  Background: User is in group chat with Bob
    Given I am Alice
    And user Bob
    And Bob has group chat with me named 'Alice and Bob'
    And I am in chat 'Alice and Bob'

  Scenario: User change chat avatar and delete it
    When I tap `ChatAvatar` element
    Then I wait until `ChangeAvatar` is present

    When I am change chat avatar inside chat 'Alice and Bob'
    Then I wait until `DeleteAvatar` is present

    When I tap `DeleteAvatar` button
    Then I wait until `ChangeAvatar` is present
