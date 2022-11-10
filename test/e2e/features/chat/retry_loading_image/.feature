Feature: Image refetching

  Scenario: User sees image refetched in chat
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And Bob sends "test.jpg" image to me
    And I have Internet with delay of 4 seconds
    And I am in chat with Bob

    When I wait until image "test.jpg" is loading
    Then I wait until image "test.jpg" is loaded
