const mongoose = require('mongoose');
require('../models/request_log');

const DotEnv = require('dotenv')
const Fs = require("fs");
const envr = DotEnv.parse(Fs.readFileSync('../../.env'));

async function clearLog() {
    await mongoose.connect(envr.MONGODB_URI);
    const RequestLog = mongoose.model('RequestLog');
    const d_obj = new Date();

    // Set it to one month ago
    let to_date = d_obj.setMonth(d_obj.getMonth() - 1);
    let filter = {};
    filter['createdAt'] = {
        $lte: to_date
    }

// RequestLog.remove(filter, err => {
    RequestLog.deleteMany(filter, (err) => {
        if (err) {
            console.log('Error: ', err.message);
        } else {
            console.log('Delete log successfully');
        }
    });
}

clearLog();
