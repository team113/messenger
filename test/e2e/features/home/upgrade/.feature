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

Feature: Upgrade popup
  Background: I am guest
    Given I am guest

  Scenario: New versions are prompted in upgrade alerts
    Given appcast with newer version is available

    When I wait for app to settle
    And I pause for 5 seconds
    Then I wait until `UpgradeAlert` is present

  Scenario: Upgrade alerts aren't displayed for current version
    Given appcast with current version is available

    When I wait for app to settle
    And I wait for 5 seconds
    Then I wait until `UpgradePopup` is absent
    And I wait until `UpgradeAlert` is absent

  Scenario: Critical upgrade popup can't be skipped
    Given appcast with critical version is available

    When I wait for app to settle
    Then I wait until `UpgradePopup` is present
    And I wait until `SkipButton` is absent
