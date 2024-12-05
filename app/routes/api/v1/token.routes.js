const tokensController = require('../../../controllers/api/v1/tokens_controller');
const TokenAuthentication = require('../../../middlewares/token_auth.middleware');
const AdminAuthentication = require("../../../middlewares/admin_auth.middleware");

module.exports = (router, api_base) => {
    router.get(`${api_base}/tokens`, TokenAuthentication.read, tokensController.index);
    router.post(`${api_base}/tokens/create`, TokenAuthentication.write, tokensController.create);
    router.post(`${api_base}/tokens/update_use_replica`, TokenAuthentication.write, tokensController.update_use_replica);
    router.post(`${api_base}/tokens/:id/update`, TokenAuthentication.write, tokensController.update);
    router.delete(`${api_base}/tokens/:id/delete`, TokenAuthentication.write, tokensController.delete);
}
