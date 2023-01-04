# Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

Feature: Favorite contacts

  Background: User has contacts Bob and Charlie
    Given I am Alice
    And users Bob and Charlie
    And contacts Bob and Charlie
    And I wait until `HomeView` is present
    And I tap `ContactsButton` button

  Scenario: User adds contact to favorites
    When I long press "Bob" contact
    And I tap `FavoriteContactButton` button
    Then I see "Bob" contact as favorite
    And I see "Bob" contact first in contacts list

    When I long press "Charlie" contact
    And I tap `FavoriteContactButton` button
    Then I see "Charlie" contact as favorite
    And I see "Charlie" contact first in contacts list

  Scenario: User removes contact from favorites
    Given "Bob" contact is favorite
    And I see "Bob" contact as favorite

    When I long press "Bob" contact
    And I tap `UnfavoriteContactButton` button
    Then I see "Bob" contact as unfavorited
    And I see "Bob" contact last in contacts list
