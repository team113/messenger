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

 Feature: User phones

   Scenario: User adds, confirms and deletes phone
     Given I am Alice
     And I wait until `HomeView` is present

     When I tap `MenuButton` button
     And I tap `Signing` button
     And I tap `AddPhone` button
     Then I wait until `Phone` is present

     When I fill `Phone` field with "+380971234567"
     And I tap `Proceed` button
     And I tap `CloseButton` button
     Then I wait until `UnconfirmedPhone` is present

     When I tap `UnconfirmedPhone` widget
     And I wait until `ConfirmationCode` is present
     And I fill `ConfirmationCode` field with "1234"
     And I tap `Proceed` button
     Then I wait until `ConfirmedPhone` is present

     When I tap `DeletePhone` widget
     And I tap `Proceed` button
     Then I wait until `AddPhone` is present
