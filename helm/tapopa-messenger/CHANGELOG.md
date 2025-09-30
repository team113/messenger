`tapopa-messenger` Helm chart changelog
=======================================

All user visible changes to this project will be documented in this file. This project uses [Semantic Versioning 2.0.0].




## [0.1.0] · 2025-??-??
[0.1.0]: https://github.com/tapopa/messenger/tree/helm%2Ftapopa-messenger%2F0.1.0/helm/tapopa-messenger

### Added

- `Service` with `tapopa-messenger` and optional `sftp` containers. ([#1])
- `Ingress` with: ([#1])
    - `/` prefix pointing to `tapopa` container.
    - `tls.auto` capabilities.
    - Handling optional `www.` domain part.
- Ability to specify application's configuration. ([#1])

[#1]: https://github.com/tapopa/messenger/pull/1




[Semantic Versioning 2.0.0]: https://semver.org
