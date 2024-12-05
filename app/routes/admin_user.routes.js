const adminUsersController = require('../controllers/admin_users_controller');
const AdminAuthentication = require('../middlewares/admin_auth.middleware');

module.exports = (router) => {
    router.get('/admin_users', AdminAuthentication, adminUsersController.index);
    router.get('/admin_users/new', AdminAuthentication, adminUsersController.new);
    router.post('/admin_users/create', AdminAuthentication, adminUsersController.create);
    router.get('/admin_users/:id/edit', AdminAuthentication, adminUsersController.edit);
    router.post('/admin_users/:id/update', AdminAuthentication, adminUsersController.update);
    router.delete('/admin_users/:id/delete', AdminAuthentication, adminUsersController.delete);
    router.get('/admin_users/two_factor', AdminAuthentication, adminUsersController.two_factor);
    router.post('/admin_users/update_2fa', AdminAuthentication, adminUsersController.update_2fa);
    router.post('/admin_users/:id/disable_2fa', AdminAuthentication, adminUsersController.disable_2fa);
}