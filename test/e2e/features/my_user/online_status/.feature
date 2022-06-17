Feature: MyUser's online status is correctly updated

  Scenario: Bob sees Alice changing her online status
    Given I am Alice
    And user Bob

    Then I wait until `HomeView` is present
    And Bob sees Alice as online

    When I tap `MenuButton` button
    And I tap `LogoutButton` button
    Then I wait until `AuthView` is present
    And Bob sees Alice as offline

    When I sign in as Alice
    Then Bob sees Alice as online
