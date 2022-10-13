Change Log
==========

All user visible changes to this project will be documented in this file. This project uses to [Semantic Versioning 2.0.0].




## [0.1.0-alpha.7] · 2022-??-??
[0.1.0-alpha.7]: /../../tree/v0.1.0-alpha.7

[Diff](/../../compare/v0.1.0-alpha.6.1...v0.1.0-alpha.7) | [Milestone](/../../milestone/2)

### Added

- UI:
    - Media panel:
        - Dock buttons persistence. ([#159], [#137])
    - Chat info page:
        - Chat avatar uploading and deleting. ([#163], [#146])

### Changed

- UI:
    - Chat page:
        - Redesigned system messages. ([#161], [#158])

[#137]: /../../issues/137
[#146]: /../../issues/146
[#158]: /../../issues/158
[#159]: /../../pull/159
[#161]: /../../pull/161
[#163]: /../../pull/163




## [0.1.0-alpha.6.1] · 2022-10-03
[0.1.0-alpha.6.1]: /../../tree/v0.1.0-alpha.6.1

[Diff](/../../compare/v0.1.0-alpha.6...v0.1.0-alpha.6.1) | [Milestone](/../../milestone/3)

### Changed

- UI:
    - Redesigned context menu. ([#147], [#132])

### Fixed

- Web:
    - Application not loading due to IndexedDB error. ([#154])

[#132]: /../../issues/132
[#147]: /../../pull/147
[#154]: /../../pull/154




## [0.1.0-alpha.6] · 2022-09-28
[0.1.0-alpha.6]: /../../tree/v0.1.0-alpha.6

[Diff](/../../compare/3aa35d5bf8ba9728f54db7bf4e21425711097cda...v0.1.0-alpha.6) | [Milestone](/../../milestone/1)

### Added

- macOS:
    - Unread chats count badge on app's icon. ([#106])
- UI:
    - User information auto-updating on changes. ([#7], [#4])
    - Side bar resizing on desktop. ([#89], [#82])
    - Menu:
        - Language selection. ([#23], [#29])
        - No password reminder on logout. ([#39])
    - Media panel:
        - Reorderable buttons dock on desktop. ([#9], [#6])
    - Chats tab:
        - Button joining call with video. ([#56], [#51])
    - Introduction modal window. ([#38])
    - Chat page:
        - Message forwarding. ([#72], [#8])
        - Failed messages persistence. ([#5], [#3])
        - Message splitting when character limit is exceeded. ([#115], [#100])
        - Send field multiline support. ([#139])
        - Attachments downloading and sharing. ([#12], [#11])
    - Background setting and removing. ([#129], [#123])
    - User online status badge. ([#148], [#130])
- Deployment:
    - [Helm] chart. ([#73], [#85])

### Changed

- UI:
    - Media panel:
        - Redesigned desktop interface. ([#26], [#34], [#9])
        - Redesigned mobile interface. ([#31], [#34], [#47], [#53])
    - Redesigned login interface. ([#35], [#83])
    - Redesigned auth page. ([#29])
    - Chat page:
        - Messages and attachments sending status. ([#5], [#3])

### Fixed

- Android:
    - [ConnectionService] displaying call when application is in foreground. ([#14])
    - Back button not minimizing call. ([#80], [#76])
- macOS:
    - Call ringtone not being looped. ([#90])
- Web:
    - UI not hiding on window focus loses. ([#60])
- UI:
    - Chat page:
        - Missing avatars in group creation popup. ([#15], [#2])
    - Home page:
        - Horizontal scroll overlapping with vertical. ([#42], [#41])
    - Media panel:
        - Mobile minimization gesture being too rapid. ([#45], [#44])
        - Media not enabling in empty call. ([#79], [#117], [#75])
        - Prevent device from sleeping. ([#112], [#92]) 

[#2]: /../../issues/2
[#3]: /../../issues/3
[#4]: /../../issues/4
[#5]: /../../pull/5
[#6]: /../../issues/6
[#7]: /../../pull/7
[#8]: /../../issues/8
[#9]: /../../pull/9
[#11]: /../../issues/11
[#12]: /../../pull/12
[#14]: /../../pull/14
[#15]: /../../pull/15
[#23]: /../../pull/23
[#26]: /../../pull/26
[#29]: /../../pull/29
[#31]: /../../pull/31
[#34]: /../../pull/34
[#35]: /../../pull/35
[#38]: /../../pull/38
[#39]: /../../pull/39
[#41]: /../../issues/41
[#42]: /../../pull/42
[#44]: /../../issues/44
[#45]: /../../pull/45
[#47]: /../../pull/47
[#51]: /../../issues/51
[#53]: /../../pull/53
[#56]: /../../pull/56
[#60]: /../../pull/60
[#72]: /../../pull/72
[#73]: /../../pull/73
[#75]: /../../issues/75
[#76]: /../../issues/76
[#79]: /../../pull/79
[#80]: /../../pull/80
[#82]: /../../issues/82
[#83]: /../../pull/83
[#85]: /../../pull/85
[#89]: /../../pull/89
[#90]: /../../pull/90
[#92]: /../../issues/92
[#100]: /../../issues/100
[#106]: /../../pull/106
[#112]: /../../pull/112
[#115]: /../../pull/115
[#117]: /../../pull/117
[#123]: /../../issues/123
[#129]: /../../pull/129
[#130]: /../../issues/130
[#139]: /../../pull/139
[#148]: /../../pull/148




[ConnectionService]: https://developer.android.com/reference/android/telecom/ConnectionService
[Helm]: https://helm.sh
[Semantic Versioning 2.0.0]: https://semver.org
