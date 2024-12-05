const clickRoutes = require('./click.routes');
const tokenRoutes = require('./token.routes');
const clickIntegration = require('./click_integration.routes');
const clickImpression = require('./impression.routes');
const leadRoutes = require('./lead.routes');
const callRoutes = require('./call.routes');
const publicController = require("../../../controllers/api/v1/public_controller");
const BrandDbConnection = require('../../../middlewares/brand_db_connection.middleware');

const api_brand = '/api/v1/:brand?'
module.exports = (router) => {
    clickRoutes(router, api_brand);
    tokenRoutes(router, api_brand);
    clickIntegration(router, api_brand);
    clickImpression(router, api_brand);
    leadRoutes(router, api_brand);
    callRoutes(router, api_brand);
    router.get(`${api_brand}/status`, BrandDbConnection, publicController.status_checker);
}
