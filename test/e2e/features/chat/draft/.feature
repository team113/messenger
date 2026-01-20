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

Feature: Drafts

  Scenario: Draft is persisted
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I pause for 3 seconds

    When I attach "test.txt" file
    And I fill `MessageField` field with "He-he, draft!"
    And I pause for 2 seconds
    And I return to previous page
    Then I see draft "He-he, draft!" in chat with Bob
    And I pause for 2 seconds

    When I am in chat with Bob
    And I pause for 2 seconds
    Then I wait until text "He-he, draft!" is present

    When I tap `Send` button
    Then I wait until status of "He-he, draft!" message is sent
