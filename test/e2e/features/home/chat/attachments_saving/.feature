Feature: Attachments downloading

  Background:
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

  Scenario: Attachments has correct status during downloading
    When Bob sends "test.txt" attachment to me
    Then I wait until status of "test.txt" file is empty

    When I start downloading "test.txt" file
    Then I wait until status of "test.txt" file is downloading
    And I wait until status of "test.txt" file is downloaded

  Scenario: Canceling attachment downloading work correctly
    When Bob sends "test.txt" attachment to me
    Then I wait until status of "test.txt" file is empty

    When I start downloading "test.txt" file
    Then I wait until status of "test.txt" file is downloading

    When I cancel downloading "test.txt" file
    Then I wait until status of "test.txt" file is empty
