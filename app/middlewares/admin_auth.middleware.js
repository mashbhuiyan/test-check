module.exports = AdminAuthentication = (req, res, next) => {
    if (req.isAuthenticated()) {
        return next();
    }
    req.app.locals.reqUrl = req.originalUrl;
    res.status(401);
    res.redirect("/login");
};
