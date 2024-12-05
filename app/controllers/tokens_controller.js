require('../models/token');
const mongoose = require('mongoose');
const Token = mongoose.model('Token');
const Pagination = require('../lib/pagination');

module.exports.index = function (req, res) {
    const page = parseInt(req.query.page || 1);
    const limit = 10;
    const skip = limit * (page - 1);
    const filter = searchFilter(req.query);
    Token.find(filter).sort({createdAt: -1}).limit(limit).skip(skip).then(async tokens => {
        const count = await Token.count(filter);
        const pageCount = parseInt(Math.ceil(count / limit));
        res.status(200);
        res.render('tokens/index', {
            tokens,
            error: getErrorMessage(req),
            page,
            pageCount,
            pageUrl: Pagination.getPageUrl(req._parsedUrl),
            type: req.query.type,
            level: req.query.level,
            status: req.query.status,
            project_id: req.query.project_id,
            search: req.query.search,
        });
    });
}

function searchFilter(query) {
    const filter = {}
    if (query.type) {
        filter['type'] = query.type;
    }
    if (query.level) {
        filter['access_level'] = query.level;
    }
    if (query.status) {
        filter['active'] = query.status;
    }
    if (query.project_id) {
        filter['project_id'] = query.project_id;
    }
    if (query.search) {
        filter['$or'] = [
            {label: {$regex: query.search, $options: 'i'}},
            {access_token: {$regex: query.search, $options: 'i'}},
            {_id: query.search}
        ];
    }
    return filter;
}

module.exports.create = function (req, res) {
    const token = new Token();
    token.access_token = Token.generateToken();
    token.type = 'admin';
    token.save(function (err, token) {
        if (err) {
            res.status(500);
            errorSession(req, err.message);
            res.redirect('/tokens');
        } else {
            res.status(200);
            res.redirect(`/tokens/${token._id}/edit`);
        }
    });
}

module.exports.edit = function (req, res) {
    Token.findById(req.params.id, (err, token) => {
        if (err) {
            res.status(404);
            errorSession(req);
            res.redirect('/tokens');
        } else {
            res.status(200);
            res.render('tokens/edit', {token, error: getErrorMessage(req)});
        }
    });
}

module.exports.update = function (req, res) {
    Token.findById(req.params.id, (err, token) => {
        if (err) {
            res.status(404);
            errorSession(req);
            res.redirect('/tokens');
        } else {
            token.label = req.body.label;
            token.request_limit = req.body.request_limit;
            token.request_period = req.body.request_period;
            token.access_level = req.body.access_level;
            token.active = req.body.active;
            token.project_id = req.body.project_id;
            token.schema_validation_required = req.body.schema_validation_required;
            token.transfer_types = req.body.transfer_types;
            token.call_origination_type = req.body.call_origination_type;
            token.brands = req.body.brands;
            token.use_replica = (req.body.use_replica || false);
            token.assignWhitelistedIPs(req.body.whitelisted_ips);
            if (req.body.campaign_bid_multipliers) {
                try {
                    token.campaign_bid_multipliers = JSON.parse(req.body.campaign_bid_multipliers);
                } catch (e) {
                    res.status(422);
                    return res.render('tokens/edit', {token, error: e.message});
                }
            } else {
                token.campaign_bid_multipliers = [];
            }

            token.save((error) => {
                if (error) {
                    res.status(422);
                    return res.render('tokens/edit', {token, error: error.message});
                }
                res.status(200);
                res.redirect(`/tokens`);
            });
        }
    });
}

module.exports.destroy = function (req, res) {
    Token.findById(req.params.id, (err, token) => {
        if (err) {
            res.status(404);
            errorSession(req);
            res.redirect('/tokens');
        } else {
            token.remove((error) => {
                if (error) {
                    res.status(500);
                    errorSession(req, error.message);
                    res.redirect('/tokens');
                } else {
                    res.status(200);
                    res.redirect('/tokens');
                }
            });
        }
    });
}

function errorSession(req, msg = 'Token Not Found.') {
    req.session.error = msg;
}

function getErrorMessage(req) {
    let error;
    if (req.session.error) {
        error = req.session.error;
        req.session.error = null;
    }
    return error;
}
