Feature: Image refetching

  Background: User is in dialog with Bob
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And Bob sends image to me
    And I do not have Internet
    And I am in chat with Bob

  Scenario: User sees image refetched in chat
    Then I wait until image is loading

    When I have Internet without delay
    Then I wait until image is loaded
