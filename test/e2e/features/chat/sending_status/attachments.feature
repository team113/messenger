Feature: Chat attachments have correct sending status

  Background: User is in dialog with Bob
    Given I am Alice
    And user Bob
    And I have dialog with Bob
    And I am in chat with Bob
    And I wait for app to settle

  Scenario: File attachment status changes from `sending` to `sent`
    Given I have Internet with delay of 4 seconds

    When I attach "test.txt" file
    And I tap `Send` button

    Then I wait until status of "test.txt" attachment is sending
    And I wait until status of "test.txt" attachment is sent

  Scenario: Image attachment status changes from `sending` to `sent`
    Given I have Internet with delay of 4 seconds

    When I attach "test.jpg" image
    And I tap `Send` button

    Then I wait until status of "test.jpg" attachment is sending
    And I wait until status of "test.jpg" attachment is sent

  Scenario: User resends file attachment
    Given I do not have Internet
    When I attach "test.txt" file
    And I tap `Send` button
    Then I wait until status of "test.txt" attachment is error

    Given I have Internet with delay of 4 seconds
    When I long press message with "test.txt"
    And I tap `Resend` button
    Then I wait until status of "test.txt" attachment is sending
    And I wait until status of "test.txt" attachment is sent

  Scenario: User resends image attachment
    Given I do not have Internet
    When I attach "test.jpg" image
    And I tap `Send` button
    Then I wait until status of "test.jpg" attachment is error

    Given I have Internet with delay of 4 seconds
    When I long press message with "test.jpg"
    And I tap `Resend` button
    Then I wait until status of "test.jpg" attachment is sending
    And I wait until status of "test.jpg" attachment is sent
