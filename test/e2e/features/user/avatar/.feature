#Feature: User change avatar
#  @smoke
#  Scenario: User sees Bob changing his avatar
#    Given I am Alice
#    And user Bob
#    And I wait until `HomeView` is present
#    And I go to Bob's page
#
#    When Bob update his avatar with "test.jpg"
#    Then I see Bob's avatar as "test.jpg"
