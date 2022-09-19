Feature: Attachments downloading

  Background:
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob

  Scenario: Attachments can be downloaded
    When Bob sends "test.txt" attachment to me
    Then I wait until "test.txt" file is not downloaded

    When I download "test.txt" file
    Then I wait until "test.txt" file is downloading
    And I wait until "test.txt" file is downloaded

  Scenario: Attachment download can be canceled
    When Bob sends "test.txt" attachment to me
    Then I wait until "test.txt" file is not downloaded

    When I download "test.txt" file
    Then I wait until "test.txt" file is downloading

    When I cancel "test.txt" file download
    Then I wait until "test.txt" file is not downloaded
