module.exports = PartnerAuthentication = (req, res, next) => {
    if (req.isAuthenticated()) {
        return next();
    }

    if (req.query.auth_token && req.query.auth_token === process.env.API_DOC_AUTH_TOKEN) {
        return next();
    }
    req.app.locals.reqUrl = req.originalUrl;
    res.status(401);
    res.redirect("/login");
};
