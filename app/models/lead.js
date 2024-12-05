require('./click_debug');
const axios = require('axios');
const util = require('./utils');
const mongoose = require('mongoose');
const ErrorHandler = require("./error_handler");
const ClickDebug = mongoose.model('ClickDebug');
const errorHandler = new ErrorHandler();
const uuid = require("uuid");
const LeadIntegration = require("./lead_integration");
const {query} = require("express");
const MiniOrm = require('../lib/mini_orm');

module.exports = class Lead extends LeadIntegration {
    ping_integrations = [];
    orm = null;

    constructor(brand_conf, pm, tbm) {
        super();
        this.db = brand_conf.db;
        this.orm = new MiniOrm(brand_conf.db);
        this.brand_conf = brand_conf;
        this.read_replica_db = (brand_conf.read_replica || brand_conf).db;
        this.params = pm;
        this.token_bid_multipliers = tbm || [];
        this.lead_uid = uuid.v4();
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

    processResponse(startTime) {
        const res_campaign = {};
        let qualified_campaigns = [];
        res_campaign['listings'] = [];
        for (let campaign of this.campaign_list) {
            let campaign_id = campaign.campaign_id;
            if (this.campaign_exclusion.includes(campaign_id)) {
                this.setDebugData(campaign_id, 'qualified', false);
                continue;
            }
            if (this.filter_campaign_list.includes(campaign_id)) {
                campaign.price = this.getFinalPrice(campaign_id, campaign.base_bid_price);
                campaign.price -= this.weekendDiscount(campaign);
                campaign.est_payout = this.estimatedPayout(campaign);
                this.setDebugData(campaign_id, 'final_bid', campaign.price);
                qualified_campaigns.push(campaign);
            } else {
                this.setDebugData(campaign_id, 'qualified', false);
            }
        }
        res_campaign['listings'] = qualified_campaigns;
        const endTime = new Date().getTime();
        res_campaign['response_ms'] = endTime - startTime;//'567'
        return res_campaign;
    }

    async storeLeadPing(lead_data) {
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
            let device_type = util.getParam(this.params, 'device_type')

            let data = [partner_id, lead_type_id, aid, cid, sid, ks, session_id, zip, state, device_type, source_type_id, form_type_id, lead_data, total_opportunities, total_listings, total_revenue, total_cost, this.lead_uid, timestamps, timestamps];
            this.db.query('INSERT INTO lead_pings (partner_id, lead_type_id, aid, cid, sid, ks, session_id, zip, state, device_type, source_type_id, form_type_id, lead_data, total_opportunities, total_listings, total_revenue, total_cost, uid, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20) RETURNING *', data, (error, results) => {
                if (error) {
                    errorHandler.notify({message: JSON.stringify({error: error.message, from: 'storeLeadPing'})});
                    resolve({success: false});
                } else {
                    if (results.rows[0]) {
                        this.ping_id = results.rows[0].id;
                        this.storeLeadPingDetails().then(resp => {
                            resolve({success: true});
                        });
                        this.storeLeadPingMatches(this.ping_id, zip, lead_type_id);
                    } else {
                        errorHandler.notify({message: `storeLeadPing no id return from database ${JSON.stringify(results)}`});
                        resolve({success: false});
                    }
                }
            });
        });
    }

    async storeLeadPingDetails() {
        return new Promise((resolve, reject) => {
            let data = this.mapLeadData();
            data.unshift(this.ping_id);
            this.db.query('INSERT INTO lead_ping_details (lead_ping_id, insured, continuous_coverage, home_owner, gender, marital_status, consumer_age, education, credit_rating, military_affiliation, num_drivers, num_vehicles, violations, dui, accidents, license_status, first_name, last_name, phone, email, city, county, tobacco, major_health_conditions, life_coverage_type, life_coverage_amount, property_type, property_age, years_in_business, commercial_coverage_type, household_income, jornaya_lead_id, trusted_form_token, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35) RETURNING *', data, (error, results) => {
                if (error) {
                    console.log("Lead Ping Details Error: ", error.message);
                    errorHandler.notify(error);
                    resolve({success: false});
                } else {
                    resolve({success: true});
                }
            });
        });
    }

    mapLeadData() {
        const insured = util.getParam(this.params, 'currently_insured') === true;
        const continuous_coverage = `${util.getParam(this.params, 'coverage_years') || 0} years`;
        const gender = util.getParam(this.params, 'gender');
        const marital_status = util.getParam(this.params, 'marital_status');
        const education = util.getParam(this.params, 'education');
        const credit_rating = util.getParam(this.params, 'credit');
        const military_affiliation = util.getParam(this.params, 'military_affiliation') === true;
        const first_name = util.getParam(this.params, 'first_name');
        const last_name = util.getParam(this.params, 'last_name');
        const email = util.getParam(this.params, 'email');
        const phone = util.getParam(this.params, 'primary_phone');
        const city = util.getParam(this.params, 'city');
        const county = util.getParam(this.params, 'county');
        const num_drivers = util.getParam(this.params, 'num_drivers') || 0;
        const num_vehicles = util.getParam(this.params, 'num_vehicles') || 0;
        const violations = util.getParam(this.params, 'num_violations') > 0;
        const accidents = util.getParam(this.params, 'num_accidents') > 0;
        const dui = util.getParam(this.params, 'dui') === true;
        const tobacco = util.getParam(this.params, 'tobacco') === true;
        const life_coverage_type = util.getParam(this.params, 'coverage_type');
        const life_coverage_amount = util.getParam(this.params, 'coverage_amount');
        const property_type = util.getParam(this.params, 'property_type');
        const property_age = util.getParam(this.params, 'year_built');
        const years_in_business = util.getParam(this.params, 'years_in_business');
        const commercial_coverage_type = this.commercialCoverageTypes();
        const household_income = util.getParam(this.params, 'household_income');
        const major_health_conditions = this.majorHealthConditions();
        const home_owner = this.getHomeOwner();
        const consumer_age = util.getParam(this.params, 'age') || 18;
        const jornaya_lead_id = util.getParam(this.params, 'jornaya_lead_id');
        const trusted_form_token = util.getParam(this.params, 'trusted_form_token');
        const license_status = 'Active'; // Todo: have to get it from params
        const current_date_time = new Date();
        return [insured, continuous_coverage, home_owner, gender, marital_status, consumer_age, education, credit_rating, military_affiliation, num_drivers, num_vehicles, violations, dui, accidents, license_status, first_name, last_name, phone, email, city, county, tobacco, major_health_conditions, life_coverage_type, life_coverage_amount, property_type, property_age, years_in_business, commercial_coverage_type, household_income, jornaya_lead_id, trusted_form_token, current_date_time, current_date_time];
    }

    mapLeadDataExt() {
        return [
            util.getParam(this.params, 'lead_type_id') || 6,
            util.getParam(this.params, 'session_id'),
            util.getParam(this.params, 'aid'),
            util.getParam(this.params, 'cid'),
            util.getParam(this.params, 'sid'),
            util.getParam(this.params, 'ks'),
            util.getParam(this.params, 'source_type_id') || this.source_type_id,
            util.getParam(this.params, 'form_type_id') || 0,
            util.getParam(this.params, 'zip'),
            util.getParam(this.params, 'state'),
            util.getParam(this.params, 'device_type')
        ];
    }

    async storeLeadPingMatches(ping_id, zip, lead_type_id) {
        try {
            const ping_matches = await this.getPingMatches(zip, lead_type_id, 3, this.token_bid_multipliers)
            let ping_match_promise = [];
            const pst_columns = await this.getPSTColumns();
            let non_rtb_datasets = [];
            for (let ping_match of ping_matches) {
                ping_match_promise.push(this.storeLeadPingMatchesData(ping_id, ping_match, pst_columns));
                non_rtb_datasets.push(this.collectNonRtbDataExt(ping_match));
            }
            if (ping_match_promise.length > 0) {
                Promise.all(ping_match_promise).then(results => {
                    const value_set = this.getSQLValueSet(results);
                    this.db.query(`INSERT INTO lead_ping_matches (lead_ping_id, account_id, campaign_id,
                                                                  ad_group_id, brand_id, ad_group_active, payout,
                                                                  pst_hour, pst_day, pst_week, pst_month,
                                                                  pst_quarter, pst_year, created_at, updated_at)
                    VALUES
                    ${value_set}`, results.flat(), (error, result) => {
                        if (error) {
                            errorHandler.notify(error);
                        }
                    });
                    this.setNonRtbPingStat(results, non_rtb_datasets);
                });
            }
        } catch (ex) {
            errorHandler.notify({message: `Store ping matches: ${ex.message}`});
        }
    }

    async setNonRtbPingStat(ping_matches, non_rtb_datasets) {
        const lead_data = [...this.mapLeadData(), ...this.mapLeadDataExt()];
        let data = [];
        for (let i = 0; i < ping_matches.length; ++i) {
            const ping_match = ping_matches[i];
            data.push([...ping_match.slice(0, ping_match.length - 2), ...lead_data, ...Object.values(non_rtb_datasets[i])]); // remove created_at, updated_at
        }

        this.storeNonRtbPingStat(3, [...this.leadAttrs(), ...Object.keys(non_rtb_datasets[0])], data);
    }

    leadAttrs() {
        return [
            'lead_ping_id', 'account_id', 'campaign_id', 'ad_group_id', 'brand_id', 'ad_group_active',
            'payout', 'pst_hour', 'pst_day', 'pst_week', 'pst_month', 'pst_quarter', 'pst_year', 'insured',
            'continuous_coverage', 'home_owner', 'gender', 'marital_status', 'consumer_age', 'education', 'credit_rating',
            'military_affiliation', 'num_drivers', 'num_vehicles', 'violations', 'dui', 'accidents', 'license_status',
            'first_name', 'last_name', 'phone', 'email', 'city', 'county', 'tobacco', 'major_health_conditions',
            'life_coverage_type', 'life_coverage_amount', 'property_type', 'property_age', 'years_in_business',
            'commercial_coverage_type', 'household_income', 'jornaya_lead_id', 'trusted_form_token', 'created_at',
            'updated_at', 'lead_type_id', 'session_id', 'aid', 'cid', 'sid', 'ks', 'source_type_id', 'form_type_id',
            'zip', 'state', 'device_type'
        ];
    }

    async storeLeadPingMatchesData(ping_id, ping_match, pst_columns) {
        try {
            let current_date_time = new Date();
            return [ping_id, ping_match.account_id, ping_match.campaign_id, ping_match.ad_group_id, ping_match.brand_id, ping_match.ad_group_active, ping_match.payout, pst_columns.pst_hour, pst_columns.pst_day, pst_columns.pst_week, pst_columns.pst_month, pst_columns.pst_quarter, pst_columns.pst_year, current_date_time, current_date_time]
        } catch (ex) {
            errorHandler.notify({message: `Store ping matches: ${ex.message}`});
        }
    }

    async storeLeadListing(listings) {
        this.carriers = await this.loadCarriers();
        return new Promise(async (resolve, reject) => {
            let all_promise = [];
            let integration_promise = [];
            let campaign_integrations = {};
            let brand_campaigns = {};
            for (let integration of this.ping_integrations) {
                campaign_integrations[integration.campaign_id] = integration;
            }
            for (let listing of listings) {
                integration_promise.push(this.getPingIntegrationListings(campaign_integrations[listing.campaign_id], listing));
            }
            Promise.all(integration_promise).then(ping_listings => {
                ping_listings = ping_listings.flat();
                let selected_listings = this.selectedListings(ping_listings);
                for (let listing of ping_listings) {
                    let branch_with_type = `${listing.brand_id}_${listing.exclusive ? 'exclusive' : 'shared'}`;
                    let ext_campaign = listing;
                    if (brand_campaigns[branch_with_type]) {
                        let existing_campaign = brand_campaigns[branch_with_type];
                        if (existing_campaign.price < listing.price) {
                            brand_campaigns[branch_with_type] = listing;
                            ext_campaign = existing_campaign;
                        }
                        this.setDebugData(ext_campaign.campaign_id, 'exclusion', "Lower bid price within same brand campaigns");
                    } else {
                        brand_campaigns[branch_with_type] = listing;
                    }
                }
                for (let listing of Object.values(brand_campaigns)) {
                    let selected_listing = selected_listings.filter(l => l.id === listing.id).length > 0;
                    listing.de_duped = !selected_listing;
                    listing.selected = selected_listing;
                    all_promise.push(this.storeLeadListingDB(listing));
                }
                Promise.all(all_promise).then(results => {
                    resolve(results);
                });
            });
        });
    }

    async storeLeadOpportunity() {
        return new Promise((resolve, reject) => {
            let all_promise = [];
            for (let listing of this.campaign_list) {
                all_promise.push(this.leadOpportunityData(listing))
            }
            Promise.all(all_promise).then(results => {
                this.storeLeadOpportunityDB(results);
                //console.log("storeLeadOpportunity Response: ", results)
            });
        });
    }

    async leadOpportunityData(listing) {
        return new Promise(async (resolve, reject) => {
            const current_date_time = new Date();
            const pst_columns = await this.getPSTColumns();

            resolve([this.ping_id, listing.campaign_id, listing.ad_group_id, listing.brand_id, listing.account_id, listing.base_bid_price, pst_columns.pst_hour, pst_columns.pst_day, pst_columns.pst_week, pst_columns.pst_month, pst_columns.pst_quarter, pst_columns.pst_year, current_date_time, current_date_time]);
        });
    }

    async storeLeadOpportunityDB(value_set) {
        const columns = ['lead_ping_id', 'campaign_id', 'ad_group_id', 'brand_id', 'account_id', 'payout', 'pst_hour', 'pst_day', 'pst_week', 'pst_month', 'pst_quarter', 'pst_year', 'created_at', 'updated_at'];
        this.orm.batchInsert('lead_opportunities', columns, value_set).then(result => {
            // console.log("lead_opportunities stored");
        }, error => {
            errorHandler.notify(error);
            console.log('Unable to add lead_opportunities', error.message);
        });

        // return new Promise(async (resolve, reject) => {
        //     let current_date_time = new Date();
        //     const pst_columns = await this.getPSTColumns();
        //     let data = [this.ping_id, listing.campaign_id, listing.ad_group_id, listing.brand_id, listing.account_id, listing.base_bid_price, pst_columns.pst_hour, pst_columns.pst_day, pst_columns.pst_week, pst_columns.pst_month, pst_columns.pst_quarter, pst_columns.pst_year, current_date_time, current_date_time];
        //     this.db.query('INSERT INTO lead_opportunities (lead_ping_id, campaign_id, ad_group_id, brand_id, account_id, payout, pst_hour, pst_day, pst_week, pst_month, pst_quarter, pst_year, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14) RETURNING *', data, (error, results) => {
        //         if (error) {
        //             console.log("Store Lead Opportunity Error: ", error);
        //             errorHandler.notify(error);
        //             resolve(false);
        //         } else {
        //             //console.log("Store Lead Opportunity");
        //             resolve(true);
        //         }
        //     });
        // });
    }

    async storeDebugData(resp_time, num_listing) {
        let current_date_time = new Date();
        let data = [this.ping_id, JSON.stringify({campaigns: Object.values(this.debug_data.campaigns)}), resp_time, num_listing, this.req_token, current_date_time, current_date_time]
        this.db.query('INSERT INTO lead_ping_debug_logs (lead_ping_id, log, response_time_ms, num_listings, token, created_at, updated_at) VALUEs($1, $2, $3, $4, $5, $6, $7)', data, (error, result) => {
            if (error) {
                errorHandler.notify(error);
                console.log("Error Store Debug", error.message);
            } else {
                //console.log("Stored Debug Data Successfully!");
            }
        });
    }

    async storeLeadListingDB(listing) {
        return new Promise(async (resolve, reject) => {
            let current_date_time = new Date();
            const pst_columns = await this.getPSTColumns();
            let source_type_id = util.getParam(this.params, 'source_type_id') || this.source_type_id;
            let lead_type_id = util.getParam(this.params, 'lead_type_id') || this.req_params.lead_type_id;
            let state = util.getParam(this.params, 'state')
            let buyer = listing.carrier_id === '32' ? listing.brand_name : listing.company_name;
            if (listing.ping_post) {
                buyer = util.toLowerCase(listing.company_name) === 'independent agent' ? listing.business_name : listing.company_name;
            }
            listing.bid_id = uuid.v4();
            let data = [this.ping_id, listing.campaign_id, listing.brand_id, listing.account_id, listing.ad_group_id, listing.carrier_id, listing.price, listing.est_payout, listing.bid_id, listing.selected, listing.de_duped, listing.license_number, buyer, listing.listing_type, pst_columns.pst_hour, pst_columns.pst_day, pst_columns.pst_week, pst_columns.pst_month, pst_columns.pst_quarter, pst_columns.pst_year, state, lead_type_id, source_type_id, listing.pp_ping_id, listing.pp_bid_id, listing.ping_post, current_date_time, current_date_time];
            this.db.query('INSERT INTO lead_listings (lead_ping_id, campaign_id, brand_id, account_id, ad_group_id, carrier_id, payout, est_payout, bid_id, selected, de_duped, license_num, buyer, listing_type, pst_hour, pst_day, pst_week, pst_month, pst_quarter, pst_year, state, lead_type_id, source_type_id, pp_ping_id, pp_bid_id, ping_post, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28) RETURNING *', data, async (error, results) => {
                if (error) {
                    errorHandler.notify(error);
                    listing.lead_listing_id = null;
                } else {
                    listing.lead_listing_id = results.rows[0].id;

                    if (listing.ping_post) {
                        const non_rtb_ping_count = await this.findNonRtbPing(this.ping_id, listing.campaign_id, listing.ad_group_id, listing.account_id);
                        // console.log('non rtb count: ', non_rtb_ping_count);
                        if (non_rtb_ping_count) {
                            // console.log('update....');
                            this.updateListingOfNonRtbPingStat(listing);
                        } else {
                            // console.log('insert....');
                            this.storeNonRtbPingFromListing(listing);
                        }
                    } else {
                        this.updateListingOfNonRtbPingStat(listing);
                    }
                }
                resolve(listing);
            });
        });
    }

    async findNonRtbPing(lead_ping_id, campaign_id, ad_group_id, account_id) {
        return this.orm.select('non_rtb_ping_stats', ['COUNT(*)'],
            `account_id = ${account_id} and campaign_id = ${campaign_id} and ping_id = ${lead_ping_id}
             and ad_group_id = ${ad_group_id} and product_type_id = 3`).then((result) => {
            return parseInt(result.rows[0]?.count || '0');
        }, (err) => {
            console.log('err: ', err);
            return 0;
        });
    }

    async storeNonRtbPingFromListing(listing) {
        const pst_columns = await this.getPSTColumns();
        let ping_match_data = await this.storeLeadPingMatchesData(this.ping_id, {
            account_id: listing.account_id,
            campaign_id: listing.campaign_id,
            ad_group_id: listing.ad_group_id,
            brand_id: listing.brand_id,
            payout: listing.price,
            product_type_id: listing.product_type_id
        }, pst_columns);
        const non_rtb_data = this.collectNonRtbDataExt(listing);
        const columns = [...this.leadAttrs(), ...Object.keys(non_rtb_data)];
        ping_match_data = ping_match_data.slice(0, ping_match_data.length - 2);
        const values = [...ping_match_data, ...this.mapLeadData(), ...this.mapLeadDataExt(), ...Object.values(non_rtb_data)];

        columns.push('listing');
        values.push(true);
        columns.push('opportunity');
        values.push(true);
        columns.push('active_source');
        values.push(!(listing.active_source === false || listing.active_source == 0));

        for (const key in listing) {
            const key_at = columns.indexOf(key);
            if (key_at < 0) {
                columns.push(key);
                values.push(listing[key]);
            } else {
                values[key_at] = listing[key];
            }
        }

        this.storeNonRtbPingStat(3, columns, [values]);
    }

    async updateListingOfNonRtbPingStat(listing) {
        let update_params = {...listing, ...{listing: true, opportunity: true}, ...this.collectNonRtbDataExt(listing)};
        if (typeof (listing.price) !== 'undefined' || listing.price !== null) {
            update_params.payout = listing.price;
        }
        this.updateNonRtbPingStat(3, {
            ping_id: this.ping_id,
            account_id: listing.account_id,
            campaign_id: listing.campaign_id,
            ad_group_id: listing.ad_group_id
        }, update_params);
    }

    async storeLeadPost(lead_ping_id, post_data) {
        this.ping_id = lead_ping_id;
        this.post_uid = uuid.v4();
        let partner_id = this.token_id;
        const total_revenue = 0;
        const total_cost = 0;
        let lead_type_id = util.getParam(this.params, 'lead_type_id') || 6;
        let timestamps = new Date();
        let zip = util.getParam(this.params, 'zip');
        let state = util.getParam(this.params, 'state');

        let data = [lead_ping_id, partner_id, lead_type_id, zip, state, false, 0, 0, total_cost, total_revenue, false, post_data, this.post_uid, timestamps, timestamps];
        this.db.query('INSERT INTO lead_posts (lead_ping_id, partner_id, lead_type_id, zip, state, accepted, num_legs, accepted_legs, "cost", revenue, refunded, "data", uid, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15) RETURNING *', data, (error, results) => {
            if (error) {
                errorHandler.notify({message: JSON.stringify({error: error.message, from: 'storeLeadPost'})});
            } else {
                if (results.rows[0]) {
                    this.post_id = results.rows[0].id;
                    this.storeLeadPostDetails();
                } else {
                    errorHandler.notify({message: `storeLeadPost no id return from database ${JSON.stringify(results)}`});
                }
            }
        });
    }

    async storeLeadPostDetails() {
        let data = this.mapLeadData();
        data.unshift(this.post_id);
        this.db.query('INSERT INTO lead_post_details (lead_post_id, insured, continuous_coverage, home_owner, gender, marital_status, consumer_age, education, credit_rating, military_affiliation, num_drivers, num_vehicles, violations, dui, accidents, license_status, first_name, last_name, phone, email, city, county, tobacco, major_health_conditions, life_coverage_type, life_coverage_amount, property_type, property_age, years_in_business, commercial_coverage_type, household_income, jornaya_lead_id, trusted_form_token, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35) RETURNING *', data, (error, results) => {
            if (error) {
                console.log("Lead Post Details Error: ", error.message);
                errorHandler.notify(error);
            }
        });
    }

    async post(post_data, lead_data) {
        return new Promise((resolve, reject) => {
            return axios.post(this.brand_conf.lead_post_url, {
                campaign_ids: post_data,
                data: lead_data
            }, {headers: {}}).then(resp => {
                if (resp.data) {
                    resolve({success: true, data: resp.data});
                }
            }).catch(error => {
                console.log("Error", error.message);
                errorHandler.notify(error);
                resolve({success: false, data: error});
            });
        });
    }

    async updateLeadPost(bid_campaigns, status, post_api_response) {
        let num_legs = bid_campaigns.length;
        let post_response = JSON.stringify(post_api_response);
        let accepted_legs = 0;
        let revenue = 0;
        for (let bid_campaign of bid_campaigns) {
            if (bid_campaign.accepted) {
                accepted_legs += 1;
                revenue += bid_campaign.payout;
            }
        }
        const data = [num_legs, accepted_legs, revenue, status, post_response, this.post_id];
        this.db.query('UPDATE lead_posts set num_legs = $1, accepted_legs = $2, revenue = $3, accepted = $4, post_response = $5 where id = $6', data, (error, results) => {
            if (error) {
                errorHandler.notify(error);
            }
        });
    }

    async storePostLegs(bid_campaigns) {
        const prms = [];
        for (let bid_campaign of bid_campaigns) {
            prms.push(this.storePostLegsDB(bid_campaign));
        }
        Promise.all(prms).then(results => {
            // console.log('store legs', results);
        });
    }

    async updateLeadListings(bid_campaigns) {
        const proms = [];
        for (let bid_campaign of bid_campaigns) {
            proms.push(this.updateLeadListingsDB(bid_campaign));
        }
        Promise.all(proms).then(results => {
            // console.log('update lead listings', results);
        });
    }

    async storePostLegsDB(bid_campaign) {
        return new Promise((resolve, reject) => {
            let current_date_time = new Date();
            let data = [this.post_id, bid_campaign.bid_id, bid_campaign.accepted, bid_campaign.payout, false, bid_campaign.error, current_date_time, current_date_time];
            this.db.query('INSERT INTO lead_post_legs (lead_post_id, bid_id, accepted, payout, refunded, msg, created_at, updated_at) VALUES($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *', data, (error, results) => {
                if (error) {
                    errorHandler.notify(error);
                    resolve(false);
                } else {
                    resolve(true);
                }
            });
        });
    }

    async updateLeadListingsDB(bid_campaign) {
        return new Promise((resolve, reject) => {
            const data = [bid_campaign.accepted, bid_campaign.org_payout, bid_campaign.bid_id]
            this.db.query('UPDATE lead_listings set posted = true, post_accepted = $1, post_payout = $2 where bid_id = $3', data, (error, results) => {
                if (error) {
                    errorHandler.notify(error);
                    resolve(false);
                } else {
                    this.updateNonRtbPingStat(3, {
                        listing_id: bid_campaign.id,
                        campaign_id: bid_campaign.campaign_id
                    }, {
                        won: true,
                        accepted: bid_campaign.accepted
                    })
                    resolve(true);
                }
            });
        });
    }

    async updateLeadPings(num_listings) {
        this.db.query('update lead_pings set total_opportunities = $1, total_listings = $2 where id = $3', [this.campaign_list.length, num_listings, this.ping_id], (error, results) => {
            if (error) {
                errorHandler.notify(error);
            } else {
                //console.log('Lead ping has been updated');
            }
        });
    }

    selectedListings(listings) {
        let selected_listings = {};
        listings.map(listing => {
            let select_key = `${listing.carrier_id}_${listing.listing_type}`;
            if (listing.carrier_id === '32') {
                select_key = `${listing.license_number}_${listing.listing_type}`;
            }
            if (selected_listings[select_key]) {
                if (selected_listings[select_key].price < listing.price) {
                    selected_listings[select_key] = listing;
                }
            } else {
                selected_listings[select_key] = listing;
            }
            return listing;
        });
        return Object.values(selected_listings);
    }
}
