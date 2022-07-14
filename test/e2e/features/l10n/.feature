Feature: Application localization changes correctly

  Scenario: User changes localization
    Given I am Alice
    And I wait until `HomeView` is present

    Then I tap `MenuButton` button
    And I tap `SettingsButton` button

    Then I tap `Language_enUS` within `LanguageDropdown` dropdown
    And I wait until text "Settings" is present

    Then I tap `Language_ruRU` within `LanguageDropdown` dropdown
    And I wait until text "Настройки" is present
