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

Feature: Chats searching

  Scenario: I found chat, user and contact
    Given I am Alice
    And users Bob and Charlie
    And I have "Example" group with Bob
    And I have contact Charlie

    When I tap `SearchButton` button
    And I fill `SearchField` field with "Example"
    Then I wait until "Example" chat in search results is present

    When I fill `SearchField` field with "Bob"
    Then I wait until Bob user in search results is present

    When I fill `SearchField` field with "Charlie"
    Then I wait until "Charlie" contact in search results is present
