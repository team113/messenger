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
# Feature: Contacts pagination

#   Scenario: Contacts pagination works correctly
#     Given user Alice
#     And Alice has 16 contacts
#     And I sign in as Alice

#     When I scroll `IntroductionScrollable` until `ProceedButton` is present
#     And I tap `ProceedButton` button
#     And I tap `ContactsButton` button
#     Then I wait until `ContactsTab` is present
#     And I see 15 contacts

#     Given I have Internet with delay of 3 seconds
#     When I scroll `Contacts` until `ContactsLoading` is present
#     Then I wait until `ChatsLoading` is absent
#     And I see 16 contacts

#   Scenario: Contacts pagination transitions from favorites to all
#     Given user Alice
#     And Alice has 30 favorite contacts
#     And Alice has 15 contacts
#     And I sign in as Alice

#     When I scroll `IntroductionScrollable` until `ProceedButton` is present
#     And I tap `ProceedButton` button
#     And I tap `ContactsButton` button
#     Then I see 15 contacts

#     When I scroll `Contacts` to bottom
#     Then I see 30 contacts

#     When I scroll `Contacts` to bottom
#     Then I see 45 contacts
