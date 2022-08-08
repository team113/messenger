Feature: Calls test

  Scenario: Outcoming dialog call changes state correctly
    Given I am Alice
    And user Bob
    And Bob has dialog with me
    And I am in chat with Bob
    And I wait until `StartAudioCall` is present

    Then I tap `StartAudioCall` button
    And I wait until `Call` is present
    And I wait 2 seconds
    And Bob accept call
    And I wait until `Calladasd` is present

