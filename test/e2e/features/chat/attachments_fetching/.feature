Feature: Attachments refetching

  Scenario: User sees image refetched in chat
    Given I am Alice
    And user Bob
    And I have dialog with Bob
    And Bob sends "test.jpg" attachment to me
    And I have Internet with delay of 4 seconds

    When I am in chat with Bob
    Then I wait until "test.jpg" attachment is fetching
    And I wait until "test.jpg" attachment is fetched
