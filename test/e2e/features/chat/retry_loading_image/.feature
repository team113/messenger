Feature: Chat messages have correct sending status

  Background: User is in dialog with Bob
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And Bob sends "test.jpg" attachment to me
    And I am in chat with Bob

  Scenario: Message status changes from `sending` to `sent`
    Then I wait until `RetryImageLoading` is present
    Then I wait until `RetryImageLoaded` is present

    Then I back to previous page
    Then I am in chat with Bob

    Then I wait until `RetryImageLoading` is present
    Then I wait until `RetryImageLoaded` is present
    Then I pause for 10 seconds
