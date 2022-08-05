Feature: Attachments downloading

  Scenario: Attachments has correct status during downloading
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

    Then Bob sends "test.txt" attachment to me
    And I wait until status of "test.txt" file is empty
    Then I start downloading "test.txt" file
    And I wait until status of "test.txt" file is downloading
    And I wait until status of "test.txt" file is downloaded

  Scenario: Canceling attachment downloading work correctly
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

    Then Bob sends "test.txt" attachment to me
    And I wait until status of "test.txt" file is empty
    Then I start downloading "test.txt" file
    And I wait until status of "test.txt" file is downloading
    Then I cancel downloading "test.txt" file
    And I wait until status of "test.txt" file is empty
