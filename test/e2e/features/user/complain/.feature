Feature: Complain
  @smoke
  Scenario: Complaint about the user is being sent
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I wait until `HomeView` is present

    When I go to Bob's page
    And I scroll `UserScrollable` to bottom
    And I pause for 2 seconds
    And I tap `ReportButton` button
    And I fill `ReportField` field with "Spam"
    And I tap `ProceedReport` button
    Then the email client should open with predefined subject and body
    And the report dialog should close

