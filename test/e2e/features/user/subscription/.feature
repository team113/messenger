Feature: User subscription

  Scenario: User sees Bob changing his bio
    Given I am Alice
    And user Bob

    And I wait until `HomeView` is present
    And I go to Bob's page

    And Bob updates his bio with "Hello world!"
    Then I wait until text "Hello world!" is present

    And Bob updates his bio with "Me Bob, me funny, haha"
    Then I wait until text "Me Bob, me funny, haha" is present
