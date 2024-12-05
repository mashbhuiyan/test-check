require('../../../models/token');
const mongoose = require('mongoose');
const ErrorHandler = require("../../../models/error_handler");
const Token = mongoose.model('Token');
const errorHandler = new ErrorHandler();

module.exports.index = function (req, res) {
    const page = parseInt(req.query.page || 1);
    const limit = parseInt(req.query.per_page || 10);
    if (page < 1 || limit < 1) {
        return res.status(422).json({success: false, message: 'Invalid Page Params'});
    }
    const skip = limit * (page - 1);
    const filter = {project_id: (req.query.project_id || req.body.project_id), type: 'generic'};

    Token.find(filter, commonProjection()).sort({createdAt: -1}).limit(limit).skip(skip).then(async tokens => {
        const count = await Token.count(filter);
        const pageCount = parseInt(Math.ceil(count / limit));
        res.status(200);
        res.json({tokens: tokens, success: true, page, page_count: pageCount});
    }, (err) => {
        res.status(422).json({success: false, message: err.message});
    });
}

module.exports.create = function (req, res) {
    if (req.body.token_type === 'admin' && !req.body.project_id) {
        return res.status(422).json({success: false, message: 'Project ID is required'});
    }
    const token = new Token();
    token.label = req.body.label;
    token.access_token = Token.generateToken();
    token.access_level = req.body.access_level || 'read';
    token.request_limit = req.body.request_limit;
    token.request_period = req.body.request_period;
    token.campaign_bid_multipliers = req.body.campaign_bid_multipliers;
    token.project_id = req.body.project_id;
    token.assignWhitelistedIPs(req.body.whitelisted_ips);
    token.save((err, tkn) => {
        if (err) {
            errorHandler.notify(err);
            res.status(500).json({success: false, error: err.message});
        } else {
            tokenResponse(res, tkn);
        }
    });
}

module.exports.update = function (req, res) {
    Token.findOne({_id: req.params.id}).exec(function (err, token) {
        if (err) {
            res.status(404).json({success: false});
        } else {
            token.label = req.body.label || token.label;
            token.access_level = req.body.access_level || token.access_level;
            token.assignWhitelistedIPs(req.body.whitelisted_ips);
            token.campaign_bid_multipliers = req.body.campaign_bid_multipliers || token.campaign_bid_multipliers;
            token.request_limit = req.body.request_limit;
            token.request_period = req.body.request_period;
            token.active = req.body.active;
            token.save(function (err, tkn) {
                if (err) {
                    errorHandler.notify(err);
                    res.status(500).json({success: false, error: err.message});
                } else {
                    tokenResponse(res, tkn);
                }
            });
        }
    });
}

module.exports.update_use_replica = function (req, res) {
    let filter = {type: req.body.type};
    if (filter.type === 'all') {
        filter = {}
    }
    Token.find(filter).updateMany({$set: {use_replica: req.body.status}}).exec((err, tokens) => {
        if (err) {
            res.status(500).json({success: false, error: err.message});
        } else {
            res.status(200).json({success: true, message: `${req.body.type} tokens has been updated`});
        }
    });
}

module.exports.delete = function (req, res) {
    Token.findOne({_id: req.params.id}).exec(function (err, token) {
        if (err) {
            res.status(404).json({success: false});
        } else {
            token.remove(function (err) {
                if (err) {
                    errorHandler.notify(err);
                    res.status(500).json({success: false, error: err.message});
                } else {
                    res.status(200).json({success: true});
                }
            });
        }
    });
}

function commonProjection() {
    return {
        _id: 1,
        label: 1,
        access_level: 1,
        type: 1,
        active: 1,
        whitelisted_ips: 1,
        campaign_bid_multipliers: 1,
        access_token: 1,
        request_limit: 1,
        request_period: 1,
        project_id: 1
    }
}

function tokenResponse(res, token) {
    res.status(200).json({
        success: true,
        token: {
            _id: token._id,
            label: token.label,
            access_level: token.access_level,
            type: token.type,
            active: token.active,
            whitelisted_ips: token.whitelisted_ips,
            campaign_bid_multipliers: token.campaign_bid_multipliers,
            access_token: token.access_token,
            request_limit: token.request_limit,
            request_period: token.request_period,
            project_id: token.project_id
        }
    });
}
