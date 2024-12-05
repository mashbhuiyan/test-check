const mongoose = require('mongoose');
const timestamps = require('mongoose-timestamp');
const crypto = require('crypto');
const { authenticator } = require('otplib');

const adminUserSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    email: {
        type: String,
        unique: true,
        required: true
    },
    password: String,
    salt: String,
    otp_secret: { type: String, unique: true, sparse: true },
    enabled_2fa: { type: Boolean, default: false }
})

adminUserSchema.plugin(timestamps);

adminUserSchema.methods.setPassword = function(password) {
    if (!this.salt) {
        this.salt = crypto.randomBytes(16).toString('hex');
    }
    this.password = crypto.pbkdf2Sync(password, this.salt, 1000, 64, 'sha512').toString('hex');
};

adminUserSchema.methods.validPassword = function(password) {
    const hash = crypto.pbkdf2Sync(password, this.salt, 1000, 64, 'sha512').toString('hex');
    return this.password === hash;
};

adminUserSchema.methods.setOtpSecret = function() {
    this.otp_secret = authenticator.generateSecret();
};

mongoose.model('AdminUser', adminUserSchema);
