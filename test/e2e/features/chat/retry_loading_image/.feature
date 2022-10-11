Feature: Chat images try to load

  Background: User is in dialog with Bob
    Given I am Alice
    And user Bob
    And Bob has dialog with me

  Scenario: Try to load image when i'm open chat
    When Bob sends image to me
    And I am in chat with Bob

    Then I wait until image is loading
    Then I wait until image is loaded


  Scenario: Try to load image when i'm in chat
    When I am in chat with Bob
    And Bob sends image to me

    Then I wait until image is loading
    Then I wait until image is loaded
