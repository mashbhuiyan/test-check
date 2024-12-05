const flatten = require('flat');
const util = require("../../../../../app/models/utils");
const Click = require("../../../../../app/models/click");
require('dotenv').config({path: `../../../../../.env`});

class ClicksController {
    async index(req) {
        let product_type_ids = [1, 4];
        const db = req.brand_conf.db;
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
        const year = date.getFullYear();
        const month = (date.getMonth() + 1);
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

        let query = "select t1.id, t4.id account_id, t5.id user_id, t13.id brand_id, t2.campaign_id, t3.lead_type_id, t3.price_presentation, t3.name campaign_name, t2.base_bid_price::FLOAT, t13.name display_name, t4.timezone, t4.company_name, t4.account_manager_id, t4.sales_manager_id, t4.insurance_carrier_id, case when t3.is_campaign_level_tracking is true then t10.dest_url else t9.dest_url end as dest_url, case when t3.is_campaign_level_tracking is true then t10.fallback_url else t9.fallback_url end as fallback_url, t2.id as ad_group_id, t2.ad_group_name, t15.dest_url click_dest_url, t15.id click_integration_id, t16.name click_integration_type, t10.pub_aid, t10.pub_cid, t14.active active_source, t14.weight source_weight, t3.product_type_id \n" +
            ", t8.dollar_budget::FLOAT budgets, t8.volume_budget, t11.dollar_amt spent, t10.floor_cpc, t10.bpfm_status, t10.target_cpc, t10.append_tracking, t2.rtb_cm, t7.invoice \n" +
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
            "left join campaign_monthly_spends cms on cms.campaign_id = t3.id and cms.discarded_at is null and cms.year = " + year + " and cms.month = " + month + " \n" +
            // "left join (select campaign_id, sum(dollar_amt) as monthly_spend, sum(units) as monthly_vol from campaign_spends where discarded_at is null and dt >= '" + begin_month + "'" + cs_query + " group by 1) t12 on t12.campaign_id = t3.id \n" +
            // "left join (select campaign_id, sum(dollar_amt) as monthly_spend, sum(units) as monthly_vol from campaign_spends where discarded_at is null and created_at >= '" + begin_month + "' group by 1) t12 on t12.campaign_id = t3.id \n" +
            "left join campaign_source_settings t14 on t14.campaign_id = t3.id and t14.source_type_id = " + source_type_id + " \n" +
            "left join click_integrations t15 on t15.id = (case when t3.is_campaign_level_tracking is true then (case when t10.has_click_integration then t10.click_integration_id else null end) else (case when t9.has_click_integration then t9.click_integration_id else null end) end) \n" +
            "left join click_integration_types t16 on t16.id = t15.click_integration_type_id \n" +
            "where t1.zip = '" + util.getParam(f_params, 'zip') + "' and t3.active is true and t2.active is true and t4.status = 'active' and t13.active is true \n" +
            "and (invoice = 1 OR ((current_balance+promo_balance) >= 0 and rebill = 1 and rebill_failure = 0 and card_last4 is not null)) \n" +
            `and t2.active is true and product_type_id in (${product_type_ids.join(',')}) and lead_type_id = ` + util.getParam(f_params, 'lead_type_id') + "\n" +
            "and (t11.dollar_amt is null OR t11.dollar_amt < dollar_budget OR t11.units is null OR t11.units < volume_budget) \n" +
            "and (case when t8.dollar_budget is not null then (t11.dollar_amt is null OR t11.dollar_amt < t8.dollar_budget) else (t11.units is null OR t11.units < t8.volume_budget) end) \n" +
            // "and (monthly_spend is null OR monthly_spend < monthly_budget OR monthly_vol is null OR monthly_vol < monthly_volume) \n" +
            "and (cms.dollar_amt is null OR cms.dollar_amt < monthly_budget OR cms.units is null OR cms.units < monthly_volume) \n" +
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
                return { step1_listings: [] };
            }
        } else {
            query += " and t4.internal = false";
        }
        return db.query(query).then(results => {
            return { step1_listings: results.rows };
        }, err => {
            return { step1_listings: [] };
        });
    }
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
                console.log('Unable to add new source: ', err.message);
                return null;
            });
        }
    }, err => {
        console.log('Unable to add new source: ', err.message);
        return null;
    });
}

module.exports = ClicksController;
