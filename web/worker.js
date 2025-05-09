onconnect = function (e) {
    var port = e.ports[0];
    port.postMessage('Hello World!');
    port.onmessage = function (e) {
        try {
            var data = JSON.parse(e.data);

            if (data.type == 'lock') {
                navigator.locks.request('test-lock', async function () {
                    port.postMessage("first ping");
                    await timeout(5000);
                    port.postMessage("second ping");
                });
            } else if (data.type == 'message') {
                port.postMessage(`received message from worker: ${data}`);
            } else {
                port.postMessage(`received JSON from worker: ${data}`);
            }
        } catch (_) {
            port.postMessage(`received data from worker: ${e.data}`);
        }
    };

    var before = Date.now();
    setInterval(() => {
        var now = Date.now();

        if (now - before >= 2500) {
            port.postMessage(`difference -> ${now - before} ms -> INACTIVE`);
        } else {
            port.postMessage(`difference -> ${now - before} ms`);
        }

        before = now;
    }, 2000);
}

function timeout(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
