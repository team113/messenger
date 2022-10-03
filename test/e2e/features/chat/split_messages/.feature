Feature: Chat messages and attachments are splitted

  Background: User is in dialog with Bob
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

  Scenario: User sends 1 message
    When I fill `MessageField` field with 8191 "A" symbols
    And I tap `Send` button
    Then I expect to see 1 message in chat

  Scenario: User sends 2 messages
    When I fill `MessageField` field with 8193 "A" symbols
    And I tap `Send` button
    Then I expect to see 2 messages in chat
