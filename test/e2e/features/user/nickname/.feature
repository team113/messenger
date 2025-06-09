Feature: User subscription in ChatTab


  Background: User is in dialog with Bob
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

  @smoke
  Scenario: User sees Bob changing his name on ChatTab

    When Bob updates his name with "Hello world!"
    Then I wait until text "Hello world!" is present

    When Bob updates his name with "Me Bob, me funny, haha"
    Then I wait until text "Me Bob, me funny, haha" is present
