const authController = require('../controllers/auth_controller');
const NoAuthentication = require('../middlewares/no_auth.middleware');
const passport = require('passport');

module.exports = (router) => {
    router.get('/login', NoAuthentication, authController.new);
    router.post('/create_session', passport.authenticate('local',{
        failureRedirect: '/login'
    }), function(req, res) {
        let redirectTo = '/';
        if (req.app.locals.reqUrl) {
            redirectTo = req.app.locals.reqUrl;
            req.app.locals.reqUrl = null;
        }

        res.redirect(redirectTo);
    });
    router.post('/logout', authController.logout);
    router.get('/two_factor', authController.two_factor);
}