const Lead = require('../../../models/lead');
const flatten = require('flat');
const util = require('../../../models/utils');
const ErrorHandler = require("../../../models/error_handler");
const errorHandler = new ErrorHandler();

module.exports.ping = async function (req, res, next) {
    const db = req.brand_conf.db;
    const read_replica_db = (req.brand_conf.read_replica || req.brand_conf).db;
    const startTime = new Date().getTime();
    const params = req.body ? req.body.lead : {};
    const req_body = req.body ? req.body : {};
    const f_params = flatten(params);
    f_params.age = util.getAge(f_params);
    let source_type_id = util.getParam(f_params, 'source_type_id');
    const utcDate = new Date();
    const date1 = utcDate.toLocaleString("en-US", {
        timeZone: "America/Los_Angeles"
    });
    const date = new Date(date1);
    const day = date.getDay();
    const todate = date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate();
    const begin_month = date.getFullYear() + "-" + (date.getMonth() + 1) + "-01";
    const leadModel = new Lead(req.brand_conf, f_params, req_body.campaign_bid_multipliers);
    leadModel.token_type = req_body.token_type ? req_body.token_type : 'generic'
    leadModel.token_id = req_body.token_id;
    leadModel.req_token = req.headers.authorization.split('Bearer ')[1].trim();
    leadModel.req_params = params;
    leadModel.self_integration = req.get('SelfIntegration') || false; // TODO: Remove when push live
    if (!source_type_id) {
        source_type_id = await leadModel.addSourceType(params.traffic_tier, req_body.project_id, leadModel.token_type);
        leadModel.updateCampaignSourceSettings(source_type_id, [3]);
    } else {
        leadModel.updateCampaignSourceSettings(source_type_id, [3]);
    }
    leadModel.source_type_id = source_type_id;
    await leadModel.storeLeadPing(params);
    let query = "select t1.id, t4.id account_id, t4.enterprise, t4.account_manager_id, t4.sales_manager_id, t4.insurance_carrier_id, t4.company_name business_name, t5.id user_id, t13.id brand_id, t13.name brand_name, t3.allowable_return_perc, t2.campaign_id, t3.lead_type_id, t3.price_presentation, t3.name campaign_name, t2.base_bid_price::FLOAT, t13.name brand_name, t4.timezone, t4.enterprise, t4.insurance_carrier_id carrier_id, t4.license_number, lcs.exclusive, lcs.weekend_discount, ic.name company_name, t2.id as ad_group_id, t2.ad_group_name, t3.locked_price, t14.active active_source, t14.weight source_weight, t7.invoice\n" +
        "from ad_group_locations t1\n" +
        "inner join ad_groups t2 on t1.ad_group_id = t2.id\n" +
        "inner join campaigns t3 on t3.id = t2.campaign_id\n" +
        "inner join accounts t4 on t4.id = t3.account_id\n" +
        "inner join users t5 on t5.id = t3.user_id\n" +
        "inner join account_balances t6 on t6.account_id = t4.id\n" +
        "inner join billing_settings t7 on t7.account_id = t4.id\n" +
        "inner join campaign_budgets t8 on t8.campaign_id = t3.id and t8.day_id = " + day + " \n" +
        "inner join brands t13 on t3.brand_id = t13.id\n" +
        "inner join insurance_carriers ic on t4.insurance_carrier_id = ic.id\n" +
        "left join campaign_spends t11 on t11.campaign_id = t3.id and t11.discarded_at is null and t11.dt = '" + todate + "' \n" +
        "left join (select campaign_id, sum(dollar_amt) as monthly_spend, sum(units) as monthly_vol from campaign_spends where discarded_at is null and created_at >= '" + begin_month + "' group by 1) t12 on t12.campaign_id = t3.id\n" +
        "left join campaign_source_settings t14 on t14.campaign_id = t3.id and t14.source_type_id = " + source_type_id + " \n" +
        "left join lead_campaign_settings lcs on lcs.campaign_id = t3.id\n" +
        "where t1.zip = '" + util.getParam(f_params, 'zip') + "' and t3.active is true and t2.active is true and t4.status = 'active' and t13.active is true \n" +
        "and (invoice = 1 OR ((current_balance+promo_balance) >= coalesce(case when t3.locked_price is true then t3.base_price else t3.base_price + t3.max_price end, 0)) OR ((current_balance+promo_balance) >= 0 and rebill = 1 and rebill_failure = 0 and card_last4 is not null)) \n" +
        "and t2.active is true and product_type_id = 3 and lead_type_id = " + util.getParam(f_params, 'lead_type_id') + " \n" +
        "and (dollar_amt is null OR dollar_amt < dollar_budget OR units is null OR units < volume_budget) \n" +
        "and (case when t8.dollar_budget is not null then (t11.dollar_amt is null OR t11.dollar_amt < t8.dollar_budget) else (t11.units is null OR t11.units < t8.volume_budget) end)\n" +
        "and (monthly_spend is null OR monthly_spend < monthly_budget OR monthly_vol is null OR monthly_vol < monthly_volume) \n" +
        "and t1.discarded_at is null and t2.discarded_at is null and t3.discarded_at is null \n" +
        "and t4.discarded_at is null and t5.discarded_at is null and t8.discarded_at is null \n" +
        "and (lcs.throttle is null OR t11.updated_at is null OR EXTRACT(EPOCH FROM (now() - t11.updated_at)) > lcs.throttle) \n" +
        "and t13.discarded_at is null";
    if (leadModel.token_type === 'generic') {
        const token_campaign_ids = leadModel.token_bid_multipliers.map(tbm => tbm.campaign_id);
        if (token_campaign_ids.length > 0) {
            query += " and t2.campaign_id in (" + token_campaign_ids + ")";
        } else {
            leadModel.updateLeadPings(0);
            res.status(200).json({listings: [], num_listings: 0, time: ((new Date().getTime()) - startTime)});
            return;
        }
    } else {
        query += " and t4.internal = false";
    }
    util.dynamicReplicaDB(req).query(query, async (error, results) => {
        if (error) {
            throw error
        }
        leadModel.campaign_list = results.rows;
        leadModel.initData();
        if (leadModel.campaign_ids.length > 0) {
            if (!leadModel.self_integration) {
                let phase_integrations = await leadModel.getIntegrations(leadModel.campaign_ids, ['ping', "pre-ping"]);
                leadModel.ping_integrations = phase_integrations['ping'] || [];
                leadModel.pre_ping_integrations = phase_integrations['pre-ping'] || [];
            }
            const scheduleModifier = leadModel.scheduleModifier();
            const filterGroups = leadModel.filterGroups();
            const modifierGroups = leadModel.modifierGroups();

            Promise.all([scheduleModifier, filterGroups, modifierGroups]).then(async results => {
                let process_response = leadModel.processResponse(startTime);
                if (process_response.listings.length > 0) {
                    process_response.listings.sort((a, b) => b.est_payout - a.est_payout);
                    leadModel.storeLeadOpportunity();
                    process_response.listings = await leadModel.applyPrePingIntegration(process_response.listings);
                    leadModel.storeLeadListing(process_response.listings).then(lead_listings => {
                        let endTime = new Date().getTime();
                        leadModel.storeDebugData((endTime - startTime), process_response.listings.length);
                        lead_listings.sort((a, b) => b.est_payout - a.est_payout);
                        leadModel.updateLeadPings(lead_listings.length);
                        res.status(200).json({
                            ping_id: leadModel.lead_uid,
                            buyers: responseFormat(lead_listings, leadModel.token_type),
                            time: (endTime - startTime)
                        });
                    });
                } else {
                    leadModel.storeLeadOpportunity();
                    leadModel.storeDebugData(process_response.response_ms, 0);
                    leadModel.updateLeadPings(0);
                    let endTime = new Date().getTime();
                    res.status(200).json({ping_id: leadModel.lead_uid, time: (endTime - startTime), buyers: []});
                }
            });
        } else {
            leadModel.updateLeadPings(0);
            let endTime = new Date().getTime();
            res.status(200).json({ping_id: leadModel.lead_uid, time: (endTime - startTime), buyers: []});
        }
    });
}

module.exports.post = function (req, res) {
    const db = req.brand_conf.db;
    const startTime = new Date().getTime();
    const lead_ping_uid = req.body.ping_id;
    const token_type = req.body.token_type ? req.body.token_type : 'generic';
    let bid_ids = (req.body.bid_ids || ['0']).map(id => {
        return "'" + id + "'";
    }).join(', ');
    db.query(`select *
              from lead_pings
              where uid = '${lead_ping_uid}'
              limit 1`, async (error, results) => {
        if (error) {
            errorHandler.notify(error);
            res.status(500).json(postResponseFormat(false, 0, null, startTime, 'rejected'));
        } else {
            if (results.rows[0]) {
                const lead_ping_id = results.rows[0].id;
                const existing_post = await getExistingPost(db, lead_ping_id);
                if (existing_post) {
                    res.status(200).json(postResponseFormat(false, 0, null, startTime, 'Duplicate post with the same ping ID'));
                } else {
                    const params = req.body ? req.body.lead : {};
                    const f_params = flatten(params);
                    const leadModel = new Lead(req.brand_conf, f_params, []);
                    leadModel.req_params = params;
                    leadModel.token_id = req.body.token_id;
                    leadModel.self_integration = req.get('SelfIntegration') || false; // TODO: Remove when push live
                    await leadModel.storeLeadPost(results.rows[0].id, JSON.stringify(params));
                    let lead_listings = {}
                    let general_listing_campaigns = {}
                    let ping_post_listing_campaigns = {};
                    const query = `select ll.*, ac.enterprise
                                   from lead_listings ll
                                            left join accounts ac on ac.id = ll.account_id
                                   where ll.bid_id in (${bid_ids})`;
                    db.query(query, async (error, results) => { // TODO: query taking a bit more time. Maybe need to add bid_id as index
                        if (error) {
                            errorHandler.notify(error);
                            res.status(500).json(postResponseFormat(false, 0, null, startTime, error.message));
                        } else {
                            let campaign_ids = results.rows.map(lead_listing => {
                                lead_listings[lead_listing.id] = {
                                    bid_id: lead_listing.bid_id,
                                    type: lead_listing.listing_type,
                                    buyer: lead_listing.buyer,
                                    error: '',
                                    payout: parseFloat(lead_listing.payout),
                                    est_payout: parseFloat(lead_listing.est_payout),
                                    campaign_id: lead_listing.campaign_id,
                                    id: lead_listing.id,
                                    retail: !lead_listing.enterprise
                                };
                                if (lead_listing.pp_ping_id) {
                                    if (ping_post_listing_campaigns[lead_listing.campaign_id]) {
                                        ping_post_listing_campaigns[lead_listing.campaign_id][lead_listing.pp_ping_id].push(lead_listing)
                                    } else {
                                        let pp_ping_id = {}
                                        pp_ping_id[lead_listing.pp_ping_id] = [lead_listing];
                                        ping_post_listing_campaigns[lead_listing.campaign_id] = pp_ping_id;
                                    }
                                } else {
                                    general_listing_campaigns[lead_listing.campaign_id] = lead_listing;
                                    return lead_listing.campaign_id; // return general lead listing campaign id
                                }
                            });
                            // Get and apply integration for general lead listing
                            let filtered_campaigns = [];
                            campaign_ids = campaign_ids.filter(cid => !!cid);
                            let general_integrations = [];
                            if (campaign_ids.length > 0 && !leadModel.self_integration) {
                                general_integrations = await leadModel.getIntegrations(campaign_ids);
                                filtered_campaigns = await leadModel.applyPostIntegrations(general_integrations, general_listing_campaigns);
                            }

                            // Get and apply integration for ping post lead listing
                            let ping_post_campaign_ids = Object.keys(ping_post_listing_campaigns);
                            let filtered_ping_post_campaigns = [];
                            if (ping_post_campaign_ids.length > 0 && !leadModel.self_integration) {
                                let post_integrations = await leadModel.getIntegrations(ping_post_campaign_ids, 'post');
                                filtered_ping_post_campaigns = await leadModel.applyPingPostIntegrations(post_integrations, ping_post_listing_campaigns);
                            }

                            let post_data = [];
                            filtered_campaigns = filtered_campaigns.map(fc => fc.toString());
                            for (let listing of results.rows) {
                                if (filtered_campaigns.includes(listing.campaign_id.toString())) {
                                    post_data.push({
                                        cost: parseFloat(listing.payout),
                                        campaign_id: listing.campaign_id,
                                        lead_listing_id: listing.id
                                    });
                                } else {
                                    lead_listings[listing.id].error = 'Apply integration failed';
                                    lead_listings[listing.id].payout = 0;
                                    lead_listings[listing.id].accepted = false;
                                }
                            }
                            for (let filtered_ping_post_campaign of filtered_ping_post_campaigns) {
                                //console.log('filtered_ping_post_campaign.buyers: ', filtered_ping_post_campaign.buyers);
                                for (let buyer of filtered_ping_post_campaign.buyers) {
                                    if (lead_listings[buyer.listing_id]) {
                                        lead_listings[buyer.listing_id].error = buyer.error;
                                        lead_listings[buyer.listing_id].payout = buyer.payout;
                                        lead_listings[buyer.listing_id].est_payout = buyer.est_payout;
                                        lead_listings[buyer.listing_id].accepted = buyer.success;
                                        lead_listings[buyer.listing_id].ping_post = true;
                                    }
                                }
                                if (filtered_ping_post_campaign.payout > 0) {
                                    post_data.push({
                                        cost: parseFloat(filtered_ping_post_campaign.payout),
                                        campaign_id: filtered_ping_post_campaign.campaign_id,
                                        lead_listing_id: filtered_ping_post_campaign.listing_id
                                    });
                                }
                            }
                            console.log('lead post_data: ', post_data);
                            //console.log('lead_listings: ', lead_listings);
                            leadModel.post(post_data, params).then(results => {
                                leadModel.processGeneralIntegrations(general_integrations, Object.values(lead_listings));
                                if (results.success) {
                                    let post_campaigns = results.data.campaigns;
                                    // console.log('post_campaigns: ', post_campaigns);
                                    let total_payout = 0;
                                    for (let campaign of post_campaigns) {
                                        let listings = Object.values(lead_listings).filter(l => l.campaign_id === campaign.campaign_id);
                                        for (let listing of listings) {
                                            if (campaign.success) {
                                                total_payout += listing.est_payout || 0;
                                                lead_listings[listing.id].accepted = listing.ping_post ? listing.accepted : true;
                                                lead_listings[listing.id].org_payout = listing.payout;
                                                lead_listings[listing.id].payout = listing.est_payout;
                                                lead_listings[listing.id].error = '';
                                            } else {
                                                lead_listings[listing.id].accepted = false;
                                                lead_listings[listing.id].error = campaign.error;
                                                lead_listings[listing.id].payout = 0;
                                                lead_listings[listing.id].org_payout = 0;
                                            }
                                        }
                                    }
                                    let post_status = post_campaigns.filter(bid => bid.success).length > 0;
                                    let final_listings = Object.values(lead_listings);
                                    final_listings = final_listings.map(l => {
                                        if (!l.accepted) {
                                            l.payout = 0;
                                            l.est_payout = 0;
                                            l.org_payout = 0;
                                        }
                                        return l;
                                    })
                                    leadModel.storePostLegs(final_listings);
                                    leadModel.updateLeadPost(final_listings, post_status, post_campaigns);
                                    leadModel.updateLeadListings(final_listings);
                                    res.status(200).json(postResponseFormat(post_status, total_payout, leadModel.post_uid, startTime, '', final_listings, token_type));
                                } else {
                                    res.status(200).json(postResponseFormat(false, 0, leadModel.post_uid, startTime, results.data.message, []));
                                }
                            }, error => {
                                errorHandler.notify(error);
                                res.status(500).json(postResponseFormat(false, 0, leadModel.post_uid, startTime, 'rejected with internal server error'));
                            });
                        }
                    });
                }
            } else {
                res.status(404).json(postResponseFormat(false, 0, null, startTime, 'Lead ping not found'));
            }
        }
    });
}

function responseFormat(listings, token_type) {
    let selected_listings = listings.filter(listing => listing.selected);
    selected_listings = selected_listings.map(listing => {
        let ping_response = {
            bid_id: listing.bid_id,
            buyer: listingBuyerName(listing),
            bid: listing.est_payout,
            type: listing.exclusive ? 'exclusive' : 'shared'
        }
        if (token_type === 'admin') {
            ping_response.retail = !listing.enterprise
        }
        return ping_response;
    });
    return selected_listings.filter(sl => sl.bid > 0);
}

function listingBuyerName(listing) {
    let company_name = util.toLowerCase(listing.company_name) === 'independent agent' ? listing.business_name : listing.company_name;
    if (listing.ping_post) {
        return company_name;
    } else {
        return listing.carrier_id === '32' ? listing.brand_name : company_name;
    }
}

function postResponseFormat(status, payout, post_uid, startTime, error = '', buyers = [], token_type = null) {
    const endTime = new Date().getTime();
    let response = {
        post_id: post_uid,
        status: status,
        payout: payout,
        error: error,
        time: (endTime - startTime)
    }
    if (buyers.length > 0) {
        response.buyers = buyers.map(b => {
            let post_response = {
                bid_id: b.bid_id,
                type: b.type,
                buyer: b.buyer,
                error: b.error,
                payout: b.est_payout,
                accepted: b.accepted,
            }
            if (token_type === 'admin') {
                post_response.retail = b.retail
            }
            return post_response;
        });
    }
    if (!status && response.error === '') {
        response.error = 'rejected';
    }
    return response;
}

function getExistingPost(db, lead_ping_id) {
    const query = `SELECT *
                   FROM lead_posts
                   WHERE lead_ping_id = ${lead_ping_id}
                   limit 1`;
    return db.query(query).then((results) => {
        return results.rows[0] ? results.rows[0].id : null;
    }, err => {
        console.log('source_types query error lead: ', err.message);
        return null;
    });
}
