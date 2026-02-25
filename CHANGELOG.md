Change Log
==========

All user visible changes to this project will be documented in this file. This project uses to [Semantic Versioning 2.0.0].




## [0.10.0] · 2026-??-??
[0.10.0]: /../../tree/v0.10.0

[Diff](/../../compare/v0.9.3...v0.10.0) | [Milestone](/../../milestone/69)

### Fixed

- UI:
    - Profile page:
        - Country and city missing from linked Web devices. ([#1620])
    - Media panel:
        - Reconnect button playing animation when dragging. ([#1621])

[#1620]: /../../pull/1620
[#1621]: /../../pull/1621




## [0.9.3] · 2026-02-23
[0.9.3]: /../../tree/v0.9.3

[Diff](/../../compare/v0.9.2...v0.9.3) | [Milestone](/../../milestone/68)

### Fixed

- UI:
    - Chat page:
        - Draft not being updated when removing attachments or replies. ([#1613])
    - Profile page:
        - Invalid microphone and output device displayed as selected by default. ([#1613])
        - Invalid icon being used for devices with unknown OS. ([#1615])

[#1613]: /../../pull/1613
[#1615]: /../../pull/1615




## [0.9.2] · 2026-02-16
[0.9.2]: /../../tree/v0.9.2

[Diff](/../../compare/v0.9.1...v0.9.2) | [Milestone](/../../milestone/67)

### Fixed

- UI:
    - Media panel:
        - Pending call notification being displayed when already joined on another device. ([#1605])
        - Invalid microphone or output being used by default when joining call on Web. ([#1606])
        - Invalid screen sharing resolution under desktop platforms. ([#1609])
        - Default device not being first in devices list. ([#1610])
    - Context menu closing when clicking RMB instead of reopening on desktops. ([#1603])

[#1603]: /../../pull/1603
[#1605]: /../../pull/1605
[#1606]: /../../pull/1606
[#1609]: /../../pull/1609
[#1610]: /../../pull/1610




## [0.9.1] · 2026-02-11
[0.9.1]: /../../tree/v0.9.1

[Diff](/../../compare/v0.9.0...v0.9.1) | [Milestone](/../../milestone/66)

### Fixed

- UI:
    - Media panel:
        - Enabled video sometimes not being seen by participants. ([#1602])
        - Call buttons dragged from dock to panel are being left hanging on screen. ([#1602])

[#1602]: /../../pull/1602




## [0.9.0] · 2026-02-05
[0.9.0]: /../../tree/v0.9.0

[Diff](/../../compare/v0.8.2...v0.9.0) | [Milestone](/../../milestone/65)

### Changed

- UI:
    - Profile page:
        - Allow name to be 1 symbols long. ([#1600])

[#1600]: /../../pull/1600




## [0.8.2] · 2026-02-02
[0.8.2]: /../../tree/v0.8.2

[Diff](/../../compare/v0.8.1...v0.8.2) | [Milestone](/../../milestone/64)

### Added

- UI:
    - Support chat. ([#1598], [#1597], [#1595])
    - Chat page:
        - Logs button in notes and support chats. ([#1595])
- Mobile:
    - Media panel:
        - Output device modal being displayed when any external device is connected. ([#1596], [#1593])

### Changed

- UI:
    - User page:
        - Join and decline call buttons. ([#1597])

### Fixed

- UI:
    - Media panel:
        - Camera disabling for remote peers when disable screen sharing. ([#1594])
- iOS:
    - Dialogue calls not being connected sometimes. ([#1594])
    - Output device not switching to headphones or not displaying being switched. ([#1593])

[#1593]: /../../pull/1593
[#1594]: /../../pull/1594
[#1595]: /../../pull/1595
[#1596]: /../../pull/1596
[#1597]: /../../pull/1597
[#1598]: /../../pull/1598




## [0.8.1] · 2026-01-26
[0.8.1]: /../../tree/v0.8.1

[Diff](/../../compare/v0.8.0...v0.8.1) | [Milestone](/../../milestone/63)

### Fixed

- UI:
    - Media panel:
        - Incoming call sometimes being stuck ringing infinitely. ([#1589])
        - Text below accept and decline buttons being unreadable. ([#1589])
        - Remote video not being disabled on slow Internet connection. ([#1591])

[#1589]: /../../pull/1589
[#1591]: /../../pull/1591




## [0.8.0] · 2026-01-21
[0.8.0]: /../../tree/v0.8.0

[Diff](/../../compare/v0.7.2...v0.8.0) | [Milestone](/../../milestone/62)

### Added

- UI:
    - Media panel:
        - Reconnecting notifications when network changes in call. ([#1581])

### Fixed

- UI:
    - Chat info page:
        - Leave group button in members list not working. ([#1578])
    - Media panel:
        - Infinite vibration when ringing pending calls on iOS and Android. ([#1580])
        - Connection not being reconnected on network changes on Web. ([#1581])
        - Own camera or recipient's video sometimes not being rendered. ([#1582])
        - Raised hand appearing on display demonstrations. ([#1584])

[#1578]: /../../pull/1578
[#1580]: /../../pull/1580
[#1581]: /../../pull/1581
[#1582]: /../../pull/1582
[#1584]: /../../pull/1584




## [0.7.2] · 2026-01-12
[0.7.2]: /../../tree/v0.7.2

[Diff](/../../compare/v0.7.1...v0.7.2) | [Milestone](/../../milestone/61)

### Added

- UI:
    - Media panel:
        - Reconnect call button. ([#1577], [#1575])
    - Profile page:
        - Display domains of linked devices. ([#1576])
- Mobile:
    - Media panel:
        - Disclaimer of microphone and camera being blocked when tab is in background. ([#1575])

### Changed

- UI:
    - Menu tab:
        - Buttons grouped into sections. ([#1577])

[#1575]: /../../pull/1575
[#1576]: /../../pull/1576
[#1577]: /../../pull/1577




## [0.7.1] · 2026-01-07
[0.7.1]: /../../tree/v0.7.1

[Diff](/../../compare/v0.7.0...v0.7.1) | [Milestone](/../../milestone/60)

### Added

- UI:
    - Media panel:
        - Audio sharing with screen sharing. ([#1570])

### Fixed

- UI:
    - Media panel:
        - Empty screen sharing being displayed sometimes. ([#1566])
        - Incoming call window not being displayed in rare cases. ([#1567])
        - Camera device turning off sometimes when microphone device is disconnected. ([#1568])
    - Autocorrect invalidly enabled for login, passwords and e-mail fields. ([#1571])
    - New and repeat password fields filling in current password instead of suggesting new. ([#1571])
- iOS:
    - Media panel:
        - Calls not transmitting neither audio nor video to recipients. ([#1571])

[#1566]: /../../pull/1566
[#1567]: /../../pull/1567
[#1568]: /../../pull/1568
[#1570]: /../../pull/1570
[#1571]: /../../pull/1571




## [0.7.0] · 2025-12-25
[0.7.0]: /../../tree/v0.7.0

[Diff](/../../compare/v0.6.14...v0.7.0) | [Milestone](/../../milestone/59)

### Fixed

- Authorization sometimes being lost on some devices. ([#1564])

[#1564]: /../../pull/1564




## [0.6.14] · 2025-12-19
[0.6.14]: /../../tree/v0.6.14

[Diff](/../../compare/v0.6.13...v0.6.14) | [Milestone](/../../milestone/58)

### Fixed

- UI:
    - Media panel:
        - Calls ringing from muted chats. ([#1557], [#1546])

[#1546]: /../../pull/1546
[#1557]: /../../pull/1557




## [0.6.13] · 2025-12-10
[0.6.13]: /../../tree/v0.6.13

[Diff](/../../compare/v0.6.12...v0.6.13) | [Milestone](/../../milestone/57)

### Fixed

- UI:
    - Profile page:
        - Presence status sometimes not being updated. ([#1540], [#1539])
    - Passwords fields having first letter capitalization enabled automatically. ([#1537], [#1533])
    - Chats tab:
        - Answered or declined call displayed as unread notification in chat. ([#1516], [#1508])

[#1508]: /../../issues/1508
[#1516]: /../../pull/1516
[#1533]: /../../issues/1533
[#1537]: /../../pull/1537
[#1539]: /../../issues/1539
[#1540]: /../../pull/1540




## [0.6.12] · 2025-12-01
[0.6.12]: /../../tree/v0.6.12

[Diff](/../../compare/v0.6.11...v0.6.12) | [Milestone](/../../milestone/56)

### Changed

- UI:
    - Menu tab:
       - Redesigned sidebar color. [[#1529], [#1524]]
    - Chat page:
        - Auto-play video thumbnails only when hovered. ([#1518], [#1446])

### Fixed

- UI:
    - Chat page:
        - Page sometimes not being popped when navigating back. ([#1526])
        - Forwarded messages displaying invalid sent/read status. ([#1521], [#1452])
    - Home Page:
        - Navigation bar expanding inappropriately when side bar is wide enough. ([#1532], [#1528])

[#1446]: /../../issues/1446
[#1452]: /../../issues/1452
[#1518]: /../../pull/1518
[#1521]: /../../pull/1521
[#1524]: /../../issues/1524
[#1526]: /../../pull/1526
[#1528]: /../../issues/1528
[#1529]: /../../pull/1529
[#1532]: /../../pull/1532




## [0.6.11] · 2025-11-24
[0.6.11]: /../../tree/v0.6.11

[Diff](/../../compare/v0.6.10...v0.6.11) | [Milestone](/../../milestone/55)

### Changed

- UI:
    - Chat page:
        - File uploads can be canceled. ([#1496], [#1490])
    - Chats tab:
        - Redesigned chats appearing animation. ([#1514])
        - Redesigned unread messages counter. ([#1512], [#1507])

### Fixed

- UI:
    - Chat page:
        - Inability to navigate back after clicking on direct link. ([#1504], [#1460])

[#1460]: /../../issues/1460
[#1490]: /../../issues/1490
[#1496]: /../../pull/1496
[#1504]: /../../pull/1504
[#1507]: /../../issues/1507
[#1512]: /../../pull/1512
[#1514]: /../../pull/1514




## [0.6.10] · 2025-11-17
[0.6.10]: /../../tree/v0.6.10

[Diff](/../../compare/v0.6.9...v0.6.10) | [Milestone](/../../milestone/54)

### Fixed

- UI:
    - Chat page:
        - Upload progress indicator not updating during file upload. ([#1492], [#1491])
- Web:
    - Inability to crop SVG avatar images on Web. ([#1501], [#1489])

[#1489]: /../../issues/1489
[#1491]: /../../issues/1491
[#1492]: /../../pull/1492
[#1501]: /../../pull/1501




## [0.6.9] · 2025-11-11
[0.6.9]: /../../tree/v0.6.9

[Diff](/../../compare/v0.6.8...v0.6.9) | [Milestone](/../../milestone/53)

### Fixed

- UI:
    - Chat page:
        - Inability to move caret in message field up and down. ([#1494], [#1493])
        - Redesigned file attachments. ([#1480], [#1412])
- Push notifications:
    - Notifications duplicating on iOS and Android. ([#1500], [#1495], [#1472])
    - Notifications not being canceled after reading on another device on iOS and Android. ([#1500])
- iOS:
    - [VoIP] [CallKit] notification still ringing despite already joined call on another device. ([#1499])
    - Unread chats badge not updating sometimes on app's icon. ([#1500])

[#1412]: /../../issues/1412
[#1472]: /../../issues/1472
[#1480]: /../../pull/1480
[#1493]: /../../issues/1493
[#1494]: /../../pull/1494
[#1495]: /../../pull/1495
[#1499]: /../../pull/1499
[#1500]: /../../pull/1500




## [0.6.8] · 2025-11-03
[0.6.8]: /../../tree/v0.6.8

[Diff](/../../compare/v0.6.7...v0.6.8) | [Milestone](/../../milestone/52)

### Added

- UI:
    - Pages scrolling by pressing "PageUp" and "PageDown" keys. ([#1469], [#1228])

### Changed

- UI:
    - Chat page:
        - Redesigned forward message modal. ([#1476], [#1408])

[#1228]: /../../issues/1228
[#1408]: /../../issues/1408
[#1469]: /../../pull/1469
[#1476]: /../../pull/1476




## [0.6.7] · 2025-10-29
[0.6.7]: /../../tree/v0.6.7

[Diff](/../../compare/v0.6.6...v0.6.7) | [Milestone](/../../milestone/51)

### Changed

- UI:
    - Home page:
        - Display "Deleted Account" title for deleted users. ([#1445], [#1419])
    - Chats tab:
        - Redesigned app bar and searching. ([#1438], [#1396])
    - Chat page:
        - "Ctrl+F"/"Cmd+F" toggling messages searching. ([#1438], [#1396])

### Fixed

- UI:
    - Media panel:
        - Updated overlay icons. ([#1466], [#1453])
        - Invalid tooltip positions for buttons in dock. ([#1473], [#1436])

[#1396]: /../../issues/1396
[#1419]: /../../issues/1419
[#1436]: /../../issues/1436
[#1438]: /../../pull/1438
[#1445]: /../../pull/1445
[#1453]: /../../issues/1453
[#1466]: /../../pull/1466
[#1473]: /../../pull/1473




## [0.6.6] · 2025-10-13
[0.6.6]: /../../tree/v0.6.6

[Diff](/../../compare/v0.6.5...v0.6.6) | [Milestone](/../../milestone/50)

### Added

- UI:
    - Help page:
        - Download logs button. ([#1458])
    - Archived chats. ([#1414], [#1255])

### Fixed

- Web:
    - Player:
        - Inability to copy images to clipboard. ([#1457])

[#1255]: /../../issues/1255
[#1414]: /../../pull/1414
[#1457]: /../../pull/1457
[#1458]: /../../pull/1458




## [0.6.5] · 2025-10-06
[0.6.5]: /../../tree/v0.6.5

[Diff](/../../compare/v0.6.4...v0.6.5) | [Milestone](/../../milestone/49)

### Changed

- UI:
    - Chat page:
        - Redesigned messages selection. ([#1416], [#1410])
        - Redesigned message information. ([#1437], [#1379])

### Fixed

- UI:
    - Login modal:
        - Meaningless formatting errors when leading/trailing spaces are present. ([#1448], [#1443])

[#1379]: /../../issues/1379
[#1410]: /../../issues/1410
[#1416]: /../../pull/1416
[#1437]: /../../pull/1437
[#1443]: /../../issues/1443
[#1448]: /../../issues/1448




## [0.6.4] · 2025-09-29
[0.6.4]: /../../tree/v0.6.4

[Diff](/../../compare/v0.6.3...v0.6.4) | [Milestone](/../../milestone/48)

### Changed

- UI:
    - Home page:
        - Redesigned context panel for switching statuses over profile button. ([#1422], [#1254])

### Fixed

- UI:
    - Chat page:
        - Inability to copy text from forwarded messages. ([#1434], [#1271])

[#1254]: /../../issues/1254
[#1271]: /../../issues/1271
[#1422]: /../../pull/1422
[#1434]: /../../pull/1434




## [0.6.3] · 2025-09-22
[0.6.3]: /../../tree/v0.6.3

[Diff](/../../compare/v0.6.2...v0.6.3) | [Milestone](/../../milestone/47)

### Changed

- UI:
    - Chat info page:
        - Updated monolog description. ([#1409], [#1248])
    - Home page:
        - Redesigned introduction for guests accounts. ([#1430])
    - Media panel:
        - Updated remote audio icons. ([#1424], [#1281])

[#1248]: /../../issues/1248
[#1281]: /../../issues/1281
[#1409]: /../../pull/1409
[#1424]: /../../pull/1424
[#1430]: /../../pull/1430




## [0.6.2] · 2025-09-15
[0.6.2]: /../../tree/v0.6.2

[Diff](/../../compare/v0.6.1...v0.6.2) | [Milestone](/../../milestone/46)

### Changed

- UI:
    - Chat page:
        - Actions removed from more button. ([#1401], [#1249])
    - Chat info page:
        - Redesigned title and members blocks. ([#1401], [#1249])
        - Actions added. ([#1401], [#1249])
    - Chats tab:
        - Redesigned chats deletion dialogs. ([#1401])
    - Player:
        - Interface hiding after 3 seconds of inactivity on desktops. ([#1415])
        - Player closing when clicking outside of content. ([#1415])

[#1249]: /../../issues/1249
[#1401]: /../../pull/1401
[#1415]: /../../pull/1415




## [0.6.1] · 2025-09-09
[0.6.1]: /../../tree/v0.6.1

[Diff](/../../compare/v0.6.0...v0.6.1) | [Milestone](/../../milestone/45)

### Changed

- UI:
    - Redesigned media player. ([#1395], [#1368], [#1367], [#1356])
    - Chat info page:
        - Display folded indicator when chat is in favorites. ([#1391], [#1274])
    - User page:
        - Display folded indicator when user is in favorites. ([#1391], [#1274])
    - Display Gapopa ID with hyphens instead of spaces. ([#1393], [#1352])
- Mobile:
    - App bar and navigation bar extending its height to account safe area paddings. ([#1369])

### Fixed

- UI:
    - Chat page:
        - Text in forwarded messages not being selectable. ([#1367])
- Web:
    - Back/forward buttons appearing in Chrome when swiping back/forward. ([#1386])

[#1274]: /../../issues/1274
[#1352]: /../../issues/1352
[#1356]: /../../pull/1356
[#1367]: /../../pull/1367
[#1368]: /../../pull/1368
[#1369]: /../../pull/1369
[#1386]: /../../pull/1386
[#1391]: /../../pull/1391
[#1393]: /../../pull/1393
[#1395]: /../../pull/1395




## [0.6.0] · 2025-08-07
[0.6.0]: /../../tree/v0.6.0

[Diff](/../../compare/v0.5.4...v0.6.0) | [Milestone](/../../milestone/44)

### Changed

- Desktop:
    - Route switching animation. ([#1336], [#1311])
- UI:
    - Profile page:
        - Redesigned session delete modals. ([#1344])

### Fixed

- UI:
    - Chats tab:
        - Infinite typing indicator occurring sometimes. ([#1350], [#1348])
    - Login modal:
        - Inability to sign in with one-time password. ([#1357], [#1358])

[#1311]: /../../issues/1311
[#1336]: /../../pull/1336
[#1344]: /../../pull/1344
[#1348]: /../../issues/1348
[#1350]: /../../pull/1350
[#1357]: /../../pull/1357
[#1358]: /../../issues/1358




## [0.5.4] · 2025-07-25
[0.5.4]: /../../tree/v0.5.4

[Diff](/../../compare/v0.5.3...v0.5.4) | [Milestone](/../../milestone/43)

### Added

- UI:
    - Spanish localization. ([#1333])

### Changed

- UI:
    - Chat page:
        - Redesigned editing mode. ([#1327])
    - Profile page:
        - Slider with ticks. ([#1330])
    - Chats tab:
        - Group creating and chats selecting buttons. ([#1333])
    - Redesigned delete account page. ([#1339])
    - Login modal:
        - Accept any identifier instead of e-mail only during sign in via e-mail. ([#1339])

### Fixed

- iOS:
    - Authorization sometimes being lost when receiving push notifications. ([#1331], [#1326])

[#1326]: /../../pull/1326
[#1327]: /../../pull/1327
[#1330]: /../../pull/1330
[#1331]: /../../pull/1331
[#1333]: /../../pull/1333
[#1339]: /../../pull/1339




## [0.5.3] · 2025-07-10
[0.5.3]: /../../tree/v0.5.3

[Diff](/../../compare/v0.5.2...v0.5.3) | [Milestone](/../../milestone/42)

### Added

- UI:
    - Profile page:
        - Voice processing settings for calls. ([#1323], [#1287], [#1264])
- Technical information and logs modal opened by double clicking logo's eye. ([#1319])

### Changed

- UI:
    - Profile page:
        - Redesigned email and password popups. ([#1296], [#1293])

### Fixed

- iOS:
    - [VoIP] [CallKit] notification still ringing despite already joined call on another device. ([#1320])

[#1264]: /../../issue/1264
[#1287]: /../../pull/1287
[#1293]: /../../issue/1293
[#1296]: /../../pull/1296
[#1319]: /../../pull/1319
[#1320]: /../../pull/1320
[#1323]: /../../pull/1323




## [0.5.2] · 2025-07-01
[0.5.2]: /../../tree/v0.5.2

[Diff](/../../compare/v0.5.1...v0.5.2) | [Milestone](/../../milestone/41)

### Changed

- UI:
    - Chat page:
        - Redesigned message delete popups. ([#1291], [#1268])
    - Media panel:
        - Default order of call buttons in dock. ([#1294], [#1263])
    - User page:
        - Redesigned description and actions. ([#1310], [#1282], [#1250])

### Fixed

- Android:
    - Black screen stuck when opening application. ([#1308])
- UI:
    - Chat page:
        - Screenshots made to clipboard not pasted as attachments. ([#1280])
        - Scroll back button not scrolling chat to its true bottom. ([#1302])
    - Auth page:
        - Inability to proceed to recover access with username not being empty. ([#1285])
    - User page:
        - Links in description not being clickable. ([#1310])
- Web:
    - Web application install button incorrectly stating that [Progressive Web Application (PWA)](PWA) is already installed. ([#1303])

[#1250]: /../../issue/1250
[#1263]: /../../issue/1263
[#1268]: /../../issue/1268
[#1280]: /../../pull/1280
[#1282]: /../../pull/1282
[#1285]: /../../pull/1285
[#1291]: /../../pull/1291
[#1294]: /../../pull/1294
[#1302]: /../../pull/1302
[#1303]: /../../pull/1303
[#1308]: /../../pull/1308
[#1310]: /../../pull/1310




## [0.5.1] · 2025-06-03
[0.5.1]: /../../tree/v0.5.1

[Diff](/../../compare/v0.5.0...v0.5.1) | [Milestone](/../../milestone/40)

### Fixed

- UI:
    - Chat page:
        - Duplicating read users avatars under messages. ([#1243])
        - Invalid message's author being displayed sometimes. ([#1243], [#1050])
        - Gallery image flashing when being opened. ([#1246])
    - Chats tab:
        - Infinite typing indicator occurring sometimes. ([#1243], [#1244])
    - Chat info page:
        - Infinite loader displayed under members list. ([#1246])
    - Media panel:
        - Users sometimes not being listed in add participant modal. ([#1272])
- Web:
    - Invalid animation when swiping pages back in Safari on iOS. ([#1267])

[#1050]: /../../issues/1050
[#1244]: /../../issues/1244
[#1243]: /../../pull/1243
[#1244]: /../../issues/1244
[#1246]: /../../pull/1246
[#1267]: /../../pull/1267
[#1272]: /../../pull/1272




## [0.5.0] · 2025-05-09
[0.5.0]: /../../tree/v0.5.0

[Diff](/../../compare/v0.4.3...v0.5.0) | [Milestone](/../../milestone/39)

### Fixed

- UI:
    - Chat page:
        - Images in replied messages sometimes not being loaded. ([#1238])

[#1238]: /../../pull/1238




## [0.4.3] · 2025-05-06
[0.4.3]: /../../tree/v0.4.3

[Diff](/../../compare/v0.4.2...v0.4.3) | [Milestone](/../../milestone/38)

### Changed

- UI:
    - Media panel:
        - Context menu icons in actions over participants. ([#1226])
    - Auth page:
        - Upgrade popup redesigned to be upgrade alert. ([#1229])

### Fixed

- UI:
    - Media panel:
        - Incoming call displayed multiple times when declined quickly enough. ([#1219])
        - Call buttons hanging in air when dragging from launchpad fast enough. ([#1237], [#1236])
- Web:
    - Translate popup displaying in browsers. ([#1215])
    - Call audio ringtone not being played. ([#1218])
    - Preferred microphone and camera not being used in Safari. ([#1223])
    - Microphone devices not being listed in PWA in Safari. ([#1227])

[#1215]: /../../pull/1215
[#1218]: /../../pull/1218
[#1219]: /../../pull/1219
[#1223]: /../../pull/1223
[#1226]: /../../pull/1226
[#1227]: /../../pull/1227
[#1229]: /../../pull/1229
[#1236]: /../../issues/1236
[#1237]: /../../pull/1237




## [0.4.2] · 2025-04-22
[0.4.2]: /../../tree/v0.4.2

[Diff](/../../compare/v0.4.1...v0.4.2) | [Milestone](/../../milestone/37)

### Changed

- Web:
    - Updated [Progressive Web Application (PWA)][PWA] icon. ([#1209])

### Fixed

- UI:
    - Chat page:
        - Inability to delete errored messages when chat is read by recipient. ([#1210], [#1207])
- iOS:
    - Inability to upload drag-n-dropped files to chat. ([#1210], [#1206])

[#1206]: /../../issues/1206
[#1207]: /../../issues/1207
[#1209]: /../../pull/1209
[#1210]: /../../pull/1210




## [0.4.1] · 2025-04-15
[0.4.1]: /../../tree/v0.4.1

[Diff](/../../compare/v0.4.0...v0.4.1) | [Milestone](/../../milestone/36)

### Changed

- UI:
    - Redesigned upgrade popup. ([#1201])

### Fixed

- Direct links not working when authorized. ([#1201])
- UI:
    - Profile page:
        - Inability to crop SVG avatar images. ([#1201])

[#1201]: /../../pull/1201




## [0.4.0] · 2025-04-12
[0.4.0]: /../../tree/v0.4.0

[Diff](/../../compare/v0.3.3...v0.4.0) | [Milestone](/../../milestone/35)

### Added

- Web:
    - Upgrade popup displaying when new deployment is available. ([#1181])
- UI:
    - Profile page:
        - Ability to rebind hot key for toggling microphone on and off. ([#1193])

### Changed

- UI:
    - Media panel:
        - Dock and panels redesigned contrast colors. ([#1182])
    - Redesigned my profile page. ([#1185])
    - Redesigned menu tab labels and icons. ([#1185])
    - Redesigned share link modal. ([#1191])
    - Redesigned logout modal. ([#1194])
    - Redesigned call window switch modal. ([#1194])
    - Chat page:
        - Message field gaining focus when entering chat. ([#1196])
        - Key up presses editing last sent message. ([#1196])

### Fixed

- UI:
    - User page:
        - Missing localization for biography expand button. ([#1185], [#1186])
        - Inability to input block reason in Safari and Firefox. ([#1190], [#1187])
- iOS:
    - Authorization sometimes being lost when receiving push notifications. ([#1197])

[#1181]: /../../pull/1181
[#1182]: /../../pull/1182
[#1185]: /../../pull/1185
[#1186]: /../../issues/1186
[#1187]: /../../issues/1187
[#1190]: /../../pull/1190
[#1191]: /../../pull/1191
[#1193]: /../../pull/1193
[#1194]: /../../pull/1194
[#1196]: /../../pull/1196
[#1197]: /../../pull/1197




## [0.3.3] · 2025-03-07
[0.3.3]: /../../tree/v0.3.3

[Diff](/../../compare/v0.3.2...v0.3.3) | [Milestone](/../../milestone/34)

### Added

- UI:
    - Media panel:
        - Hot key `Alt + M` for toggling microphone on and off. ([#1179])

### Fixed

- UI:
    - Mobile:
        - Context menus having meaningless dividers. ([#1170])
    - Chats tab:
        - Inability to paste clipboard into search field when chat is open. ([#1170])
    - Profile page:
        - Blocklist count not being updated in real time. ([#1175])
- macOS:
    - Application becoming unresponsive when drag-n-dropping screenshots to chat. ([#1177])

[#1170]: /../../pull/1170
[#1175]: /../../pull/1175
[#1177]: /../../pull/1177
[#1179]: /../../pull/1179




## [0.3.2] · 2025-02-07
[0.3.2]: /../../tree/v0.3.2

[Diff](/../../compare/v0.3.1...v0.3.2) | [Milestone](/../../milestone/33)

### Changed

- UI:
    - Home page:
        - Updated app bar and navigation panel to be of rectangular shape. ([#1164])
        - Updated group creating and chats selecting UX. ([#1164])
    - Updated chat info page editing and overall design. ([#1164])
    - Updated user page design. ([#1164])
    - Chat page:
        - Updated monolog chat description. ([#1164])

### Fixed

- UI:
    - Mobile:
        - Auto-capitalization setting being ignored in text fields. ([#1164])

[#1164]: /../../pull/1164




## [0.3.1] · 2025-02-03
[0.3.1]: /../../tree/v0.3.1

[Diff](/../../compare/v0.3.0...v0.3.1) | [Milestone](/../../milestone/32)

### Added

- iOS:
    - [VoIP] [CallKit] notifications. ([#1142])

### Fixed

- UI:
    - User page:
        - Too large away badge being displayed on avatar. ([#1157])
    - Profile page:
        - Inability to crop SVG avatar images. ([#1157])
        - Initial cropping area being smaller than image's size. ([#1159])
    - Chat page:
        - Inability to close chat page when writing to it the first time. ([#1158])
        - Members count being bigger than actual members number. ([#1159])

[#1142]: /../../pull/1142
[#1157]: /../../pull/1157
[#1158]: /../../pull/1158
[#1159]: /../../pull/1159




## [0.3.0] · 2024-12-25
[0.3.0]: /../../tree/v0.3.0

[Diff](/../../compare/v0.2.2...v0.3.0) | [Milestone](/../../milestone/31)

### Added

- UI:
    - Profile page:
        - Avatar cropping. ([#1143], [#1139], [#1130], [#530])
    - Chat page:
        - Image and file attachments pasting from pasteboard. ([#1141])
    - Chats tab:
        - Image and file attachments drag-n-drop. ([#1140], [#594])

[#530]: /../../issues/530
[#594]: /../../issues/594
[#1130]: /../../pull/1130
[#1139]: /../../pull/1139
[#1140]: /../../pull/1140
[#1141]: /../../pull/1141
[#1143]: /../../pull/1143




## [0.2.2] · 2024-11-01
[0.2.2]: /../../tree/v0.2.2

[Diff](/../../compare/v0.2.1...v0.2.2) | [Milestone](/../../milestone/30)

### Added

- UI:
    - Chat page:
        - Swipe to reply trackpad gesture. ([#1112], [#296])
        - Messages searching. ([#1116], [#692])
    - Chats tab:
        - Device being offline label. ([#1121], [#547])

### Changed

- UI:
    - Chat page:
        - File sizes displayed in B, KB, MB, GB or PB. ([#1115], [#603])

### Fixed

- UI:
    - Media panel:
        - Invalid diagonal window resize cursors on macOS. ([#1120], [#568])
    - Chats tab:
        - Deleted chats still displaying in list after mass clearing. ([#1133])
- Web:
    - Invalid camera, microphone and output device names in Firefox. ([#1117])

[#296]: /../../issues/296
[#547]: /../../issues/547
[#568]: /../../issues/568
[#603]: /../../issues/603
[#692]: /../../issues/692
[#1112]: /../../pull/1112
[#1115]: /../../pull/1115
[#1116]: /../../pull/1116
[#1117]: /../../pull/1117
[#1120]: /../../pull/1120
[#1121]: /../../pull/1121
[#1133]: /../../pull/1133




## [0.2.1] · 2024-09-12
[0.2.1]: /../../tree/v0.2.1

[Diff](/../../compare/v0.2.0...v0.2.1) | [Milestone](/../../milestone/29)

### Fixed

- UI:
    - Chat page:
        - Active call's duration not being refreshed every second. ([#1105])
    - Chats tab:
        - Restore button clipping chats on mobile platforms. ([#1108], [#758])
- Web:
    - Inability to input chat's name during group creation. ([#1103])

[#1103]: /../../pull/1103
[#1105]: /../../pull/1105
[#1108]: /../../pull/1108




## [0.2.0] · 2024-09-04
[0.2.0]: /../../tree/v0.2.0

[Diff](/../../compare/v0.1.4...v0.2.0) | [Milestone](/../../milestone/28)

### Added

- UI:
    - Support page:
        - Current version information. ([#1079], [#896])
    - Profile page:
        - Credentials confirmation of account deletion. ([#1086])
        - Welcome message. ([#1090], [#553])
        - Geolocation of active sessions. ([#1094], [#1005])
    - Auth page:
        - Signing up by login and password. ([#1087])
        - Signing in by one-time password sent to e-mail. ([#1089], [#555])

### Changed

- UI:
    - Chat page:
        - Updated messages color. ([#1069])
    - Upgrade popup:
        - Binary download progress being displayed on desktop platforms. ([#1079], [#896])
- iOS:
    - Better described microphone and camera usage prompts. ([#1066])

### Fixed

- UI:
    - Chat page:
        - Typing being infinitely displayed after focus is lost. ([#995], [#988])
        - Notes being duplicated when pressing on authorized user's name in chat. ([#1097], [#1083])
- Web:
    - Application becoming unresponsive when navigating back with gallery being opened. ([#1078], [#900])
    - [Progressive Web Application (PWA)][PWA] on iOS missing bottom safe area paddings. ([#1098], [#1015])
- Windows:
    - Application not launching due to `MSVCP140.dll` library being missing. ([#1070])

[#553]: /../../issues/553
[#555]: /../../issues/555
[#896]: /../../issues/896
[#900]: /../../issues/900
[#988]: /../../issues/988
[#995]: /../../pull/995
[#1005]: /../../issues/1005
[#1015]: /../../issues/1015
[#1066]: /../../pull/1066
[#1069]: /../../pull/1069
[#1070]: /../../pull/1070
[#1078]: /../../pull/1078
[#1079]: /../../pull/1079
[#1083]: /../../issues/1083
[#1086]: /../../pull/1086
[#1087]: /../../pull/1087
[#1089]: /../../pull/1089
[#1090]: /../../pull/1090
[#1094]: /../../pull/1094
[#1097]: /../../pull/1097
[#1098]: /../../pull/1098




## [0.1.4] · 2024-07-11
[0.1.4]: /../../tree/v0.1.4

[Diff](/../../compare/v0.1.3...v0.1.4) | [Milestone](/../../milestone/27)

### Fixed

- UI:
    - Selected language not persisting. ([#1055])

[#1055]: /../../pull/1055




## [0.1.3] · 2024-07-04
[0.1.3]: /../../tree/v0.1.3

[Diff](/../../compare/v0.1.0...v0.1.3) | [Milestone](/../../milestone/26)

### Changed

- UI:
    - Chat page:
        - Blurred previews under single images. ([#1057], [#985])

[#985]: /../../issues/985
[#1057]: /../../pull/1057




## [0.1.0] · 2024-06-27
[0.1.0]: /../../tree/v0.1.0

[Diff](/../../compare/v0.1.0-alpha.13.5...v0.1.0) | [Milestone](/../../milestone/24)

### Added

- UI:
    - Home page:
        - Link tab. ([#1012])
- Deep links. ([#1035], [#799])

### Changed

- UI:
    - Update available popup displaying critical updates. ([#973], [#896])
    - Home page:
        - Removed contacts tab. ([#1012])
        - Removed work with us tab. ([#1012])
    - Chat page:
        - Direct links in messages opening within application. ([#1012], [#800])

### Fixed

- Web:
    - Audio playback stopping when receiving or sending message on iOS. ([#1039], [#968])

[#799]: /../../issues/799
[#800]: /../../issues/800
[#896]: /../../issues/896
[#968]: /../../issues/968
[#973]: /../../pull/973
[#1012]: /../../pull/1012
[#1035]: /../../pull/1035
[#1039]: /../../pull/1039




## [0.1.0-alpha.13.5] · 2024-05-13
[0.1.0-alpha.13.5]: /../../tree/v0.1.0-alpha.13.5

[Diff](/../../compare/v0.1.0-alpha.13.4...v0.1.0-alpha.13.5) | [Milestone](/../../milestone/23)

### Added

- UI:
    - Profile page:
        - Connected devices list. ([#986], [#566])
    - Accounts switching. ([#975], [#312])
    - Auth page:
        - Kept accounts displaying. ([#992])

### Changed

- UI:
    - Chat page:
        - Redesigned avatar, name and link editing. ([#980], [#948])
    - User page:
        - Redesigned avatar and name editing. ([#980], [#948])
    - Profile page:
        - Redesigned avatar and link editing. ([#980], [#948])

### Fixed

- UI:
    - Home page:
        - Own avatar displaying with question marks when signing in or signing up. ([#978], [#950])
    - Chat page:
        - Tapping on image opens gallery when being in context menu. ([#983], [#979])

[#312]: /../../issues/312
[#566]: /../../issues/566
[#896]: /../../issues/896
[#948]: /../../issues/948
[#950]: /../../issues/950
[#973]: /../../pull/973
[#975]: /../../pull/975
[#978]: /../../pull/978
[#979]: /../../issues/979
[#980]: /../../pull/980
[#983]: /../../pull/983
[#986]: /../../pull/986
[#992]: /../../pull/992




## [0.1.0-alpha.13.4] · 2024-04-23
[0.1.0-alpha.13.4]: /../../tree/v0.1.0-alpha.13.4

[Diff](/../../compare/v0.1.0-alpha.13.3...v0.1.0-alpha.13.4) | [Milestone](/../../milestone/22)

### Added

- UI:
    - Support page. ([#971])

### Changed

- UI:
    - Home page:
        - Contacts button moved to chats tab app bar. ([#970])
    - Auth page:
        - Redesigned footer. ([#971])
    - Work page:
        - Removed UI/UX designer vacancy. ([#971])

[#970]: /../../pull/970
[#971]: /../../pull/971




## [0.1.0-alpha.13.3] · 2024-04-19
[0.1.0-alpha.13.3]: /../../tree/v0.1.0-alpha.13.3

[Diff](/../../compare/v0.1.0-alpha.13.2...v0.1.0-alpha.13.3) | [Milestone](/../../milestone/21)

### Added

- UI:
    - Account deletion page. ([#961])
    - "Terms and conditions" page. ([#961])
    - "Privacy policy" page. ([#961])

### Fixed

- UI:
    - Chats tab:
        - Dialogs missing their avatars in some cases. ([#967], [#964])

[#961]: /../../pull/961
[#964]: /../../issues/964
[#967]: /../../pull/967




## [0.1.0-alpha.13.2] · 2024-04-11
[0.1.0-alpha.13.2]: /../../tree/v0.1.0-alpha.13.2

[Diff](/../../compare/v0.1.0-alpha.13.1...v0.1.0-alpha.13.2) | [Milestone](/../../milestone/20)

### Fixed

- UI:
    - Chat page:
        - Active and ended calls displaying invalid duration. ([#944])

[#944]: /../../pull/944




## [0.1.0-alpha.13.1] · 2024-04-10
[0.1.0-alpha.13.1]: /../../tree/v0.1.0-alpha.13.1

[Diff](/../../compare/v0.1.0-alpha.13...v0.1.0-alpha.13.1) | [Milestone](/../../milestone/19)

### Changed

- UI:
    - Home page:
        - Redesigned app bar. ([#942], [#939])

[#939]: /../../issues/939
[#942]: /../../pull/942




## [0.1.0-alpha.13] · 2024-04-09
[0.1.0-alpha.13]: /../../tree/v0.1.0-alpha.13

[Diff](/../../compare/v0.1.0-alpha.12.3...v0.1.0-alpha.13) | [Milestone](/../../milestone/18)

### Added

- UI:
    - Media panel:
        - Call ended sound and left alone in group call sound. ([#877], [#809])
        - Member connected sound. ([#935], [#928])
    - Update available popup. ([#907], [#896])
    - Work page:
        - UI/UX designer vacancy. ([#941])

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
    - Home page:
        - Alarm sound when clicking on empty right space. ([#937])
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
[#928]: /../../issues/928
[#934]: /../../pull/934
[#935]: /../../pull/935
[#937]: /../../pull/937
[#941]: /../../pull/941




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




[CallKit]: https://developer.apple.com/documentation/callkit/
[ConnectionService]: https://developer.android.com/reference/android/telecom/ConnectionService
[Helm]: https://helm.sh
[PWA]: https://en.wikipedia.org/wiki/Progressive_web_app
[Semantic Versioning 2.0.0]: https://semver.org
[VoIP]: https://wikipedia.org/wiki/Voice_over_IP
