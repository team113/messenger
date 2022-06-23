Feature: Attachments downloading

  Scenario: Attachments has correct status during downloading
    Given I am Alice
    And user Bob

    Then I wait until `HomeView` is present
    And I wait until `ChatsTab` is present

    Given Bob has dialog with me
    And Bob sends "test.txt" attachment to me

    Then I wait until text "Bob" is present
    And I tap "Bob" text
    And I wait until `DownloadFile` in list is present

    Then I start downloading "test.txt" attachment in chat with Bob
    And I wait until `DownloadingFile` is present

    Then I finish downloading "test.txt" attachment in chat with Bob
    And I wait until `DownloadedFile` is present
