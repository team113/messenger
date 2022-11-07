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

Feature: Drafts

  Scenario: Message is persisted
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I attach "test.txt" file
    And I fill `MessageField` field with "123"

    When I return to previous page
    Then I wait until `DraftMessage` is present

    When I am in chat with Bob
    Then I wait until text "test" is present
    And I wait until text "123" is present

    When I tap `Send` button
    Then I wait until `DraftMessage` is absent
