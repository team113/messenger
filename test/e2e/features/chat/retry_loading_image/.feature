Feature: Trying to load chat images

  Background: User is in dialog with Bob
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And Bob sends image to me
    And I do not have Internet 2
    And I am in chat with Bob

  Scenario: Try to load image when i'm open chat
    When I wait until image is loading
    And I have Internet without delay
    Then I wait until image is loaded
