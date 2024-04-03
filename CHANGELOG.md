Change Log
==========

All user visible changes to this project will be documented in this file. This project uses to [Semantic Versioning 2.0.0].




## [0.1.0-alpha.13] · 2024-??-??
[0.1.0-alpha.13]: /../../tree/v0.1.0-alpha.13

[Diff](/../../compare/v0.1.0-alpha.12.3...v0.1.0-alpha.13) | [Milestone](/../../milestone/18)

### Added

- UI:
    - Media panel:
        - Call ended sound and left alone in group call sound. ([#877], [#809])
    - Update available popup. ([#907], [#896])

### Changed

- UI:
    - Chat page:
        - Redesigned editing mode and actions. ([#868])
        - Blurred previews under wide/narrow images. ([#934])
    - User page:
        - Redesigned editing mode and actions. ([#868])
    - Profile page:
        - About field in separate block. ([#891])
    - Contacts displayed everywhere with given names. ([#890], [#874])

### Fixed

- Android:
    - Sent or received message sound stopping music. ([#915], [#912])
- UI:
    - Chats tab:
        - Chat not disappearing after being kicked from it. ([#864], [#851])
    - Profile page:
        - Missing bottom mobile paddings. ([#886], [#821])
    - Media panel:
        - Missing bottom mobile paddings in panel. ([#886], [#821])
    - Chat page:
        - Images displayed with vertical gaps on narrow screens. ([#901], [#888])
        - Messages marked as read when gallery is opened. ([#897], [#854])
        - Replied calls displaying irrelevant information. ([#919], [#455])
    - Gapopa ID displaying incorrectly in notifications. ([#910], [#909])
    - Incoming call notification duplicating. ([#914])
- Web:
    - Missing blurred image previews in gallery. ([#880])

[#455]: /../../issues/455
[#809]: /../../issues/809
[#821]: /../../issues/821
[#851]: /../../issues/851
[#854]: /../../issues/854
[#864]: /../../pull/864
[#868]: /../../pull/868
[#874]: /../../issues/874
[#877]: /../../pull/877
[#880]: /../../pull/880
[#886]: /../../pull/886
[#888]: /../../issues/888
[#890]: /../../pull/890
[#891]: /../../pull/891
[#896]: /../../issues/896
[#897]: /../../pull/897
[#901]: /../../pull/901
[#907]: /../../pull/907
[#909]: /../../issues/909
[#910]: /../../pull/910
[#912]: /../../issues/912
[#914]: /../../pull/914
[#915]: /../../pull/915
[#919]: /../../pull/919
[#934]: /../../pull/934




## [0.1.0-alpha.12.3] · 2024-02-23
[0.1.0-alpha.12.3]: /../../tree/v0.1.0-alpha.12.3

[Diff](/../../compare/v0.1.0-alpha.12.2...v0.1.0-alpha.12.3) | [Milestone](/../../milestone/17)

### Fixed

- UI:
    - Media panel:
        - Ringtone not switching its output device on mobile. ([#840], [#817])
    - Chat page:
        - Blank previews of video attachments. ([#840])
- Web:
    - Video in calls being loaded indefinitely. ([#840])

[#817]: /../../issues/817
[#840]: /../../pull/840




## [0.1.0-alpha.12.2] · 2024-02-22
[0.1.0-alpha.12.2]: /../../tree/v0.1.0-alpha.12.2

[Diff](/../../compare/v0.1.0-alpha.12.1...v0.1.0-alpha.12.2) | [Milestone](/../../milestone/15)

### Added

- UI:
    - Media panel:
        - Default device on desktop platforms. ([#465], [#464])

### Changed

- UI:
    - Media panel:
        - Redesigned incoming/outgoing call. ([#832], [#812])
        - Mobile interface on tablets. ([#863])
    - Chats tab:
        - Direct link searching. ([#843], [#831])
        - Name specifying of group being created in app bar. ([#863])
    - Home page:
        - Redesigned introduction after following direct link. ([#848], [#820])
        - Redesigned context menu in navigation. ([#863])

### Fixed

- UI:
    - Chat page:
        - Keyboard hiding after sending a message on mobile. ([#856], [#828])
- Web:
    - Inability to view camera, microphone and output devices in Firefox. ([#855])

[#464]: /../../issues/464
[#465]: /../../pull/465
[#812]: /../../issues/812
[#820]: /../../issues/820
[#828]: /../../issues/828
[#831]: /../../issues/831
[#832]: /../../pull/832
[#843]: /../../pull/843
[#848]: /../../pull/848
[#855]: /../../pull/855
[#856]: /../../pull/856
[#863]: /../../pull/863




## [0.1.0-alpha.12.1] · 2024-02-08
[0.1.0-alpha.12.1]: /../../tree/v0.1.0-alpha.12.1

[Diff](/../../compare/v0.1.0-alpha.12...v0.1.0-alpha.12.1) | [Milestone](/../../milestone/16)

### Fixed

- Web:
    - Authentication token not being refreshed. ([#844])

[#844]: /../../pull/844




## [0.1.0-alpha.12] · 2024-02-08
[0.1.0-alpha.12]: /../../tree/v0.1.0-alpha.12

[Diff](/../../compare/v0.1.0-alpha.11.1...v0.1.0-alpha.12) | [Milestone](/../../milestone/14)

### Added

- UI:
    - Profile page:
        - Work with us tab hiding and showing. ([#794], [#789])
        - Cache maximum size slider. ([#794], [#789])
    - Media panel:
        - Screen dimming when close to ear on mobile. ([#823], [#808])
        - Secondary panel mode switches. ([#837], [#811])

### Changed

- UI:
    - Chat page:
        - Call buttons position setting and adjusting. ([#750], [#718])
        - Removed timeline mode. ([#791], [#788])
        - Attachments fading out when dismissed by swipe gesture. ([#786], [#699])
    - Chats tab:
        - Monolog searching. ([#745], [#582])
    - Redesigned user page. ([#769], [#771], [#766])
    - Chat info page:
        - Redesigned general information and group members. ([#769], [#766])
        - Redesigned direct chat link. ([#796], [#787])
    - Tuned up page transition animation. ([#775], [#573])
    - Profile page:
        - Redesigned direct chat link. ([#796], [#787])
        - Redesigned sign in section. ([#827], [#794], [#789])
    - Redesigned search modal. ([#805], [#790])
    - Media panel:
        - Grab cursor over participants. ([#816], [#810])

### Fixed

- UI:
    - Chats tab:
        - Restore button displaying under mobile navigation bar. ([#763], [#758])
    - Contacts tab:
        - Restore button displaying under mobile navigation bar. ([#763], [#758])
    - User page:
        - Downloaded avatar missing its extension on desktop. ([#756], [#726])
    - Chat page:
        - Read partially message status missing in forwards. ([#776])
    - Media panel:
        - Dock animations lagging when dragging buttons. ([#774], [#698])
        - Participants duplicating in rare cases. ([#759], [#743])
- Web:
    - Media devices not showing up on profile page in Safari. ([#780])
    - Video popup calls starting without camera enabled. ([#797])

[#573]: /../../issues/573
[#582]: /../../issues/582
[#698]: /../../issues/698
[#699]: /../../issues/699
[#718]: /../../issues/718
[#726]: /../../issues/726
[#743]: /../../issues/743
[#745]: /../../pull/745
[#750]: /../../pull/750
[#756]: /../../pull/756
[#758]: /../../issues/758
[#759]: /../../pull/759
[#763]: /../../pull/763
[#766]: /../../issues/766
[#769]: /../../pull/769
[#771]: /../../pull/771
[#774]: /../../pull/774
[#775]: /../../pull/775
[#776]: /../../pull/776
[#780]: /../../pull/780
[#786]: /../../pull/786
[#787]: /../../issues/787
[#788]: /../../issues/788
[#789]: /../../issues/789
[#790]: /../../issues/790
[#791]: /../../pull/791
[#794]: /../../pull/794
[#796]: /../../pull/796
[#797]: /../../pull/797
[#805]: /../../pull/805
[#808]: /../../issues/808
[#810]: /../../issues/810
[#811]: /../../issues/811
[#816]: /../../pull/816
[#823]: /../../pull/823
[#827]: /../../pull/827
[#837]: /../../pull/837




## [0.1.0-alpha.11.1] · 2023-12-22
[0.1.0-alpha.11.1]: /../../tree/v0.1.0-alpha.11.1

[Diff](/../../compare/v0.1.0-alpha.11...v0.1.0-alpha.11.1) | [Milestone](/../../milestone/13)

### Added

- UI:
    - Style page:
        - Icons tab. ([#730], [#710])
    - Chat page:
        - `Download` and `Save as` context menu options. ([#697], [#654])
        - Multiple messages selection, forwarding and deletion. ([#735], [#584])
    - Chats tab:
        - Swipe to delete gesture. ([#732])
    - Contacts tab:
        - Swipe to delete gesture. ([#732])

### Changed

- UI:
    - Always display online status on desktop. ([#702], [#681])
    - Style page:
        - Redesigned widgets tab. ([#695], [#632])
    - Chat page:
        - Display read partially message status in groups. ([#703], [#666])
        - Actions moved to more button. ([#736], [#719])
    - Chat info page:
        - Actions moved to more button. ([#736], [#719])
    - User page:
        - Actions moved to more button. ([#736], [#719])
    - Chats tab:
        - Redesigned chat tile. ([#748], [#741])
    - Icons in desktop context menu. ([#757])

### Fixed

- UI:
    - Media panel:
        - Disabled incoming video being loaded indefinitely. ([#707], [#700])
- Web:
    - Invalid caller name in popup calls. ([#711])

[#584]: /../../issues/584
[#632]: /../../issues/632
[#654]: /../../issues/654
[#666]: /../../issues/666
[#681]: /../../issues/681
[#697]: /../../pull/697
[#695]: /../../pull/695
[#700]: /../../issues/700
[#702]: /../../pull/702
[#703]: /../../pull/703
[#707]: /../../pull/707
[#710]: /../../issues/710
[#711]: /../../pull/711
[#719]: /../../issues/719
[#730]: /../../pull/730
[#732]: /../../pull/732
[#735]: /../../pull/735
[#736]: /../../pull/736
[#741]: /../../issues/741
[#748]: /../../pull/748
[#757]: /../../pull/757




## [0.1.0-alpha.11] · 2023-11-02
[0.1.0-alpha.11]: /../../tree/v0.1.0-alpha.11

[Diff](/../../compare/v0.1.0-alpha.10.1...v0.1.0-alpha.11) | [Milestone](/../../milestone/12)

### Changed

- UI:
    - Updated fonts. ([#663], [#615])
    - Style page:
        - Redesigned typography tab. ([#663], [#615])
    - Chat page:
        - Display message field while loading. ([#662], [#634])
        - Display small images smaller. ([#688], [#653])
        - Message attachments and replies editing. ([#671], [#557])
    - Disabled larger fonts accessibility setting temporary. ([#679])
    - Home page:
        - Redesigned introduction modal. ([#668], [#633])
- Web:
    - Updated loading animation. ([#662], [#634])
    - Updated [Progressive Web Application (PWA)][PWA] iOS home screen icon. ([#668])

### Fixed

- UI:
    - Profile page:
        - Save button displaying when login field is empty. ([#672], [#575])

[#557]: /../../issues/557
[#575]: /../../issues/575
[#615]: /../../issues/615
[#634]: /../../issues/634
[#633]: /../../issues/633
[#653]: /../../issues/653
[#662]: /../../pull/662
[#663]: /../../pull/663
[#668]: /../../pull/668
[#671]: /../../pull/671
[#672]: /../../pull/672
[#679]: /../../pull/679
[#688]: /../../pull/688




## [0.1.0-alpha.10.1] · 2023-10-19
[0.1.0-alpha.10.1]: /../../tree/v0.1.0-alpha.10.1

[Diff](/../../compare/v0.1.0-alpha.10...v0.1.0-alpha.10.1) | [Milestone](/../../milestone/11)

### Added

- Push notifications. ([#202], [#201])

### Changed

- UI:
    - Updated avatars colors. ([#656])
    - Chat page:
        - Attachments panel smoothly appearing and disappearing. ([#657], [#641])
        - Updated messages color. ([#656])

### Fixed

- UI:
    - Chats tab:
        - Wide image attachments having blurry previews. ([#628], [#525])
- Web:
    - Back button not working on Android. ([#548])
- macOS:
    - Application crashing when encountering video attachments in chat. ([#656])

[#201]: /../../issues/201
[#202]: /../../pull/202
[#525]: /../../issues/525
[#548]: /../../issues/548
[#628]: /../../pull/628
[#641]: /../../pull/641
[#656]: /../../pull/656
[#657]: /../../pull/657




## [0.1.0-alpha.10] · 2023-10-10
[0.1.0-alpha.10]: /../../tree/v0.1.0-alpha.10

[Diff](/../../compare/v0.1.0-alpha.9.4...v0.1.0-alpha.10) | [Milestone](/../../milestone/9)

### Added

- UI:
    - Chat page:
        - `Save as` for media attachments. ([#423], [#370])
        - Pinning/unpinning actions in send field. ([#609], [#559])

### Changed

- UI:
    - Display Gapopa ID in quartets. ([#587])
    - Work page:
        - Redesigned icons and texts. ([#597])
    - Redesigned auth page. ([#564], [#533])
    - Redesigned login modal. ([#564], [#533])
    - Redesigned language selection modal. ([#533])
    - Style page:
        - Redesigned colors tab. ([#616], [#614])

### Fixed

- Mobile:
    - Back camera being mirrored. ([#301], [#70])
- UI:
    - Chats tab:
        - Context menu appearing twice when long pressing dots. ([#599], [#508])
        - Title jumping around when entering search. ([#613], [#550])
    - User's last seen status not updating periodically. ([#610], [#551])
- Web:
    - Fix background flashing after loading. ([#604], [#549])

[#70]: /../../issues/70
[#301]: /../../pull/301
[#370]: /../../issues/370
[#423]: /../../pull/423
[#508]: /../../issues/508
[#533]: /../../pull/533
[#549]: /../../issues/549
[#550]: /../../issues/550
[#551]: /../../issues/551
[#559]: /../../issue/559
[#564]: /../../issues/564
[#587]: /../../pull/587
[#597]: /../../pull/597
[#599]: /../../pull/599
[#604]: /../../pull/604
[#609]: /../../pull/609
[#610]: /../../pull/610
[#613]: /../../pull/613
[#614]: /../../issues/614
[#616]: /../../pull/616




## [0.1.0-alpha.9.4] · 2023-09-04
[0.1.0-alpha.9.4]: /../../tree/v0.1.0-alpha.9.4

[Diff](/../../compare/v0.1.0-alpha.9.3...v0.1.0-alpha.9.4) | [Milestone](/../../milestone/10)

### Added

- UI:
    - Work page and tab. ([#541])

[#541]: /../../pull/541




## [0.1.0-alpha.9.3] · 2023-09-01
[0.1.0-alpha.9.3]: /../../tree/v0.1.0-alpha.9.3

[Diff](/../../compare/v0.1.0-alpha.9.2...v0.1.0-alpha.9.3) | [Milestone](/../../milestone/8)

### Added

- Windows:
    - Notifications. ([#492], [#439])

### Changed

- UI:
    - Context menu with fading effect on desktop. ([#506])
    - Profile page:
        - Sections highlighting. ([#513], [#385])
    - Home page:
        - Redesigned navigation buttons' badges. ([#529], [#500])
    - Display online status only when application is active. ([#522])

[#385]: /../../issues/385
[#439]: /../../issues/439
[#492]: /../../pull/492
[#500]: /../../issues/500
[#506]: /../../pull/506
[#513]: /../../pull/513
[#522]: /../../pull/522
[#529]: /../../pull/529




## [0.1.0-alpha.9.2] · 2023-07-28
[0.1.0-alpha.9.2]: /../../tree/v0.1.0-alpha.9.2

[Diff](/../../compare/v0.1.0-alpha.9.1...v0.1.0-alpha.9.2) | [Milestone](/../../milestone/6)

### Fixed

- Linux:
    - Application crashing when playing sounds. ([#496])
- Web:
    - Default locale not detecting in Safari. ([#491])

[#491]: /../../pull/491
[#496]: /../../pull/496




## [0.1.0-alpha.9.1] · 2023-07-20
[0.1.0-alpha.9.1]: /../../tree/v0.1.0-alpha.9.1

[Diff](/../../compare/v0.1.0-alpha.9...v0.1.0-alpha.9.1) | [Milestone](/../../milestone/7)

### Fixed

- Performance:
    - Spamming backend API when reading a chat. ([#487])
- iOS:
    - Unreadable status bar text color. ([#487])
- Web:
    - Avatar not uploading due to simultaneous file read. ([#487])

[#487]: /../../pull/487




## [0.1.0-alpha.9] · 2023-07-17
[0.1.0-alpha.9]: /../../tree/v0.1.0-alpha.9

[Diff](/../../compare/v0.1.0-alpha.8...v0.1.0-alpha.9) | [Milestone](/../../milestone/5)

### Added

- UI:
    - Chat page:
        - History clearing. ([#361])
        - Text selection in messages. ([#118], [#17])
        - Clickable links and emails. ([#436], [#388])
        - Replied and forwarded messages highlighting. ([#467])
    - Chats tab:
        - Multiple chats selection. ([#361], [#348])
        - Chat-monolog. ([#456], [#412], [#333], [#326])
    - Contacts tab:
        - Multiple contacts selection. ([#361], [#348])
    - Media panel:
        - Low signal icons. ([#454])
        - Device changed notifications. ([#472])
    - Clickable icons animating on hovers and clicks. ([#470])
- Web:
    - Unread chats badge on favicon. ([#403])
- Desktop:
    - Video playback. ([#468], [#445], [#438])
- Mobile:
    - Video rewinding indication. ([#468], [#452])

### Changed

- UI:
    - Chat page:
        - Redesigned info and call messages. ([#453], [#357])
        - Redesigned file attachments. ([#453], [#362])
        - Message timestamps. ([#399])
        - Redesigned chat messages and forwards. ([#416])
        - Read messages only when application is active. ([#462], [#418])
    - Media panel:
        - Position and size persistence. ([#270], [#264])
        - Proportionally resizing secondary panel. ([#393], [#356], [#258])
        - Incoming ringtone fading in. ([#375], [#367])
        - Participants dialing indication. ([#286], [#281])
    - Chats tab:
        - Inverted selected chat colors. ([#405])
        - Chats with ongoing calls sorting above favorites. ([#392], [#371])
        - Redesigned chats selecting. ([#463])
    - Contacts tab:
        - Redesigned contacts selecting. ([#463])
    - Home page:
        - Redesigned navigation buttons animation. ([#440])
        - Redesigned quick mute and status changing menus. ([#443])

### Fixed

- UI:
    - Profile page:
        - Change password modal flickering. ([#380], [#377])
    - Media panel:
        - Media buttons controlling ringtone. ([#437], [#401])
- Web:
    - Images sometimes not loading. ([#408], [#344])

[#17]: /../../issues/17
[#118]: /../../pull/118
[#258]: /../../issues/258
[#264]: /../../issues/264
[#270]: /../../pull/270
[#281]: /../../issues/281
[#286]: /../../pull/286
[#326]: /../../issues/326
[#333]: /../../pull/333
[#344]: /../../issues/344
[#348]: /../../issues/348
[#356]: /../../pull/356
[#357]: /../../pull/357
[#361]: /../../pull/361
[#362]: /../../pull/362
[#367]: /../../issues/367
[#371]: /../../issues/371
[#375]: /../../pull/375
[#377]: /../../issues/377
[#380]: /../../pull/380
[#388]: /../../pull/388
[#392]: /../../pull/392
[#393]: /../../pull/393
[#399]: /../../pull/399
[#401]: /../../issues/401
[#403]: /../../pull/403
[#405]: /../../pull/405
[#408]: /../../pull/408
[#412]: /../../pull/412
[#418]: /../../issues/418
[#436]: /../../pull/436
[#437]: /../../pull/437
[#438]: /../../issues/438
[#440]: /../../pull/440
[#443]: /../../pull/443
[#445]: /../../pull/445
[#452]: /../../issues/452
[#453]: /../../pull/453
[#454]: /../../pull/454
[#456]: /../../pull/456
[#462]: /../../pull/462
[#463]: /../../pull/463
[#467]: /../../pull/467
[#468]: /../../pull/468
[#470]: /../../pull/470
[#472]: /../../pull/472




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
[PWA]: https://en.wikipedia.org/wiki/Progressive_web_app
[Semantic Versioning 2.0.0]: https://semver.org
