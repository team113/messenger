# Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

Feature: Gallery pagination

  Background: User has group chat
    Given user Alice with their password set
    And Alice has "Gallery" group

  @disabled
  @chat
  @common
  Scenario: User can paginate images in gallery
    Given Alice posts 60 image attachments to "Gallery" group
    And Alice reads all messages in "Gallery" group
    And I sign in as Alice
    And I am in "Gallery" group
    And I wait for app to settle

    When I tap on last image in chat
    # Then I wait until `GalleryPopup` is present
    And I wait until `LeftButton` is present
    And I wait until `NoRightButton` is present

    When I tap `LeftButton` button 59 times
    Then I wait until `NoLeftButton` is present
    And I wait until `RightButton` is present

  @disabled
  @chat
  @common
  Scenario: User can paginate images in gallery with a lot of content
    Given Alice posts 10 image attachments to "Gallery" group
    And Alice posts 20 file attachments to "Gallery" group
    And Alice sends 30 messages to "Gallery" group
    And Alice posts 10 image attachments to "Gallery" group
    And Alice reads all messages in "Gallery" group
    And I sign in as Alice
    And I am in "Gallery" group
    And I wait for app to settle

    When I tap on last image in chat
    # Then I wait until `GalleryPopup` is present
    And I wait until `LeftButton` is present
    And I wait until `NoRightButton` is present

    When I tap `LeftButton` button 19 times
    Then I wait until `NoLeftButton` is present
    And I wait until `RightButton` is present
