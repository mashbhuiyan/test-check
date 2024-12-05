const clicksController = require('../../../controllers/api/v2/clicks_controller');
const TokenAuthentication = require('../../../middlewares/token_auth.middleware');
const StrongParams = require('../../../middlewares/click_strong_params.middleware');
const BrandDbConnection = require('../../../middlewares/brand_db_connection.middleware');
const CustomSourceSettings = require('../../../middlewares/custom_source_settings.middleware');

module.exports = (router, api_base) => {
    router.post(`${api_base}/clicks`, [BrandDbConnection, TokenAuthentication.read, CustomSourceSettings.custom_source, StrongParams], clicksController.index);
}
