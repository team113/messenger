`messenger` Helm chart changelog
================================

All user visible changes to this project will be documented in this file. This project uses [Semantic Versioning 2.0.0].




## [0.1.2] · 2024-04-19
[0.1.2]: https://github.com/team113/messenger/tree/helm%2Fmessenger%2F0.1.2/helm/messenger

### Added

- `/privacy` and `/terms` URI paths to [Nginx] configuration. ([#961])

[#961]: https://github.com/team113/messenger/pull/961




## [0.1.1] · 2024-01-29
[0.1.1]: https://github.com/team113/messenger/tree/helm%2Fmessenger%2F0.1.1/helm/messenger

### Fixed

- `copy-src` init container not copying hidden files. ([#818])

[#818]: https://github.com/team113/messenger/pull/818




## [0.1.0] · 2022-09-28
[0.1.0]: https://github.com/team113/messenger/tree/helm%2Fmessenger%2F0.1.0/helm/messenger

### Added

- `Service` with `messenger` and optional `sftp` containers. ([#73])
- `Ingress` with: ([#73])
    - `/` prefix pointing to `messenger` container.
    - `tls.auto` capabilities.
    - Handling optional `www.` domain part.
- Ability to specify application's configuration. ([#73])

[#73]: https://github.com/team113/messenger/pull/73




[Nginx]: https://nginx.org
[Semantic Versioning 2.0.0]: https://semver.org
