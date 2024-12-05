module.exports = function (time_ms = 500) {
    return new Promise(resolve =>
        setTimeout(() => resolve('success'), time_ms),
    );
}
