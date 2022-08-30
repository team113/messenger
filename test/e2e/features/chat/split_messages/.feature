Feature:  
  Background: User is in dialog with Bob
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait until `ChatView` is present

  Scenario: User sends message
    When I fill `MessageField` field with "123"
    And I tap `Send` button
    Then I wait until status of "123" message is sent