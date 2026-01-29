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

Feature: Group members

  @chat
  @group
  Scenario: Chat members pagination works correctly
    Given user Alice
    And Alice has "Members" group with 16 members
    And I sign in as Alice
    And I pause for 2 seconds
    And I am in "Members" group
    And I pause for 5 seconds

    When I scroll `IntroductionScrollable` until `ProceedButton` is present
    And I tap `ProceedButton` button
    And I open chat's info
    And I pause for 10 seconds
    Then I see 15 chat members

    Given I have Internet with delay of 3 seconds
    When I scroll `ChatInfoScrollable` until `ChatMembers` is present
    And I scroll `ChatMembers` until `MembersLoading` is present
    Then I wait until `MembersLoading` is absent
    And I see 16 chat members

  @chat
  @group
  Scenario: User removes a member
    Given I am Alice
    And I pause for 1 second
    And users Bob and Charlie
    And I have "Alice and Bob" group with Bob
    And I am in "Alice and Bob" group
    And I open chat's info

    When I wait until text "Bob" is present
    And I scroll `ChatInfoScrollable` until `DeleteMemberButton` is present
    And I tap `DeleteMemberButton` button
    And I tap `Proceed` button
    Then I wait until text "Bob" is absent

  @chat
  @group
  Scenario: User adds a member
    Given I am Alice
    And I pause for 1 second
    And users Bob and Charlie
    And I have "Alice and Bob" group with Bob
    And I am in "Alice and Bob" group
    And I open chat's info

    Given Charlie has dialog with me
    When I scroll `ChatInfoScrollable` until `AddMemberButton` is present
    And I tap `AddMemberButton` button
    Then I wait until `SearchView` is present

    When I fill `SearchTextField` field with Charlie's num
    And I tap user Charlie in search results
    And I tap `SearchSubmitButton` button
    Then I wait until text "Charlie" is present

  @chat
  Scenario: User gets removed
    Given I am Alice
    And I pause for 1 second
    And users Bob and Charlie
    And I have "Alice and Bob" group with Bob
    And I am in "Alice and Bob" group
    And I open chat's info

    When I wait until text "Alice and Bob" is present
    And Bob removes Alice from "Alice and Bob" group
    Then I wait until text "Alice and Bob" is absent
