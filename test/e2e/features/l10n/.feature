Feature: Application localization changes correctly

  Scenario: User changes localization
    When I tap `StartChattingButton` button
    And I wait until `HomeView` is present

    Then I tap `MenuButton` button
    And I tap `SettingsButton` button

    Then I tap `en_US` within `LocalizationDropdown` dropdown
    And I wait until text "Settings" is present

    Then I tap `ru_RU` within `LocalizationDropdown` dropdown
    And I wait until text "Настройки" is present
