Feature: Attachments refetching

  Scenario: User sees image refetched in chat
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And Bob sends "test.jpg" to me
    And I do not have Internet for 4 seconds
    And I am in chat with Bob

    When I wait until "test.jpg" attachment is loading
    Then I wait until "test.jpg" attachment is loaded
