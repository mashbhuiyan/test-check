const NodeCache = require('node-cache');
const appCache = new NodeCache();
const AppMemcached = require("../../../lib/app_memcached");

const statusCodes = {
    working: 1,
    hard_failed: 2,
    soft_failed: 3,
    soft_failed_informational: 4,
    soft_failed_degradation: 5
}

module.exports.status_checker = async function (req, res) {
    let response = statusCheckerResponse('client-api', 'Client API Portal')
    response = await checkDbStatus(req.brand_conf.db, response);

    if (response.status === statusCodes.working) {
        await checkMemcachedStatus(response, res);
    }
}

function checkDbStatus(db, response) {
    return db.query('SELECT NOW()').then(() => {
        return response;
    }, error => {
        return setErrorResponse(response, statusCodes.hard_failed, error.message);
    });
}

async function checkMemcachedStatus(response, res) {
    try {
        const memcached = AppMemcached.getInstance();
        await memcached.set('test', 'test', 60);
        const testData = await memcached.get('test');
        if (testData !== 'test') {
            response = setErrorResponse(response, statusCodes.soft_failed, 'Memcached not working.');
        } else {
            response = checkNodeCacheStatus(response);
        }
        res.status(200).json(response);
    } catch (ex) {
        response = setErrorResponse(response, statusCodes.soft_failed, `Memcached Error: ${ex.message}`);
        res.status(200).json(response);
    }
}

function checkNodeCacheStatus(response) {
    try {
        appCache.set('test', 'test');
        if (appCache.get('test') !== 'test') {
            return setErrorResponse(response, statusCodes.soft_failed, 'In-Memory Cache not working');
        }
    } catch (e) {
        return setErrorResponse(response, statusCodes.soft_failed, e.message);
    }
    return response;
}

function statusCheckerResponse(api, description) {
    return {
        api,
        description,
        status: statusCodes.working,
        message: 'Service is operating normally',
        updated_at: new Date().toISOString()
    }
}

function setErrorResponse(response, status, message) {
    response.status = status;
    response.message = message;
    return response;
}
