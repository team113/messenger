Change Log
==========

All user visible changes to this project will be documented in this file. This project uses to [Semantic Versioning 2.0.0].




## [0.2.0] · 2026-01-21
[0.2.0]: /../../tree/v0.2.0

[Diff](/../../compare/v0.1.0...v0.2.0) | [Milestone](/../../milestone/2)

### Added

- UI:
    - Media panel:
        - Reconnecting notifications when network changes in call. ([team113/messenger#1581])
    - Chat page:
        - Logs button in notes and support chats. ([#12])

### Fixed

- UI:
    - Media panel:
        - Infinite vibration when ringing pending calls on iOS and Android. ([team113/messenger#1580])
        - Connection not being reconnected on network changes on Web. ([team113/messenger#1581])
        - Own camera or recipient's video sometimes not being rendered. ([team113/messenger#1582])
        - Raised hand appearing on display demonstrations. ([team113/messenger#1584])

[#12]: /../../pull/12
[team113/messenger#1580]: https://github.com/team113/messenger/pull/1580
[team113/messenger#1581]: https://github.com/team113/messenger/pull/1581
[team113/messenger#1582]: https://github.com/team113/messenger/pull/1582
[team113/messenger#1584]: https://github.com/team113/messenger/pull/1584




## [0.1.0] · 2026-01-15
[0.1.0]: /../../tree/v0.1.0

[Diff](/../../compare/70ddb0e8375b57f9c1d8f5d69f9e25407915bc34...v0.1.0) | [Milestone](/../../milestone/1)

### Added

- UI:
    - Home page:
        - Wallet and monetization tabs. ([#2])
    - Wallet tab:
        - Top up and transactions pages. ([#4])
    - Monetization tab:
        - Partner programs and your promotion pages. ([#4])
        - Set your prices, transactions and withdrawal pages. ([#5])
    - Support chat. ([#6])
- Deployment:
    - [Helm] chart. ([#1])

[#1]: /../../pull/1
[#2]: /../../pull/2
[#4]: /../../pull/4
[#5]: /../../pull/5
[#6]: /../../pull/6




[Helm]: https://helm.sh
[Semantic Versioning 2.0.0]: https://semver.org
