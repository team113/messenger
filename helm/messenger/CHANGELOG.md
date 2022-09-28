`messenger` Helm chart changelog
================================

All user visible changes to this project will be documented in this file. This project uses [Semantic Versioning 2.0.0].




## [0.1.0] · 2022-09-28
[0.1.0]: https://github.com/team113/messenger/tree/helm/messenger/0.1.0

### Added

- `Service` with `messenger` and optional `sftp` containers ([#73]).
- `Ingress` with: ([#73])
    - `/` prefix pointing to `messenger` container.
    - `tls.auto` capabilities.
    - Handling optional `www.` domain part.
- Ability to specify application's configuration ([#73]).

[#73]: https://github.com/team113/messenger/pull/73




[Semantic Versioning 2.0.0]: https://semver.org
