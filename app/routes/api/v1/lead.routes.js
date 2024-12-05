const leadsController = require('../../../controllers/api/v1/leads_controller');
const TokenAuthentication = require('../../../middlewares/token_auth.middleware');
const StrongParams = require('../../../middlewares/lead_strong_params.middleware');
const BrandDbConnection = require('../../../middlewares/brand_db_connection.middleware');

module.exports = (router, api_base) => {
    router.post(`${api_base}/leads/ping`, [BrandDbConnection, TokenAuthentication.read, StrongParams], leadsController.ping);
    router.post(`${api_base}/leads/post`, [BrandDbConnection, TokenAuthentication.write, StrongParams], leadsController.post);
}
