const Click = require('../../../models/click');
const flatten = require('flat');
const util = require('../../../models/utils');
const uuid = require("uuid");
const ErrorHandler = require("../../../models/error_handler");
const errorHandler = new ErrorHandler();

module.exports.index = async function (req, res, next) {
    let product_type_ids = [1, 4];
    const db = req.brand_conf.db;
    const read_replica_db = (req.brand_conf.read_replica || req.brand_conf).db;
    const startTime = new Date().getTime();
    const params = req.body ? req.body.lead : {};
    const req_body = req.body ? req.body : {};
    const f_params = flatten(params);
    f_params.age = util.getAge(f_params);
    let source_type_id = util.getParam(f_params, 'source_type_id');
    // const date = new Date();
    const utcDate = new Date();
    const date1 = utcDate.toLocaleString("en-US", {
        timeZone: "America/Los_Angeles"
    });
    const date = new Date(date1);
    const day = date.getDay();
    const todate = date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate();
    const begin_month = date.getFullYear() + "-" + (date.getMonth() + 1) + "-01";
    const clickModel = new Click(req.brand_conf, f_params, req_body.campaign_bid_multipliers);
    clickModel.token_type = req_body.token_type ? req_body.token_type : 'generic'
    clickModel.token_id = req_body.token_id;
    clickModel.req_token = req.headers.authorization.split('Bearer ')[1].trim();
    clickModel.req_params = params;
    if (req.params.brand) {
        clickModel.brand_url = `${req.params.brand}/`;
        if (req.brand_conf.name.toLowerCase() === 'goal') {
            product_type_ids = [5];
        }
    }
    if (!source_type_id) {
        source_type_id = await addSourceType(db, params.traffic_tier, req_body.project_id, clickModel.token_type);
        clickModel.updateCampaignSourceSettings(source_type_id, product_type_ids);
    } else {
        clickModel.updateCampaignSourceSettings(source_type_id, product_type_ids);
    }
    clickModel.source_type_id = source_type_id;
    await clickModel.storeClickPing(params, (req.body.original_lead || {}));
    // TODO update campaign_spends query to not check discarded_at
    let cs_query = '';
    if (clickModel.token_type === 'generic') {
        const tc_ids = clickModel.token_bid_multipliers.map(tbm => tbm.campaign_id);
        if (tc_ids.length > 0) {
            cs_query += " and campaign_id in (" + tc_ids + ") ";
        }
    }
    let query = "select t1.id, t4.id account_id, t5.id user_id, t13.id brand_id, t2.campaign_id, t3.lead_type_id, t3.price_presentation, t3.name campaign_name, t2.base_bid_price::FLOAT, t13.name display_name, t4.timezone, t4.company_name, t4.account_manager_id, t4.sales_manager_id, t4.insurance_carrier_id, case when t3.is_campaign_level_tracking is true then t10.dest_url else t9.dest_url end as dest_url, case when t3.is_campaign_level_tracking is true then t10.fallback_url else t9.fallback_url end as fallback_url, t2.id as ad_group_id, t2.ad_group_name, t15.dest_url click_dest_url, t15.id click_integration_id, t16.name click_integration_type, t10.pub_aid, t10.pub_cid, t14.active active_source, t14.weight source_weight, t3.product_type_id \n" +
        ", t8.dollar_budget::FLOAT budgets, t8.volume_budget, t11.dollar_amt spent, t11.units, t12.monthly_spend, t12.monthly_vol, t3.monthly_volume, t3.monthly_budget::FLOAT, t10.floor_cpc, t10.bpfm_status, t10.target_cpc, t10.append_tracking, t2.rtb_cm, t7.invoice \n" +
        "from ad_group_locations t1 \n" +
        "inner join ad_groups t2 on t1.ad_group_id = t2.id \n" +
        "inner join campaigns t3 on t3.id = t2.campaign_id \n" +
        "inner join accounts t4 on t4.id = t3.account_id \n" +
        "inner join users t5 on t5.id = t3.user_id \n" +
        "inner join account_balances t6 on t6.account_id = t4.id \n" +
        "inner join billing_settings t7 on t7.account_id = t4.id \n" +
        "inner join campaign_budgets t8 on t8.campaign_id = t3.id and t8.day_id = " + day + " \n" +
        "inner join brands t13 on t3.brand_id = t13.id \n" +
        "left join click_ad_group_settings t9 on t9.ad_group_id = t2.id \n" +
        "left join click_campaign_settings t10 on t10.campaign_id = t3.id \n" +
        "left join campaign_spends t11 on t11.campaign_id = t3.id and t11.discarded_at is null and t11.dt = '" + todate + "' \n" +
        // "left join campaign_spends t11 on t11.campaign_id = t3.id and t11.dt = '2022-07-22' \n" +
        "left join (select campaign_id, sum(dollar_amt) as monthly_spend, sum(units) as monthly_vol from campaign_spends where discarded_at is null and dt >= '" + begin_month + "'" + cs_query + " group by 1) t12 on t12.campaign_id = t3.id \n" +
        // "left join (select campaign_id, sum(dollar_amt) as monthly_spend, sum(units) as monthly_vol from campaign_spends where discarded_at is null and created_at >= '" + begin_month + "' group by 1) t12 on t12.campaign_id = t3.id \n" +
        "left join campaign_source_settings t14 on t14.campaign_id = t3.id and t14.source_type_id = " + source_type_id + " \n" +
        "left join click_integrations t15 on t15.id = (case when t3.is_campaign_level_tracking is true then (case when t10.has_click_integration then t10.click_integration_id else null end) else (case when t9.has_click_integration then t9.click_integration_id else null end) end) \n" +
        "left join click_integration_types t16 on t16.id = t15.click_integration_type_id \n" +
        "where t1.zip = '" + util.getParam(f_params, 'zip') + "' and t3.active is true and t2.active is true and t4.status = 'active' and t13.active is true \n" +
        "and (invoice = 1 OR ((current_balance+promo_balance) >= 0 and rebill = 1 and rebill_failure = 0 and card_last4 is not null)) \n" +
        `and t2.active is true and product_type_id in (${product_type_ids.join(',')}) and lead_type_id = ` + util.getParam(f_params, 'lead_type_id') + "\n" +
        // "and (dollar_amt is null OR dollar_amt < dollar_budget OR units is null OR units < volume_budget) \n" +
        // "and (case when t8.dollar_budget is not null then (t11.dollar_amt is null OR t11.dollar_amt < t8.dollar_budget) else (t11.units is null OR t11.units < t8.volume_budget) end) \n" +
        // "and (monthly_spend is null OR monthly_spend < monthly_budget OR monthly_vol is null OR monthly_vol < monthly_volume) \n" +
        "and t1.discarded_at is null and t2.discarded_at is null and t3.discarded_at is null \n" +
        "and t4.discarded_at is null and t5.discarded_at is null and t8.discarded_at is null \n" +
        "and (t10.throttle is null OR t11.updated_at is null OR EXTRACT(EPOCH FROM (now() - t11.updated_at)) > t10.throttle) \n" +
        "and t13.discarded_at is null and t9.discarded_at is null and t10.discarded_at is null";
    if (clickModel.token_type === 'generic') {
        const token_campaign_ids = clickModel.token_bid_multipliers.map(tbm => tbm.campaign_id);
        if (token_campaign_ids.length > 0) {
            query += " and t2.campaign_id in (" + token_campaign_ids + ")";
        } else {
            clickModel.updateClickPings(0, ((new Date().getTime()) - startTime));
            res.status(200).json({listings: [], num_listings: 0, response_ms: ((new Date().getTime()) - startTime)});
            return;
        }
    } else {
        query += " and t4.internal = false";
    }
    util.dynamicReplicaDB(req).query(query, async (error, results) => {
        if (error) {
            throw error
        }
        clickModel.campaign_list = results.rows;
        clickModel.initData();
        if (clickModel.campaign_ids.length > 0) {
            // clickModel.ping_integrations = clickModel.self_integration ? [] : await clickModel.getIntegrations(clickModel.campaign_ids, 'ping');
            // clickModel.pre_ping_integrations = clickModel.self_integration ? [] : await clickModel.getIntegrations(clickModel.campaign_ids, 'pre-ping');
            if (!clickModel.self_integration) {
                let phase_integrations = await clickModel.getIntegrations(clickModel.campaign_ids, ['ping', "pre-ping", "price_presentation", "pre_fill"]);
                clickModel.ping_integrations = phase_integrations['ping'] || [];
                clickModel.pre_ping_integrations = phase_integrations['pre-ping'] || [];
                clickModel.price_presentation_integrations = phase_integrations['price_presentation'] || [];
                clickModel.pre_fill_integrations = phase_integrations['pre_fill'] || [];
            }
            const scheduleModifier = clickModel.scheduleModifier();
            const budgetFilter = clickModel.budgetFilter();
            const filterGroups = clickModel.filterGroups();
            const modifierGroups = clickModel.modifierGroups();
            const adGroups = clickModel.adGroups();
            Promise.all([budgetFilter, scheduleModifier, filterGroups, modifierGroups, adGroups]).then(async results => {
                let process_response = await clickModel.processResponse(startTime);
                if (process_response.listings.length > 0) {
                    let click_ints = [];
                    // clickModel.price_presentation_integrations = await clickModel.getIntegrations(clickModel.campaign_ids, 'price_presentation');
                    for (let listing of process_response.listings) {
                        let click_id = uuid.v4().replace(/-/g, '');
                        let data = {
                            click_id: click_id,
                            aid: listing.pub_aid || params.aid,
                            cid: listing.pub_cid || params.cid,
                            clk_cost: listing.price
                        }
                        click_ints.push(clickModel.applyClickIntegration(listing, data));
                    }
                    Promise.all(click_ints).then(async resp_campaigns => {
                        clickModel.storeClickOpportunity();
                        let pre_ping_listings = await clickModel.applyPrePingIntegration(resp_campaigns);
                        clickModel.storeClickListing(pre_ping_listings).then(async click_listings => {
                            click_listings = click_listings.filter(listing => (listing.est_payout > 0 && listing.price > 0));
                            let endTime = new Date().getTime();
                            clickModel.storeDebugData((endTime - startTime), click_listings.length);
                            clickModel.updateClickPings(click_listings.length, (endTime - startTime));
                            click_listings.map(listing => {
                                return clickModel.applyMacros(listing);
                            });
                            click_listings.sort((a, b) => b.est_payout - a.est_payout);
                            res.status(200).json({
                                listings: responseFormat(click_listings, clickModel),
                                num_listings: click_listings.length,
                                response_ms: (endTime - startTime)
                            });
                        });
                    });
                } else {
                    let endTime = new Date().getTime();
                    clickModel.storeClickOpportunity();
                    clickModel.storeDebugData((endTime - startTime), 0);
                    clickModel.updateClickPings(0, (endTime - startTime));
                    res.status(200).json({listings: [], num_listings: 0, response_ms: (endTime - startTime)});
                }
            });
        } else {
            let endTime = new Date().getTime();
            clickModel.updateClickPings(0, (endTime - startTime));
            res.status(200).json({listings: [], num_listings: 0, response_ms: (endTime - startTime)});
        }
    });
}

function responseFormat(listings, objClickModel) {
    return listings.map(campaign => {
        let listing_resp = {
            display_name: campaign.display_name,
            company_name: campaign.company_name,
            click_url: campaign.tracking_url,
            payout: campaign.est_payout,
            title: campaign.title,
            description: campaign.description,
            logo_url: campaign.logo_url,
            impr_html: campaign.impr_html,
            site_host: campaign.display_url,
            events_url: campaign.events_url,
            post_url: `${process.env.APP_HOST}/api/v1/${objClickModel.brand_url}clicks/${campaign.click_listing_id}/post`
        }
        if (objClickModel.token_type === 'admin') {
            listing_resp.price_presentation = campaign.price_presentation;
            listing_resp.premium = campaign.premium;
            listing_resp.term = campaign.term;
            if (typeof (campaign.bpfm_score) !== 'undefined') {
                listing_resp.bpfm_score = campaign.bpfm_score;
            }
        }
        return listing_resp;
    });
}

function addSourceType(db, source, project_id, token_type) {
    let current_date_time = new Date();
    let active_source = (token_type === 'admin' || process.env.PRODUCTION == 0); //make source type active on staging or dev env.
    const data = [source, 'Added by API', false, active_source, project_id, current_date_time, current_date_time];
    let query = `SELECT id
                 FROM source_types
                 WHERE LOWER(name) = '${source.toLowerCase()}'`;
    if (project_id) {
        query += ` and project_id = '${project_id}'`
    }
    query += ' limit 1';
    return db.query(query).then(results => {
        if (results.rows.length > 0) {
            return results.rows[0].id || null;
        } else {
            return db.query('INSERT INTO source_types (name, description, internal, active, project_id, created_at, updated_at) VALUES($1, $2, $3, $4, $5, $6, $7) RETURNING *', data).then((results) => {
                console.log('Added new source type');
                return results.rows[0] ? results.rows[0].id : null;
            }, err => {
                errorHandler.notify(err);
                console.log('Unable to add new source: ', err.message);
                return null;
            });
        }
    }, err => {
        errorHandler.notify(err);
        return null;
    });
}
