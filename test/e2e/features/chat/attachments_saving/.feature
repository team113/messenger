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

Feature: Attachments downloading

  Background:
    Given users Alice and Bob
    And Bob has dialog with Alice
    And I sign in as Alice
    And I pause for 2 seconds
    And I wait until `IntroductionView` is present
    And I scroll `IntroductionScrollable` until `ProceedButton` is present
    And I tap `ProceedButton` button
    And I am in chat with Bob

  Scenario: Attachments can be downloaded
    When Bob sends "test.txt" attachment to me
    Then I wait until "test.txt" file is not downloaded

    When I download "test.txt" file
    Then I wait until "test.txt" file is downloading
    And I wait until "test.txt" file is downloaded

  Scenario: Attachment download can be canceled
    When Bob sends "test.txt" attachment to me
    Then I wait until "test.txt" file is not downloaded

    When I download "test.txt" file
    Then I wait until "test.txt" file is downloading

    When I cancel "test.txt" file download
    Then I wait until "test.txt" file is not downloaded
