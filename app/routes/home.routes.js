const homeController = require('../controllers/home_controller');
const AdminAuthentication = require('../middlewares/admin_auth.middleware');

module.exports = (router) => {
    router.get('/', AdminAuthentication, homeController.index);
    router.get('/reports', AdminAuthentication, homeController.getReports);
    router.get('/:log_type/debug', AdminAuthentication, homeController.debug);
    router.get('/:log_type/debug/:id', AdminAuthentication, homeController.debug_details);
    router.get('/activity-log', AdminAuthentication, homeController.activity_log);
    router.get('/clear-activity-log', homeController.clear_activity_log);
    router.get('/activity-log-detail/:id', AdminAuthentication, homeController.activity_log_detail);
    router.get('/:log_type/ping/:id', AdminAuthentication, homeController.click_ping);
}
