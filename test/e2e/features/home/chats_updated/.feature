Feature: Chats tab is correctly updated

  Scenario: Alice sees chats and messages from Bob and Charlie
    Given I am Alice
    And users Bob and Charlie

    Then I wait until `HomeView` is present
    And I wait until `ChatsTab` is present

    Given Bob has dialog with me
    And Bob sends "Hello, world" message to me
    Then I wait until text "Bob" is present
    # TODO: Uncomment when backend new version is released.
    # And I wait until text "Hello, world" is present

    Given Charlie has dialog with me
    And Charlie sends "I am Charlie" message to me
    Then I wait until text "Charlie" is present
    # TODO: Uncomment when backend new version is released.
    # And I wait until text "I am Charlie" is present
