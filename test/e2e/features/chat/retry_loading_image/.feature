Feature: Chat messages have correct sending status

  Background: User is in dialog with Bob
    Given I am Alice
    And user Bob
    And Bob has dialog with me

  Scenario: Message status changes from `sending` to `sent`
    Then I am in chat with Bob
    Then Bob sends "test.jpg" attachment to me


    Then I wait until `ImageLoading` is present
    Then I wait until `ImageLoaded` is present



#Feature: Chat messages have correct sending status
#  Background: User is in dialog with Bob
#    Given I am Alice
#    And user Bob
#    And Bob has dialog with me
#    And I am in chat with Bob
#  Scenario: Message status changes from `sending` to `sent`
#
#    Given I have Internet with delay of 3 seconds
#
#    When I attach "test.jpg" image
#    And I tap `Send` button
#
#    Then I wait until status of "test.jpg" attachment is sending
#    And I wait until status of "test.jpg" attachment is sent

