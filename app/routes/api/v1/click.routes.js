const clicksController = require('../../../controllers/api/v1/clicks_controller');
const TokenAuthentication = require('../../../middlewares/token_auth.middleware');
const StrongParams = require('../../../middlewares/click_strong_params.middleware');
const BrandDbConnection = require('../../../middlewares/brand_db_connection.middleware');
const CustomSourceSettings = require('../../../middlewares/custom_source_settings.middleware');

module.exports = (router, api_base) => {
    // router.post('/api/v1/clicks', TokenAuthentication, clicksController.index);
    router.post(`${api_base}/clicks`, [BrandDbConnection, TokenAuthentication.read, CustomSourceSettings.custom_source, StrongParams], clicksController.index);
    // router.post(`${api_base}/clicks`, [BrandDbConnection, TokenAuthentication.read, StrongParams], clicksController.index);
    router.post(`${api_base}/clicks/:click_listing_id/events`, [BrandDbConnection, TokenAuthentication.write], clicksController.events);
    router.post(`${api_base}/clicks/:click_listing_id/post`, [BrandDbConnection, TokenAuthentication.write], clicksController.post);
}
