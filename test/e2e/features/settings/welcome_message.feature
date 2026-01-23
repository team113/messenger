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

Feature: Welcome message

  @profile
  Scenario: User creates and deletes welcome message
    Given I am Alice

    When I tap `MenuButton` button
    And I scroll `MenuListView` until `WelcomeMessage` is present
    And I tap `WelcomeMessage` button
    Then I wait until `NoWelcomeMessage` is present

    When I fill `WelcomeMessageField` field with "Hello"
    And I tap `PostWelcomeMessage` button
    Then I wait until `NoWelcomeMessage` is absent

    When I tap `DeleteWelcomeMessage` button
    Then I wait until `NoWelcomeMessage` is present
