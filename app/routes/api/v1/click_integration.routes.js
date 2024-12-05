const clickIntegrationCtrl = require('../../../controllers/api/v1/click_integrations_controller');
const TokenAuthentication = require('../../../middlewares/token_auth.middleware');
const BrandDbConnection = require('../../../middlewares/brand_db_connection.middleware');

module.exports = (router, api_base) => {
    router.post(`${api_base}/click_integration/:partner_id`, [BrandDbConnection, TokenAuthentication.read], clickIntegrationCtrl.create);
    router.get(`${api_base}/click/:click_listing_id/track`, BrandDbConnection, clickIntegrationCtrl.click_track);
    router.get(`${api_base}/click/:click_listing_id/track/:partner_id`, BrandDbConnection, clickIntegrationCtrl.click_static_track);
    router.get(`${api_base}/partner_integration`, [BrandDbConnection, TokenAuthentication.read], clickIntegrationCtrl.partner_integration);
    router.post(`${api_base}/partners/:partner_id/integration`, [BrandDbConnection, TokenAuthentication.read], clickIntegrationCtrl.test_partner_integration);
}
