const crypto = require('crypto');
const mongoose = require('mongoose');
const timestamps = require('mongoose-timestamp');

const tokenSchema = new mongoose.Schema({
    label: String,
    access_token: String,
    access_level: {type: String, default: 'read', enum: ['read', 'write']},
    type: {type: String, default: 'generic', enum: ['generic', 'admin']},
    request_limit: {
        type: Number,
        min: 1,
        get: v => v ? Math.round(v) : v,
        set: v => v ? Math.round(v) : v
    },
    request_period: {
        type: Number,
        min: 1,
        get: v => v ? Math.round(v) : v,
        set: v => v ? Math.round(v) : v,
        required: function () {
            return this.request_limit >= 1;
        }
    },
    active: {type: Boolean, default: true},
    whitelisted_ips: [],
    campaign_bid_multipliers: {
        type: [{
            campaign_id: {type: Number, required: true},
            multiplier: {type: Number, required: true}
        }]
    },
    project_id: Number,
    schema_validation_required: {type: Boolean, default: true},
    transfer_types: {type: [Number], default: [], enum: [0, 1, 2]}, // 0=>Cold, 1=>Blind, 2=>Warm
    call_origination_type: {type: Number, enum: [1, 2]}, // 1=>Inbound, 2=>Outbound
    brands: {
        type: [String],
        default: [],
        enum: ['smartfinancial', 'usha', 'insuranceagents', 'goal', 'smartfinancial_pro']
    },
    use_replica: {type: Boolean, default: true}
})

tokenSchema.plugin(timestamps);

tokenSchema.statics.generateToken = () => {
    return crypto.randomBytes(64).toString('hex') + new Date().getMilliseconds().toFixed();
}

tokenSchema.methods.assignWhitelistedIPs = function (whitelistedIPs) {
    // console.log('whitelistedIPs: ', whitelistedIPs);
    if (whitelistedIPs) {
        this.whitelisted_ips = whitelistedIPs.split(',').map((whitelistIP) => {
            return whitelistIP.trim();
        });
    } else if (whitelistedIPs !== undefined) {
        this.whitelisted_ips = [];
    }
}

mongoose.model('Token', tokenSchema);
