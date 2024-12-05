require('./click_debug');
const util = require('./utils');
const ErrorHandler = require("./error_handler");
const errorHandler = new ErrorHandler();
const uuid = require("uuid");
const axios = require("axios");
const LeadIntegration = require('./lead_integration');
const MiniOrm = require('../lib/mini_orm');

module.exports = class Call extends LeadIntegration {
    orm = null;
    call_listing_id = null;

    constructor(brand_conf, pm, tbm) {
        super();
        this.brand_conf = brand_conf;
        this.db = brand_conf.db;
        this.orm = new MiniOrm(brand_conf.db);
        this.read_replica_db = (brand_conf.read_replica || brand_conf).db;
        this.params = pm;
        this.token_bid_multipliers = tbm || [];
        this.call_uid = uuid.v4();
    }

    initData() {
        let temp_campaign_list = {};
        for (let campaign of this.campaign_list) {
            temp_campaign_list[`${campaign.id}_${campaign.ad_group_id}`] = campaign;
        } // remove duplicate listings
        this.campaign_list = Object.values(temp_campaign_list);
        this.campaign_ids = this.campaign_list.map(cp => cp.campaign_id);
        for (let campaign of this.campaign_list) {
            this.bid_multipliers[campaign.campaign_id] = [];
            this.ads[campaign.campaign_id] = [];
            this.setInitialDebugData(campaign);
        }
        let device_type = util.getParam(this.params, 'device_type');
        if (device_type !== '') {
            this.device_types.push("'" + device_type + "'");
            this.mobile_device = util.toLowerCase(device_type) !== 'desktop';
        }
        for (let tbm of this.token_bid_multipliers) {
            if (this.bid_multipliers[tbm.campaign_id]) {
                this.bid_multipliers[tbm.campaign_id].push(util.parseToFloat(tbm.multiplier || '100'));
            } else {
                this.bid_multipliers[tbm.campaign_id] = util.parseToFloat(tbm.multiplier || '100');
            }
            this.setDebugData(tbm.campaign_id, 'token_bid_multiplier', util.parseToFloat(tbm.multiplier || '100'), true);
        }
        this.checkSourceSettings();
    }

    initialQuery() {
        const utcDate = new Date();
        const date1 = utcDate.toLocaleString("en-US", {
            timeZone: "America/Los_Angeles"
        });
        const date = new Date(date1);
        const day = date.getDay();
        const todate = date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate();
        const begin_month = date.getFullYear() + "-" + (date.getMonth() + 1) + "-01";

        return "select t1.id, t4.id account_id, t5.id user_id, t13.id brand_id, t4.enterprise, t4.company_name business_name, t3.allowable_return_perc, t2.campaign_id, t3.lead_type_id, t3.price_presentation, t3.name campaign_name, t2.base_bid_price::FLOAT, t13.name brand_name, t4.timezone, t4.enterprise, t4.insurance_carrier_id carrier_id, t4.license_number, ic.name company_name, t4.account_manager_id, t4.sales_manager_id, t4.insurance_carrier_id, ccs.tracking_number, ccs.transfer_number, ccs.billable_duration, ccs.overflow, ccs.conv_rate, ccs.max_bid, t2.id as ad_group_id, t2.ad_group_name, t2.rtb_cm, t3.locked_price, css.active active_source, css.weight source_weight, t7.invoice \n" +
            "from ad_group_locations t1\n" +
            "inner join ad_groups t2 on t1.ad_group_id = t2.id \n" +
            "inner join campaigns t3 on t3.id = t2.campaign_id \n" +
            "inner join accounts t4 on t4.id = t3.account_id \n" +
            "inner join users t5 on t5.id = t3.user_id \n" +
            "inner join account_balances t6 on t6.account_id = t4.id \n" +
            "inner join billing_settings t7 on t7.account_id = t4.id \n" +
            "inner join campaign_budgets t8 on t8.campaign_id = t3.id and t8.day_id = " + day + " \n" +
            "inner join brands t13 on t3.brand_id = t13.id \n" +
            "inner join insurance_carriers ic on t4.insurance_carrier_id = ic.id\n" +
            "left join call_campaign_settings ccs on ccs.campaign_id = t3.id \n" +
            "left join campaign_spends t11 on t11.campaign_id = t3.id and t11.discarded_at is null and t11.dt = '" + todate + "' \n" +
            "left join (select campaign_id, sum(dollar_amt) as monthly_spend, sum(units) as monthly_vol from campaign_spends where discarded_at is null and created_at >= '" + begin_month + "' group by 1) t12 on t12.campaign_id = t3.id \n" +
            "left join campaign_source_settings css on css.campaign_id = t3.id and css.source_type_id = " + this.source_type_id + " \n" +
            "left join (select campaign_id, count(*) as in_progress_calls from quote_calls where status = 'in-progress' group by 1) t14 on t14.campaign_id = t3.id \n" +
            "where t1.zip = '" + util.getParam(this.params, 'zip') + "' and t3.active is true and t2.active is true and t4.status = 'active' and t13.active is true \n" +
            "and (invoice = 1 OR ((current_balance+promo_balance) >= coalesce(case when t3.locked_price is true then t3.base_price else t3.base_price + t3.max_price end, 0)) OR ((current_balance+promo_balance) >= 0 and rebill = 1 and rebill_failure = 0 and card_last4 is not null)) \n" +
            "and t2.active is true and product_type_id = 2 and lead_type_id = " + util.getParam(this.params, 'lead_type_id') + " \n" +
            "and (dollar_amt is null OR dollar_amt < dollar_budget OR units is null OR units < volume_budget) \n" +
            "and (case when t8.dollar_budget is not null then (t11.dollar_amt is null OR t11.dollar_amt < t8.dollar_budget) else (t11.units is null OR t11.units < t8.volume_budget) end) \n" +
            "and (monthly_spend is null OR monthly_spend < monthly_budget OR monthly_vol is null OR monthly_vol < monthly_volume) \n" +
            "and (ccs.concurrency_cap is null OR coalesce(in_progress_calls,0) < ccs.concurrency_cap) \n" +
            "and t1.discarded_at is null and t2.discarded_at is null and t3.discarded_at is null \n" +
            "and t4.discarded_at is null and t5.discarded_at is null and t8.discarded_at is null \n" +
            "and t13.discarded_at is null and ccs.tracking_number is not null \n" +
            "and (ccs.call_origination_type is null OR ccs.call_origination_type = " + (util.getParam(this.params, 'call_type') || 2) + ")";
    }

    processResponse(startTime) {
        const res_campaign = {};
        let processed_campaigns = [];
        res_campaign['listings'] = [];
        for (let campaign of this.campaign_list) {
            let campaign_id = campaign.campaign_id;
            if (this.campaign_exclusion.includes(campaign_id)) {
                this.setDebugData(campaign_id, 'qualified', false);
                continue;
            }
            if (this.filter_campaign_list.includes(campaign_id)) {
                campaign.price = this.getFinalPrice(campaign_id, campaign.base_bid_price);
                campaign.est_payout = this.estimatedPayout(campaign);
                if (campaign.enterprise) {
                    let conv_rate = Math.max(campaign.conv_rate, 10);
                    campaign.est_payout *= (conv_rate / 100);
                    this.setDebugData(campaign.campaign_id, 'conversion_rate_multiplier', conv_rate);
                }
                this.setDebugData(campaign_id, 'final_bid', campaign.price);
                processed_campaigns.push(campaign);
            } else {
                this.setDebugData(campaign_id, 'qualified', false);
            }
        }
        res_campaign['listings'] = processed_campaigns;
        const endTime = new Date().getTime();
        res_campaign['response_ms'] = endTime - startTime;//'567'
        this.storeDebugData(res_campaign['response_ms'], res_campaign['listings'].length);
        return res_campaign;
    }

    async storeCallPing(call_data, original_primary_phone) {
        return new Promise((resolve, reject) => {
            let partner_id = this.token_id;
            const total_opportunities = 0;
            const total_listings = 0;
            const total_revenue = 0;
            const total_cost = 0;
            let lead_type_id = util.getParam(this.params, 'lead_type_id') || 6;
            let session_id = util.getParam(this.params, 'session_id');
            let aid = util.getParam(this.params, 'aid');
            let cid = util.getParam(this.params, 'cid');
            let sid = util.getParam(this.params, 'sid');
            let ks = util.getParam(this.params, 'ks');
            let source_type_id = util.getParam(this.params, 'source_type_id') || this.source_type_id;
            let timestamps = new Date();
            let form_type_id = util.getParam(this.params, 'form_type_id') || 0;
            let zip = util.getParam(this.params, 'zip');
            let state = util.getParam(this.params, 'state');
            let device_type = util.getParam(this.params, 'device_type');
            let data = [partner_id, lead_type_id, aid, cid, sid, ks, session_id, zip, state, device_type, source_type_id, form_type_id, call_data, total_opportunities, total_listings, total_revenue, total_cost, this.call_uid, timestamps, timestamps];
            this.db.query('INSERT INTO call_pings (partner_id, lead_type_id, aid, cid, sid, ks, session_id, zip, state, device_type, source_type_id, form_type_id, lead_data, total_opportunities, total_listings, total_revenue, total_cost, uid, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20) RETURNING *', data, (error, results) => {
                if (error) {
                    errorHandler.notify({message: JSON.stringify({error: error.message, from: 'storeCallPing'})});
                    resolve({success: false});
                } else {
                    if (results.rows[0]) {
                        this.ping_id = results.rows[0].id;
                        this.storeCallPingDetails(original_primary_phone).then(resp => {
                            resolve({success: true});
                        });
                        try {
                            this.storeCallPingMatches(this.ping_id, zip, lead_type_id);
                        } catch (ex) {
                            errorHandler.notify(ex);
                            console.log('Call Ping Match', ex);
                        }
                    } else {
                        errorHandler.notify({message: `storeLeadPing no id return from database ${JSON.stringify(results)}`});
                        resolve({success: false});
                    }
                }
            });
        });
    }

    async storeCallPingDetails(original_primary_phone = '') {
        return new Promise((resolve, reject) => {
            let insured = util.getParam(this.params, 'currently_insured') === true;
            let continuous_coverage = `${util.getParam(this.params, 'coverage_years') || 0} years`;
            let gender = util.getParam(this.params, 'gender');
            let marital_status = util.getParam(this.params, 'marital_status');
            let education = util.getParam(this.params, 'education');
            let credit_rating = util.getParam(this.params, 'credit');
            let military_affiliation = util.getParam(this.params, 'military_affiliation') === true;
            let first_name = util.getParam(this.params, 'first_name');
            let last_name = util.getParam(this.params, 'last_name');
            let email = util.getParam(this.params, 'email');
            let phone = util.getParam(this.params, 'primary_phone');
            if (original_primary_phone.length > 15) {
                phone = original_primary_phone;
            }
            let city = util.getParam(this.params, 'city');
            let county = util.getParam(this.params, 'county');
            let num_drivers = util.getParam(this.params, 'num_drivers') || 0;
            let num_vehicles = util.getParam(this.params, 'num_vehicles') || 0;
            let violations = util.getParam(this.params, 'num_violations') > 0;
            let accidents = util.getParam(this.params, 'num_accidents') > 0;
            let dui = util.getParam(this.params, 'dui') === true;
            let tobacco = util.getParam(this.params, 'tobacco') === true;
            let life_coverage_type = util.getParam(this.params, 'coverage_type');
            let life_coverage_amount = util.getParam(this.params, 'coverage_amount');
            let property_type = util.getParam(this.params, 'property_type');
            let property_age = util.getParam(this.params, 'year_built');
            let years_in_business = util.getParam(this.params, 'years_in_business');
            let commercial_coverage_type = this.commercialCoverageTypes();
            let household_income = util.getParam(this.params, 'household_income');
            let major_health_conditions = this.majorHealthConditions();
            let home_owner = this.getHomeOwner();
            let consumer_age = util.getParam(this.params, 'age');
            let jornaya_lead_id = util.getParam(this.params, 'jornaya_lead_id');
            let trusted_form_token = util.getParam(this.params, 'trusted_form_token');
            let license_status = 'Active'; // Todo: have to get it from params
            let current_date_time = new Date();
            let data = [this.ping_id, insured, continuous_coverage, home_owner, gender, marital_status, consumer_age, education, credit_rating, military_affiliation, num_drivers, num_vehicles, violations, dui, accidents, license_status, first_name, last_name, phone, email, city, county, tobacco, major_health_conditions, life_coverage_type, life_coverage_amount, property_type, property_age, years_in_business, commercial_coverage_type, household_income, jornaya_lead_id, trusted_form_token, current_date_time, current_date_time];
            this.db.query('INSERT INTO call_ping_details (call_ping_id, insured, continuous_coverage, home_owner, gender, marital_status, consumer_age, education, credit_rating, military_affiliation, num_drivers, num_vehicles, violations, dui, accidents, license_status, first_name, last_name, phone, email, city, county, tobacco, major_health_conditions, life_coverage_type, life_coverage_amount, property_type, property_age, years_in_business, commercial_coverage_type, household_income, jornaya_lead_id, trusted_form_token, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35) RETURNING *', data, (error, results) => {
                if (error) {
                    console.log("Call Ping Details Error: ", error.message);
                    errorHandler.notify(error);
                    resolve({success: false});
                } else {
                    resolve({success: true});
                }
            });
        });
    }

    async storeCallListing(campaign_listings, check_rtb_cm_max_bid = true) {
        this.carriers = await this.loadCarriers();
        return new Promise(async (resolve, reject) => {
            let all_promise = [];
            let selected_listings = {};
            let campaign_integrations = {};
            let integration_promise = [];
            for (let integration of this.ping_integrations) {
                campaign_integrations[integration.campaign_id] = integration;
            }
            for (let listing of campaign_listings) {
                integration_promise.push(this.getPingIntegrationListings(campaign_integrations[listing.campaign_id], listing));
            }
            Promise.all(integration_promise).then(ping_listings => {
                ping_listings = ping_listings.flat();
                ping_listings = this.applyBrandDedupe(ping_listings);
                let selected_listings = this.selectedListings(ping_listings);
                if (check_rtb_cm_max_bid && this.token_type === 'generic') { // Apply RTB CM and Check max bid for generic token
                    selected_listings = this.applyRTBCMMaxBid(selected_listings);
                }
                for (let listing of ping_listings) {
                    let selected_listing = selected_listings.filter(l => l.id === listing.id).length > 0;
                    listing.de_duped = !selected_listing;
                    listing.selected = selected_listing;
                    all_promise.push(this.storeCallListingDB(listing));
                }
                Promise.all(all_promise).then(results => {
                    resolve(results);
                });
            });
        });
    }

    applyRTBCMMaxBid(listings) {
        return listings.map(listing => {
            let rtb_cm = parseFloat(listing.rtb_cm || '1');
            let max_bid = parseFloat(listing.max_bid || '99999');
            console.log(`rtb_cm: ${rtb_cm}, max_bid: ${max_bid}`);
            listing.price = (listing.price * rtb_cm) > max_bid ? max_bid : (listing.price * rtb_cm);
            listing.est_payout = (listing.est_payout * rtb_cm) > max_bid ? max_bid : (listing.est_payout * rtb_cm);
            return listing;
        });
    }

    async storeCallOpportunity() {
        return new Promise((resolve, reject) => {
            let all_promise = [];
            for (let listing of this.campaign_list) {
                all_promise.push(this.callOpportunityData(listing))
            }
            Promise.all(all_promise).then(results => {
                this.storeCallOpportunityDB(results);
                //console.log("storeCallOpportunity Response: ", results)
            });
        });
    }

    async callOpportunityData(listing) {
        return new Promise((resolve, reject) => {
            const current_date_time = new Date();
            const active_source_setting = !(listing.active_source === false || listing.active_source == 0)

            this.updateCallResultOpportunity(listing, active_source_setting);
            resolve([this.ping_id, listing.campaign_id, listing.ad_group_id, listing.brand_id, listing.account_id, listing.base_bid_price, current_date_time, current_date_time]);
        });
    }

    async storeCallOpportunityDB(value_set) {
        const columns = ['call_ping_id', 'campaign_id', 'ad_group_id', 'brand_id', 'account_id', 'payout', 'created_at', 'updated_at'];
        this.orm.batchInsert('call_opportunities', columns, value_set).then(result => {
            // console.log("call_opportunities stored");
        }, error => {
            errorHandler.notify(error);
            console.log('Unable to add call_opportunities', error.message);
        });
    }

    async updateCallResultOpportunity(listing, active_source_setting) {
        let call_result_data = this.getCallResultListingData(listing);
        call_result_data.opportunity = true;
        call_result_data.active_source = active_source_setting;
        call_result_data.est_payout = listing.base_bid_price;
        this.updateCallResult(this.ping_id, listing.account_id, listing.campaign_id, listing.ad_group_id, call_result_data);
    }

    async storeDebugData(resp_time, num_listing) {
        let current_date_time = new Date();
        let data = [this.ping_id, JSON.stringify({campaigns: Object.values(this.debug_data.campaigns)}), resp_time, num_listing, this.req_token, current_date_time, current_date_time]
        this.db.query('INSERT INTO call_ping_debug_logs (call_ping_id, log, response_time_ms, num_listings, token, created_at, updated_at) VALUEs($1, $2, $3, $4, $5, $6, $7)', data, (error, result) => {
            if (error) {
                errorHandler.notify(error);
                console.log("Error Store Debug", error.message);
            } else {
                //console.log('Store call debug log success');
            }
        });
    }

    async storeCallPingMatches(ping_id, zip, lead_type_id) {
        try {
            const ping_matches = await this.getPingMatches(zip, lead_type_id, 2, this.token_bid_multipliers);
            let ping_match_promise = [];
            const pst_columns = await this.getPSTColumns();
            for (let ping_match of ping_matches) {
                ping_match_promise.push(this.callPingMatchesData(ping_id, ping_match, pst_columns));
            }
            if (ping_match_promise.length > 0) {
                Promise.all(ping_match_promise).then(async results => {
                    let value_set = [];
                    let column_set = [];
                    let counter = 1;
                    for (let result of results) {
                        let val = []
                        let match_result = result.call_match;
                        for (let key in match_result) {
                            val.push(`$${counter}`);
                            counter += 1;
                        }
                        column_set.push(`(${val})`);
                        value_set.push(match_result);
                    }
                    this.db.query(`INSERT INTO call_ping_matches (call_ping_id, account_id, campaign_id,
                                                                  ad_group_id, brand_id, ad_group_active,
                                                                  payout, pst_hour, pst_day, pst_week,
                                                                  pst_month, pst_quarter, pst_year,
                                                                  created_at, updated_at)
                    VALUES
                    ${column_set.join(', ')}`, value_set.flat(), (error, result) => {
                        if (error) {
                            errorHandler.notify(error);
                        }
                    });
                    this.storeCallResultDB(results);
                });
            }
        } catch (ex) {
            errorHandler.notify({message: `Call Store ping matches: ${ex.message}`});
        }
    }

    async callPingMatchesData(ping_id, ping_match, pst_columns) {
        try {
            let current_date_time = new Date();
            let ping_match_data = [ping_id, ping_match.account_id, ping_match.campaign_id, ping_match.ad_group_id, ping_match.brand_id, ping_match.ad_group_active, ping_match.payout || 0.0, pst_columns.pst_hour, pst_columns.pst_day, pst_columns.pst_week, pst_columns.pst_month, pst_columns.pst_quarter, pst_columns.pst_year, current_date_time, current_date_time]
            return {
                call_match: ping_match_data,
                call_result: this.callResultData(ping_id, ping_match, pst_columns),
                non_rtb_data: this.collectNonRtbDataExt(ping_match)
            }
        } catch (ex) {
            errorHandler.notify({message: `Store ping matches: ${ex.message}`});
        }
    }

    callResultData(ping_id, ping_match, pst_columns) {
        let current_date_time = new Date();
        let source_type_id = util.getParam(this.params, 'source_type_id') || this.source_type_id;
        let lead_type_id = util.getParam(this.params, 'lead_type_id') || 6;
        let aid = util.getParam(this.params, 'aid');
        let cid = util.getParam(this.params, 'cid');
        let insured = util.toLowerCase(util.getParam(this.params, 'currently_insured')) === 'yes'
        let cont_coverage = util.getParam(this.params, 'coverage_years') || 0;
        cont_coverage = `${cont_coverage} years`;
        let military = util.toLowerCase(util.getParam(this.params, 'military_affiliation')) === 'yes'
        let homeowner = this.getHomeOwner();
        let num_drivers = util.getParam(this.params, 'num_drivers') || 0
        let num_vehicles = util.getParam(this.params, 'num_vehicles') || 0
        let violations = util.getParam(this.params, 'num_violations') > 0
        let accidents = util.getParam(this.params, 'num_accidents') > 0
        let dui = util.toLowerCase(util.getParam(this.params, 'dui')) === 'yes'
        let ip_address = util.getParam(this.params, 'ip_address')
        let first_name = util.getParam(this.params, 'first_name')
        let last_name = util.getParam(this.params, 'last_name')
        let email = util.getParam(this.params, 'email');
        let phone = util.getParam(this.params, 'primary_phone');
        let city = util.getParam(this.params, 'city')
        let county = util.getParam(this.params, 'county');
        let gender = util.getParam(this.params, 'gender');
        let marital_status = util.getParam(this.params, 'marital_status');
        let education = util.getParam(this.params, 'education');
        let credit = util.getParam(this.params, 'credit');
        let tobacco = util.toLowerCase(util.getParam(this.params, 'tobacco')) === 'yes';
        let major_health_conditions = this.majorHealthConditions();
        let life_coverage_type = util.getParam(this.params, 'coverage_type');
        let life_coverage_amount = util.getParam(this.params, 'coverage_amount');
        let property_type = util.getParam(this.params, 'property_type');
        let property_age = util.getParam(this.params, 'year_built');
        let years_in_business = util.getParam(this.params, 'years_in_business');
        let commercial_coverage_type = this.commercialCoverageTypes();
        let household_income = util.getParam(this.params, 'household_income');
        let license_status = util.getParam(this.params, 'license_status');
        let zip = util.getParam(this.params, 'zip');
        let state = util.getParam(this.params, 'state');
        let device_type = util.getParam(this.params, 'device_type') || '';
        let mobile = util.toLowerCase(device_type) === 'mobile';
        let session_id = util.getParam(this.params, 'session_id');

        return [ping_id, this.partner_id, ping_match.account_id, ping_match.campaign_id, ping_match.ad_group_id, ping_match.brand_id, ping_match.payout || 0.0, source_type_id, lead_type_id, true, pst_columns.pst_hour, pst_columns.pst_day, pst_columns.pst_week, pst_columns.pst_month, pst_columns.pst_quarter, pst_columns.pst_year, aid, cid, first_name, last_name, phone, email, homeowner, this.params.age, military, num_drivers, num_vehicles, violations, dui, accidents, city, county, tobacco, major_health_conditions, life_coverage_type, life_coverage_amount, property_type, property_age, years_in_business, license_status, device_type, zip, state, education, credit, ip_address, cont_coverage, commercial_coverage_type, gender, marital_status, household_income, insured, mobile, session_id, current_date_time, current_date_time]
    }

    async storeCallResultDB(results) {
        let value_set = [];
        let counter_set = [];
        let non_rtb_values = []
        let counter = 1;
        for (let result of results) {
            let val = []
            let call_result = result.call_result;
            non_rtb_values.push([...result.call_result, ...Object.values(result.non_rtb_data)]);
            for (let key in call_result) {
                val.push(`$${counter}`);
                counter += 1;
            }
            counter_set.push(`(${val})`);
            value_set.push(call_result);
        }
        const column_set = this.callResultAttrs();
        value_set = value_set.flat();
        // Concat non rtb columns with call result columns and store non rtb data
        this.storeNonRtbPingStat(2, [...column_set, ...Object.keys(results[0].non_rtb_data)], non_rtb_values);

        setTimeout(() => {
            this.db.query(`INSERT INTO call_results (${column_set.join(', ')})
            VALUES
            ${counter_set.join(', ')}`, value_set.flat(), (error, result) => {
                if (error) {
                    console.log('Call Result: ', error);
                    errorHandler.notify(error);
                }
            });
        }, 1000);
    }

    callResultAttrs() {
        return [
            'call_ping_id', 'partner_id', 'account_id', 'campaign_id', 'ad_group_id',
            'brand_id', 'payout', 'source_type_id', 'lead_type_id', 'match', 'pst_hour',
            'pst_day', 'pst_week', 'pst_month', 'pst_quarter', 'pst_year', 'aid', 'cid',
            'first_name', 'last_name', 'phone', 'email', 'home_owner', 'consumer_age',
            'military_affiliation', 'num_drivers', 'num_vehicles', 'violations',
            'dui', 'accidents', 'city', 'county', 'tobacco', 'major_health_conditions',
            'life_coverage_type', 'life_coverage_amount', 'property_type',
            'property_age', 'years_in_business', 'license_status', 'device_type',
            'zip', 'state', 'education', 'credit_rating', 'ip_address',
            'continuous_coverage', 'commercial_coverage_type', 'gender',
            'marital_status', 'household_income', 'insured', 'mobile', 'session_id',
            'created_at', 'updated_at'
        ];
    }

    getCallResultListingData(listing) {
        return {
            payout: listing.price,
            est_payout: listing.price,
            post_payout: listing.post_payout || 0,
            brand_id: listing.brand_id,
            excluded: this.campaign_exclusion.includes(listing.campaign_id),
            license_num: listing.license_number,
            carrier_id: listing.carrier_id,
            transfer_number: listing.transfer_number,
            tracking_number: listing.tracking_number,
            billable_duration: listing.billable_duration,
            de_duped: listing.de_duped,
            buyer: listing.buyer || '',
            ping_post: listing.ping_post,
            pp_ping_id: listing.pp_ping_id || '',
            pp_bid_id: listing.pp_bid_id || '',
        }
    }

    async updateCallResult(call_ping_id, account_id, campaign_id, ad_group_id, data, call_listing_id = null, data_ext = {}) {
        let counter = 1;
        let columns = [];
        let values = [];
        data.updated_at = new Date();

        for (let field in data) {
            values.push(data[field]);
            columns.push(`${field} = $${counter}`);
            counter += 1;
        }
        const query = `update call_results
                       set ${columns.join(',')}
                       where account_id = ${account_id}
                         and campaign_id = ${campaign_id}
                         and call_ping_id = ${call_ping_id}
                         and ad_group_id = ${ad_group_id}`;
        setTimeout(() => {
            this.db.query(query, values, (error, result) => {
                if (error) {
                    errorHandler.notify(error);
                } else {
                    //console.log('Update call result success');
                }
            });
        }, 2000);

        let rtb_data = Object.assign({}, data);

        this.updateNonRtbPingStat(2, {
            ping_id: call_ping_id,
            listing_id: call_listing_id,
            account_id,
            campaign_id,
            ad_group_id
        }, {...rtb_data, ...data_ext});
    }

    async storeCallListingDB(listing) {
        return new Promise((resolve, reject) => {
            listing.bid_id = uuid.v4();
            let current_date_time = new Date();
            let billable_duration = listing.billable_duration || 90;
            let company_name = util.toLowerCase(listing.company_name) === 'independent agent' ? listing.business_name : listing.company_name;
            let buyer = listing.carrier_id === '32' ? listing.brand_name : company_name;
            let data = [this.ping_id, listing.campaign_id, listing.brand_id, listing.account_id, listing.ad_group_id, listing.carrier_id, listing.price, (listing.est_payout || listing.price), listing.bid_id, listing.selected, listing.de_duped, listing.license_number, listing.tracking_number, listing.transfer_number, buyer, billable_duration, listing.pp_ping_id, listing.pp_bid_id, listing.ping_post, current_date_time, current_date_time];
            this.db.query('INSERT INTO call_listings (call_ping_id, campaign_id, brand_id, account_id, ad_group_id, carrier_id, payout, est_payout, bid_id, selected, de_duped, license_num, tracking_number, transfer_number, buyer, billable_duration, pp_ping_id, pp_bid_id, ping_post, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21) RETURNING *', data, async (error, results) => {
                if (error) {
                    errorHandler.notify(error);
                    listing.call_listing_id = null;
                } else {
                    listing.call_listing_id = results.rows[0].id;
                    this.call_listing_id = results.rows[0].id;
                    let call_result_data = this.getCallResultListingData(listing);
                    call_result_data.listing = true;
                    call_result_data.opportunity = true;
                    call_result_data.active_source = !(listing.active_source === false || listing.active_source == 0);

                    const non_rtb_data = {...this.collectNonRtbDataExt(listing), ...{call_listing_id: listing.call_listing_id}};

                    if (listing.ping_post) {
                        const call_result_count = await this.findCallResultForListing(this.ping_id, listing.campaign_id, listing.ad_group_id, listing.account_id);
                        // console.log('result count: ', call_result_count);
                        if (call_result_count) {
                            this.updateCallResult(this.ping_id, listing.account_id, listing.campaign_id, listing.ad_group_id, call_result_data, null, non_rtb_data)
                        } else {
                            const pst_columns = await this.getPSTColumns();
                            this.storeCallResultFromListing(this.callResultData(this.ping_id, {
                                account_id: listing.account_id,
                                campaign_id: listing.campaign_id,
                                ad_group_id: listing.ad_group_id,
                                brand_id: listing.brand_id,
                                payout: listing.price,
                                product_type_id: listing.product_type_id
                            }, pst_columns), call_result_data, non_rtb_data);
                        }
                    } else {
                        this.updateCallResult(this.ping_id, listing.account_id, listing.campaign_id, listing.ad_group_id, call_result_data, null, non_rtb_data);
                    }
                }
                resolve(listing);
            });
        });
    }

    async findCallResultForListing(call_ping_id, campaign_id, ad_group_id, account_id) {
        return this.orm.select('call_results', ['COUNT(*)'],
            `account_id = ${account_id} and campaign_id = ${campaign_id} and call_ping_id = ${call_ping_id}
             and ad_group_id = ${ad_group_id}`).then((result) => {
            return parseInt(result.rows[0]?.count || '0');
        }, (err) => {
            console.log('err: ', err);
            return 0;
        });
    }

    async storeCallResultFromListing(call_result_data, additional_data_obj, non_rtb_data) {
        const columns = this.callResultAttrs();
        const values = Object.assign([], call_result_data);

        for (const key in additional_data_obj) {
            const key_at = columns.indexOf(key);
            if (key_at < 0) {
                columns.push(key);
                values.push(additional_data_obj[key]);
            } else {
                values[key_at] = additional_data_obj[key];
            }
        }
        setTimeout(() => {
            this.orm.batchInsert('call_results', columns, [values]).then(() => {
            }, (err) => {
                errorHandler.notify(err);
            });
        }, 1000);

        this.storeNonRtbPingFromListing(columns, values, non_rtb_data);
    }

    async storeNonRtbPingFromListing(columns, values, non_rtb_data) {
        const rtb_columns = Object.assign([], columns);
        const rtb_values = Object.assign([], values);
        for (const key in non_rtb_data) {
            const key_at = rtb_columns.indexOf(key);
            if (key_at < 0) {
                rtb_columns.push(key);
                rtb_values.push(non_rtb_data[key]);
            } else {
                rtb_values[key_at] = non_rtb_data[key];
            }
        }
        this.storeNonRtbPingStat(2, rtb_columns, [rtb_values]);
    }

    async updateCallPings(num_listings) {
        this.db.query('update call_pings set total_opportunities = $1, total_listings = $2 where id = $3', [this.campaign_list.length, num_listings, this.ping_id], (error, results) => {
            if (error) {
                errorHandler.notify(error);
            }
        });
    }

    async storeCallPost(call_ping_id, post_data) {
        this.post_uid = uuid.v4();
        let partner_id = this.token_id;
        const total_revenue = 0;
        const total_cost = 0;
        let lead_type_id = util.getParam(this.params, 'lead_type_id') || 6;
        let timestamps = new Date();
        let zip = util.getParam(this.params, 'zip');
        let state = util.getParam(this.params, 'state');

        let data = [call_ping_id, partner_id, lead_type_id, zip, state, true, total_cost, total_revenue, false, post_data, this.post_uid, timestamps, timestamps];
        this.db.query('INSERT INTO call_posts (call_ping_id, partner_id, lead_type_id, zip, state, accepted, "cost", revenue, refunded, "data", uid, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13) RETURNING *', data, (error, results) => {
            if (error) {
                errorHandler.notify({message: JSON.stringify({error: error.message, from: 'storeLeadPost'})});
            } else {
                if (results.rows[0]) {
                    this.post_id = results.rows[0].id;
                    this.storeCallPostDetails();
                } else {
                    errorHandler.notify({message: `storeCallPost no id return from database ${JSON.stringify(results)}`});
                }
            }
        });
    }

    async storeCallPostDetails() {
        let insured = util.getParam(this.params, 'currently_insured') === true;
        let continuous_coverage = `${util.getParam(this.params, 'coverage_years') || 0} years`;
        let gender = util.getParam(this.params, 'gender');
        let marital_status = util.getParam(this.params, 'marital_status');
        let education = util.getParam(this.params, 'education');
        let credit_rating = util.getParam(this.params, 'credit');
        let military_affiliation = util.getParam(this.params, 'military_affiliation') === true;
        let first_name = util.getParam(this.params, 'first_name');
        let last_name = util.getParam(this.params, 'last_name');
        let email = util.getParam(this.params, 'email');
        let phone = util.getParam(this.params, 'primary_phone');
        let city = util.getParam(this.params, 'city');
        let county = util.getParam(this.params, 'county');
        let num_drivers = util.getParam(this.params, 'num_drivers') || 0;
        let num_vehicles = util.getParam(this.params, 'num_vehicles') || 0;
        let violations = util.getParam(this.params, 'num_violations') > 0;
        let accidents = util.getParam(this.params, 'num_accidents') > 0;
        let dui = util.getParam(this.params, 'dui') === true;
        let tobacco = util.getParam(this.params, 'tobacco') === true;
        let life_coverage_type = util.getParam(this.params, 'coverage_type');
        let life_coverage_amount = util.getParam(this.params, 'coverage_amount');
        let property_type = util.getParam(this.params, 'property_type');
        let property_age = util.getParam(this.params, 'year_built');
        let years_in_business = util.getParam(this.params, 'years_in_business');
        let commercial_coverage_type = this.commercialCoverageTypes();
        let household_income = util.getParam(this.params, 'household_income');
        let major_health_conditions = this.majorHealthConditions();
        let home_owner = util.toLowerCase(util.getParam(this.params, 'own_home')) === 'Yes';
        let consumer_age = util.getParam(this.params, 'age') || 18;
        let jornaya_lead_id = util.getParam(this.params, 'jornaya_lead_id');
        let trusted_form_token = util.getParam(this.params, 'trusted_form_token');
        let license_status = 'Active'; // Todo: have to get it from params
        let current_date_time = new Date();
        let data = [this.post_id, insured, continuous_coverage, home_owner, gender, marital_status, consumer_age, education, credit_rating, military_affiliation, num_drivers, num_vehicles, violations, dui, accidents, license_status, first_name, last_name, phone, email, city, county, tobacco, major_health_conditions, life_coverage_type, life_coverage_amount, property_type, property_age, years_in_business, commercial_coverage_type, household_income, jornaya_lead_id, trusted_form_token, current_date_time, current_date_time];
        this.db.query('INSERT INTO call_post_details (call_post_id, insured, continuous_coverage, home_owner, gender, marital_status, consumer_age, education, credit_rating, military_affiliation, num_drivers, num_vehicles, violations, dui, accidents, license_status, first_name, last_name, phone, email, city, county, tobacco, major_health_conditions, life_coverage_type, life_coverage_amount, property_type, property_age, years_in_business, commercial_coverage_type, household_income, jornaya_lead_id, trusted_form_token, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35) RETURNING *', data, (error, results) => {
            if (error) {
                console.log("Call Post Details Error: ", error.message);
                errorHandler.notify(error);
            }
        });
    }

    async updateCallPostStatus(status) {
        const data = [status, this.post_id];
        this.db.query('UPDATE call_posts set accepted = $1 where id = $2', data, (error, results) => {
            if (error) {
                errorHandler.notify(error);
            }
        });
    }

    async updateCallListings(listings) {
        const proms = [];
        for (let listing of listings) {
            proms.push(this.updateCallListingsDB(listing));
        }
        Promise.all(proms).then(results => {
            // console.log('update call listings', results);
        });
    }

    async updateCallListingsDB(listing) {
        return new Promise((resolve, reject) => {
            const data = [listing.payout, listing.transfer_number, listing.billable_duration, listing.bid_id]
            this.db.query('UPDATE call_listings set post_payout = $1, transfer_number = $2, billable_duration = $3 where bid_id = $4', data, (error, results) => {
                if (error) {
                    errorHandler.notify(error);
                    resolve(false);
                } else {
                    resolve(true);
                }
            });
        });
    }

    async checkCallDuplicacy(account_id, phone) {
        let dateObj = new Date();
        dateObj.setDate(dateObj.getDate() - 30);
        const last30_days = dateObj.getFullYear() + "-" + (dateObj.getMonth() + 1) + "-" + dateObj.getDate();
        const query = `select count(*)
                       from quote_calls
                       where account_id = ${account_id}
                         and caller = '${phone}'
                         and charged is true
                         and DATE(created_at) > '${last30_days}'`;
        return this.db.query(query).then((results) => {
            return results.rows[0].count > 0;
        }, err => {
            errorHandler.notify(err);
            return false;
        });
    }

    async checkCallConcurrency(campaign_id) {
        let dateObj = new Date();
        dateObj.setDate(dateObj.getDate() - 30);
        const last30_days = dateObj.getFullYear() + "-" + (dateObj.getMonth() + 1) + "-" + dateObj.getDate();
        const query = `select *
                       from call_campaign_settings ccs
                                inner join
                            (select campaign_id, count(*) as in_progress_calls
                             from quote_calls
                             where status = 'in-progress'
                             group by 1) imp on imp.campaign_id = ccs.campaign_id
                       where imp.campaign_id = ${campaign_id}
                         and (ccs.concurrency_cap IS NOT NULL AND
                              coalesce(in_progress_calls, 0) >= ccs.concurrency_cap)`;
        return this.db.query(query).then((results) => {
            return results.rows.length > 0;
        }, err => {
            errorHandler.notify(err);
            return false;
        });
    }

    static async checkAvailableAgents() {
        return await axios.get('https://api.convoso.com/v1/user-activity/search?auth_token=e4augcm6i05qez6xq9n8qk9z9cpldjdi&campaign_id=&queue_id=4310,4311,4312,4423,4424,4425&user_id=&filter_by_skill_options=').then(response => {
            return response.data ? (response.data.data.available_agents || 0) : 0;
        }).catch(error => {
            errorHandler.notify(error);
            return 0;
        });
    }
}
