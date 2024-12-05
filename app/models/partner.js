const mongoose = require('mongoose');
const timestamps = require('mongoose-timestamp');
const crypto = require("crypto");

const partnerSchema = new mongoose.Schema({
    name: { type: String, required: true },
    email: String,
    phone: String,
    module: { type: String, required: true },
    active: { type: Boolean, default: true },
    timeout: { type: Number, default: 7000, required: true }
});

partnerSchema.plugin(timestamps);

mongoose.model('Partner', partnerSchema);
