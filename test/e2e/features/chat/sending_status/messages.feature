Feature: Chat messages have correct sending status

  Scenario: User sends message
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait until `MessageField` is present

    Then I fill `MessageField` field with "123"
    And I wait until `Send` is present
    Then I tap `Send` widget
    And I wait until status of "123" message is sent

  Scenario: Message status changes from `sending` to `sent`
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait until `MessageField` is present

    Given I have Internet with delay of 3 seconds
    Then I fill `MessageField` field with "123"
    And I wait until `Send` is present
    Then I tap `Send` widget
    And I wait until status of "123" message is sending
    And I wait until status of "123" message is sent

  Scenario: User deletes non-sent message
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait until `MessageField` is present

    Given I do not have Internet
    Then I fill `MessageField` field with "123"
    And I wait until `Send` is present
    Then I tap `Send` widget
    And I wait until status of "123" message is error

    Then I long press "123" message
    And I wait until `Delete` is present
    And I tap `Delete` button
    And I wait until text "123" is absent

  Scenario: User resends message
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait until `MessageField` is present

    Then I fill `MessageField` field with "123"
    And I wait until `Send` is present

    Given I do not have Internet
    Then I tap `Send` widget
    And I wait until status of "123" message is error

    Given I have Internet with delay of 3 seconds
    Then I long press "123" message
    And I wait until `Resend` is present
    And I tap `Resend` button
    And I wait until status of "123" message is sending
    And I wait until status of "123" message is sent

  Scenario: Non-sent messages are persisted
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

    Then I wait until `MessageField` is present
    And I fill `MessageField` field with "123"
    And I wait until `Send` is present

    Given I do not have Internet
    Then I tap `Send` widget
    And I wait until status of "123" message is error

    Given I have Internet with delay of 3 seconds
    Then I restart app
    And I wait until `HomeView` is present
    And I am in chat with Bob
    And I wait until status of "123" message is error
