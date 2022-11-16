Feature: Attachments refetching

  Scenario: User sees image refetched in chat
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And Bob sends "test.jpg" attachment to me
    And I have Internet with delay of 4 seconds
    And I am in chat with Bob

    When I wait until "test.jpg" attachment is loading
    Then I wait until "test.jpg" attachment is loaded
