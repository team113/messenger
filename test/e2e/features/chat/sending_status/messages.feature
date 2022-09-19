Feature: Chat messages have correct sending status

  Background: User is in dialog with Bob
    Given I am Alice
    And user Bob
    And Bob has dialog with Alice
    And I am in chat with Bob

  Scenario: User sends message
    When I fill `MessageField` field with "123"
    And I tap `Send` button
    Then I wait until status of "123" message is sent

  Scenario: Message status changes from `sending` to `sent`
    Given I have Internet with delay of 3 seconds

    When I fill `MessageField` field with "123"
    And I tap `Send` button

    Then I wait until status of "123" message is sending
    And I wait until status of "123" message is sent

  Scenario: User deletes non-sent message
    Given I do not have Internet
    When I fill `MessageField` field with "123"
    And I tap `Send` button
    Then I wait until status of "123" message is error

    When I long press "123" message
    And I tap `Delete` button
    Then I wait until text "123" is absent

  Scenario: User resends message
    Given I do not have Internet
    When I fill `MessageField` field with "123"
    And I tap `Send` button
    Then I wait until status of "123" message is error

    Given I have Internet with delay of 3 seconds
    When I long press "123" message
    And I tap `Resend` button
    Then I wait until status of "123" message is sending
    And I wait until status of "123" message is sent

  Scenario: Non-sent messages are persisted
    Given I do not have Internet
    When I fill `MessageField` field with "123"
    And I tap `Send` button
    Then I wait until status of "123" message is error

    Given I have Internet with delay of 3 seconds
    When I restart app
    And I am in chat with Bob
    Then I wait until status of "123" message is error
