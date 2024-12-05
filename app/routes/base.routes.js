const apiV1BaseApiRoutes = require('./api/v1/base.routes');
const apiV2BaseApiRoutes = require('./api/v2/base.routes');
const homeRoutes = require('./home.routes');
const tokenRoutes = require('./token.routes');
const authRoutes = require('./auth.routes');
const adminRoutes = require('./admin_user.routes');
const partnerRoutes = require('./partner.routes');

module.exports = (router) => {
    apiV1BaseApiRoutes(router);
    apiV2BaseApiRoutes(router);
    homeRoutes(router);
    tokenRoutes(router);
    authRoutes(router);
    adminRoutes(router);
    partnerRoutes(router);
}
