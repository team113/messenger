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

Feature: Attachments uploading

  Background:
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait for app to settle
    And I have Internet with delay of 20 seconds

  Scenario: Canceling upload of one of the files after sending a new message
    When I attach "test.txt" file
    And I attach "test2.txt" file
    And I tap `Send` button

    Then I wait until status of "test.txt" attachment is sending
    When I cancel "test.txt" file upload
    Then I wait until attachment "test.txt" is absent
    And I wait until status of "test2.txt" attachment is sent

  Scenario: Canceling upload of all files after sending a new message
    When I attach "test.txt" file
    And I attach "test2.txt" file
    And I tap `Send` button

    Then I wait until status of "test.txt" attachment is sending
    When I cancel "test.txt" file upload
    Then I wait until attachment "test.txt" is absent
    When I cancel "test2.txt" file upload
    Then I see no messages in chat

