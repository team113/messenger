# Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

Feature: Chats searching

  Scenario: User and chat can be found
    Given I am Alice
    And users Bob and Charlie
    # And contact Charlie
    And I have "Example" group with Bob

    When I fill `SearchField` field with "Example"
    Then I see chat "Example" in search results

    When I fill `SearchField` field with "Bob"
    Then I see user Bob in search results

  # When I fill `SearchField` field with "Charlie"
  # Then I see contact Charlie in search results

  # Scenario: Search paginates its results
  #   Given I am Alice
  #   And 31 users Dave
  #   And I wait until `HomeView` is present

  #   When I tap `SearchButton` button
  #   And I fill `SearchField` field with "Dave"
  #   Then I wait until `Search` is present

  #   Given I have Internet with delay of 4 seconds
  #   When I scroll `SearchScrollable` until `SearchLoading` is present
  #   And I wait until `SearchLoading` is absent

  Scenario: Dialog can be found by direct link
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And Bob has his direct link set up

    When I fill `SearchField` field with Bob's direct link
    Then I see user Bob in search results
