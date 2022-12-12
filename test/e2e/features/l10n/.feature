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

# TODO: fix test after profile modal windows transferring.
#Feature: Application localization changes correctly
#
#  Scenario: User changes localization
#    Given I am Alice
#    And I wait until `HomeView` is present
#
#    Then I tap `MenuButton` button
#    And I tap `SettingsButton` button
#
#    Then I tap `Language_enUS` within `LanguageDropdown` dropdown
#    And I wait until text "Settings" is present
#
#    Then I tap `Language_ruRU` within `LanguageDropdown` dropdown
#    And I wait until text "Настройки" is present
