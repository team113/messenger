Feature: Forward messages

  Scenario: Alice forward message from Bob to Bob and Charlie
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
    And I long press "Hello, world" message inside "Bob" chat
    Then I tap `ForwardMessage` button

    When I wait until `ForwardModal` is present
    And I tap chat named "Bob" inside modal
    Then I tap chat named "Charlie" inside modal

    When I fill `ModalForwardMessageField` field with "Forward to 2 chats"
    And I tap `SendForwardInModal` button

    When I wait for "Hello, world" message inside "Charlie" chat
    Then I wait for "Forward to 2 chats" message inside "Charlie" chat
    Then I wait for "Forward to 2 chats" message inside "Bob" chat
