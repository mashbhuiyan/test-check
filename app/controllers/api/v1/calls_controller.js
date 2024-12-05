const Call = require('../../../models/call');
const flatten = require('flat');
const util = require('../../../models/utils');
const ErrorHandler = require("../../../models/error_handler");
const CallEvent = require("../../../models/call_events");
const errorHandler = new ErrorHandler();
const axios = require("axios");

module.exports.ping = async function (req, res, next) {
    const db = req.brand_conf.db;
    const read_replica_db = (req.brand_conf.read_replica || req.brand_conf).db;
    const startTime = new Date().getTime();
    const params = req.body ? req.body.lead : {};
    const req_body = req.body ? req.body : {};
    const original_primary_phone = req_body.original_primary_phone || '';
    const f_params = flatten(params);
    f_params.age = util.getAge(f_params);
    let source_type_id = util.getParam(f_params, 'source_type_id');
    const callModel = new Call(req.brand_conf, f_params, req_body.campaign_bid_multipliers);
    callModel.token_type = req_body.token_type ? req_body.token_type : 'generic'
    callModel.token_id = req_body.token_id;
    callModel.req_token = req.headers.authorization.split('Bearer ')[1].trim();
    callModel.req_params = params;
    callModel.self_integration = req.get('SelfIntegration') || false; // TODO: Remove when push live
    if (!source_type_id) {
        source_type_id = await callModel.addSourceType(params.traffic_tier, req_body.project_id, callModel.token_type);
        callModel.updateCampaignSourceSettings(source_type_id, [2]);
    } else {
        callModel.updateCampaignSourceSettings(source_type_id, [2]);
    }
    callModel.source_type_id = source_type_id;
    await callModel.storeCallPing(params, original_primary_phone);
    let query = callModel.initialQuery();
    if (!params.inbound) {
        query += ` and ccs.inbound_only is not true`;
    }
    if (req_body.call_transfer_types && req_body.call_transfer_types.length > 0) {
        query += ` and ccs.transfer_type in (${req_body.call_transfer_types})`;
    }
    if (callModel.token_type === 'generic') {
        const token_campaign_ids = callModel.token_bid_multipliers.map(tbm => tbm.campaign_id);
        if (token_campaign_ids.length > 0) {
            query += " and t2.campaign_id in (" + token_campaign_ids + ")";
        } else {
            callModel.updateCallPings(0);
            res.status(200).json({listings: [], num_listings: 0, time: ((new Date().getTime()) - startTime)});
            return;
        }
    } else {
        query += " and t4.internal = false";
    }
    util.dynamicReplicaDB(req).query(query, async (error, results) => {
        if (error) {
            console.log('Error here');
            throw error
        }
        callModel.campaign_list = results.rows;
        callModel.initData();
        if (callModel.campaign_ids.length > 0) {
            if (!callModel.self_integration) {
                let phase_integrations = await callModel.getIntegrations(callModel.campaign_ids, ['pre-ping', 'ping']);
                callModel.pre_ping_integrations = phase_integrations['pre-ping'] || [];
                callModel.ping_integrations = phase_integrations['ping'] || [];
            }
            const scheduleModifier = callModel.scheduleModifier();
            const filterGroups = callModel.filterGroups();
            const modifierGroups = callModel.modifierGroups();

            Promise.all([scheduleModifier, filterGroups, modifierGroups]).then(async results => {
                let campaigns = callModel.processResponse(startTime);
                if (campaigns.listings.length > 0) {
                    campaigns.listings.sort((a, b) => b.est_payout - a.est_payout);
                    callModel.storeCallOpportunity();
                    campaigns.listings = await callModel.applyPrePingIntegration(campaigns.listings);
                    callModel.storeCallListing(campaigns.listings).then(call_listings => {
                        call_listings = call_listings.filter(listing => (listing.est_payout > 0 && listing.price > 0));
                        callModel.updateCallPings(call_listings.length);
                        let endTime = new Date().getTime();
                        res.status(200).json({
                            ping_id: callModel.call_uid,
                            buyers: responseFormat(call_listings, callModel.token_type),
                            time: (endTime - startTime)
                        });
                    });
                } else {
                    callModel.storeCallOpportunity();
                    callModel.updateCallPings(0);
                    let endTime = new Date().getTime();
                    res.status(200).json({ping_id: callModel.call_uid, time: (endTime - startTime), buyers: []});
                }
            });
        } else {
            callModel.updateCallPings(0);
            let endTime = new Date().getTime();
            res.status(200).json({ping_id: callModel.call_uid, time: (endTime - startTime), buyers: []});
        }
    });
}

module.exports.brand_availability = async function (req, res) {
    const startTime = new Date().getTime();
    const req_body = req.body ? req.body : {};
    let callModel = await pingInitialCallModel(req, req_body);
    let query = callModel.initialQuery();
    query += ` and ccs.inbound_only is true`;
    if (req_body.call_transfer_types && req_body.call_transfer_types.length > 0) {
        query += ` and ccs.transfer_type in (${req_body.call_transfer_types})`;
    }
    if (callModel.token_type === 'generic') {
        const token_campaign_ids = callModel.token_bid_multipliers.map(tbm => tbm.campaign_id);
        if (token_campaign_ids.length > 0) {
            query += " and t2.campaign_id in (" + token_campaign_ids + ")";
        } else {
            callModel.updateCallPings(0);
            res.status(200).json({listings: [], num_listings: 0, time: ((new Date().getTime()) - startTime)});
            return;
        }
    } else {
        query += " and t4.internal = false";
    }
    util.dynamicReplicaDB(req).query(query, async (error, results) => {
        if (error) {
            console.log('Error here');
            throw error
        }
        callModel.campaign_list = results.rows;
        callModel.initData();
        callModel.filter_campaign_list = callModel.campaign_list.map(campaign => campaign.campaign_id);
        if (callModel.campaign_ids.length > 0) {
            const scheduleModifier = callModel.scheduleModifier();
            const modifierGroups = callModel.modifierGroups(true);
            Promise.all([scheduleModifier, modifierGroups]).then(async results => {
                let campaigns = callModel.processResponse(startTime);
                if (campaigns.listings.length > 0) {
                    campaigns.listings.sort((a, b) => b.est_payout - a.est_payout);
                    callModel.storeCallOpportunity();
                    callModel.storeCallListing(campaigns.listings, false).then(call_listings => {
                        call_listings = call_listings.filter(listing => (listing.est_payout > 0 && listing.price > 0));
                        callModel.updateCallPings(call_listings.length);
                        let endTime = new Date().getTime();
                        res.status(200).json({
                            ping_id: callModel.call_uid,
                            buyers: responseFormat(call_listings, callModel.token_type, true),
                            time: (endTime - startTime)
                        });
                    });
                } else {
                    callModel.storeCallOpportunity();
                    callModel.updateCallPings(0);
                    let endTime = new Date().getTime();
                    res.status(200).json({ping_id: callModel.call_uid, time: (endTime - startTime), buyers: []});
                }
            });
        } else {
            callModel.updateCallPings(0);
            let endTime = new Date().getTime();
            res.status(200).json({ping_id: callModel.call_uid, time: (endTime - startTime), buyers: []});
        }
    });
}

module.exports.availability = async function (req, res) {
    const all_promise = [];
    const brands = ['smartfinancial', 'usha', 'insuranceagents', 'goal', 'smartfinancial_pro'];
    try {
        let available_agents = await Call.checkAvailableAgents();
        console.log('available_agents: ', available_agents);
        if (available_agents <= 0) {
            res.status(200).json({});
            return;
        }
        console.log('available_agents: ', available_agents);
        for (let brand of brands) {
            all_promise.push(req_brand_call_available(brand, req));
        }
        Promise.all(all_promise).then(results => {
            let max_bid_per_carrier = {};
            let all_listings = results.map(result => (result.buyers || [])).flat();
            all_listings = all_listings.filter(listing => listing.carrier_id != '32');
            if (all_listings.length > 0) {
                const max_bid_listing = all_listings.reduce((prev, current) => {
                    return (prev && prev.bid > current.bid) ? prev : current
                });
                for (let listing of all_listings) {
                    if (max_bid_per_carrier[listing.carrier_id]) {
                        if (listing.bid > max_bid_per_carrier[listing.carrier_id]) {
                            max_bid_per_carrier[listing.carrier_id] = listing.bid;
                        }
                    } else {
                        max_bid_per_carrier[listing.carrier_id] = listing.bid;
                    }
                }
                let max_bids = Object.values(max_bid_per_carrier);
                console.log(max_bids);
                let final_bid = max_bids.reduce((a, b) => a + b) / max_bids.length;
                max_bid_listing.bid = util.parseToFloat(final_bid.toFixed(2));
                max_bid_listing.buyer = 'SmartFinancial Insurance';
                res.status(200).json(max_bid_listing);
            } else {
                res.status(200).json({});
            }
        }, error => {
            console.log(error);
            res.status(200).json({});
        });
    } catch (ex) {
        console.log(ex);
        res.status(200).json({});
    }
}

module.exports.post = function (req, res) {
    const db = req.brand_conf.db;
    const startTime = new Date().getTime();
    const lead_ping_uid = req.body.ping_id;
    const token_type = req.body.token_type;
    const phone = req.body.lead ? req.body.lead.contact.primary_phone : '';
    let brand_url = '';
    if (req.params.brand) {
        brand_url = `${req.params.brand}/`;
    }
    let bid_ids = (req.body.bid_ids || ['0']).map(id => {
        return "'" + id + "'";
    }).join(', ');
    db.query(`select *
              from call_pings
              where uid = '${lead_ping_uid}'
              limit 1`, async (error, results) => {
        if (error) {
            errorHandler.notify(error);
            res.status(500).json(postResponseFormat(false, 0, startTime, 'rejected'));
        } else {
            if (results.rows[0]) {
                const call_ping_id = results.rows[0].id;
                const existing_post = false; // await getExistingPost(call_ping_id);
                if (existing_post) {
                    res.status(200).json(postResponseFormat(false, '', startTime, 'Duplicate post with the same ping ID'));
                } else if (!phone) {
                    res.status(200).json(postResponseFormat(false, '', startTime, 'Rejected with no phone number'));
                } else {
                    const params = req.body ? req.body.lead : {};
                    const f_params = flatten(params);
                    const callModel = new Call(req.brand_conf, f_params, []);
                    callModel.token_id = req.body.token_id;
                    callModel.req_params = params;
                    await callModel.storeCallPost(results.rows[0].id, JSON.stringify(params));
                    const query = `select cl.*,
                                          ccs.transfer_type,
                                          ccs.pre_transfer_script,
                                          ccs.transfer_script,
                                          ccs.overflow,
                                          ac.enterprise
                                   from call_listings cl
                                            inner join call_campaign_settings ccs on ccs.campaign_id = cl.campaign_id
                                            left join accounts ac on ac.id = cl.account_id
                                   where cl.bid_id in (${bid_ids})`;
                    db.query(query, async (error, results) => {
                        if (error) {
                            errorHandler.notify(error);
                            res.status(500).json(postResponseFormat(false, callModel.post_uid, startTime, error.message));
                        } else {
                            let buyers = [];
                            let call_listings = {};
                            let general_listing_campaigns = {}
                            let ping_post_listing_campaigns = {};
                            let campaign_ids = results.rows.map(call_listing => {
                                call_listings[call_listing.id] = {
                                    bid_id: call_listing.bid_id,
                                    buyer: call_listing.buyer,
                                    error: '',
                                    payout: parseFloat(call_listing.payout),
                                    est_payout: parseFloat(call_listing.est_payout),
                                    campaign_id: call_listing.campaign_id,
                                    account_id: call_listing.account_id,
                                    id: call_listing.id,
                                    retail: !call_listing.enterprise,
                                    tracking_number: call_listing.tracking_number,
                                    transfer_number: call_listing.transfer_number,
                                    billable_duration: call_listing.billable_duration,
                                    transfer_type: call_listing.transfer_type,
                                    pre_transfer_script: call_listing.pre_transfer_script,
                                    warm_transfer_script: call_listing.transfer_script,
                                    overflow: call_listing.overflow,
                                    events_url: `${process.env.APP_HOST}/api/v1/${brand_url}calls/${call_listing.id}/events`
                                };
                                if (call_listing.pp_ping_id) {
                                    if (ping_post_listing_campaigns[call_listing.campaign_id]) {
                                        ping_post_listing_campaigns[call_listing.campaign_id][call_listing.pp_ping_id].push(call_listing)
                                    } else {
                                        let pp_ping_id = {}
                                        pp_ping_id[call_listing.pp_ping_id] = [call_listing];
                                        ping_post_listing_campaigns[call_listing.campaign_id] = pp_ping_id;
                                    }
                                } else {
                                    general_listing_campaigns[call_listing.campaign_id] = call_listing;
                                    return call_listing.campaign_id
                                }
                            });
                            // Get and apply integration for general lead listing
                            let filtered_campaigns = Object.keys(general_listing_campaigns);
                            campaign_ids = campaign_ids.filter(cid => !!cid);
                            let general_integrations = [];
                            if (campaign_ids.length > 0 && !callModel.self_integration) {
                                general_integrations = await callModel.getIntegrations(campaign_ids);
                                //if (general_integrations.length > 0) {
                                filtered_campaigns = await callModel.applyPostIntegrations(general_integrations, general_listing_campaigns);
                                //}
                            }

                            // Get and apply integration for ping post lead listing
                            let ping_post_campaign_ids = Object.keys(ping_post_listing_campaigns);
                            let filtered_ping_post_campaigns = [];
                            if (ping_post_campaign_ids.length > 0 && !callModel.self_integration) {
                                let post_integrations = await callModel.getIntegrations(ping_post_campaign_ids, 'post');
                                filtered_ping_post_campaigns = await callModel.applyPingPostIntegrations(post_integrations, ping_post_listing_campaigns);
                            }
                            filtered_campaigns = filtered_campaigns.map(fc => fc.toString());
                            for (let listing of results.rows) {
                                if (filtered_campaigns.includes(listing.campaign_id.toString())) {
                                    call_listings[listing.id].accepted = true;
                                }
                            }

                            for (let filtered_ping_post_campaign of filtered_ping_post_campaigns) {
                                //console.log('filtered_ping_post_campaign.buyers: ', filtered_ping_post_campaign.buyers);
                                for (let buyer of filtered_ping_post_campaign.buyers) {
                                    if (call_listings[buyer.listing_id]) {
                                        call_listings[buyer.listing_id].error = buyer.error;
                                        call_listings[buyer.listing_id].payout = buyer.payout;
                                        call_listings[buyer.listing_id].est_payout = buyer.est_payout;
                                        call_listings[buyer.listing_id].accepted = buyer.success;
                                        call_listings[buyer.listing_id].ping_post = true;
                                    }
                                }
                            }
                            const final_listings = Object.values(call_listings);
                            for (let call_listing of final_listings) {
                                let status = false;
                                if (call_listing.accepted) {
                                    let duplicate_call = await callModel.checkCallDuplicacy(call_listing.account_id, phone);
                                    let concurrent_call = await callModel.checkCallConcurrency(call_listing.campaign_id);
                                    status = !(duplicate_call || concurrent_call)
                                }
                                let buyer_resp = {
                                    status: status,
                                    bid_id: call_listing.bid_id,
                                    buyer: call_listing.buyer,
                                    overflow: call_listing.overflow,
                                    transfer_number: call_listing.tracking_number,
                                    billable_duration: call_listing.billable_duration,
                                    transfer_type: call_listing.transfer_type,
                                    pre_transfer_script: call_listing.pre_transfer_script,
                                    warm_transfer_script: call_listing.warm_transfer_script,
                                    error: status ? '' : (call_listing.error || "Call received in last 30 day's"),
                                    payout: status ? parseFloat(call_listing.payout) : 0,
                                    events_url: call_listing.events_url
                                }
                                if (token_type === 'admin') {
                                    buyer_resp.retail = call_listing.retail
                                }
                                buyers.push(buyer_resp);
                            }
                            let post_status = buyers.filter(buyer => buyer.status).length > 0;
                            callModel.updateCallPostStatus(post_status);
                            callModel.updateCallListings(final_listings);
                            res.status(200).json(postResponseFormat(post_status, callModel.post_uid, startTime, '', buyers, token_type));
                        }
                    });
                }
            } else {
                res.status(404).json(postResponseFormat(false, '', startTime, 'Lead ping not found', [], token_type));
            }
        }
    });
}

module.exports.events = function (req, res) {
    const db = req.brand_conf.db;
    const call_listing_id = req.params.call_listing_id
    db.query(`select *
              from call_listings
              where id = ${call_listing_id}`, (error, results) => {
        if (error) {
            errorHandler.notify(error);
            res.status(500).json({success: false, message: 'failed'});
        } else {
            if (results.rows[0]) {
                const callEvent = new CallEvent(req.brand_conf, results.rows[0]);
                if (req.body) {
                    callEvent.updateCallListing(req.body).then(resp => {
                        res.status(200).json({success: true, message: 'success'});
                        // console.log(resp);
                    });
                }
            } else {
                res.status(404).json({success: false, message: 'Call listings not found'});
            }
        }
    });
}

async function req_brand_call_available(brand, req) {
    const req_body = {lead: req.body.lead};
    let rsp = {};
    let auth = req.headers?.authorization || '';
    await axios.post(`${req.headers.origin}/api/v1/${brand}/calls/brand_availability`, req_body, {
        headers: {authorization: auth},
        timeout: 5000
    }).then(response => {
        rsp = response.data;
    }).catch(error => {
        console.log(error);
        errorHandler.notify(error);
    });
    return rsp;
}

async function pingInitialCallModel(req, req_body) {
    const params = req.body ? req.body.lead : {};
    const f_params = flatten(params);
    f_params.age = util.getAge(f_params);
    let source_type_id = util.getParam(f_params, 'source_type_id');
    const callModel = new Call(req.brand_conf, f_params, req_body.campaign_bid_multipliers);
    callModel.token_type = req_body.token_type ? req_body.token_type : 'generic'
    callModel.token_id = req_body.token_id;
    callModel.req_token = req.headers.authorization.split('Bearer ')[1].trim();
    callModel.req_params = params;
    callModel.self_integration = req.get('SelfIntegration') || false; // TODO: Remove when push live
    if (!source_type_id) {
        source_type_id = await callModel.addSourceType(params.traffic_tier, req_body.project_id, callModel.token_type);
        callModel.updateCampaignSourceSettings(source_type_id, [2]);
    } else {
        callModel.updateCampaignSourceSettings(source_type_id, [2]);
    }
    callModel.source_type_id = source_type_id;
    await callModel.storeCallPing(params);
    return callModel;
}

function responseFormat(listings, token_type, return_carrier = false) {
    return listings.map(listing => {
        let company_name = util.toLowerCase(listing.company_name) === 'independent agent' ? listing.business_name : listing.company_name;
        let ping_response = {
            bid_id: listing.bid_id,
            buyer: listing.carrier_id === '32' ? listing.brand_name : company_name,
            bid: listing.est_payout,
            transfer_number: listing.tracking_number,
            billable_duration: listing.billable_duration || 90
        }
        if (token_type === 'admin') {
            ping_response.retail = !listing.enterprise;
            ping_response.overflow = listing.overflow;
        }
        if (return_carrier) {
            ping_response.carrier_id = listing.carrier_id;
        }
        return ping_response;
    });
}

function postResponseFormat(status, post_id, startTime, error = '', buyers = [], token_type) {
    const endTime = new Date().getTime();
    let response = {
        status: status,
        post_id: post_id,
        error: error,
        time: (endTime - startTime)
    }
    if (buyers.length > 0) {
        response.buyers = buyers
    }
    return response;
}
