Feature: Forward messages

  Scenario: Bob forwards "Hello, world" message to same chat
    Given I am Alice
    And users Bob and Charlie

    Then I wait until `HomeView` is present
    And I wait until `ChatsTab` is present

    Given Bob has dialog with me
    And Bob sends "Hello, world" message to me
    Then I wait until text "Bob" is present

    Given Charlie has dialog with me
    Then I wait until text "Charlie" is present

    When I tap chat named "Bob"
    Then I wait for "Hello, world" message inside "Bob" chat
    And Bob forward "Hello, world" message with comment "Some comment" to same chat
    Then I wait for "Some comment" message inside "Bob" chat

