const mongoose = require('mongoose');
const timestamps = require('mongoose-timestamp');

const logSchema = new mongoose.Schema({
    url: String,
    http_version: String,
    referrer: String,
    request_method: String,
    ip: String,
    user_agent: String,
    access_token: String,
    status: Number,
    request_header: mongoose.Schema.Types.Mixed,
    response_header: mongoose.Schema.Types.Mixed,
    request_query: mongoose.Schema.Types.Mixed,
    request_body: mongoose.Schema.Types.Mixed,
    response_data: mongoose.Schema.Types.Mixed,
    response_time: Number,
    lead_type_id: Number
});

logSchema.plugin(timestamps);

mongoose.model('RequestLog', logSchema);
