Change Log
==========

All user visible changes to this project will be documented in this file. This project uses to [Semantic Versioning 2.0.0].




## [0.1.0-alpha.6] · 2022-??-??
[0.1.0-alpha.6]: /../../tree/v0.1.0-alpha.6

[Diff](/../../compare/3aa35d5bf8ba9728f54db7bf4e21425711097cda...v0.1.0-alpha.6) | [Milestone](/../../milestone/1)

### Added

- UI:
    - User information auto-updating on changes ([#7], [#4]).
    - Menu:
        - Language selection ([#23]).
    - Media panel:
        - Reorderable buttons dock on desktop ([#9], [#6]).

### Changed

- UI:
    - Media panel:
        - Redesigned desktop interface ([#26], [#34], [#9]);
        - Redesigned mobile interface ([#31], [#34]).
    - Redesigned login interface ([#35]).

### Fixed

- Android:
    - [ConnectionService] displaying call when application is in foreground ([#14]).
- UI:
    - Chat page:
        - Missing avatars in group creation popup ([#15], [#2]).
    - Home page:
        - Horizontal scroll overlapping with vertical ([#42], [#41]).
    - Media panel:
        - Mobile minimization gesture being too rapid ([#45], [#44]).

[#2]: /../../issues/2
[#4]: /../../issues/4
[#6]: /../../issues/6
[#7]: /../../pull/7
[#9]: /../../pull/9
[#14]: /../../pull/14
[#15]: /../../pull/15
[#23]: /../../pull/23
[#26]: /../../pull/26
[#31]: /../../pull/31
[#34]: /../../pull/34
[#35]: /../../pull/35
[#41]: /../../issues/41
[#42]: /../../pull/42
[#44]: /../../issues/44
[#45]: /../../pull/45




[ConnectionService]: https://developer.android.com/reference/android/telecom/ConnectionService
[Semantic Versioning 2.0.0]: https://semver.org
