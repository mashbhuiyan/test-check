const passport = require('passport');
const LocalStrategy = require('passport-local').Strategy;
const mongoose = require('mongoose');
const { authenticator } = require('otplib');
const AdminUser = mongoose.model('AdminUser');

passport.use(new LocalStrategy({usernameField: 'email', passReqToCallback: true},
    (req, username, password, done) => {
        AdminUser.findOne({email: username}, (err, adminUser) => {
            if (err) {
                req.session.error = err.message;
                return done(err);
            }
            if (!adminUser) {
                req.session.error = 'User not found';
                return done(null, false, { message: 'User not found' });
            }
            if (!adminUser.validPassword(password)) {
                req.session.error = 'Password does not match';
                return done(null, false, { message: 'Password does not match' });
            }
            if (adminUser.enabled_2fa) {
                if (req.body.otp_code) {
                    if (!authenticator.check(req.body.otp_code, adminUser.otp_secret)) {
                        req.session.two_factor = { username, password };
                        req.session.error = 'Invalid OTP or OTP expired. Please try again.';
                        return done(null, false, { message: 'Invalid OTP or OTP expired. Please try again.' });
                    }
                } else {
                    req.session.two_factor = { username, password };
                    req.session.error = 'Please verify with OTP';
                    return done(null, false, { message: 'Please verify with OTP' });
                }
            }
            req.app.locals.user = {name: adminUser.name, email: adminUser.email};
            return done(null, adminUser);
        })
    }));

passport.serializeUser(function (user, done) {
    done(null, {id: user._id, email: user.email, name: user.name});
});

passport.deserializeUser((adminUser, done) => {
    done(null, adminUser);
})
