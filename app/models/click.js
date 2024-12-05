require('./click_debug');
const LeadIntegration = require('./lead_integration');
const axios = require('axios');
const util = require('./utils');
const flatten = require('flat');
const State = require('./state');
const DataState = require('./data_state');
const ClickResult = require('./click_result');
const RtbBidCalculator = require('./rtb_bid_calculator');
const mongoose = require('mongoose');
const ErrorHandler = require("./error_handler");
const ClickDebug = mongoose.model('ClickDebug');
const errorHandler = new ErrorHandler();
const ExchangeIntegration = require('./bid_check_integration');
const AESCipher = require("./aes_cipher");
const MiniOrm = require('../lib/mini_orm');

module.exports = class Click extends LeadIntegration {
    date = new Date();
    source_type_id = '';
    campaign_exclusion = []
    campaign_list = []
    bid_multipliers = {}
    campaign_ids = [];
    device_types = ["'both'"];
    mobile_device = true;
    token_type = '';
    token_id = '';
    click_ping = 0;
    ads = {}
    ping_id = null;
    req_token = "";
    req_params = {};
    debug_data = {
        campaigns: {}
    }
    click_listings = {};
    data_state_info = {};
    pst_columns = [];
    rtbBidObj = null;
    rtb_bid_check = null;
    click_results = [];

    constructor(brand_conf, pm, tbm) {
        super();
        this.db = brand_conf.db;
        this.read_replica_db = (brand_conf.read_replica || brand_conf).db;
        this.brand_conf = brand_conf;
        this.params = pm;
        this.token_bid_multipliers = tbm || [];
        this.orm = new MiniOrm(brand_conf.db);
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
            this.mobile_device = device_type.toLowerCase() !== 'desktop';
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

    async qualifyAdGroup() {
        return new Promise((resolve, reject) => {
            if (this.campaign_ids.length <= 0) {
                return resolve([]);
            }
            let query = "select ag.id ad_group_id, agf.include, ag.campaign_id, agf.filter_value, agf.filter_value_min, agf.filter_value_max, sf.name, sf.query_param, sf.filter_type  from ad_groups ag inner join ad_group_filters agf on agf.ad_group_id = ag.id inner join sf_filters sf on agf.sf_filter_id = sf.id where agf.discarded_at IS NULL and ag.discarded_at IS NULL and ag.campaign_id in (" + this.campaign_ids + ") and ag.active = true";
            this.db.query(query, (error, results) => {
                if (error) {
                    errorHandler.notify(error);
                    return resolve([]);
                }
                let qualify_ad_groups = {};
                let qualify_ad_group_ids = [];
                let ad_groups = results.rows;
                for (let ad_group of ad_groups) {
                    let campaign_id = ad_group.campaign_id;
                    let ad_group_id = ad_group.ad_group_id;
                    if (qualify_ad_groups[campaign_id] && typeof (qualify_ad_groups[campaign_id][ad_group_id]) != 'undefined') {
                        qualify_ad_groups[campaign_id][ad_group_id] *= this.filterAdGroup(ad_group); // AND filters within a group which is *
                    } else {
                        if (typeof (qualify_ad_groups[campaign_id]) == 'undefined') {
                            qualify_ad_groups[campaign_id] = {};
                        }
                        qualify_ad_groups[campaign_id][ad_group_id] = this.filterAdGroup(ad_group) ? 1 : 0;
                    }
                    if (!this.geo_filter.includes(ad_group.name)) { // Not include geo filter in debug log
                        this.setDebugData(campaign_id, 'ad_group_filter_groups', {
                            id: ad_group_id,
                            condition: this.getFilterCondition(ad_group),
                            qualified: this.filterAdGroup(ad_group) ? 1 : 0
                        }, true);
                    }
                } // Filter ad group under/group by campaign
                for (let campaign_id in qualify_ad_groups) {
                    let qualify_ad_group = qualify_ad_groups[campaign_id];
                    let qualify_campaign = 0;
                    for (let ad_group_id in qualify_ad_group) {
                        qualify_campaign += qualify_ad_group[ad_group_id];
                        if (qualify_ad_group[ad_group_id]) {
                            qualify_ad_group_ids.push(ad_group_id); // Qualify ad_group id that qualify filter
                        }
                    }
                    if (qualify_campaign === 0) {
                        this.campaign_exclusion.push(campaign_id); // Does not qualify any ad_group
                        this.setDebugData(campaign_id, 'exclusion', 'Does not qualify any ad_group');
                    }
                }
                resolve(qualify_ad_group_ids);
            });
        });
    }

    async budgetFilter() {
        return new Promise((resolve, reject) => {
            for (let campaign of this.campaign_list) {
                if ((campaign.spent && campaign.budgets && campaign.spent >= campaign.budgets) ||
                    (campaign.units && campaign.volume_budget && campaign.units >= campaign.volume_budget)) {
                    this.campaign_exclusion.push(campaign.campaign_id);
                    this.setDebugData(campaign.campaign_id, 'exclusion', 'Daily budget reached (budget)');
                } else if ((campaign.monthly_spend && campaign.monthly_budget && campaign.monthly_spend >= campaign.monthly_budget) ||
                    (campaign.monthly_vol && campaign.monthly_volume && campaign.monthly_vol >= campaign.monthly_volume)) {
                    this.campaign_exclusion.push(campaign.campaign_id);
                    this.setDebugData(campaign.campaign_id, 'exclusion', 'Monthly budget reached (budget)');
                }
            }
            resolve([]);
        });
    }

    async adGroups() {
        let integration_campaign_ids = this.ping_integrations.map(integration => integration.campaign_id);
        return new Promise((resolve, reject) => {
            if (this.campaign_ids.length <= 0) {
                resolve([]);
                return;
            }
            this.qualifyAdGroup().then(qualify_ad_group_ids => {
                this.filter_ad_group_list = qualify_ad_group_ids;
                if (qualify_ad_group_ids.length > 0) {
                    let query = "select ad.id ad_id, agf.filter_value, ad.carriers, ad.ad_name, sf.name, sf.query_param, sf.filter_type, ad.ad_image_url, aga.weight, aga.active_weight, aga.weight_type, aga.platform, ag.campaign_id, adc.title, adc.bullet_points, adc.display_url, adc.display_name from ad_groups ag inner join ad_group_ads aga on ag.id = aga.ad_group_id inner join ads ad on aga.ad_id = ad.id inner join ad_contents adc on ad.id = adc.ad_id inner join ad_group_filters agf on ag.id = agf.ad_group_id inner join sf_filters sf on sf.id = agf.sf_filter_id where adc.discarded_at IS NULL and agf.discarded_at IS NULL and ad.discarded_at IS NULL and aga.discarded_at IS NULL and ag.discarded_at IS NULL and ag.id in (" + qualify_ad_group_ids + ") and ag.base_bid_price IS NOT NULL and aga.platform in (" + this.device_types + ")";
                    this.db.query(query, (error, results) => {
                        if (error) {
                            errorHandler.notify(error);
                            return resolve(this.ads);
                        }
                        let ad_groups = results ? results.rows : [];
                        for (let ad_group of ad_groups) {
                            let campaign_id = ad_group.campaign_id;

                            if (campaign_id) {
                                this.ads[campaign_id].push(ad_group);
                            }
                        }
                        query = "select ad.id ad_id, ad.ad_image_url, ad.carriers, ad.ad_name, ca.weight, ca.active_weight, ca.weight_type, ca.platform, ca.campaign_id, adc.title, adc.bullet_points, adc.display_url, adc.display_name from campaign_ads ca inner join ads ad on ca.ad_id = ad.id inner join ad_contents adc on ad.id = adc.ad_id where ca.discarded_at IS NULL and ad.discarded_at IS NULL and ca.campaign_id in (" + this.campaign_ids + ") and ca.platform in (" + this.device_types + ")";
                        this.db.query(query, (err, results) => {
                            if (err) {
                                errorHandler.notify(err);
                                return resolve(this.ads);
                            }
                            let campaign_ads = results ? results.rows : [];
                            for (let campaign_ad of campaign_ads) {
                                let campaign_id = campaign_ad.campaign_id;
                                if (this.ads[campaign_id]) {
                                    this.ads[campaign_id].push(campaign_ad);
                                }
                            }
                            for (let campaign_id of this.campaign_ids) {
                                // Disqualify campaign if there are no ads but skip for integration campaign
                                if (this.ads[campaign_id].length <= 0 && !integration_campaign_ids.includes(campaign_id)) {
                                    this.campaign_exclusion.push(campaign_id);
                                    this.setDebugData(campaign_id, 'exclusion', 'No ads of this campaign');
                                }
                            }
                            resolve(this.ads);
                        });
                    });
                } else {
                    resolve([]);
                }
            });
        });
    }

    async processResponse(startTime) {
        let brand_name = util.toLowerCase(this.brand_conf.name);
        const res_campaign = {};
        let brand_campaigns = {};
        let filtered_ad_group_campaign = [];
        res_campaign['listings'] = [];
        let integration_campaign_ids = this.ping_integrations.map(integration => integration.campaign_id);
        this.campaign_list = this.campaign_list.map(campaign => {
            campaign.price = this.getFinalPrice(campaign.campaign_id, campaign.base_bid_price);
            return campaign;
        }); // Calculate campaign/listing price
        if (this.token_type === 'admin' && brand_name === 'goal') {
            this.campaign_list = await this.applyBPFMScore(this.campaign_list);
        }
        for (let campaign of this.campaign_list) {
            let campaign_id = campaign.campaign_id;
            let ad_group_id = campaign.ad_group_id;
            if (this.campaign_exclusion.includes(campaign_id)) {
                this.setDebugData(campaign_id, 'qualified', false);
                filtered_ad_group_campaign.push(campaign_id);
                continue;
            }
            // check both campaign and ad group are in qualified list
            if (this.filter_campaign_list.includes(campaign_id)) {
                // Only process campaign with qualify ad group id
                if (this.filter_ad_group_list.includes(ad_group_id)) {
                    campaign.price = this.getFinalPrice(campaign_id, campaign.base_bid_price);
                    if (this.ads[campaign_id].length > 0) {
                        let ad = this.getFinalAd(campaign_id);
                        if (ad) {
                            campaign.title = ad.title;
                            campaign.description = ad.description || '';
                            campaign.logo_url = ad.logo_url;
                            campaign.display_url = ad.display_url;
                            campaign.ad_id = ad.id;
                            campaign.ad_name = ad.ad_name;
                            campaign.display_name = ad.display_name || campaign.display_name;
                        } else if (!integration_campaign_ids.includes(campaign_id)) {
                            // No qualify ad found, Also skip for ping post campaign
                            this.campaign_exclusion.push(campaign_id);
                            this.setDebugData(campaign_id, 'exclusion', 'Does not qualify any ad');
                            this.setDebugData(campaign_id, 'final_bid', campaign.price);
                            this.setDebugData(campaign_id, 'base_bid', campaign.base_bid_price);
                            continue;
                        }
                    }

                    if (campaign.dest_url || campaign.fallback_url) {
                        if (brand_campaigns[campaign.brand_id]) {
                            let existing_campaign = brand_campaigns[campaign.brand_id];
                            let ext_campaign_id = campaign.campaign_id;
                            if (this.checkBrandDedupeLogic(existing_campaign, campaign, brand_name, campaign.bpfm_status)) {
                                brand_campaigns[campaign.brand_id] = campaign;
                                this.setDebugData(campaign_id, 'final_bid', campaign.price);
                                this.setDebugData(campaign_id, 'base_bid', campaign.base_bid_price);
                                ext_campaign_id = existing_campaign.campaign_id;
                            }
                            if (brand_name === 'goal' && this.token_type === 'admin') {
                                console.log(`higher bpfm score for ${existing_campaign.campaign_id} vs ${campaign.campaign_id}`);
                            }
                            this.setDebugData(ext_campaign_id, 'exclusion', `${(brand_name === 'goal' && this.token_type === 'admin') ? 'Higher bpfm score' : 'Lower bid price'} within same brand campaigns`);
                            this.setDebugData(ext_campaign_id, 'qualified', false);
                        } else {
                            brand_campaigns[campaign.brand_id] = campaign;
                            this.setDebugData(campaign_id, 'final_bid', campaign.price);
                            this.setDebugData(campaign_id, 'base_bid', campaign.base_bid_price);
                        }
                    } else {
                        this.setDebugData(campaign_id, 'final_bid', campaign.price);
                        this.setDebugData(campaign_id, 'exclusion', "dest_url and fallback_url are not present");
                        this.setDebugData(campaign_id, 'qualified', false);
                        this.setDebugData(campaign_id, 'base_bid', campaign.base_bid_price);
                    }
                    filtered_ad_group_campaign.push(campaign_id);
                }
            } else {
                this.setDebugData(campaign_id, 'exclusion', "Filtered out the campaign");
                this.setDebugData(campaign_id, 'qualified', false);
            }
        }
        for (let campaign of this.campaign_list) {
            // Marked qualified false of that campaign that doesn't have any qualify ad group
            if (!filtered_ad_group_campaign.includes(campaign.campaign_id)) {
                this.campaign_exclusion.push(campaign.campaign_id);
                this.setDebugData(campaign.campaign_id, 'exclusion', `Campaign ad group ${campaign.ad_group_id} is not qualified`);
                this.setDebugData(campaign.campaign_id, 'qualified', false);
            }
        }
        res_campaign['listings'] = Object.values(brand_campaigns);
        const endTime = new Date().getTime();
        res_campaign['response_ms'] = endTime - startTime;//'567'
        return res_campaign;
    }

    checkBrandDedupeLogic(existing_campaign, campaign, brand_name, bpfm_status) {
        if (this.token_type === 'admin' && brand_name === 'goal' && bpfm_status === true) {
            return existing_campaign.bpfm_score > campaign.bpfm_score;
        } else {
            return existing_campaign.price < campaign.price;
        }
    }

    getFinalAd(campaign_id) {
        let ads = this.ads[campaign_id] || [];
        let format_ads = [];
        let input_carrier = util.getParam(this.params, 'carrier') || null;
        let carrier_regx = new RegExp(`${input_carrier}`, 'i');
        for (let ad of ads) {
            let h = {
                logo_url: ad.ad_image_url,
                title: ad.title,
                description: this.convertToHtmlList(ad.bullet_points),
                display_url: ad.display_url,
                weight: (ad.weight - ad.active_weight),
                id: ad.ad_id,
                ad_name: ad.ad_name,
                carriers: ad.carriers,
                display_name: ad.display_name
            };
            format_ads.push(h);
            if (input_carrier && ad.carriers) {
                let arr_carriers = JSON.parse(ad.carriers || '[]');
                let selected_carrier = arr_carriers.some(val => {
                    return (carrier_regx.exec(val) || []).length > 0
                });
                if (selected_carrier) {
                    console.log(`Got final ad: ${ad.ad_id}`);
                    return h;
                }
            }
        }
        format_ads = format_ads.filter(ad => (ad.carriers === null || ad.carriers === ''));
        format_ads.sort((a, b) => (a.weight < b.weight) ? 1 : -1);
        return format_ads[0];
    }

    async storeClickPing(xml, original_data) {
        this.carriers = await this.loadCarriers();
        return new Promise(async (resolve, reject) => {
            const f_params = flatten(xml);
            const data_state = new DataState();
            this.data_state_info = await data_state.prepareDataState(f_params, xml);
            this.partner_id = this.token_id;
            let session_id = util.getParam(this.params, 'click_id') || 0;
            let source_type_id = util.getParam(this.params, 'source_type_id') || this.source_type_id;
            let form_type_id = util.getParam(this.params, 'form_type_id') || 0;
            let zip = util.getParam(this.params, 'zip');
            let lead_type_id = util.getParam(this.params, 'lead_type_id') || 6;
            let current_date_time = new Date();
            let data = [this.partner_id, util.getParam(this.params, 'lead_type_id'), session_id, util.getParam(this.params, 'zip'), util.getParam(this.params, 'state'), util.getParam(this.params, 'device_type'), source_type_id, form_type_id, util.getParam(this.params, 'aid'), util.getParam(this.params, 'cid'), util.getParam(this.params, 'sid'), util.getParam(this.params, 'ks'), xml, this.data_state_info.full_data, this.data_state_info.prefill_perc, this.data_state_info.pii, this.data_state_info.missing_fields, current_date_time, current_date_time];
            this.db.query('INSERT INTO click_pings (partner_id, lead_type_id, session_id, zip, state, device_type, source_type_id, form_type_id, aid, cid, sid, ks, xml, full_data, prefill_perc, pii, missing_fields, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19) RETURNING *', data, (error, results) => {
                if (error) {
                    errorHandler.notify({message: JSON.stringify({error: error.message, from: 'storeClickPing'})});
                    resolve({success: false});
                } else {
                    if (results.rows[0]) {
                        this.ping_id = results.rows[0].id;
                        this.storeClickPingVals(original_data, xml);
                        this.storeClickPingDetails(xml, lead_type_id).then(resp => {
                            resolve({success: true});
                        });
                        this.storeClickPingMatches(this.ping_id, zip, lead_type_id);
                        //TODO: rtbBidCheck should call for 63221ca202c25cefb36e8524
                        if (process.env.RTB_PARTNERS.split(',').includes(this.partner_id)) {
                            this.rtbBidObj = new RtbBidCalculator(this.db);
                            this.rtbBidObj.rtbBidCheck(this.partner_id, this.req_params, this.ping_id).then(resp => {
                                this.rtb_bid_check = resp;
                            });
                        }
                        if (['63221ca202c25cefb36e8524'].includes(this.partner_id)) {
                            // store call panels only for MT leads
                            this.getCallPanels(xml);
                        }
                    } else {
                        errorHandler.notify({message: `storeClickPing no id return from database ${JSON.stringify(results)}`});
                        resolve({success: false});
                    }
                }
            });
        });
    }

    async storeClickPingVals(original_data, processed_data) {
        const current_date_time = new Date();
        const data = [this.ping_id, original_data, processed_data, current_date_time, current_date_time]
        this.db.query('INSERT INTO click_ping_vals (click_ping_id, incoming_data, processed_data, created_at, updated_at) VALUEs($1, $2, $3, $4, $5)', data, (error, result) => {
            if (error) {
                errorHandler.notify(error);
                console.log("Error click_ping_vals", error.message);
            } else {
                // console.log("Stored click_ping_vals Successfully!");
            }
        });
    }

    async storeClickPingDetails(xml, lead_type_id) {
        return new Promise((resolve, reject) => {
            let insured = util.toLowerCase(util.getParam(this.params, 'currently_insured')) === 'yes'
            // let current_coverage = util.getParam(this.params, 'current_coverage').length > 3
            let cont_coverage = util.getParam(this.params, 'coverage_years') || 0;
            cont_coverage = `${cont_coverage} years`;
            let military = util.getParam(this.params, 'military_affiliation').toLowerCase() === 'yes'
            let homeowner = this.getHomeOwner();
            let num_drivers = util.getParam(this.params, 'num_drivers') || 0
            let num_vehicles = util.getParam(this.params, 'num_vehicles') || 0
            let violations = util.getParam(this.params, 'num_violations') > 0
            let accidents = util.getParam(this.params, 'num_accidents') > 0
            let dui = util.toLowerCase(util.getParam(this.params, 'dui')) === 'yes'
            let ip_address = util.getParam(this.params, 'ip_address')
            let firstName = util.getParam(this.params, 'first_name')
            let lastName = util.getParam(this.params, 'last_name')
            let email = util.getParam(this.params, 'email')
            let phone = util.getParam(this.params, 'primary_phone')
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
            let slice_num = util.getParam(this.params, 'slice_num');
            let carrier = util.getParam(this.params, 'carrier');
            let current_date_time = new Date();

            let data = [this.ping_id, insured, cont_coverage, homeowner, gender, marital_status, this.params.age, education, credit, military, num_drivers, num_vehicles, dui, util.getParam(this.params, 'license_status'), violations, accidents, current_date_time, current_date_time, ip_address, firstName, lastName, email, phone, city, county, tobacco, major_health_conditions, life_coverage_type, life_coverage_amount, property_type, property_age, years_in_business, commercial_coverage_type, household_income, slice_num, carrier];
            let columns = ['click_ping_id', 'insured', 'continuous_coverage', 'home_owner', 'gender', 'marital_status', 'consumer_age', 'education', 'credit_rating', 'military_affiliation', 'num_drivers', 'num_vehicles', 'dui', 'license_status', 'violations', 'accidents', 'created_at', 'updated_at', 'ip_address', 'first_name', 'last_name', 'email', 'phone', 'city', 'county', 'tobacco', 'major_health_conditions', 'life_coverage_type', 'life_coverage_amount', 'property_type', 'property_age', 'years_in_business', 'commercial_coverage_type', 'household_income', 'slice_num', 'insco'];
            if (lead_type_id == 6) { // 6 for auto insurance
                data.push(this.isAutoSr22(xml.drivers), util.toLowerCase(util.getParam(this.params, 'bundle_home')) === 'yes')
                columns.push('sr22', 'bundle_home');
            }
            let counters = Object.keys(columns).map(i => `$${(parseInt(i) + 1)}`);

            this.db.query(`INSERT INTO click_ping_details (${columns})
                           VALUES (${counters})
                           RETURNING *`, data, (error, results) => {
                if (error) {
                    console.log("Ping Details Error: ", error.message);
                    errorHandler.notify(error);
                    resolve({success: false});
                } else {
                    // console.log('click_ping_details success');
                    resolve({success: true});
                }
            });
        });
    }

    isAutoSr22(drivers = []) {
        for (let driver of drivers) {
            if (util.toLowerCase(driver.sr22_required) === 'yes') {
                return true;
            }
        }
        return false;
    }

    async storeClickListing(listings) {
        let brand_name = util.toLowerCase(this.brand_conf.name)
        this.carriers = await this.loadCarriers();
        if (brand_name === 'goal') {
            listings = await this.filterDuplicateGoalConsumer(listings);
        }
        return new Promise(async (resolve, reject) => {
            let ping_integration_promise = [];
            let all_promise = [];
            listings = listings.filter(listing => {
                if (listing.base_bid_price) {
                    return listing;
                } else {
                    this.debug_data.campaigns[listing.campaign_id].qualified = false;
                }
            });
            let campaign_integrations = {};

            for (let integration of this.ping_integrations) {
                campaign_integrations[integration.campaign_id] = integration;
            }
            for (let listing of listings) {
                ping_integration_promise.push(this.getPingIntegrationListings(campaign_integrations[listing.campaign_id], listing, 'click'));
            }
            let syndi_campaign_ids = this.campaign_list.filter(campaign => campaign.product_type_id == 4).map(listing => listing.campaign_id);
            let syndi_campaigns_rules = await this.syndiCampaignsRules(syndi_campaign_ids);
            Promise.all(ping_integration_promise).then(ping_listings => { // Apply click integrations
                let ping_click_listings = ping_listings.flat();
                for (let listing of ping_click_listings) {
                    listing.est_payout = listing.price;
                    if (listing.ping_post && listing.product_type_id == 4) {
                        let qualified_rule = this.getQualifiedSyndiRule(listing, syndi_campaigns_rules[listing.campaign_id]);
                        if (qualified_rule) {
                            let margin = qualified_rule.margin || 50;
                            let est_price = (listing.price * ((100 - margin) / 100)).toFixed(2); // Apply syndi click margin
                            listing.est_payout = parseFloat(est_price);
                            // pass cost & revenue to the syndi click URL
                            listing.click_url = `${listing.click_url}&rev=${listing.price}&cost=${listing.est_payout}`
                        } else {
                            continue; // Does not qualify any syndi click rules
                        }
                    }
                    all_promise.push(this.storeClickListingDB(listing));
                }
                Promise.all(all_promise).then(results => {
                    for (let listing of results) {
                        this.click_listings[listing.id || listing.campaign_id] = listing;
                        let click_url = this.getMacroUrl(listing.click_url, listing);
                        let fallback_url = this.getMacroUrl(listing.fallback_url, listing);
                        this.updateTrackingUrl(listing.click_listing_id, listing.tracking_url, click_url, fallback_url);
                    }
                    this.storeClickResultToDatabase();
                    resolve(results);
                });
            });
        });
    }

    async filterDuplicateGoalConsumer(listings) {
        try {
            if (this.req_params.contact && (this.req_params.contact.primary_phone || this.req_params.contact.email)) {
                let date = new Date();
                let date_before_30days = new Date(date.getTime() - (30 * 24 * 60 * 60 * 1000)).toUTCString();
                let query = `select account_id, count(*)
                             from click_listings cl
                                      inner join click_ping_details cpd on cl.click_ping_id = cpd.click_ping_id
                             where cl.created_at >= '${date_before_30days}'
                               and cl.clicked = 1`;

                if (this.req_params.contact.primary_phone && this.req_params.contact.email) {
                    query += ` and (cpd.phone = '${this.req_params.contact.primary_phone}' OR cpd.email = '${this.req_params.contact.email}')`;
                } else if (this.req_params.contact.primary_phone) {
                    query += ` and cpd.phone = '${this.req_params.contact.primary_phone}'`;
                } else {
                    query += ` and cpd.email = '${this.req_params.contact.email}'`;
                }
                query += ` group by account_id having count(*) >= 1`;
                return this.read_replica_db.query(query).then((results) => {
                        const account_ids = (results.rows || []).map(acc => acc.account_id);
                        let filtered_listing = [];
                        for (let listing of listings) {
                            if (account_ids.includes(listing.account_id)) {
                                this.setDebugData(listing.campaign_id, 'exclusion', `Duplicate listing found for consumer ${listing.account_id} in last 30 days`);
                                this.setDebugData(listing.campaign_id, 'qualified', false);
                            } else {
                                filtered_listing.push(listing);
                            }
                        }
                        return filtered_listing;
                    },
                    error => {
                        errorHandler.notify(error);
                        return listings;
                    });
            } else {
                return listings; // return original listing if ping doesn't have email or phone.
            }
        } catch (e) {
            errorHandler.notify(e);
            return listings;
        }
    }

    async storeDebugData(resp_time, num_listing) {
        let current_date_time = new Date();
        for (let campaign_id in this.debug_data.campaigns) {
            let campaign = this.debug_data.campaigns[campaign_id];
            if (typeof (campaign.schedule_modifier) == 'undefined') {
                campaign.ping_id = this.ping_id;
                errorHandler.notify(JSON.stringify(campaign));
            }
        }
        let data = [this.ping_id, JSON.stringify({campaigns: Object.values(this.debug_data.campaigns)}), resp_time, num_listing, this.req_token, current_date_time, current_date_time]
        this.db.query('INSERT INTO click_ping_debug_logs (click_ping_id, log, response_time_ms, num_listings, token, created_at, updated_at) VALUEs($1, $2, $3, $4, $5, $6, $7)', data, (error, result) => {
            if (error) {
                errorHandler.notify(error);
                console.log("Error Store Debug", error.message);
            } else {
                // console.log("Stored Debug Data Successfully!");
            }
        });
    }

    async storeClickListingDB(listing) {
        return new Promise(async (resolve, reject) => {
            let pst_columns = await this.getPSTColumns();
            let current_date_time = new Date();
            let source_type_id = util.getParam(this.params, 'source_type_id') || this.source_type_id;
            let lead_type_id = util.getParam(this.params, 'lead_type_id') || this.req_params.lead_type_id;
            let state = util.getParam(this.params, 'state');
            let upstream_bid = listing.product_type_id == 4 ? listing.price : null;
            //TODO: Call rtbBidObj.rtbBidLogic for partner  63221ca202c25cefb36e8524 for live
            if (!listing.ping_post && process.env.RTB_PARTNERS.split(',').includes(this.partner_id)) {
                if (this.rtbBidObj && listing.price >= 0.10) {
                    if (!this.rtb_bid_check) {
                        this.rtb_bid_check = await this.rtbBidObj.rtbBidCheck(this.partner_id, this.req_params, this.ping_id);
                    }
                    let rtb_bids = {success: false, bid_to_use: 0.01}
                    if (this.rtb_bid_check?.output_code == 0) {
                        this.rtb_bid_check.current_bid = listing.price;
                        this.rtb_bid_check.dynamic_cm = parseFloat(listing.rtb_cm || '0.30');
                        this.rtb_bid_check.campaign_id = listing.campaign_id;
                        rtb_bids = await this.rtbBidObj.rtbBidLogic(this.rtb_bid_check);
                    } else if (typeof (this.rtb_bid_check?.output_code) === 'undefined' || this.rtb_bid_check?.output_code > 100) {
                        rtb_bids.success = true;
                    }
                    if (rtb_bids.success) {
                        let bid_to_use = parseFloat(rtb_bids.bid_to_use.toFixed(2));
                        listing.current_bid = listing.price;
                        listing.price = bid_to_use
                        listing.est_payout = bid_to_use;
                        this.rtbBidObj.updateRtbBid(this.ping_id, bid_to_use, this.rtb_bid_check.dynamic_cm);
                    }
                }
            }
            let data = [(this.ping_id || 15326713), listing.campaign_id, listing.ad_group_id, (listing.ad_id || 0), listing.title, listing.description, listing.logo_url, listing.company_name, listing.display_name, listing.price, listing.est_payout, listing.brand_id, listing.account_id, listing.click_id, listing.click_url, (listing.premium || ''), (listing.term || ''), listing.fallback_url, this.mobile_device, lead_type_id, source_type_id, state, pst_columns.pst_hour, pst_columns.pst_day, pst_columns.pst_week, pst_columns.pst_month, pst_columns.pst_quarter, pst_columns.pst_year, listing.pp_ping_id, listing.pp_bid_id, listing.ping_post, listing.display_url, upstream_bid, listing.product_type_id, listing.network_id, listing.current_bid, current_date_time, current_date_time];
            this.db.query('INSERT INTO click_listings (click_ping_id, campaign_id, ad_group_id, ad_id, title, description, logo_url, company_name, display_name, payout, est_payout, brand_id, account_id, click_id, click_url, premium, term, fallback_url, device_type_mobile, lead_type_id, source_type_id, state, pst_hour, pst_day, pst_week, pst_month, pst_quarter, pst_year, pp_ping_id, pp_bid_id, ping_post, site_host, upstream_bid, product_type_id, network_id, current_bid, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38) RETURNING *', data, async (error, results) => {
                if (this.token_type === 'admin') {
                    listing.premium = listing.premium || '';
                    listing.term = listing.premium || '';
                }
                if (error) {
                    errorHandler.notify(error);
                    console.log("Store Click Listing Error: ", error);
                    listing.click_listing_id = 0;
                    resolve(listing);
                } else {
                    if (results.rows[0]) {
                        listing.impr_html = `<img src='${process.env.APP_HOST}/api/v1/${this.brand_url}click_listing/${results.rows[0].id}/impression?pos={position}' alt='pixel'/>`;
                        listing.click_listing_id = results.rows[0].id;
                        listing.tracking_url = `${this.brand_conf.tracking_host}/clicks?click_listing_id=${listing.click_listing_id}`;
                        listing.events_url = `${process.env.APP_HOST}/api/v1/${this.brand_url}clicks/${listing.click_listing_id}/events`;
                    } else {
                        listing.click_listing_id = 0;
                        resolve(listing);
                    }
                }
                let click_result_data = this.getClickResultListingData(listing);
                click_result_data.listing = true;
                click_result_data.opportunity = true;
                click_result_data.upstream_bid = listing.product_type_id == 4 ? listing.price : null;
                click_result_data.network_id = listing.network_id;
                click_result_data.click_listing_id = listing.click_listing_id;
                click_result_data.active_source = !(listing.active_source === false || listing.active_source == 0);

                const non_rtb_data = this.collectNonRtbDataExt(listing);
                if (listing.ping_post) {
                    if (listing.product_type_id == 4) {
                        this.prepareClickResultFromListing(this.clickResultData(this.ping_id, {
                            account_id: listing.account_id,
                            campaign_id: listing.campaign_id,
                            ad_group_id: listing.ad_group_id,
                            brand_id: listing.brand_id,
                            payout: listing.price,
                            product_type_id: listing.product_type_id
                        }, pst_columns, false), click_result_data, non_rtb_data);
                    } else {
                        let click_results = this.findClickResultForListing(this.ping_id, listing.campaign_id, listing.ad_group_id, listing.account_id, listing.display_name);
                        if (click_results.length > 0) {
                            this.updateClickResultObject(this.ping_id, listing.account_id, listing.campaign_id, listing.ad_group_id, click_result_data, listing.display_name, null, non_rtb_data)
                        } else {
                            this.prepareClickResultFromListing(this.clickResultData(this.ping_id, {
                                account_id: listing.account_id,
                                campaign_id: listing.campaign_id,
                                ad_group_id: listing.ad_group_id,
                                brand_id: listing.brand_id,
                                payout: listing.price,
                                product_type_id: listing.product_type_id
                            }, pst_columns, false), click_result_data, non_rtb_data)
                        }
                    }
                } else {
                    this.updateClickResultObject(this.ping_id, listing.account_id, listing.campaign_id, listing.ad_group_id, click_result_data, null, null, non_rtb_data);
                }
                // if (listing.account_id == 5) {
                //     this.exchangeIntegration(listing.click_listing_id);
                // }
                if (listing.account_id != 5) {
                    this.updateCampaignActiveWeight(listing.campaign_id, listing.ad_id || 0);
                    this.updateAdGroupActiveWeight(listing.ad_id || 0, listing.ad_group_id);
                }
                resolve(listing);
            });
        });
    }

    async updateCampaignActiveWeight(campaign_id, ad_id) {
        let query = `select id, weight, active_weight
                     from campaign_ads
                     where campaign_id = ${campaign_id}
                       and ad_id = ${ad_id}
                     ORDER BY id DESC
                     LIMIT 1`;
        this.read_replica_db.query(query).then((results) => {
            try {
                const campaign_ad = results.rows[0];
                // campaign_ad.weight < 100
                if (campaign_ad && campaign_ad.weight < 100) {
                    const active_weight_inc = 100 - campaign_ad.weight;
                    this.db.query('update campaign_ads set active_weight = active_weight + $1 where id = $2', [active_weight_inc, campaign_ad.id], (error, results) => {
                        if (error) {
                            errorHandler.notify(error);
                        } else {
                            // console.log('campaign_ad active weight has been updated');
                        }
                    });
                }
            } catch (e) {
                errorHandler.notify(e);
            }
        }, error => {
            errorHandler.notify(error);
        });
    }

    async updateAdGroupActiveWeight(ad_id, ad_group_id) {
        let query = `select id, weight, active_weight
                     from ad_group_ads
                     where ad_id = ${ad_id}
                       and ad_group_id = ${ad_group_id}
                     ORDER BY id DESC
                     LIMIT 1`;
        this.db.query(query).then((results) => {
            try {
                const ad_group_ad = results.rows[0];
                if (ad_group_ad && ad_group_ad.weight < 100) {
                    const active_weight_inc = 100 - ad_group_ad.weight;
                    this.db.query('update ad_group_ads set active_weight = active_weight + $1 where id = $2', [active_weight_inc, ad_group_ad.id], (error, results) => {
                        if (error) {
                            errorHandler.notify(error);
                        } else {
                            // console.log('ad_group_ads active weight has been updated');
                        }
                    });
                }
            } catch (e) {
                errorHandler.notify(e);
            }
        }, error => {
            errorHandler.notify(error);
        });
    }

    async exchangeIntegration(listing_id) {
        new ExchangeIntegration(this.db, this.ping_id, listing_id, this.params).check();
    }

    async prepareClickResultFromListing(click_result_data, additional_data, non_rtb_data) {
        let result_data = {...click_result_data, ...additional_data};
        result_data.non_rtb_data = non_rtb_data;
        let objClickResult = new ClickResult();
        this.click_results.push(Object.assign(objClickResult, result_data));
    }

    findClickResultForListing(click_ping_id, campaign_id, ad_group_id, account_id, display_name) {
        return this.click_results.filter(click_result => (click_result.account_id == account_id && click_result.campaign_id == campaign_id && click_result.ad_group_id == ad_group_id && click_result.display_name == display_name));
    }

    async storeClickOpportunity() {
        return new Promise(async (resolve, reject) => {
            let all_promise = [];
            let pst_columns = await this.getPSTColumns();
            for (let listing of this.campaign_list) {
                all_promise.push(this.clickOpportunityData(listing, pst_columns));
            }
            Promise.all(all_promise).then(results => {
                this.storeClickOpportunityDB(results);
                resolve(results);
            });
        });
    }

    async clickOpportunityData(listing, pst_columns) {
        return new Promise((resolve, reject) => {
            const current_date_time = new Date();
            const active_source_setting = !(listing.active_source === false || listing.active_source == 0)
            const ad = this.getFinalAd(listing.campaign_id) || {id: null};
            const source_type_id = util.getParam(this.params, 'source_type_id') || this.source_type_id;
            const lead_type_id = util.getParam(this.params, 'lead_type_id') || this.req_params.lead_type_id;

            this.updateClickResultOpportunity(listing, active_source_setting, ad.id, pst_columns);
            resolve([this.ping_id, listing.campaign_id, listing.ad_group_id, ad.id, listing.brand_id, listing.account_id, listing.base_bid_price, source_type_id, lead_type_id, active_source_setting, current_date_time, current_date_time]);
        });
    }

    async storeClickOpportunityDB(value_set) {
        const columns = ['click_ping_id', 'campaign_id', 'ad_group_id', 'ad_id', 'brand_id', 'account_id', 'payout', 'source_type_id', 'lead_type_id', 'active_source_setting', 'created_at', 'updated_at'];
        this.orm.batchInsert('click_opportunities', columns, value_set).then(result => {
            // console.log("click_opportunities stored");
        }, error => {
            errorHandler.notify(error);
            console.log('Unable to add click_opportunities', error.message);
        });
    }

    async updateClickResultOpportunity(listing, active_source_setting, ad_id, pst_columns) {
        let click_result_data = this.getClickResultListingData(listing, true);
        click_result_data.opportunity = true;
        click_result_data.active_source = active_source_setting;
        click_result_data.ad_id = ad_id;
        click_result_data.est_payout = listing.base_bid_price;
        try {
            // Check for click result update for click opportunity
            let update_result = false;
            for (let click_result of this.click_results) {
                if (click_result.account_id == listing.account_id && click_result.campaign_id == listing.campaign_id && click_result.ad_group_id == listing.ad_group_id) {
                    update_result = true;
                    break;
                }
            }
            if (update_result) {
                this.updateClickResultObject(this.ping_id, listing.account_id, listing.campaign_id, listing.ad_group_id, click_result_data);
            } else {
                this.prepareClickResultFromListing(this.clickResultData(this.ping_id, {
                    account_id: listing.account_id,
                    campaign_id: listing.campaign_id,
                    ad_group_id: listing.ad_group_id,
                    brand_id: listing.brand_id,
                    payout: listing.price,
                    product_type_id: listing.product_type_id
                }, pst_columns, false), click_result_data, this.collectNonRtbDataExt(listing));
            }
        } catch (ex) {
            errorHandler.notify(ex);
        }
    }

    async updateClickPings(num_listings, ttr_ms = 0) {
        this.db.query('update click_pings set total_opportunities = $1, filtered_listings = $2, ttr_ms = $3 where id = $4', [this.campaign_list.length, num_listings, ttr_ms, this.ping_id], (error, results) => {
            if (error) {
                errorHandler.notify(error);
            } else {
                // console.log('Click ping has been updated');
            }
        });
    }

    async updateTrackingUrl(click_listing_id, tracking_url, click_url, fallback_url) {
        this.db.query('update click_listings set tracking_url = $1, click_url = $2, fallback_url = $4 where id = $3', [tracking_url, click_url, click_listing_id, fallback_url], (error, results) => {
            if (error) {
                errorHandler.notify(error);
                // console.log('Failed to update tracking url');
            } else {
                // console.log('tracking url has been updated');
            }
        });
    }

    applyMacros(campaign) {
        // let test_macro = this.getMacroUrl('http://smartfinancial.com?click_listing_id={click_listing_id}&click_id={click_id}&city={city}&state={state}&country={country}&state_code={state_code}&first_name={first_name}&last_name={last_name}&phone={phone}&dob={dob}&source={source}&source_type={source_type}&campaign_name={CampaignName}&adcreativename={adcreativename}&source_type_id={source_type_id}&ad_group_name={AdGroupName}', campaign)
        campaign.dest_url = this.getMacroUrl(campaign.dest_url, campaign);
        campaign.fallback_url = this.getMacroUrl(campaign.fallback_url, campaign);
        campaign.description = this.getMacroUrl(campaign.description, campaign);
        campaign.title = this.getMacroUrl(campaign.title, campaign);
        return campaign;
    }

    async applyClickIntegration(campaign, data) {
        campaign.click_id = data.click_id;
        campaign.logo_url = this.CDNLogoUrl(campaign.logo_url, data.click_id);
        if (campaign.click_integration_type === 'Price Presentation') {
            campaign = await this.staticClickIntegration(campaign, data);
            return campaign;
        } else if (campaign.click_integration_type === 'Pre-fill') {
            campaign.click_url = campaign.click_dest_url;
            return campaign;
        } else {
            let pf_integration = this.pre_fill_integrations.filter(item => item.campaign_id === campaign.campaign_id)[0];
            if (pf_integration) {
                campaign.click_url = `${process.env.APP_HOST}/api/v1/click/{click_listing_id}/track`;
            } else {
                let pp_integration = this.price_presentation_integrations.filter(item => item.campaign_id === campaign.campaign_id)[0];
                if (pp_integration) {
                    let integration_response = await this.applyIntegration(pp_integration, campaign, true);
                    if (integration_response && integration_response.data) {
                        let success = this.integrationResponse(pp_integration, integration_response);
                        if (success) {
                            let ping_config = JSON.parse(pp_integration.ping_config || "{}");
                            let parsed_integration_response = this.parsePingIntegrationResponse(integration_response.data, ping_config, false);
                            if (Array.isArray(parsed_integration_response)) {
                                parsed_integration_response = parsed_integration_response[0];
                            }
                            campaign.click_url = parsed_integration_response[ping_config.url || ping_config.click_url || 'url'] || campaign.fallback_url;
                            campaign.premium = parsed_integration_response[ping_config.premium || 'premium'] || '';
                            campaign.term = parsed_integration_response[ping_config.term || 'term'] || '';
                        } else {
                            campaign.click_url = campaign.fallback_url;
                        }
                    } else {
                        campaign.click_url = campaign.fallback_url;
                    }
                } else {
                    campaign.click_url = campaign.dest_url || campaign.fallback_url;
                }
            }
            return campaign;
        }
    }

    async staticClickIntegration(campaign, data) {
        let headers = {headers: {Authorization: `Bearer ${this.req_token}`}};
        const req_data = {...this.req_params, ...data}
        return axios.post(campaign.click_dest_url, {
            lead: req_data, click_integration_id: campaign.click_integration_id
        }, headers).then(res => {
            if (res.data) {
                campaign.click_url = res.data.url;
                campaign.premium = res.data.premium;
                campaign.term = res.data.term;
            } else {
                campaign.click_url = campaign.fallback_url;
            }
            return campaign;
        }).catch(error => {
            console.log("Error on staticClickIntegration: ", error.message);
            errorHandler.notify(error);
            campaign.click_url = campaign.fallback_url;
            return campaign;
        });
    }

    async storeClickPingMatches(ping_id, zip, lead_type_id) {
        try {
            let product_type_id = util.toLowerCase(this.brand_conf.name) === 'goal' ? 5 : 1;
            const ping_matches = await this.getPingMatches(zip, lead_type_id, product_type_id, this.token_bid_multipliers);
            let ping_match_promise = [];
            let pst_columns = await this.getPSTColumns();
            for (let ping_match of ping_matches) {
                ping_match_promise.push(this.generateClickPingMatchesData(ping_id, ping_match, pst_columns));
            }
            if (ping_match_promise.length > 0) {
                Promise.all(ping_match_promise).then(async results => {
                    if (this.token_type === 'admin') {
                        // Do not store click_ping_matches for generic tokens - IIA-336
                        let value_set = [];
                        let column_set = [];
                        let counter = 1;
                        for (let result of results) {
                            let val = []
                            let match_result = result.click_match;
                            for (let key in match_result) {
                                val.push(`$${counter}`);
                                counter += 1;
                            }
                            column_set.push(`(${val})`);
                            value_set.push(match_result);
                        }
                        this.db.query(`INSERT INTO click_ping_matches (click_ping_id, account_id, campaign_id,
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
                    }
                    this.prepareClickResultData(results);
                });
            }
        } catch (ex) {
            errorHandler.notify({message: `Click Store ping matches: ${ex.message}`});
        }
    }

    prepareClickResultData(results) {
        for (let result of results) {
            let objClickResult = new ClickResult();
            objClickResult = Object.assign(objClickResult, result.click_result);
            objClickResult.non_rtb_data = result.non_rtb_data;
            this.click_results.push(objClickResult);
        }
    }

    clickResultAttrs() {
        return ['click_ping_id', 'partner_id', 'account_id', 'campaign_id', 'ad_group_id',
            'brand_id', 'payout', 'source_type_id', 'lead_type_id', 'match', 'pst_hour',
            'pst_day', 'pst_week', 'pst_month', 'pst_quarter', 'pst_year', 'aid', 'cid',
            'first_name', 'last_name', 'phone', 'email', 'home_owner', 'consumer_age',
            'military_affiliation', 'num_drivers', 'num_vehicles', 'violations',
            'dui', 'accidents', 'city', 'county', 'tobacco', 'major_health_conditions',
            'life_coverage_type', 'life_coverage_amount', 'property_type',
            'property_age', 'years_in_business', 'license_status', 'device_type',
            'zip', 'state', 'education', 'credit_rating', 'ip_address',
            'continuous_coverage', 'commercial_coverage_type', 'gender',
            'marital_status', 'household_income', 'insured', 'mobile', 'full_data',
            'prefill_perc', 'pii', 'missing_fields', 'product_type_id', 'created_at',
            'updated_at', 'col1']
    }

    async generateClickPingMatchesData(ping_id, ping_match, pst_columns) {
        try {
            let current_date_time = new Date();
            let ping_match_data = [ping_id, ping_match.account_id, ping_match.campaign_id, ping_match.ad_group_id, ping_match.brand_id, ping_match.ad_group_active, ping_match.payout || 0.0, pst_columns.pst_hour, pst_columns.pst_day, pst_columns.pst_week, pst_columns.pst_month, pst_columns.pst_quarter, pst_columns.pst_year, current_date_time, current_date_time]
            return {
                click_match: ping_match_data,
                click_result: this.clickResultData(ping_id, ping_match, pst_columns, false),
                non_rtb_data: this.collectNonRtbDataExt(ping_match)
            }
        } catch (ex) {
            errorHandler.notify({message: `Store ping matches: ${ex.message}`});
        }
    }

    clickResultData(ping_id, ping_match, pst_columns, data_only = true) {
        let current_date_time = new Date();
        let source_type_id = util.getParam(this.params, 'source_type_id') || this.source_type_id;
        let lead_type_id = util.getParam(this.params, 'lead_type_id') || 6;
        let aid = util.getParam(this.params, 'aid');
        let cid = util.getParam(this.params, 'cid');
        let insured = util.toLowerCase(util.getParam(this.params, 'currently_insured')) === 'yes'
        let cont_coverage = util.getParam(this.params, 'coverage_years') || 0;
        cont_coverage = `${cont_coverage} years`;
        let military = util.getParam(this.params, 'military_affiliation').toLowerCase() === 'yes'
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
        let mobile = util.toLowerCase(device_type) === 'mobile'
        let session_id = util.getParam(this.params, 'click_id');

        let result_data_set = {
            click_ping_id: ping_id,
            partner_id: this.partner_id,
            account_id: ping_match.account_id,
            campaign_id: ping_match.campaign_id,
            ad_group_id: ping_match.ad_group_id,
            brand_id: ping_match.brand_id,
            payout: ping_match.payout || 0.0,
            source_type_id: source_type_id,
            lead_type_id: lead_type_id,
            match: true,
            pst_hour: pst_columns.pst_hour,
            pst_day: pst_columns.pst_day,
            pst_week: pst_columns.pst_week,
            pst_month: pst_columns.pst_month,
            pst_quarter: pst_columns.pst_quarter,
            pst_year: pst_columns.pst_year,
            aid: aid,
            cid: cid,
            first_name: first_name,
            last_name: last_name,
            phone: phone,
            email: email,
            home_owner: homeowner,
            consumer_age: this.params.age,
            military_affiliation: military,
            num_drivers: num_drivers,
            num_vehicles: num_vehicles,
            violations: violations,
            dui: dui,
            accidents: accidents,
            city: city,
            county: county,
            tobacco: tobacco,
            major_health_conditions: major_health_conditions,
            life_coverage_type: life_coverage_type,
            life_coverage_amount: life_coverage_amount,
            property_type: property_type,
            property_age: property_age,
            years_in_business: years_in_business,
            license_status: license_status,
            device_type: device_type,
            zip: zip,
            state: state,
            education: education,
            credit_rating: credit,
            ip_address: ip_address,
            continuous_coverage: cont_coverage,
            commercial_coverage_type: commercial_coverage_type,
            gender: gender,
            marital_status: marital_status,
            household_income: household_income,
            insured: insured,
            mobile: mobile,
            full_data: this.data_state_info.full_data,
            prefill_perc: this.data_state_info.prefill_perc,
            pii: this.data_state_info.pii,
            missing_fields: this.data_state_info.missing_fields,
            product_type_id: ping_match.product_type_id,
            created_at: current_date_time,
            updated_at: current_date_time,
            col1: session_id
        }

        if (data_only) {
            return Object.values(result_data_set);
        } else {
            return result_data_set;
        }
    }

    async storeClickResultToDatabase() {
        // TODO: Generate click result bulk insert data
        if (this.click_results.length > 0) {
            let click_result_columns = this.click_results[0].attributes();
            let non_rtb_columns = click_result_columns.concat(this.click_results[0].nonRtbAttributes());
            let click_results_data = [];
            let non_rtbs_data = [];
            for (let click_result of this.click_results) {
                let click_result_data = click_result.data();
                click_results_data.push(click_result_data);
                non_rtbs_data.push(click_result_data.concat(click_result.nonRtbData()))
            }
            this.orm.batchInsert('click_results', click_result_columns, click_results_data);
            this.storeNonRtbPingStat(1, non_rtb_columns, non_rtbs_data);
        }
    }

    updateClickResultObject(click_ping_id, account_id, campaign_id, ad_group_id, data, display_name = null, click_listing_id = null, non_rtb_data = {}) {
        for (let click_result of this.click_results) {
            if (click_result.account_id == account_id && click_result.campaign_id == campaign_id && click_result.ad_group_id == ad_group_id) {
                click_result.update(data, non_rtb_data);
            }
        }
    }

    async updateClickResult(click_ping_id, account_id, campaign_id, ad_group_id, data, display_name = null, click_listing_id = null, data_ext = {}) {
        let counter = 1;
        let columns = [];
        let values = [];
        data.updated_at = new Date();
        this.updateNonRtbPingStat(1, {
            ping_id: click_ping_id,
            listing_id: click_listing_id,
            account_id,
            campaign_id,
            ad_group_id
        }, {...data, ...data_ext});
        for (let field in data) {
            values.push(data[field]);
            columns.push(`${field} = $${counter}`);
            counter += 1;
        }
        let query = `update click_results
                     set ${columns.join(',')}
                     where account_id = ${account_id}
                       and campaign_id = ${campaign_id}
                       and click_ping_id = ${click_ping_id}
                       and ad_group_id = ${ad_group_id}`;
        if (display_name) {
            query = `${query} and display_name = '${display_name}'`;
        }
        if (click_listing_id) {
            query = `${query} and click_listing_id = ${click_listing_id}`;
        }
        setTimeout(() => {
            this.db.query(query, values, (error, result) => {
                if (error) {
                    errorHandler.notify(error);
                } else {
                    // console.log('Update click result success');
                }
            });
        }, 2000);
    }

    getClickResultListingData(listing, opportunity = false) {
        let result_data = {
            term: listing.term,
            payout: listing.price,
            est_payout: listing.est_payout,
            ad_id: listing.ad_id,
            brand_id: listing.brand_id,
            excluded: this.campaign_exclusion.includes(listing.campaign_id),
            title: listing.title,
            premium: listing.premium,
            fallback_url: listing.fallback_url,
            click_id: listing.click_id,
            pub_aid: listing.pub_aid,
            pub_cid: listing.pub_cid
        }
        if (!opportunity || (opportunity && listing.product_type_id != 4)) {
            result_data.display_name = listing.display_name;
            result_data.logo_url = listing.logo_url;
            result_data.company_name = listing.company_name;
        }
        if (listing.display_url) {
            result_data.site_host = listing.display_url;
        }
        if (listing.tracking_url) {
            result_data.tracking_url = listing.tracking_url;
        }
        if (listing.click_url) {
            result_data.click_url = listing.click_url;
        }
        if (listing.description) {
            result_data.description = listing.description;
        }
        if (listing.product_type_id) {
            result_data.product_type_id = listing.product_type_id;
        }
        return result_data;
    }

    async syndiCampaignsRules(campaigns_ids) {
        try {
            if (campaigns_ids.length > 0) {
                return this.db.query(`select *
                                      from syndi_click_rules
                                      where campaign_id in (${campaigns_ids})
                                        and discarded_at is null`).then(results => {
                    let syndi_campaigns_rule = {};
                    results.rows.map(rule => {
                        if (syndi_campaigns_rule[rule.campaign_id]) {
                            syndi_campaigns_rule[rule.campaign_id].push(rule);
                        } else {
                            syndi_campaigns_rule[rule.campaign_id] = [rule];
                        }
                    });
                    return syndi_campaigns_rule;
                }, error => {
                    return {};
                });
            } else {
                return {}
            }
        } catch (ex) {
            return {};
        }
    }

    async applyBPFMScore(listings) {
        let campaigns_timezone_date = await this.getCampaignsTimeZoneDate();
        let all_promise = [];
        for (let listing of listings) {
            all_promise.push(this.calculateBPFMScore(listing, campaigns_timezone_date[listing.campaign_id]));
        }
        return new Promise(async (resolve, reject) => {
            Promise.all(all_promise).then(listings => {
                resolve(listings);
            });
        });
    }

    async calculateBPFMScore(listing, schedule_timezone = {}) {
        return new Promise(async (resolve, reject) => {
            try {
                if (this.campaign_exclusion.includes(listing.campaign_id)) {
                    return resolve(listing);
                }
                if (listing.bpfm_status === false) {
                    listing.bpfm_score = 0;
                    return resolve(listing);
                }
                if (listing.price < listing.floor_cpc) {
                    listing.bpfm_score = 200;
                    return resolve(listing);
                }
                if (!listing.target_cpc) {
                    listing.target_cpc = 3.5;
                }
                const pst_date = (new Date(new Date().toLocaleString("en-US", {timeZone: 'America/Los_Angeles'})))
                const current_date_time_sec = pst_date.getTime() / 1000;
                const start_date_time_sec = pst_date.setHours(0, 0, 0, 0) / 1000;
                const end_date_time_sec = pst_date.setHours(23, 59, 59, 999) / 1000;
                // const daily_time_sec = 86400;
                const daily_time_sec = await this.getCampaignScheduleActiveTime(listing.campaign_id, schedule_timezone.date, listing.timezone);
                const time_remaining_sec = end_date_time_sec - current_date_time_sec;
                const time_passed_sec = current_date_time_sec - start_date_time_sec;
                let time_remaining_percentage = (time_remaining_sec / daily_time_sec) * 100;
                let time_passed_percentage = (time_passed_sec / daily_time_sec) * 100;
                let budgets = listing.budgets;
                if (!budgets) {
                    budgets = listing.volume_budget * listing.target_cpc;
                }
                let budget_spend_percentage = (listing.spent / budgets) * 100;
                let bid_factor = Math.min(...[(listing.price / listing.target_cpc), 1]);
                // let bpfm_score = ((budget_spend_percentage / time_remaining_percentage) / bid_factor) * 100;
                let bpfm_score = ((budget_spend_percentage / time_passed_percentage) / bid_factor) * 100;
                // console.log(`bpfm_score for campaign ID (${listing.campaign_id}): ${bpfm_score}`);
                listing.bpfm_score = parseFloat(bpfm_score.toFixed(2));
                resolve(listing);
            } catch (ex) {
                console.log(ex.message)
                listing.bpfm_score = 0;
                resolve(listing);
            }
        });
    }

    async getCampaignScheduleActiveTime(campaign_id, date, account_timezone) {
        if (!date) {
            date = this.getDate('PST');
        }
        return new Promise((resolve, reject) => {
            try {
                let account_timezone_date = this.getDate(account_timezone);
                let account_current_hour = account_timezone_date.getHours();
                let query = `select *
                             from campaign_schedules
                             where campaign_id = ${campaign_id}
                               and active = true
                               and day_id = ${date.getDay()}
                               and discarded_at IS NULL`;
                this.db.query(query, async (error, results) => {
                    if (error) {
                        console.log(error);
                        resolve(1);
                    } else {
                        if (results.rows.length <= 0) {
                            resolve(1)
                        } else {
                            let hours = results.rows[0];
                            let hours_second_count = 0;
                            if (hours[`h${account_current_hour}`] && hours[`h${account_current_hour}`] > 0) {
                                hours_second_count = (60 - account_timezone_date.getMinutes()) * 60
                            }
                            for (let i = (account_current_hour + 1); i < 24; i++) {
                                if (hours[`h${i}`] && hours[`h${i}`] > 0) {
                                    hours_second_count += 3600;
                                }
                            }
                            resolve(hours_second_count > 0 ? hours_second_count : 1);
                        }
                    }
                });
            } catch (ex) {
                console.log(ex.message);
                resolve(1);
            }
        });
    }

    getQualifiedSyndiRule(listing, rules) {
        let qualified_rule = null;
        if (rules && listing.ping_post && listing.product_type_id == 4) {
            for (let rule of rules) {
                if ((util.toLowerCase(rule.advertiser) === util.toLowerCase(listing.display_name) && listing.network_id == rule.network_id)) {
                    return rule;
                }
            }
        }
        return qualified_rule;
    }

    processAppendTrackingMacros(append_tracking, campaign) {
        try {
            const objCrypto = new AESCipher();
            let encryptions = append_tracking.match(/aes_encrypt\((.+?)\)/gm) || [];
            if (encryptions.length > 0) {
                for (let encryption of encryptions) {
                    let encrypted_data = this.parseAppendTrackingMacros(encryption, campaign, objCrypto);
                    append_tracking = append_tracking.replace(`{${encryption}}`, encrypted_data); // Single aes_encrypt
                    append_tracking = append_tracking.replace(`${encryption}`, encrypted_data); // Nested aes_encrypt with url_encoded
                }
            }
            let url_encodings = append_tracking.match(/url_encoded\((.+?)\)/gm) || [];
            if (url_encodings.length > 0) {
                for (let url_encoding of url_encodings) {
                    let processed_macros = this.parseAppendTrackingMacros(url_encoding, campaign, objCrypto, 'url_encoded');
                    append_tracking = append_tracking.replace(`{${url_encoding}}`, processed_macros);
                }
            }
            append_tracking = this.getMacroUrl(append_tracking, campaign); // If there any additional macros
        } catch (ex) {
            console.log('Error on append tracking macros', ex.message)
        }
        return append_tracking;
    }

    getMacroUrl(url, campaign) {
        try {
            let macros = (url || '').match(/\{[^}]+}/g) || '';
            if (macros && macros.length > 0) {
                for (let macro of macros) {
                    // Do not process {position} macro as we evaluate it on the ping-post app
                    if (macro != '{position}') {
                        let macro_field = macro.replace('{', '').replace('}', '').replace(/^\s+|\s+$/gm, '');
                        let macro_value = this.getMacroFieldValue(macro_field, campaign);
                        url = url.replace(macro, macro_value);
                    }
                }
            } else {
                return url;
            }
            return url;
        } catch (ex) {
            errorHandler.notify(ex);
            return url;
        }
    }

    parseAppendTrackingMacros(encryption, campaign, objCrypto, type = "aes_encrypt") {
        try {
            let encryption_data = encryption.match(/\((.+?)\)/gm)[0] || "";
            encryption_data = encryption_data.replace('(', '').replace(')', '');
            let encrypt_args = encryption_data.split(',');
            let key = encrypt_args[encrypt_args.length - 1];
            let processed_macros;
            if (type === 'aes_encrypt') {
                encrypt_args.splice((encrypt_args.length - 1), 1); // Remove key to get plain params only for encryption
            }
            let macros = encrypt_args.join(',');
            if (encryption_data.trim().startsWith('{"')) {
                processed_macros = this.processMacroFromJson(macros, campaign);
            } else {
                processed_macros = this.getMacroUrl(macros, campaign);
            }
            return type === 'url_encoded' ? encodeURIComponent(processed_macros) : objCrypto.encrypt(processed_macros, key.trim())
        } catch (ex) {
            return encryption;
        }
    }

    processMacroFromJson(json_data, campaign) {
        try {
            if (typeof (json_data) === 'string') {
                json_data = JSON.parse(json_data);
            }
            for (let key in json_data) {
                let value = json_data[key];
                if (Array.isArray(value)) {
                    if (util.toLowerCase(key) === 'drivers') {
                        json_data[key] = this.processDriversMacro(value[0]);
                    } else {
                        for (let arkey in value) {
                            let ar_value = value[arkey];
                            this.processMacroFromJson(ar_value, campaign);
                        }
                    }
                } else if (typeof (value) === 'object') {
                    this.processMacroFromJson(value, campaign);
                } else {
                    json_data[key] = this.getMacroUrl(value, campaign);
                }
            }
            return JSON.stringify(json_data);
        } catch (ex) {
            errorHandler.notify(ex);
            return json_data;
        }
    }

    processDriversMacro(driver_macros) {
        const lead_drivers = this.req_params.drivers || [];
        let output_drivers = [];
        for (let lead_driver of lead_drivers) {
            if (typeof (driver_macros) === 'object') {
                let parsed_macros = {};
                for (let key in driver_macros) {
                    parsed_macros[key] = this.getMacroValueFromDriver(driver_macros[key], lead_driver);
                }
                output_drivers.push(parsed_macros);
            } else {
                output_drivers.push(this.getMacroValueFromDriver(driver_macros, lead_driver));
            }
        }
        return output_drivers;
    }

    getMacroValueFromDriver(macro_data, driver) {
        let macros = (macro_data || '').match(/\{[^}]+}/g) || '';
        if (macros && macros.length > 0) {
            for (let macro of macros) {
                let macro_field = macro.replace('{', '').replace('}', '').replace(/^\s+|\s+$/gm, '');
                let macro_value = driver[macro_field] || '';
                macro_data = macro_data.replace(macro, macro_value);
            }
        }
        return macro_data;
    }

    getMacroFieldValue(field, campaign) {
        switch (field) {
            case 'click_listing_id': {
                let click_listing = this.click_listings[campaign.id || campaign.campaign_id];
                return click_listing ? click_listing.click_listing_id : null;
            }
            case 'click_id': {
                let click_listing = this.click_listings[campaign.id || campaign.campaign_id];
                return click_listing ? click_listing.click_id : util.getParam(this.params, 'click_id');
            }
            case 'cpc': {
                let click_listing = this.click_listings[campaign.id || campaign.campaign_id];
                return click_listing ? click_listing.payout : 0;
            }
            case 'city': {
                return this.capitalizeWord(util.getParam(this.params, 'city'));
            }
            case 'state': {
                return State.getState(util.getParam(this.params, 'state'));
            }
            case 'state_code': {
                return util.getParam(this.params, 'state').toUpperCase();
            }
            case 'county': {
                return this.capitalizeWord(util.getParam(this.params, 'county'));
            }
            case 'first_name': {
                return this.capitalizeWord(util.getParam(this.params, 'first_name'));
            }
            case 'last_name': {
                return this.capitalizeWord(util.getParam(this.params, 'last_name'));
            }
            case 'adcreativename': {
                let click_listing = this.click_listings[campaign.id || campaign.campaign_id];
                return click_listing ? click_listing.ad_name : '';
            }
            case 'phone': {
                return util.getParam(this.params, 'primary_phone')
            }
            case 'dob': {
                return util.getParam(this.params, 'date_of_birth')
            }
            case 'source': {
                return util.getParam(this.params, 'sub1') || util.getParam(this.params, 'traffic_tier')
            }
            case 'source_type': {
                return util.getParam(this.params, 'traffic_tier')
            }
            case 'source_type_id': {
                return this.source_type_id;
            }
            case 'CampaignName': {
                return campaign.campaign_name;
            }
            case 'AdGroupName': {
                return campaign.ad_group_name;
            }
            default: {
                return util.getParam(this.params, field)
            }
        }
    }

    CDNLogoUrl(logo_url, click_id) {
        if (logo_url) {
            logo_url = logo_url.replace('portal-resources-s3.s3.amazonaws.com', 'd3nhve2vinn7q8.cloudfront.net');
            logo_url = logo_url.replace('goal-portal.s3.amazonaws.com', 'd19op4oz066kwe.cloudfront.net');
        }
        return logo_url + `?c=${click_id}&e=clk_impr`
    }

    convertToHtmlList(items) {
        let html = '<ul>';
        try {
            for (let item of JSON.parse(items || "[]")) {
                html += `<li>${item}</li>`
            }
        } catch (ex) {
            errorHandler.notify(ex);
        }
        return html + '</ul>';
    }

    capitalizeWord(text) {
        const words = (typeof (text) === 'string' ? text : '').split(" ");
        for (let i = 0; i < words.length; i++) {
            words[i] = (words[i][0] || '').toUpperCase() + words[i].substr(1);
        }
        return words.join(" ");
    }

    getCallPanels(req_data) {
        try {
            const call_panel_api_endpoint = 'https://forms.smartfinancial.com/api/v1/forms/get_call_panel';
            return axios.post(call_panel_api_endpoint, req_data, {})
                .then(res => {
                    if (res.data) {
                        this.populateCallPanels(res.data.listings);
                    }
                }).catch(error => {
                    console.log("getCallPanels() -> Error", error);
                });

        } catch (error) {
            console.log('getCallPanels() -> ex = ', error.message);
        }
    }

    populateCallPanels(listings) {
        let current_date_time = new Date();
        if (listings && listings.length > 0) {
            for (let l = 0; l < listings.length; l++) {
                let data = [this.ping_id, listings[l].service_provider, listings[l].price, listings[l].est_price, l + 1, listings[l].overflow, current_date_time, current_date_time];
                this.storeListingToCallPanels(data);
            }
        }
    }

    storeListingToCallPanels(data) {
        this.db.query('INSERT INTO call_panels (click_ping_id, advertiser, payout, est_payout, position, overflow, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *', data, (error, results) => {
            if (error) {
                console.log('storeListingToCallPanels() -> error: ', error.message);
            } else {
                if (results.rows[0]) {

                } else {
                    console.log('storeListingToCallPanels() -> error: ', error.message);
                }
            }
        });
    }
}
