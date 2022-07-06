Feature: Application localization changes correctly

  Scenario: User change localization
    When I tap `StartChattingButton` button
    And I wait until `HomeView` is present

    Then I tap `MenuButton` button
    And I tap `SettingsButton` button

    Then I tap the `Localization_item_en_US` within the `LocalizationDropdown` dropdown
    And I wait until text "Settings" is present

    Then I tap the `Localization_item_ru_RU` within the `LocalizationDropdown` dropdown
    And I wait until text "Настройки" is present
