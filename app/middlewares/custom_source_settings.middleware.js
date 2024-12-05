const util = require('../models/utils');

module.exports.custom_source = (req, res, next) => {
    let token = req.body.token;
    let custom_sources = ['onlineguru-15064950', 'web2carz-79609931', 'insurancecom-204462406', 'ensurify-204553905', 'usedfirst-204662408', 'trevesz-79597131', 'media force - auto_ab 2 - auto', 'quotewizard-desktop']
    try {
        // if (token && token.partner_id === process.env.CUSTOM_SOURCE_PARTNER) {
        // do this for all tokens
        if (token) {
            if (custom_sources.includes(util.toLowerCase(req.body.lead.traffic_tier)) ||
                util.toLowerCase(req.body.lead.traffic_tier).includes('transparently_a-') ||
                util.toLowerCase(req.body.lead.traffic_tier).includes('quotewizard-') ||
                util.toLowerCase(req.body.lead.traffic_tier).includes('smartfinancial -') ||
                util.toLowerCase(req.body.lead.traffic_tier).includes('mt leads auto insurance_') ||
                util.toLowerCase(req.body.lead.traffic_tier).includes('otto - usm -') ||
                util.toLowerCase(req.body.lead.traffic_tier).includes('growthlink_')) {
                if (req.body.lead && req.body.lead.slice_num > 99) {
                    next();
                } else {
                    res.status(200);
                    res.json({success: false, num_listings: 0, listings: []});
                }
            } else {
                next();
            }
        } else {
            next();
        }
    } catch (ex) {
        next();
    }
}
