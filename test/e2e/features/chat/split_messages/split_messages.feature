Feature: Chat messages and attachments are splitted

  Background: User is in dialog with Bob
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait until `ChatView` is present

  Scenario: User sends 1 message
    When I fill `MessageField` field with 8192 "A" symbols
    And I tap `Send` button
    Then I expect 1 `ChatMessage`

  Scenario: User sends 2 messages
    When I fill `MessageField` field with 8193 "A" symbols
    And I tap `Send` button
    Then I expect 2 `ChatMessage`
