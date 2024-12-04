# Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

Feature: User scrolls MyProfileScrollable

  Scenario: User jump to last item and scrolls from it to the first item
    Given I am Alice

    When I tap `MenuButton` button
    And I tap `PublicInformation` button
    Then I wait until `MyProfileView` is present
    And I wait until `BigAvatarProfileField` is present

    When I scroll `MenuListView` until `Legal` is present
    And I tap `Legal` button
    Then I wait until `BigAvatarProfileField` is absent
    And I wait until `LegalField` is present

    When I scroll back `MyProfileScrollable` until `BigAvatarProfileField` is present
    And I wait until `LegalField` is absent
