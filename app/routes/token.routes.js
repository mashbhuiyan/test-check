const tokensController = require('../controllers/tokens_controller');
const AdminAuthentication = require('../middlewares/admin_auth.middleware');

module.exports = (router) => {
    router.get('/tokens', AdminAuthentication, tokensController.index);
    router.post('/tokens/create', AdminAuthentication, tokensController.create);
    router.get('/tokens/:id/edit', AdminAuthentication, tokensController.edit);
    router.post('/tokens/:id/update', AdminAuthentication, tokensController.update);
    router.delete('/tokens/:id/delete', AdminAuthentication, tokensController.destroy);
}
