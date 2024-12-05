const {brands} = require("../config/database");
require('../models/request_log');
require('../models/click_debug');
require('../models/token');
const mongoose = require('mongoose');
const RequestLog = mongoose.model('RequestLog');
const Token = mongoose.model('Token');
const Pagination = require('../lib/pagination');
require("../lib/app_memcached");
module.exports.index = function (req, res) {
    res.render('home/index', {name: 'Hey', subject: 'Hello there!', link: 'dddd'})
}

module.exports.activity_log = function (req, res) {
    const page = parseInt(req.query.page || 1);
    const limit = 25;
    const skip = limit * (page - 1);
    const filter = logSearchFilter(req.query);
    RequestLog.find(filter, activityLogProjection()).sort(getSortBy(req.query.response_time)).limit(limit).skip(skip).lean().then(async logs => {
        const count = await RequestLog.count(filter);
        const pageCount = parseInt(Math.ceil(count / limit));
        res.status(200);
        res.render('home/activity_log', {
            logs,
            page,
            pageCount,
            pageUrl: Pagination.getPageUrl(req._parsedUrl),
            request_method: req.query.request_method,
            status: req.query.status,
            search: req.query.search,
            response_time: req.query.response_time,
            lead_type_id: req.query.lead_type_id,
            date_range: req.query.date_range,
        });
    });
}

module.exports.activity_log_detail = function (req, res) {
    RequestLog.findById(req.params.id, (err, log) => {
        if (err) {
            return res.status(200).json({
                success: false,
                message: err.message
            });
        }

        res.status(200).json({
            success: true,
            log
        });
    });
}

module.exports.clear_activity_log = function (req, res) {
    const d_obj = new Date();

    // Set it to one month ago
    let to_date = d_obj.setMonth(d_obj.getMonth() - 1);
    let filter = {};
    filter['createdAt'] = {
        $lte: to_date
    }

    RequestLog.deleteMany(filter, (err) => {
        if (err) {
            res.status(200).json({
                error: err.message
            });
        } else {
            res.status(200).json({
                message: `Delete log successfully`
            });
        }
    });
}

function activityLogProjection() {
    return {
        createdAt: 1,
        request_method: 1,
        url: 1,
        access_token: 1,
        _id: 1,
        status: 1,
        response_time: 1
    };
}

function getSortBy(response_time) {
    if (response_time) {
        if (response_time === 'rta') {
            return {response_time: 1};
        } else if (response_time === 'rtd') {
            return {response_time: -1};
        }
    }

    return {createdAt: -1};
}

function logSearchFilter(query) {
    const filter = {}
    if (query.request_method) {
        filter['request_method'] = {$regex: query.request_method, $options: 'i'};
    }
    if (query.lead_type_id) {
        filter['lead_type_id'] = query.lead_type_id;
    }
    if (query.status) {
        filter['status'] = query.status;
    }
    if (query.date_range) {
        const custom_date = query.date_range.split(' to ');
        const fromTime = new Date(custom_date[0]);
        const toTime = new Date(custom_date[1] || custom_date[0]);
        filter['createdAt'] = {
            $gte: fromTime,
            $lte: toTime
        }
    }
    if (query.search) {
        filter['$or'] = [
            {url: {$regex: query.search, $options: 'i'}},
            {access_token: {$regex: query.search, $options: 'i'}},
            {ip: {$regex: query.search, $options: 'i'}},
        ];
    }
    return filter;
}

module.exports.debug = function (req, res) {
    let filter = req.query || {};
    const brand_db = brands[req.params.brand || 'smartfinancial'].db;
    const page = parseInt(req.query.page || 1);
    const limit = 15;
    const skip = limit * (page - 1);
    let from_date = new Date();
    let to_date = new Date();
    from_date.setDate(from_date.getDate() - 7);
    if (req.query.date_range) {
        let custom_date = req.query.date_range.split(' to ');
        from_date = new Date(custom_date[0]);
        to_date = new Date(custom_date[1] || custom_date[0]);
    }
    to_date = to_date.toISOString();
    from_date = from_date.toISOString();
    filter.from_date = toLocal(from_date);
    filter.to_date = toLocal(to_date);
    let conditions = `created_at >= '${from_date}' and created_at <= '${to_date}'`;
    if (filter.has_listing) {
        conditions += filter.has_listing === 'yes' ? ' and num_listings > 0' : ' and (num_listings <= 0 OR num_listings IS NULL)';
    }
    if (filter.keyword) {
        conditions += Number(filter.keyword) ? ` and click_ping_id = ${filter.keyword}` : ` and token = '${filter.keyword}'`;
    }
    let log_type = 'click_ping_debug_logs';
    filter.log_type = req.params.log_type;
    if (filter.log_type === 'lead') {
        log_type = 'lead_ping_debug_logs';
    } else if (filter.log_type === 'call') {
        log_type = 'call_ping_debug_logs';
    }
    brand_db.query(`SELECT count(*) as count
                    from ${log_type}
                    where ${conditions}`, (error, results) => {
        let count = results.rows[0].count;
        brand_db.query(`SELECT *
                        from ${log_type}
                        where ${conditions}
                        order by id desc
                        LIMIT ${limit} OFFSET ${skip}`, (error, results) => {
            if (error) {
                console.log("Read log error", error.message);
            } else {
                const pageCount = parseInt(Math.ceil(count / limit));
                const debugs = results.rows;
                res.render('home/debug', {
                    debugs,
                    filter,
                    page,
                    pageCount,
                    pageUrl: Pagination.getPageUrl(req._parsedUrl)
                });
            }
        });
    });
}

module.exports.click_ping = function (req, res) {
    const brand_db = brands[req.params.brand || 'smartfinancial'].db;
    let log_type = 'click_pings';
    if (req.params.log_type === 'lead') {
        log_type = 'lead_pings';
    } else if (req.params.log_type === 'call') {
        log_type = 'call_pings';
    }
    brand_db.query(`select *
                    from ${log_type}
                    where id = ${req.params.id}`, (error, results) => {
        if (error) {
            return error;
        } else {
            res.render('home/click_ping', {click_ping: results.rows[0]});
        }
    });
}

module.exports.debug_details = function (req, res) {
    const brand_db = brands[req.params.brand || 'smartfinancial'].db;
    let log_type = 'click_ping_debug_logs';
    if (req.params.log_type === 'lead') {
        log_type = 'lead_ping_debug_logs';
    } else if (req.params.log_type === 'call') {
        log_type = 'call_ping_debug_logs';
    }
    brand_db.query(`SELECT *
                    from ${log_type}
                    where id = ${req.params.id}`, (error, results) => {
        res.status(200);
        if (error) {
            res.redirect('/')
        } else {
            let ping_data = results.rows[0] || {};
            res.render('home/debug_details', {
                details: ping_data,
                log_type: req.params.log_type,
                ping_id: (ping_data.click_ping_id || ping_data.lead_ping_id || ping_data.call_ping_id)
            });
        }
    });
}

function toLocal(date) {
    const local = new Date(date);
    // local.setMinutes(date.getMinutes() - date.getTimezoneOffset());
    // return local.toJSON(); //.slice(0, 10);
    return local.toJSON();
}

module.exports.getReports = function (req, res) {
    // RequestLog.aggregate(getAggPipeline(req.query.agg_type))
    //     .then(results => {
    //         processResults(res, req.query.agg_type, results);
    //
    //     }, err => {
    //         console.log('Error: ', err.message);
    //         res.status(500).json({error: err.message});
    //     });
    monthData = {
        months: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'],
        data: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        success: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        error: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        counts: [0, 0, 0, 0, 0, 0, 0],
        tokenLabels: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        previousReport: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    }
    res.status(200).json(monthData);
}

function processResults(res, agg_type, results) {
    if (agg_type === 'monthly_status') {
        monthlyReqStatusReport(res, results);
    } else if (agg_type === 'previous') {
        monthlyReqReport(res, results);
    } else {
        processAccessTokenReport(res, results);
    }
}

function monthlyReqReport(res, allResults) {
    const data = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    allResults.forEach(item => {
        const index = parseInt(item._id) - 1;
        data[index] = item.count;
    });

    res.status(200).json({
        previousReport: data
    });
}

function monthlyReqStatusReport(res, results) {
    const monthData = {
        months: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'],
        data: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        success: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        error: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    }
    results.forEach(item => {
        const index = parseInt(item._id) - 1;
        monthData.data[index] = item.count;
        item.statuses.forEach(data => {
            if (data.status < 400) {
                monthData.success[index] += data.count;
            } else {
                monthData.error[index] += data.count;
            }
        });
    });

    res.status(200).json(monthData);
}

function processAccessTokenReport(res, results) {
    let counts = [], tokenLabels = [];
    const accessTokens = results.map(item => item._id);

    Token.find({access_token: {$in: accessTokens}}).then(tokens => {

        results.forEach(item => {
            tokenLabels.push(item._id.substring(0, 3) + '...' + item._id.substring(item._id.length - 3, item._id.length));
            counts.push(item.count);
            for (let token of tokens) {
                if (token.access_token == item._id) {
                    if (token.label) {
                        tokenLabels[tokenLabels.length - 1] = token.label;
                    }
                    break;
                }
            }
        });

        res.status(200).json({tokenLabels, counts});
    });
}

function getAggPipeline(agg_type) {
    if (agg_type === 'monthly_status') {
        return monthlyReqStatusAggPipeline();
    } else if (agg_type === 'previous') {
        return monthlyReqAggPipeline(new Date(new Date().getFullYear() - 1, 0, 1), new Date(new Date().getFullYear() - 1, 11, 31));
    } else {
        return accessTokenAggPipeline();
    }
}

function accessTokenAggPipeline() {
    return [
        {$match: {access_token: {$ne: ''}}},
        {$group: {_id: "$access_token", count: {$sum: 1}}},
        {$match: {count: {$gt: 0}}},
        {$sort: {count: -1}},
        {$limit: 10}
    ];
}

function monthlyReqAggPipeline(fromTime = new Date(new Date().getFullYear(), 0, 1), toTime = new Date()) {
    return [
        {$match: {createdAt: {$gte: fromTime, $lte: toTime}}},
        {$group: {_id: {$substr: ['$createdAt', 5, 2]}, count: {$sum: 1}}},
        {$sort: {count: -1}}
    ];
}

function monthlyReqStatusAggPipeline() {
    return [
        {$match: {createdAt: {$gte: new Date(new Date().getFullYear(), 0, 1), $lte: new Date()}}},
        {$group: {_id: {month: {$substr: ['$createdAt', 5, 2]}, status: "$status"}, statusCount: {$sum: 1}}},
        {
            $group: {
                _id: "$_id.month",
                statuses: {$push: {status: "$_id.status", count: "$statusCount"}},
                count: {$sum: "$statusCount"}
            }
        },
        {$sort: {count: -1}}
    ];
}
