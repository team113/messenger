# Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
#                       <https://github.com/team113>
# Copyright © 2025-2026 Ideas Networks Solutions S.A.,
#                       <https://github.com/tapopa>
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

Feature: Direct links

  Background:
    Given user Bob
    And Bob has his direct link set up
    And I wait until `IntroductionView` is present

  Scenario: Direct link can be opened in unauthorized mode
    When I go to Bob's direct link
    Then I wait until `HomeView` is present
    And I wait until `ChatView` is present

  Scenario: Direct link can be opened in authorized mode
    Given I am Alice
    And I wait until `HomeView` is present

    When I go to Bob's direct link
    And I wait until `ChatView` is present

