Feature: Chat attachments have correct sending status

  Background: User is in dialog with Bob
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

  Scenario: Persist chat message
    When I attach "test.txt" file
    And I fill `MessageField` field with "123"
    Then I back to previous page

    When I am in chat with Bob
    Then I wait until text "test.txt" is present
    Then I wait until text "123" is present
    Then I pause for 10 seconds

