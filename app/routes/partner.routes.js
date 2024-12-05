const partnersController = require('../controllers/partners_controller');
const AdminAuthentication = require('../middlewares/admin_auth.middleware');

module.exports = (router) => {
    router.get('/partners', AdminAuthentication, partnersController.index);
    router.get('/partners/new', AdminAuthentication, partnersController.new);
    router.post('/partners/create', AdminAuthentication, partnersController.create);
    router.get('/partners/:id/edit', AdminAuthentication, partnersController.edit);
    router.post('/partners/:id/update', AdminAuthentication, partnersController.update);
    router.delete('/partners/:id/delete', AdminAuthentication, partnersController.destroy);
}