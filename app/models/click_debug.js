const mongoose = require('mongoose');
const timestamps = require('mongoose-timestamp');

const clickDebug = new mongoose.Schema({
    initial: String,
    exclusions: String,
    token_multiplier: String,
    source_multiplier: String,
    schedule_multiplier: String,
    modifier_group: String,
    failed_filter: String,
    click_ping_id: String,
});

clickDebug.plugin(timestamps);

mongoose.model('ClickDebug', clickDebug);
