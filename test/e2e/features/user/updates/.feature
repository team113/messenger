Feature: User's updates are correct displayed to me

  Scenario: Alice sees Bob changing his bio
    Given I am Alice
    And user Bob

    And I wait until `HomeView` is present
    And I go to Bob's page

    And Bob updates his bio as "Hello world!"
    Then I wait until text "Hello world!" is present

    And Bob updates his bio as "Me Bob, me funny, haha"
    Then I wait until text "Me Bob, me funny, haha" is present
