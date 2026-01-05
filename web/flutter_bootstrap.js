// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

{{flutter_js}}
{{flutter_build_config}}

// Add `?v=` tag to `main.dart.js` file with service worker version to ensure
// the file is re-fetched from the network on the changes.
_flutter.buildConfig.builds[0].mainJsPath +=
    "?v=" + '{{flutter_service_worker_version}}';

_flutter.loader.load({
    serviceWorker: {
        serviceWorkerVersion: '{{flutter_service_worker_version}}'
    },
    onEntrypointLoaded: async function (engineInitializer) {
        try {
            await window.jasonLoaded;
        } catch (e) {
            console.error(e);
        }

        const appRunner = await engineInitializer.initializeEngine();
        await appRunner.runApp();
    }
});
