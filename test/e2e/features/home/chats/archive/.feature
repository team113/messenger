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

Feature: Archive chats

  Scenario: Chats can be added to archive
    Given user Alice
    And Alice has "01" group
    And Alice has "02" group
    And Alice has "03" group
    And Alice has "04" group in archive
    And Alice has "05" group in archive
    And I sign in as Alice
    And I wait for app to settle

    When I tap `ChatsMenu` button
    And I tap `ArchiveChatsButton` button
    Then I see "04" group as archived
    And I see "05" group as archived

    When I tap `ChatsMenu` button
    And I tap `ArchiveChatsButton` button
    Then I see "01" group as unarchived
    And I see "02" group as unarchived
    And I see "03" group as unarchived

    When I long press "01" group
    And I tap `ArchiveChatButton` button
    And I tap `Proceed` button
    And I pause for 1 second
    And I tap `ChatsMenu` button
    And I tap `ArchiveChatsButton` button
    Then I see "01" group as archived

    When I long press "01" group
    And I tap `ArchiveChatButton` button
    And I tap `Proceed` button
    And I pause for 1 second
    And I tap `ChatsMenu` button
    And I tap `ArchiveChatsButton` button
    Then I see "01" group as unarchived
