Feature: Image refetching

  Scenario: User sees image refetched in chat
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And Bob sends image to me
    And I have Internet with delay of 2 seconds

    When I am in chat with Bob
    Then I wait until image is loading

    When I have Internet without delay
    Then I wait until image is loaded
