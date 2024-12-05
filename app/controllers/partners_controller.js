require('../models/partner');
const mongoose = require('mongoose');
const Pagination = require('../lib/pagination');
const Partner = mongoose.model('Partner');

module.exports.index = function (req, res) {
    const page = parseInt(req.query.page || 1);
    const limit = 10;
    const skip = limit * (page - 1);
    Partner.find({}).sort({createdAt: -1}).limit(limit).skip(skip).then(async partners => {
        const count = await Partner.count({});
        const pageCount = parseInt(Math.ceil(count / limit));
        res.status(200);
        res.render('partners/index', {
            partners,
            error: getErrorMessage(req),
            page,
            pageCount,
            pageUrl: Pagination.getPageUrl(req._parsedUrl)
        });
    });
}

module.exports.new = function (req, res) {
    res.render('partners/new', { partner: new Partner(), error: getErrorMessage(req) });
}

module.exports.create = function (req, res) {
    const partner = new Partner();
    partner.name = req.body.name;
    partner.email = req.body.email;
    partner.phone = req.body.phone;
    partner.module = req.body.module;
    partner.active = req.body.active;
    partner.timeout = req.body.timeout;
    partner.save(function (err, partner) {
        if (err) {
            res.status(500);
            errorSession(req, err.message);
            res.redirect('/partners');
        } else {
            res.status(200);
            res.redirect(`/partners`);
        }
    });
}

module.exports.edit = function (req, res) {
    Partner.findById(req.params.id, (err, partner) => {
        if (err) {
            res.status(404);
            errorSession(req);
            res.redirect('/partners');
        } else {
            res.status(200);
            res.render('partners/edit', { partner, error: getErrorMessage(req) });
        }
    });
}

module.exports.update = function (req, res) {
    Partner.findById(req.params.id, (err, partner) => {
        if (err) {
            res.status(404);
            errorSession(req);
            res.redirect('/partners');
        } else {
            partner.name = req.body.name;
            partner.email = req.body.email;
            partner.phone = req.body.phone;
            partner.module = req.body.module;
            partner.active = req.body.active;
            partner.timeout = req.body.timeout;

            partner.save((error) => {
                if (error) {
                    res.status(422);
                    return res.render('partners/edit', { partner, error: error.message });
                }
                res.status(200);
                res.redirect(`/partners`);
            });
        }
    });
}

module.exports.destroy = function (req, res) {
    Partner.findById(req.params.id, (err, partner) => {
        if (err) {
            res.status(404);
            errorSession(req);
            res.redirect('/partners');
        } else {
            partner.remove((error) => {
                if (error) {
                    res.status(500);
                    errorSession(req, error.message);
                    res.redirect('/partners');
                } else {
                    res.status(200);
                    res.redirect('/partners');
                }
            });
        }
    });
}

function errorSession(req, msg = 'Partner Not Found.') {
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
