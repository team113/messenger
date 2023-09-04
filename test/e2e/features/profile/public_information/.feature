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

Feature: Public information

  Scenario: User change name, presence status and regular status
    When I tap `StartButton` button
    And I wait until `IntroductionView` is present
    And I tap `CloseButton` button

    And I tap `MenuButton` button
    And I tap `PublicInformation` button
    And I wait until `MyProfileView` is present
    And I wait until `NameField` is present
    And I fill `NameField` field with "Alice"
    And I tap `Approve` button
    And I fill `NameField` field with ""
    Then I tap `Approve` button

    When I tap `PresenceStatus` button 
    And I tap `Away` button
    And I tap `CloseButton` button

    When I fill `StatusField` field with "Text error, text error, text error"
    And I tap `Approve` button
    And I wait until text "Text error, text error, text error" is absent

    And I fill `StatusField` field with "My status"
    And I tap `Approve` button
    Then I wait until text "My status" is present

    

    