{{flutter_js}}
{{flutter_build_config}}

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
