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

Feature: Monolog

  Background: User has a local monolog
    Given I am Alice
    And I wait until `ChatMonolog` is present
    And I am in monolog
    And monolog is indeed local

  Scenario: Message can be posted in local monolog
    When I fill `MessageField` field with "Hello, my monolog"
    And I tap `Send` button
    Then I wait until status of "Hello, my monolog" message is read
    And monolog is indeed remote

  Scenario: Call can be made in local monolog
    Given popup windows are disabled
    When I tap `AudioCall` button
    Then monolog is indeed remote
    And I pause for 2 seconds

  Scenario: User renames local monolog
    When I open chat's info
    And I tap `EditNameButton` button
    And I fill `RenameChatField` field with "My monolog"
    And I tap `SaveNameButton` button
    Then monolog is indeed remote

  Scenario: User adds local chat monolog to favorites
    When I long press monolog
    And I tap `FavoriteChatButton` button
    Then monolog is indeed remote
    And I see monolog as favorite

  Scenario: User hides local monolog
    When I open chat's info
    And I scroll `ChatInfoScrollable` until `HideChatButton` is present
    And I tap `HideChatButton` button
    And I tap `Proceed` button
    And I pause for 1 second
    Then I wait until `ChatMonolog` is absent
    And monolog is indeed remote

    When I restart app
    And I pause for 5 seconds
    Then I wait until `ChatMonolog` is absent
