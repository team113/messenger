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

Feature: Complain user

  Scenario: Complaint about the user is being sent
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I wait until `HomeView` is present

    When I go to Bob's page
    And I scroll `UserScrollable` to bottom
    And I pause for 2 seconds
    And I tap `Report` button
    And I fill `ReportField` field with "Spam"
    And I pause for 2 seconds
    And I tap `ProceedReport` button
    Then I wait until `ProceedReport` is absent

