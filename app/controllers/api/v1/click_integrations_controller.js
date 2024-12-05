const Partners = require('../../../models/partners/partners');
const axios = require("axios");
const hash = require('object-hash');
const AppMemcached = require("../../../lib/app_memcached");
const AESCipher = require("../../../models/aes_cipher");
const Click = require('../../../models/click');
const flatten = require('flat');

require('../../../models/partner');
const mongoose = require('mongoose');
const ErrorHandler = require("../../../models/error_handler");
const PartnerBase = require("../../../models/partners/partner_base");
const Partner = mongoose.model('Partner');
const errorHandler = new ErrorHandler();

module.exports.create = function (req, res) {
    let partner_id = req.params.partner_id;
    const params = req.body ? req.body.lead : {};
    const lead_type = params.lead_type_id || 1;
    const debug = {
        partner_name: '',
        click_integration_id: req.body.click_integration_id,
        request: JSON.stringify(params),
        success: false
    }
    const partnerModel = new Partners(req.brand_conf, partner_id);
    partnerModel.integrationPartner().then(partner => {
        if (partner) {
            partner.pingRequest(partner, partner.queryParams(params, lead_type)).then(resp => {
                let response = partner.getResponse(resp);
                debug.request = resp.config.data;
                processIntegrationResponse(partnerModel, response, resp.data, debug);
                res.status(200).json(response);
            }, err => {
                let response = {success: false, message: err.message, url: ''}
                debug.request = err.config.data;
                processIntegrationResponse(partnerModel, response, err, debug);
                res.status(200).json(response);
            });
        } else {
            let response = {success: false, message: 'Partner not found', url: ''}
            processIntegrationResponse(partnerModel, response, 'Partner not found', debug);
            res.status(200).json(response);
        }
    });
}
//https://example.com/api/v1/click_integration/:partner_id

module.exports.click_track = async function (req, res) {
    const db = req.brand_conf.db;
    const memcached = AppMemcached.getInstance();
    let partner_id = req.params.partner_id;
    const click_listing_id = req.params.click_listing_id
    const mem_key = hash({partner_id: partner_id, click_listing_id: click_listing_id});
    let cache_data = null;
    try {
        cache_data = await memcached.get(mem_key);
    } catch (ex) {
        errorHandler.notify(ex);
    }
    if (cache_data) {
        console.log('Data From cache: ', cache_data);
        res.redirect(cache_data);
    } else {
        db.query(`select cl.id,
                         cl.click_ping_id,
                         cl.click_id,
                         cl.payout,
                         ccs.pub_aid,
                         ccs.pub_cid,
                         cl.fallback_url,
                         cl.campaign_id,
                         cl.ad_id,
                         cl.ad_group_id,
                         cl.source_type_id
                  from click_listings cl
                           left join click_campaign_settings ccs on cl.campaign_id = ccs.campaign_id
                  where cl.id = ${click_listing_id}`, (error, results) => {
            if (error) {
                errorHandler.notify(error);
                return error;
            } else {
                let click_listing = results.rows[0];
                if (click_listing) {
                    db.query(`select *
                              from click_pings
                              where id = ${click_listing.click_ping_id}`, async (error, results) => {
                        if (error) {
                            errorHandler.notify(error);
                            return error;
                        } else {
                            try {
                                let ping = results.rows[0];
                                let params = JSON.parse(ping.xml || "{}");
                                const f_params = flatten(params);
                                const clickModel = new Click(req.brand_conf, f_params, []);
                                clickModel.req_params = params;
                                let integrations = await clickModel.getIntegrations([click_listing.campaign_id], 'pre_fill');
                                let integration = integrations[0];
                                if (integration) {
                                    let integration_response = await clickModel.applyIntegration(integration, click_listing, true, {ping_id: click_listing.click_id});
                                    if (integration_response && integration_response.data) {
                                        let success = clickModel.integrationResponse(integration, integration_response);
                                        if (success) {
                                            flagPrefillFailed(req.brand_conf.db, click_listing_id, false);
                                            let ping_config = JSON.parse(integration.ping_config || "{}");
                                            let parsed_integration_response = clickModel.parsePingIntegrationResponse(integration_response.data, ping_config, false);
                                            if (Array.isArray(parsed_integration_response)) {
                                                parsed_integration_response = parsed_integration_response[0];
                                            }
                                            let redirect_url = parsed_integration_response[ping_config.url || ping_config.click_url || 'url'] || click_listing.fallback_url;
                                            redirectToConsumer(req.brand_conf, res, click_listing, redirect_url, params, mem_key);
                                        } else {
                                            flagPrefillFailed(req.brand_conf.db, click_listing_id);
                                            redirectToConsumer(req.brand_conf, res, click_listing, click_listing.fallback_url, params);
                                        }
                                    } else {
                                        flagPrefillFailed(req.brand_conf.db, click_listing_id);
                                        redirectToConsumer(req.brand_conf, res, click_listing, click_listing.fallback_url, params);
                                    }
                                } else {
                                    redirectToConsumer(req.brand_conf, res, click_listing, click_listing.fallback_url, params);
                                }
                            } catch (ex) {
                                console.log('exception: ', ex.message);
                                errorHandler.notify(ex);
                                redirectToConsumer(req.brand_conf, res, click_listing, click_listing.fallback_url, {});
                            }
                        }
                    });
                } else {
                    res.redirect('https://smartfinancial.com');
                }
            }
        });
    }
}
//https://example.com/api/v1/click/:click_listing_id/track

module.exports.click_static_track = async function (req, res) {
    const db = req.brand_conf.db;
    const memcached = AppMemcached.getInstance();
    let partner_id = req.params.partner_id;
    const click_listing_id = req.params.click_listing_id
    const mem_key = hash({partner_id: partner_id, click_listing_id: click_listing_id});
    let cache_data = null;
    try {
        cache_data = await memcached.get(mem_key);
    } catch (ex) {
        errorHandler.notify(ex);
    }
    if (cache_data) {
        console.log('Data From cache: ', cache_data);
        res.redirect(cache_data);
    } else {
        db.query(`select cl.id,
                         cl.click_ping_id,
                         cl.click_id,
                         cl.payout,
                         ccs.pub_aid,
                         ccs.pub_cid,
                         cl.fallback_url,
                         cl.campaign_id,
                         cl.ad_id,
                         cl.ad_group_id,
                         cl.source_type_id
                  from click_listings cl
                           left join click_campaign_settings ccs on cl.campaign_id = ccs.campaign_id
                  where cl.id = ${click_listing_id}`, (error, results) => {
            if (error) {
                errorHandler.notify(error);
                return error;
            } else {
                let click_listing = results.rows[0];
                if (click_listing) {
                    db.query(`select *
                              from click_pings
                              where id = ${click_listing.click_ping_id}`, (error, results) => {
                        if (error) {
                            errorHandler.notify(error);
                            return error;
                        } else {
                            try {
                                let ping = results.rows[0];
                                click_listing.source_type_id = ping.source_type_id;
                                let headers = {headers: {Authorization: `Bearer ${process.env.INTERNAL_TOKEN}`}};
                                let params = JSON.parse(ping.xml || "{}");
                                let data = {
                                    click_id: click_listing.click_id,
                                    aid: click_listing.pub_aid || params.aid,
                                    cid: click_listing.pub_cid || params.cid,
                                    clk_cost: click_listing.payout,
                                    campaign_id: click_listing.campaign_id
                                }
                                let req_data = {...params, ...data}
                                return axios.post(`${process.env.APP_HOST}/api/v1/click_integration/${partner_id}`, {
                                    lead: req_data,
                                    click_integration_id: req.query.click_integration_id
                                }, headers).then(resp => {
                                    if (resp.data && resp.data.success) {
                                        flagPrefillFailed(req.brand_conf.db, click_listing_id, false);
                                        redirectToConsumer(req.brand_conf, res, click_listing, resp.data.url, req_data, mem_key);
                                    } else {
                                        flagPrefillFailed(req.brand_conf.db, click_listing_id);
                                        redirectToConsumer(req.brand_conf, res, click_listing, click_listing.fallback_url, req_data);
                                    }
                                }).catch(error => {
                                    errorHandler.notify(error);
                                    flagPrefillFailed(req.brand_conf.db, click_listing_id);
                                    redirectToConsumer(req.brand_conf, res, click_listing, click_listing.fallback_url, req_data);
                                });
                            } catch (ex) {
                                errorHandler.notify(ex);
                                console.log('exception: ', ex.message);
                                redirectToConsumer(req.brand_conf, res, click_listing, click_listing.fallback_url, {});
                            }
                        }
                    });
                } else {
                    res.redirect('https://smartfinancial.com');
                }
            }
        });
    }
}
// https://example.com/api/v1/click/:click_listing_id/track/:partner_id?click_integration_id=:id

module.exports.partner_integration = function (req, res) {
    Partner.find({}, {createdAt: 0, updatedAt: 0}).exec(function (err, partners) {
        if (err) {
            errorHandler.notify(err);
            return res.status(500).json({success: false, error: err.message});
        }

        res.status(200).json({
            success: true, partners: partners.map((partner) => {
                return {
                    _id: partner._id,
                    name: partner.name,
                    module: partner.module,
                    status: partner.active ? 'Active' : 'Disabled',
                    tracking_url: `/api/v1/click/{click_listing_id}/track/${partner._id}`,
                    click_integration_link: `/api/v1/click_integration/${partner._id}`
                }
            })
        });
    });
}

// http://example.com/api/v1/partner_integration/:partner_id

function processIntegrationResponse(partnerModel, response, full_resp, debug) {
    let debug_data = Object.assign({}, response);
    debug_data.partner_response = full_resp;
    debug.response = JSON.stringify(debug_data);
    debug.success = debug_data.success;
    partnerModel.storeLogs(debug);
}

function setCacheData(key, data, lifetime) {
    try {
        const memcached = AppMemcached.getInstance();
        memcached.set(key, data, lifetime);
    } catch (ex) {
        console.log("Cache Error: ", error);
        errorHandler.notify(ex);
    }
}

module.exports.test_partner_integration = function (req, res) {
    const startReq = new Date().getTime();
    const response = {
        success: false,
        timestamp: new Date().toISOString(),
        request: '',
        partner_response: '',
        response_ms: 0
    }
    const partnerId = req.params.partner_id;
    const leadType = parseInt(req.query.lead_type || '6');
    const lead = req.body.lead;

    const partnerModel = new Partners(req.brand_conf, partnerId);
    partnerModel.integrationPartner().then(partner => {
        if (partner) {
            const params = lead ? lead : partner.getSampleLead(leadType);
            const reqParams = partner.queryParams(params, leadType);
            response.request = JSON.stringify(reqParams);
            partner.pingRequest(partner, reqParams).then(resp => {
                // console.log('success: ', resp);
                response.partner_response = JSON.stringify(resp['data']);
                response.success = partner.isSuccess(resp);
                sendTestResponse(res, response, startReq);
            }, err => {
                console.log('error: ', err);
                response.partner_response = JSON.stringify(err['response'] ? err['response']['data'] : err.message);
                sendTestResponse(res, response, startReq);
            });
        } else {
            response.partner_response = 'Partner not found.'
            sendTestResponse(res, response, startReq);
        }
    });
}

function sendTestResponse(res, response, startReq) {
    response.response_ms = new Date().getTime() - startReq;
    res.status(200).json(response);
}

function redirectToConsumer(brand_conf, res, click_listing, url, params, mem_key = null) {
    let consumer_url = url || 'https://smartfinancial.com';
    updateClickListingClickUrl(brand_conf.db, click_listing.id, consumer_url);
    brand_conf.db.query(`select *
                         from click_campaign_settings
                         where campaign_id = ${click_listing.campaign_id}`, async (error, results) => {
        if (error) {
            errorHandler.notify(error);
            res.redirect(consumer_url);
        } else {
            const campaign_setting = results.rows[0];
            if (campaign_setting) {
                // campaign_setting.append_tracking = 'click_listing_id={click_listing_id}&click_id={click_id}&city={city}&state={state}&country={country}&state_code={state_code}&first_name={first_name}&last_name={last_name}&phone={phone}&dob={dob}&source={source}&source_type={source_type}&campaign_name={CampaignName}&adcreativename={adcreativename}&source_type_id={source_type_id}&ad_group_name={AdGroupName}&cpc={cpc}';
                if (campaign_setting.append_tracking) {
                    click_listing.ad_name = await getAdName(brand_conf.db, click_listing.ad_id);
                    applyAppendTrackingMacros(brand_conf, res, campaign_setting.append_tracking, params, click_listing).then(
                        (append_tracking) => {
                            consumer_url += consumer_url.includes('?') ? '&' : '?';
                            consumer_url += append_tracking;
                            updateClickListingClickUrl(brand_conf.db, click_listing.id, consumer_url);
                            res.redirect(consumer_url);
                        }
                    );
                } else {
                    res.redirect(consumer_url);
                }
            } else {
                res.redirect(consumer_url);
            }
        }
    });
}

function applyAppendTrackingMacros(brand_conf, res, append_tracking, params, click_listing) {
    return new Promise((resolve, reject) => {
        const f_params = flatten(params);
        try {
            brand_conf.db.query(`select *
                                 from campaigns
                                 where id = ${click_listing.campaign_id}`, async (error, results) => {
                if (error) {
                    resolve(append_tracking);
                } else {
                    const campaign = results.rows[0];
                    campaign.campaign_id = campaign.id;
                    campaign.campaign_name = campaign.name;
                    campaign.ad_group_name = await getAdGroupName(brand_conf.db, click_listing.ad_group_id);
                    const clickModel = new Click(brand_conf, f_params, []);
                    clickModel.click_listings = {}
                    clickModel.req_params = params;
                    click_listing.click_listing_id = click_listing.id;
                    clickModel.click_listings[campaign.id] = click_listing;
                    clickModel.source_type_id = click_listing.source_type_id;
                    let final_append_tracking = clickModel.processAppendTrackingMacros(append_tracking, campaign);
                    resolve(final_append_tracking || append_tracking);
                }
            });
        } catch (ex) {
            resolve(append_tracking);
        }
    });
}

async function flagPrefillFailed(db, click_listing_id, flag = true) {
    db.query('update click_listings set prefill_failed = $1 where id = $2', [flag, click_listing_id], (error, results) => {
        if (error) {
            errorHandler.notify(error);
        }
    });
}

async function updateClickListingClickUrl(db, id, click_url) {
    db.query('update click_listings set click_url = $1 where id = $2', [click_url, id], (error, results) => {
        if (error) {
            errorHandler.notify(error);
        }
    });
}

function getAdName(db, ad_id) {
    const query = `SELECT *
                   FROM ads
                   WHERE id = ${ad_id}
                   limit 1;`;
    return db.query(query).then((results) => {
        return results.rows[0] ? results.rows[0].ad_name : '';
    }, err => {
        return '';
    });
}

function getAdGroupName(db, ad_group_id) {
    const query = `SELECT ad_group_name
                   FROM ad_groups
                   WHERE id = ${ad_group_id}
                   limit 1`;
    return db.query(query).then((results) => {
        return results.rows[0] ? results.rows[0].ad_group_name : '';
    }, err => {
        return '';
    });
}
