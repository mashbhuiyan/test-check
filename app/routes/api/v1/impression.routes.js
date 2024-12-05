const impressionCtrl = require('../../../controllers/api/v1/impressions_controller');
const BrandDbConnection = require('../../../middlewares/brand_db_connection.middleware');

module.exports = (router, api_base) => {
    router.get(`${api_base}/click_listing/:id/impression`, BrandDbConnection, impressionCtrl.pixel);
}
