Feature: Chat attachments has correct sending status

  Scenario: File attachment status changes from `sending` to `sent`
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait until `MessageField` is present

    Given I have Internet with delay of 3 seconds
    Then I attach "test.txt" file
    And I wait until `Send` is present
    Then I tap `Send` widget
    And I wait until status of "test.txt" attachment is sending
    And I wait until status of "test.txt" attachment is sent

  Scenario: Image attachment status changes from `sending` to `sent`
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait until `MessageField` is present

    Given I have Internet with delay of 3 seconds
    Then I attach "test.jpg" image
    And I wait until `Send` is present
    Then I tap `Send` widget
    And I wait until status of "test.jpg" attachment is sending
    And I wait until status of "test.jpg" attachment is sent

  Scenario: User resends file attachment
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait until `MessageField` is present

    Given I do not have Internet
    Then I attach "test.txt" file
    And I wait until `Send` is present
    Then I tap `Send` widget
    And I wait until status of "test.txt" attachment is error

    Given I have Internet with delay of 3 seconds
    Then I long press message with "test.txt"
    And I wait until `Resend` is present
    And I tap `Resend` button
    And I wait until status of "test.txt" attachment is sending
    And I wait until status of "test.txt" attachment is sent

  Scenario: User resends image attachment
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait until `MessageField` is present

    Given I do not have Internet
    Then I attach "test.jpg" image
    And I wait until `Send` is present
    Then I tap `Send` widget
    And I wait until status of "test.jpg" attachment is error

    Given I have Internet with delay of 3 seconds
    Then I long press message with "test.jpg"
    And I wait until `Resend` is present
    And I tap `Resend` button
    And I wait until status of "test.jpg" attachment is sending
    And I wait until status of "test.jpg" attachment is sent
