onmessage = function (e) {
    postMessage(`received message from worker: ${e}`);
};
