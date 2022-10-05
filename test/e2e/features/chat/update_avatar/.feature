Feature: Chat avatar update and remove

  Background: User is in group chat with Bob
    Given I am Alice
    And user Bob
    And Bob has group chat with me named 'Alice and Bob'
    And I am in chat named 'Alice and Bob'

  Scenario: User sends 1 message
    When I tap `ChatAvatar` element
    Then I wait until `ChangeAvatar` is present
    Then I am change chat avatar
    Then I pause for 10 seconds
    Then I wait until `DeleteAvatar` is present
    When I tap `DeleteAvatar` button
    Then I pause for 10 seconds
