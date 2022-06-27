Feature: Chat messages has correct sending status

  Scenario: User sends message
    Given I have Internet without delay
    And I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

    Then I wait until `MessageField` is present
    And I fill `MessageField` field with "123"
    And I wait until `Send` is present

    Then I tap `Send` widget
    And I wait until message status is sent

  Scenario: Message status changes from `sending` to `sent`
    Given I have Internet without delay
    And I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

    Then I wait until `MessageField` is present
    And I fill `MessageField` field with "123"
    And I wait until `Send` is present
    And I have Internet with delay 2 second

    Then I tap `Send` widget
    And I wait until message status is sending
    And I wait until message status is sent

  Scenario: User deletes non-sent message
    Given I have Internet without delay
    And I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

    Then I wait until `MessageField` is present
    And I fill `MessageField` field with "123"
    And I wait until `Send` is present
    And I do not have Internet

    Then I tap `Send` widget
    And I wait until `ButtonOk` is present
    And I tap `ButtonOk` button
    And I wait until message status is error

    Then I long press message
    And I wait until `Delete` is present
    And I tap `Delete` button
    And I wait until `ErrorMessage` is absent

  Scenario: User resends message
    Given I have Internet without delay
    And I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

    Then I wait until `MessageField` is present
    And I fill `MessageField` field with "123"
    And I wait until `Send` is present
    And I do not have Internet

    Then I tap `Send` widget
    And I wait until `ButtonOk` is present
    And I tap `ButtonOk` button
    And I wait until message status is error

    Then I have Internet with delay 2 second
    And I long press message
    And I wait until `Resend` is present
    And I tap `Resend` button
    And I wait until message status is sending
    And I wait until message status is sent

  Scenario: Non-sent messages are persisted
    Given I have Internet without delay
    And I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

    Then I wait until `MessageField` is present
    And I fill `MessageField` field with "123"
    And I wait until `Send` is present
    And I do not have Internet

    Then I tap `Send` widget
    And I wait until `ButtonOk` is present
    And I tap `ButtonOk` button
    And I wait until message status is error

    Then I have Internet with delay 1 second
    And I restart app
    And I wait until `HomeView` is present
    And I am in chat with Bob
    And I wait until message status is error
