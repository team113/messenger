Feature: Image refetching

  Scenario: User sees image refetched in chat
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And Bob sends image to me

    When I am in chat with Bob
    Then I wait until image is loading
    And I wait until image is loaded
