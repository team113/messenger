Change Log
==========

All user visible changes to this project will be documented in this file. This project uses to [Semantic Versioning 2.0.0].




## [0.1.0-alpha.9] · 2023-??-??
[0.1.0-alpha.9]: /../../tree/v0.1.0-alpha.9

[Diff](/../../compare/v0.1.0-alpha.8...v0.1.0-alpha.9) | [Milestone](/../../milestone/5)

### Added

- UI:
    - Chat page:
        - History clearing. ([#361])
        - Text selection in messages. ([#118], [#17])
    - Chats tab:
        - Multiple chats selection. ([#361], [#348])
    - Contacts tab:
        - Multiple contacts selection. ([#361], [#348])

### Changed

- UI:
    - Chat page:
        - Redesigned info and call messages. ([#357])
        - Redesigned file attachments. ([#362])
    - Media panel:
        - Position and size persistence. ([#270], [#264])
        - Proportionally resizing secondary panel. ([#356], [#258])
        - Incoming ringtone fading in. ([#375], [#367])

[#17]: /../../issues/17
[#118]: /../../pull/118
[#258]: /../../issues/258
[#264]: /../../issues/264
[#367]: /../../issues/367
[#270]: /../../pull/270
[#348]: /../../issues/348
[#357]: /../../pull/357
[#361]: /../../pull/361
[#362]: /../../pull/362
[#356]: /../../pull/356
[#375]: /../../pull/375




## [0.1.0-alpha.8] · 2023-03-07
[0.1.0-alpha.8]: /../../tree/v0.1.0-alpha.8

[Diff](/../../compare/v0.1.0-alpha.7...v0.1.0-alpha.8) | [Milestone](/../../milestone/4)

### Added

- UI:
    - Chat page:
        - Swipe to reply gesture. ([#188], [#134])
        - Drafts. ([#173], [#102])
        - Group read indicators. ([#255], [#253])
        - Message info modal. ([#335], [#330])
    - Chats tab:
        - Chat muting/unmuting. ([#251], [#172], [#63])
        - Favorite chats. ([#359], [#218], [#209])
        - Searching. ([#323], [#310], [#206], [#205])
    - Home page:
        - Quick status changing menu. ([#275], [#204], [#203])
        - Quick mute and link changing menu. ([#288], [#278])
    - Media panel:
        - Participants redialing. ([#241], [#233])
        - Screen share display choosing on desktop. ([#347], [#228], [#222])
    - Contacts tab:
        - Favorite contacts. ([#285], [#237], [#223])
        - Searching. ([#323], [#310], [#260], [#259])
    - User page:
        - Blacklisting. ([#317], [#277], [#234], [#229])
    - Window's size and position persistence. ([#274], [#263])
- Windows:
    - Unread chats count badge on app's icon. ([#342], [#327])    

### Changed

- Android:
    - Transparent status and navigation. ([#211], [#208])
- UI:
    - Home page:
        - Redesigned chats tab. ([#211], [#142])
        - Redesigned introduction and logout modals. ([#249])
        - Redesigned menu tab. ([#313], [#244], [#243], [#211])
    - Media panel:
        - Video resizing when dragged. ([#191], [#190])
        - Redesigned mobile interface. ([#340], [#319], [#316], [#287], [#246])
        - Redesigned settings. ([#293], [#283])
        - Rounded secondary panel. ([#300], [#292])
        - Redesigned participants modal. ([#332], [#328])
        - Redesigned desktop interface. ([#319], [#309])
    - Chat page:
        - Redesigned gallery. ([#212], [#199])
        - Date headers disappearing when not scrolling. ([#221], [#215])
        - Redesigned forwarding modal. ([#189], [#181])
        - Nearby messages grouping. ([#337])
    - Chats tab:
        - Redesigned attachments preview. ([#217], [#214])
        - Redesigned group creating. ([#247], [#238])
    - Profile page:
        - Redesigned profile page. ([#244], [#257], [#243])
    - Redesigned desktop context menu. ([#245])
    - Redesigned mobile context menu. ([#305], [#295])
    - Auth page:
        - Redesigned login modal. ([#249])
    - User page:
        - Redesigned user page. ([#254], [#252])
    - Contacts tab:
        - Alphabetical and last seen sorting. ([#235], [#226])
    - Chat info page:
        - Redesigned chat info page. ([#265], [#256])
    - Redesigned scrollbar. ([#276], [#262])
    - Redesigned snackbar. ([#336])
    - Redesigned loaders. ([#350], [#345])

### Fixed

- UI:
    - Chat page:
        - Replies having reversed order in messages. ([#193], [#192])
        - Images sometimes not loading. ([#164], [#126])
- Web:
    - Context menu not opening over video previews. ([#198], [#196])

[#63]: /../../issues/63
[#102]: /../../issues/102
[#126]: /../../issues/126
[#134]: /../../issues/134
[#142]: /../../pull/142
[#164]: /../../pull/164
[#172]: /../../pull/172
[#173]: /../../pull/173
[#181]: /../../issues/181
[#188]: /../../pull/188
[#189]: /../../pull/189
[#190]: /../../issues/190
[#191]: /../../pull/191
[#192]: /../../issues/192
[#193]: /../../pull/193
[#196]: /../../issues/196
[#198]: /../../pull/198
[#199]: /../../issues/199
[#203]: /../../issues/203
[#204]: /../../pull/204
[#205]: /../../issues/205
[#206]: /../../pull/206
[#208]: /../../issues/208
[#209]: /../../issues/209
[#211]: /../../pull/211
[#212]: /../../pull/212
[#214]: /../../issues/214
[#215]: /../../issues/215
[#217]: /../../pull/217
[#218]: /../../pull/218
[#221]: /../../pull/221
[#222]: /../../issues/222
[#223]: /../../issues/223
[#226]: /../../issues/226
[#228]: /../../pull/228
[#229]: /../../issues/229
[#233]: /../../issues/233
[#234]: /../../pull/234
[#235]: /../../pull/235
[#237]: /../../pull/237
[#238]: /../../issues/238
[#241]: /../../pull/241
[#243]: /../../issues/243
[#244]: /../../pull/244
[#245]: /../../pull/245
[#246]: /../../pull/246
[#247]: /../../pull/247
[#249]: /../../pull/249
[#251]: /../../pull/251
[#252]: /../../issues/252
[#253]: /../../issues/253
[#254]: /../../pull/254
[#255]: /../../pull/255
[#256]: /../../issues/256
[#257]: /../../issues/257
[#259]: /../../issues/259
[#260]: /../../pull/260
[#262]: /../../issues/262
[#263]: /../../issues/263
[#265]: /../../pull/265
[#274]: /../../pull/274
[#275]: /../../pull/275
[#276]: /../../pull/276
[#277]: /../../pull/277
[#278]: /../../issues/278
[#283]: /../../issues/283
[#285]: /../../pull/285
[#287]: /../../pull/287
[#288]: /../../pull/288
[#292]: /../../issues/292
[#293]: /../../pull/293
[#295]: /../../issues/295
[#300]: /../../pull/300
[#305]: /../../pull/305
[#309]: /../../issues/309
[#310]: /../../pull/310
[#313]: /../../pull/313
[#316]: /../../pull/316
[#317]: /../../pull/317
[#319]: /../../pull/319
[#323]: /../../pull/323
[#327]: /../../issues/327
[#328]: /../../issues/328
[#330]: /../../issues/330
[#332]: /../../pull/332
[#335]: /../../pull/335
[#336]: /../../pull/336
[#337]: /../../pull/337
[#340]: /../../pull/340
[#342]: /../../pull/342
[#345]: /../../issues/345
[#347]: /../../pull/347
[#350]: /../../pull/350
[#359]: /../../pull/359




## [0.1.0-alpha.7] · 2022-10-27
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
        - Redesigned messages and forwards. ([#162], [#151])
        - Redesigned header and send field. ([#170], [#133])
    - Media panel:
        - Redesigned participants modal. ([#127], [#122])
        - Proportionally resized secondary panel. ([#96], [#95])

### Fixed

- macOS:
    - Escape key not exiting fullscreen in calls. ([#169], [#166])
- UI:
    - Local notifications displaying in focused chats. ([#171], [#128])
    - Media panel:
        - Inability to disable certain incoming videos. ([#182], [#179])

[#95]: /../../issues/95
[#96]: /../../pull/96
[#122]: /../../issues/122
[#127]: /../../pull/127
[#128]: /../../issues/128
[#133]: /../../issues/133
[#137]: /../../issues/137
[#146]: /../../issues/146
[#151]: /../../issues/151
[#158]: /../../issues/158
[#159]: /../../pull/159
[#161]: /../../pull/161
[#162]: /../../pull/162
[#163]: /../../pull/163
[#166]: /../../issues/166
[#169]: /../../pull/169
[#170]: /../../pull/170
[#171]: /../../pull/171
[#179]: /../../issues/179
[#182]: /../../pull/182




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
