Feature: Chat attachments has correct sending status

  Scenario: User sends a file attachment and its status changes from `sending` to `sent`
    Given I have internet with delay 2 second
    And I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

    Then I wait until `MessageField` is present
    And I attach "test.txt" file in chat with Bob
    And I wait until `Send` is present

    Then I tap `Send` widget
    And I wait until file status is sending
    And I wait until file status is sent

  Scenario: User sends image attachment and its status change from `sending` to `sent`
    Given I have internet with delay 2 second
    And I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

    Then I wait until `MessageField` is present
    And I attach "test.jpg" image in chat with Bob
    And I wait until `Send` is present

    Then I tap `Send` widget
    And I wait until image status is sending
    And I wait until image status is sent

  Scenario: Resended file attachment correctly change status
    Given I do not have internet
    And I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

    Then I wait until `MessageField` is present
    And I attach "test.txt" file in chat with Bob
    And I wait until `Send` is present

    Then I tap `Send` widget
    And I wait until `ButtonOk` is present
    And I tap `ButtonOk` button
    And I wait until file status is error

    Then I have internet with delay 2 second
    And I long press message
    And I wait until `Resend` is present
    And I tap `Resend` button
    And I wait until file status is sending
    And I wait until file status is sent

  Scenario: Resended image attachment correctly change status
    Given I do not have internet
    And I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

    Then I wait until `MessageField` is present
    And I attach "test.jpg" image in chat with Bob
    And I wait until `Send` is present

    Then I tap `Send` widget
    And I wait until `ButtonOk` is present
    And I tap `ButtonOk` button
    And I wait until image status is error

    Then I have internet with delay 2 second
    And I long press message
    And I wait until `Resend` is present
    And I tap `Resend` button
    And I wait until image status is sending
    And I wait until image status is sent
