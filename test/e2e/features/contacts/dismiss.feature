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
# Feature: Contacts dismissing

#   Scenario: Contacts can be dismissed and restored
#     Given I am Alice
#     And contacts Bob and Charlie
#     And I tap `ContactsButton` button
#     And I wait until "Bob" contact is present
#     And I wait until "Charlie" contact is present
#     And I see no contacts dismissed
#     And I wait for app to settle

#     When I dismiss "Bob" contact
#     Then I wait until "Bob" contact is absent
#     And I see "Bob" contact as dismissed

#     When I tap `Restore` button
#     Then I wait until "Bob" contact is present

#     When I dismiss "Charlie" contact
#     Then I wait until "Charlie" contact is absent
#     And I see "Charlie" contact as dismissed

#     When I dismiss "Bob" contact
#     Then I wait until "Bob" contact is absent
#     And I see "Bob" contact as dismissed
#     And "Charlie" contact is indeed deleted

#     When I pause for 6 seconds
#     Then I see no contacts dismissed
#     And "Bob" contact is indeed deleted
