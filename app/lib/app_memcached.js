const Memcached = require("memcached-promise");

class AppMemcached {
    constructor() {
        throw new Error('Use AppMemcached.getInstance()');
    }

    static getInstance() {
        if (!AppMemcached.instance) {
            AppMemcached.instance = new Memcached(process.env.MEMCACHED_URI, {
                namespace: 'iia',
                timeout: 100,
                retries: 1,
                remove: true
            });
        }
        return AppMemcached.instance;
    }
}

module.exports = AppMemcached;
