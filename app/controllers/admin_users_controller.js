require('../models/admin_user');
const mongoose = require('mongoose');
const AdminUser = mongoose.model('AdminUser');
const { authenticator } = require('otplib');
const qrcode = require("qrcode");

module.exports.index = function (req, res) {
    const page = parseInt(req.query.page || 1);
    const limit = 10;
    const skip = limit * (page - 1);
    AdminUser.find({}).sort({createdAt: -1}).limit(limit).skip(skip).then(async adminUsers => {
        const count = await AdminUser.count({});
        const pageCount = parseInt(Math.ceil(count / limit));
        res.status(200);
        res.render('admin_users/index', { adminUsers, page, pageCount, error: getErrorMessage(req) });
    });
}

module.exports.new = function (req, res) {
    res.render('admin_users/new', { adminUser: new AdminUser(), error: getErrorMessage(req) });
}

module.exports.create = function (req, res) {
    const adminUser = new AdminUser();
    adminUser.name = req.body.name;
    adminUser.email = req.body.email;
    adminUser.setPassword(req.body.password);
    adminUser.setOtpSecret();
    adminUser.save((err, newAdminUser) => {
        if (err) {
            res.render('admin_users/new', { adminUser, error: err.message });
        } else {
            res.redirect('/admin_users');
        }
    });
}

module.exports.edit = function (req, res) {
    AdminUser.findById(req.params.id, (err, adminUser) => {
        if (err) {
            res.redirect('/admin_users', { error: err.message });
        } else {
            res.render('admin_users/edit', { adminUser, error: getErrorMessage(req) });
        }
    });
}

module.exports.update = function (req, res) {
    AdminUser.findById(req.params.id, (err, adminUser) => {
        if (err) {
            res.redirect('/admin_users', { error: err.message });
            return;
        }

        adminUser.name = req.body.name;
        adminUser.email = req.body.email;
        if (req.body.password) {
            adminUser.setPassword(req.body.password);
        }
        adminUser.save((error, savedAdminUser) => {
            if (error) {
                res.render('admin_users/edit', { adminUser , error: error.message });
            } else {
                res.redirect('/admin_users');
            }
        });
    });
}

module.exports.delete = function (req, res) {
    AdminUser.findById(req.params.id, (err, adminUser) => {
        if (err || !adminUser) {
            res.redirect('/admin_users');
            return;
        }

        adminUser.remove(() => {
            res.redirect('/admin_users');
        });
    })
}

module.exports.two_factor = function (req, res) {
    AdminUser.findOne({_id: req.user.id}).then((adminUser) => {
        if (adminUser) {
            if (adminUser.otp_secret) {
                render2fa(adminUser, req, res);
            } else {
                adminUser.setOtpSecret();

                adminUser.save(function (err) {
                    if (err) {
                        errorResponse(req, res, err.message, '/admin_users')
                    } else {
                        render2fa(adminUser, req, res);
                    }
                });
            }
        } else {
            errorResponse(req, res, 'Admin User not found', '/admin_users')
        }
    });
};

function render2fa(adminUser, req, res) {
    const secretUri = authenticator.keyuri(adminUser.email, 'ClientAPI', adminUser.otp_secret);

    qrcode.toDataURL(secretUri, (err, src) => {
        if (err) {
            req.session.error = err.message;
            res.redirect('/admin_users');
        } else {
            res.render('admin_users/two_factor', { adminUser , src });
        }
    });
}

module.exports.update_2fa = function (req, res) {
    AdminUser.findOne({_id: req.user.id})
        .then(adminUser => {
            if (adminUser) {
                if (req.body.refresh) {
                    adminUser.setOtpSecret();
                    userSaveWithResponse(adminUser, req, res);
                } else if (authenticator.check(req.body.otp_code, adminUser.otp_secret)) {
                    adminUser.enabled_2fa = !adminUser.enabled_2fa;
                    userSaveWithResponse(adminUser, req, res);
                } else {
                    errorResponse(req, res, 'Invalid OTP');
                }
            } else {
                errorResponse(req, res, 'Admin User not found');
            }
        });
};

module.exports.disable_2fa = function (req, res) {
    AdminUser.findOne({_id: req.params.id})
        .exec(function (err, adminUser) {
            adminUser.enabled_2fa = false;

            adminUser.save(function (err) {
                if (err) {
                    errorResponse(req, res, err.message, '/admin_users');
                } else {
                    userResponse(res, '/admin_users');
                }
            });
        });
};

function userSaveWithResponse(adminUser, req, res) {
    adminUser.save(function (err, usr) {
        if (err) {
            errorResponse(req, res, 'Unable to update information. Please try again later.');
        } else {
            userResponse(res);
        }
    });
}

function errorResponse(req, res, message, redirectTo = '/admin_users/two_factor') {
    req.session.error = message;
    userResponse(res, redirectTo);
}

function userResponse(res, redirectTo = '/admin_users/two_factor') {
    res.redirect(redirectTo);
}

function getErrorMessage(req) {
    let error;
    if (req.session.error) {
        error = req.session.error;
        req.session.error = null;
    }
    return error;
}
