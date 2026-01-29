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

# TODO: Uncomment, when contacts are implemented.
# Feature: Adding contacts

#   Background: User on Bob's page
#     Given I am Alice
#     And user Bob
#     And I wait until `HomeView` is present
#     And I tap `ContactsButton` button
#     And I go to Bob's page

#   Scenario: User adds Bob to their contacts
#     When I tap `MoreButton` button
#     And I tap `AddToContactsButton` button
#     Then I see "Bob" contact as unfavorite

#   Scenario: User adds Bob straight to favorite contacts
#     When I tap `MoreButton` button
#     And I tap `FavoriteButton` button
#     Then I see "Bob" contact as favorite
