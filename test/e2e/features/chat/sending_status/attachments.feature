Feature: Chat attachments has correct sending status

  Scenario: User sends a file attachment
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait until `MessageField` is present

    Given I have Internet with delay 2 second
    Then I attach "test.txt" file in chat with Bob
    And I wait until `Send` is present

    Then I tap `Send` widget
    And I wait until file with name "test.txt" in chat with Bob status is sending
    And I wait until file with name "test.txt" in chat with Bob status is sent

  Scenario: User sends an image attachment
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait until `MessageField` is present

    Given I have Internet with delay 2 second
    Then I attach "test.jpg" image in chat with Bob
    And I wait until `Send` is present

    Then I tap `Send` widget
    And I wait until image with name "test.jpg" in chat with Bob status is sending
    And I wait until image with name "test.jpg" in chat with Bob status is sent

  Scenario: User resends file attachment
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait until `MessageField` is present

    Given I do not have Internet
    Then I attach "test.txt" file in chat with Bob
    And I wait until `Send` is present

    Then I tap `Send` widget
    And I wait until file with name "test.txt" in chat with Bob status is error

    Given I have Internet with delay 2 second
    Then  I long press message with attachment "test.txt" in chat with Bob
    And I wait until `Resend` is present
    And I tap `Resend` button
    And I wait until file with name "test.txt" in chat with Bob status is sending
    And I wait until file with name "test.txt" in chat with Bob status is sent

  Scenario: User resends image attachment
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait until `MessageField` is present

    Given I do not have Internet
    Then I attach "test.jpg" image in chat with Bob
    And I wait until `Send` is present

    Then I tap `Send` widget
    And I wait until image with name "test.jpg" in chat with Bob status is error

    Given I have Internet with delay 2 second
    Then I long press message with attachment "test.jpg" in chat with Bob
    And I wait until `Resend` is present
    And I tap `Resend` button
    And I wait until image with name "test.jpg" in chat with Bob status is sending
    And I wait until image with name "test.jpg" in chat with Bob status is sent
