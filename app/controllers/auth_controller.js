require('../models/admin_user');
// const mongoose = require('mongoose');
// const AdminUser = mongoose.model('AdminUser');
// const passport = require('passport');

module.exports.new = function (req, res) {
    // console.log(req);
    // use this to create your first user for login
    // const adminUser = new AdminUser();
    // adminUser.name = 'AdminUser';
    // adminUser.email = 'adminuser@example.com';
    // adminUser.setPassword('smart4321');
    // adminUser.save();
    
    let two_factor = null;
    if (req.session.two_factor) {
        two_factor = req.session.two_factor;
        req.session.two_factor = null;
    }
    res.render('auth/login', {error: getErrorMessage(req, res), two_factor});
}

module.exports.two_factor = function (req, res) {
    if (req.session.two_factor) {
        res.render('auth/login', {error: getErrorMessage(req, res)});
        res.redirect('/two_factor');
    } else {
        res.render('auth/login', {error: getErrorMessage(req, res)});
    }
}

// module.exports.login = function (req, res) {
//     passport.authenticate('local', (err, adminUser, info) => {
//         if (err) {
//             res.redirect('/login');
//             return;
//         }
//
//         if (adminUser) {
//             // req.session.passport = {
//             //     user: {id: adminUser.id, email: adminUser.email, name: adminUser.name}
//             // }
//             res.redirect('/');
//         } else {
//             res.redirect('/login');
//         }
//     })(req, res);
// }

module.exports.logout = function (req, res, next) {
    req.logout((err) => {
        if (err) {
            return next(err);
        }
        res.redirect('/');
    });
}

function getErrorMessage(req) {
    let error;
    if (req.session.error) {
        error = req.session.error;
        req.session.error = null;
    }
    return error;
}
