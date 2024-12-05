const callsController = require('../../../controllers/api/v1/calls_controller');
const TokenAuthentication = require('../../../middlewares/token_auth.middleware');
const StrongParams = require('../../../middlewares/call_strong_params.middleware');
const BrandDbConnection = require('../../../middlewares/brand_db_connection.middleware');

module.exports = (router, api_base) => {
    router.post(`${api_base}/calls/ping`, [BrandDbConnection, TokenAuthentication.read, StrongParams], callsController.ping);
    router.post(`${api_base}/calls/availability`, [TokenAuthentication.read], callsController.availability);
    router.post(`${api_base}/calls/brand_availability`, [BrandDbConnection, TokenAuthentication.read], callsController.brand_availability);
    router.post(`${api_base}/calls/post`, [BrandDbConnection, TokenAuthentication.write, StrongParams], callsController.post);
    router.post(`${api_base}/calls/:call_listing_id/events`, [BrandDbConnection, TokenAuthentication.write], callsController.events);
}
