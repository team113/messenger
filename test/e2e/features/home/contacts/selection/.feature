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

# TODO: Uncomment, when contacts are implemented.
# Feature: Contacts selection

#   Scenario: User selects and deletes contacts
#     Given I am Alice
#     And users Bob and Charlie
#     And contacts Bob and Charlie
#     And I wait until `HomeView` is present
#     And I tap `ContactsButton` button
#     And I wait until "Bob" contact is present
#     And I wait until "Charlie" contact is present

#     When I tap `ContactsMenu` button
#     And I tap `SelectContactsButton` button
#     Then I see "Bob" contact as unselected
#     And I see "Charlie" contact as unselected

#     When I tap "Bob" contact
#     Then I see "Bob" contact as selected
#     When I tap "Charlie" contact
#     Then I see "Charlie" contact as selected

#     When I tap `DeleteContactsButton` button
#     And I tap `Proceed` button
#     Then I wait until "Bob" contact is absent
#     And I wait until "Charlie" contact is absent
