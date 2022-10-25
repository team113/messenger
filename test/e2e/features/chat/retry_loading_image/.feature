Feature: Trying to load chat images

  Background: User is in dialog with Bob
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And Bob sends image to me

  Scenario: Try to load image when i'm open chat
#    When I do not have2 Internet
    Then I am in chat with Bob without waiting

    When I wait until image is loading
#    And I have Internet without delay
    Then I wait until image is loaded
