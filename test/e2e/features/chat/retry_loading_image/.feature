Feature: Image refetching

  Scenario: User sees image refetched in chat
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

    When I attach "test.jpg" image
    Then I tap `Send` button

    When I go to previous page
    Then I do not have Internet

    When I am in chat with Bob
    Then I wait until image is loading

    When I have Internet without delay
    Then I wait until image is loaded
