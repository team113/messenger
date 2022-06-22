Feature: Message attachment is correctly visualize

  Scenario: Alice can see attachment from Bob
    Given I am Alice
    And user Bob

    Then I wait until `HomeView` is present
    And I wait until `ChatsTab` is present

    Given Bob has dialog with me
    And Bob sends "test.txt" attachment to me

    Then I wait until text "Bob" is present
    And I tap "Bob" text
    And I wait until `DownloadAttachment` in list is present
