Feature: MyUser's updates are correct displayed to other users

  Scenario: Alice sees Bob changing his bio
    Given I am Alice
    And user Bob

    And I wait until `HomeView` is present
    And I go to Bob page
    Then I wait until `UserColumn` is present

    And Bob set bio as "Hello world!"
    Then I wait until text "Hello world!" is present

    And Bob set bio as "Me Bob, me funny, haha"
    Then I wait until text "Me Bob, me funny, haha" is present
