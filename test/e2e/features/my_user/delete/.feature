# Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
#                       <https://github.com/team113>
# Copyright © 2025-2026 Ideas Networks Solutions S.A.,
#                       <https://github.com/tapopa>
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

Feature: Account deletion

  Scenario: User creates and deletes account without confirmation
    When I wait until `IntroductionView` is present
    And I tap `GuestButton` button
    Then I wait until `GuestCreatedScreen` is present

    When I tap `ProceedButton` button
    Then I wait until `IntroductionView` is absent
    And my account is indeed remote

    When I tap `MenuButton` button
    And I scroll `MenuListView` until `DangerZone` is present
    And I tap `DangerZone` button
    Then I wait until `EraseView` is present

    When I scroll `EraseScrollable` until `ConfirmDelete` is present
    And I tap `ConfirmDelete` button
    And I tap `Proceed` button

    Then I wait until `IntroductionView` is present
    And I pause for 1 second
