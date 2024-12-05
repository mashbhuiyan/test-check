require('../models/token');
require('../models/request_log');
const {brands} = require('../config/database');
const mongoose = require('mongoose');
const Token = mongoose.model('Token');
const requestIp = require('request-ip');
const NodeCache = require('node-cache');
const appCache = new NodeCache();
const AppMemcached = require("../lib/app_memcached");
const ErrorHandler = require("../models/error_handler");
const flatten = require('flat');
const DataState = require('../models/data_state');
const util = require('../models/utils');

module.exports.read = function (req, res, next) {
    authorize(req, res, next, {$in: ['read', 'write']});
};

module.exports.write = function (req, res, next) {
    authorize(req, res, next);
};

function authorize(req, res, next, access_level = 'write') {
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
        const access_token = req.headers.authorization.split('Bearer ')[1].trim();
        return tokenAuthorization(req, res, next, access_token, access_level);
    }
    unauthorizedResponse(res);
}

function tokenAuthorization(req, res, next, access_token, access_level) {
    const db = brands[req.params.brand || 'smartfinancial'].db;
    Token.findOne({access_token: access_token, active: true, access_level: access_level}, async (err, token) => {
        if (err || !token) {
            return unauthorizedResponse(res);
        }
        let brand = req.params.brand;
        let brand_url = '';
        if (brand) {
            brand_url = `${brand}/`
        }
        if (token.brands.length && ((!brand && !token.brands.includes('smartfinancial')) || !token.brands.includes(brand))) {
            return unauthorizedResponse(res);
        }

        if (token.whitelisted_ips.length) {
            const reqIP = requestIp.getClientIp(req);
            if (!token.whitelisted_ips.includes(reqIP)) {
                return unauthorizedResponse(res);
            }
        }

        if (token.request_limit && token.request_period) {
            const count = await reqThrottle(req, res, token);
            if (count > token.request_limit) {
                return unauthorizedResponse(res, 'Too Many Requests', 429);
            }
        }

        if (!req.url.includes('/tokens')) {
            req.body.campaign_bid_multipliers = token.campaign_bid_multipliers;
        }

        req.body.token = {use_replica: token.use_replica, partner_id: token._id.toString()}

        if ([`/api/v1/${brand_url}calls/ping`].includes(req.url)) {
            let inbound = req.body.lead.inbound;
            req.body.lead.inbound = typeof (inbound) == 'undefined' ? false : inbound;
        }

        if ([`/api/v1/${brand_url}calls/ping`, `/api/v1/${brand_url}calls/post`, `/api/v1/${brand_url}calls/brand_availability`].includes(req.url)) {
            req.body.call_transfer_types = token.transfer_types;
            req.body.lead.call_type = getCallType(req.body.lead.call_type, token);
        }

        if ([`/api/v1/${brand_url}clicks`, `/api/v1/${brand_url}leads/ping`, `/api/v1/${brand_url}leads/post`, `/api/v1/${brand_url}calls/ping`, `/api/v1/${brand_url}calls/post`].includes(req.url) || req.url.search(/\/clicks\/[0-9]+\/post/i) > 0) {
            req.body.schema_validation_required = token.schema_validation_required === true ? 'Yes' : 'No';
            // sanitize phone number fields
            if (typeof (req.body.lead) === 'undefined') {
                return unauthorizedResponse(res, 'Lead data is missing');
            }
            if (req.url === `/api/v1/${brand_url}clicks`) {
                req.body.original_lead = Object.assign({}, req.body.lead);
                req.body.lead.slice_num = Math.floor(Math.random() * 100); //returns a random integer between 0 and 99 (both included)
                // MT Leads is sending their sources under aid field (instead of traffic_tier)
                if (token._id.toString() == '63221ca202c25cefb36e8524' && req.body.lead.aid) {
                    req.body.lead.traffic_tier = req.body.lead.aid;
                }
            }

            req.body.lead.post = false;
            if (req.body.lead.contact) {
                if (!req.body.lead.contact.primary_phone && req.body.lead.contact.phone) {
                    req.body.lead.contact.primary_phone = req.body.lead.contact.phone;
                }
                if (req.body.lead.contact.primary_phone) {
                    try {
                        req.body.original_primary_phone = req.body.lead.contact.primary_phone;
                        let phone = req.body.lead.contact.primary_phone.replace(/\D/g, '');
                        if (phone.length > 10) {
                            phone = phone.substr(phone.length - 10); // Last 10 digits of the phone
                        }
                        req.body.lead.contact.primary_phone = phone;
                    } catch (ex) {
                    }
                }
                if (req.body.lead.contact.zip) {
                    try {
                        const zip_details = await getZipDetails(db, req.body.lead.contact.zip);
                        req.body.lead.contact.state = zip_details.state || req.body.lead.contact.state;
                        if (!req.body.lead.contact.county) {
                            req.body.lead.contact.county = zip_details.county || null;
                        }
                        req.body.lead.zip_tier = await getZipTierIds(db, req.body.lead.contact.zip);
                    } catch (ex) {
                        let errorHandler = new ErrorHandler();
                        errorHandler.notify(ex);
                    }
                }
            }
            if ([`/api/v1/${brand_url}clicks`, `/api/v1/${brand_url}leads/ping`, `/api/v1/${brand_url}calls/ping`].includes(req.url)) {
                if (!req.body.lead.traffic_tier) {
                    req.body.lead.traffic_tier = token.label;
                }
                // source type ID
                req.body.lead.source_type_id = await getSourceTypeId(db, req.body.lead.traffic_tier, token);
            }
            if (req.url === `/api/v1/${brand_url}clicks`) {
                let dup_modifier = await getDupModifier(req.body.lead);
                let dup_days = 100000;//null;
                if (dup_modifier) {
                    dup_days = getDupeModifierDays(dup_modifier);
                }
                req.body.lead.dupe_days_lead_modifier = dup_days;
                req.body.lead.dupe_days_click_modifier = dup_days;
                req.body.lead.dupe_days_call_modifier = dup_days;
                if (req.body.lead.click_id == undefined || req.body.lead.click_id == null) {
                    req.body.lead.click_id = null;
                }
                // if (req.body.lead.customer_profile) {
                //     req.body.lead.customer_profile.military_affiliation = req.body.lead.military_affiliation;
                // } else {
                //     req.body.lead.customer_profile = {
                //         military_affiliation: req.body.lead.military_affiliation
                //     }
                // }
            }
            if (req.body.lead && [`/api/v1/${brand_url}leads/post`, `/api/v1/${brand_url}calls/post`].includes(req.url)) {
                req.body.lead.post = true;
            }
            // home owenership
            if (req.body.lead.customer_profile && req.body.lead.customer_profile.residence) {
                // some partners are sending homeowner data under residence
                if (typeof (req.body.lead.customer_profile.residence) === 'string') {
                    req.body.lead.customer_profile.residence = {own: req.body.lead.customer_profile.residence};
                }
                req.body.lead.own_home = getHomeOwnership(req.body.lead.customer_profile.residence.own);
            }
            // property age
            if (req.body.lead.home_info && req.body.lead.home_info.year_built) {
                req.body.lead.property_age = getPropertyAge(req.body.lead.home_info.year_built);
            }
            if (typeof (req.body.lead.multiple_vehicles) != 'undefined' && typeof (req.body.lead.multiple_vehicles) === 'boolean') {
                req.body.lead.multiple_vehicles = req.body.lead.multiple_vehicles === true ? 'Yes' : 'No'
            }
            // continuous insurance
            if (req.body.lead.current_coverage && req.body.lead.current_coverage.coverage_years) {
                req.body.lead.continuous_insurance = getContinouousInsurance(req.body.lead.current_coverage.coverage_years);
            } else {
                req.body.lead.continuous_insurance = 'Less than 1 year'
            }
            // num drivers
            if (req.body.lead.drivers) {
                let num_violations = 0;
                let num_accidents = 0;
                let accidents = [];
                req.body.lead.num_drivers = req.body.lead.drivers.length;
                for (let driver of req.body.lead.drivers) {
                    num_violations += (driver.violations || []).length;
                    num_accidents += (driver.accidents || []).length;
                    accidents.push(driver.accidents || []);
                }
                req.body.lead.num_violations = num_violations;
                req.body.lead.num_accidents = num_accidents;
                req.body.lead.has_accident = hasAccident(accidents);
            } else {
                req.body.lead.has_accident = 'No';
            }
            // num vehicles
            if (req.body.lead.vehicles) {
                req.body.lead.num_vehicles = req.body.lead.vehicles.length;
            }
            // sanitize life coverage amount
            if (req.body.lead.requested_coverage && req.body.lead.requested_coverage.coverage_amount) {
                let lifeCoverageAmount = req.body.lead.requested_coverage.coverage_amount;
                if (typeof (lifeCoverageAmount) === 'string') {
                    lifeCoverageAmount = parseFloat(lifeCoverageAmount.replace(/[^\d.-]/g, ''));
                } else {
                    lifeCoverageAmount = parseFloat(lifeCoverageAmount);
                }
                if (lifeCoverageAmount <= 50000) {
                    lifeCoverageAmount = 50001;
                }
                req.body.lead.requested_coverage.coverage_amount = lifeCoverageAmount;
            }
            // map commercial_coverage
            if (req.body.lead.lead_type_id == 5) { // 5 for commercial insurance
                let commercial_coverage = [];
                try {
                    let coverages = flatten(req.body.lead.business_info.commercial_coverage_types || req.body.lead.requested_coverage || []);
                    for (let key in coverages) {
                        if (coverages[key] === true || coverages[key] == 'true') {
                            let coverage = key.split('.').pop();
                            commercial_coverage.push(mapCommercialCoverage(coverage));
                        }
                    }
                } catch (ex) {
                }
                req.body.lead.commercial_coverage = commercial_coverage.join('>;');
            }

            // map vehicle makes & years
            if (req.body.lead.lead_type_id == 6) { // 6 for auto insurance
                let vehicle_makes = [];
                let vehicle_years = [];
                try {
                    let vehicles = req.body.lead.vehicles || [];
                    for (let vehicle of vehicles) {
                        if (vehicle.make) {
                            vehicle_makes.push(vehicle.make.toLowerCase());
                        }
                        if (vehicle.year) {
                            vehicle_years.push(vehicle.year);
                        }
                    }
                } catch (ex) {
                }
                req.body.lead.veh_makes = vehicle_makes.join('>;');
                req.body.lead.veh_years = vehicle_years.join('>;');
            }

            if (req.body.lead.consent_list) {
                req.body.lead.consent_list = mapConsentList(req.body.lead.consent_list);
            }
        }

        req.body.token_type = token.type;
        req.body.token_id = token.id;
        if (token.type === 'generic') {
            req.body.project_id = token.project_id;
        }

        if (req.url === `/api/v1/${brand_url}clicks`) {
            const params = req.body.lead || {};
            const f_params = flatten(params);
            const data_state = new DataState();
            let data_state_info = await data_state.checkLeadData(f_params, params);
            let total_required_fields = data_state_info['total_required_fields'] || 0;
            let total_missing_fields = data_state_info['total_missing_fields'] || 0;
            req.body.lead.prefill_perc = total_missing_fields > 0 ? 100 - Math.ceil((100 / total_required_fields) * total_missing_fields) : 100;
        }

        next();
    });
}

function getCallType(call_type, token) {
    if (call_type) {
        return mapCallType(call_type);
    } else {
        if (token.call_origination_type) {
            return token.call_origination_type;
        } else {
            return 2; // outbound
        }
    }
}

function mapCallType(call_type) {
    if (call_type === 'inbound') {
        return 1;
    } else {
        return 2; // outbound
    }
}

function hasAccident(accidents) {
    for (let accident of accidents.flat()) {
        if (accident.incident_at_fault) {
            return "Yes";
        }
    }
    return "No";
}

function getSourceTypeId(db, source_type, token) {
    const query = `SELECT *
                   FROM source_types
                   WHERE LOWER(name) = '${util.toLowerCase(source_type)}'
                     AND project_id ${getProjectQueryString(token)}
                   ORDER BY id ASC
                   limit 1`;
    return db.query(query).then((results) => {
        return results.rows[0] ? results.rows[0].id : null;
    }, err => {
        console.log('source_types query error: ', err.message);
        return null;
    });
}

function getZipDetails(db, zip) {
    const query = `SELECT state, county
                   FROM zipcodes
                   WHERE zipcode = '${zip}'
                   limit 1`;
    return db.query(query).then((results) => {
        return results.rows[0] ? results.rows[0] : {};
    }, err => {
        console.log('county query error: ', err.message);
        return {};
    });
}

function getZipTierIds(db, zip) {
    const query = `select distinct zip_tier_id
                   from zip_tier_locations
                            inner join zip_tiers
                                       on zip_tier_locations.zip_tier_id = zip_tiers.id
                   where zip = '${zip}'
                     and zip_tiers.discarded_at is null`;
    return db.query(query).then((results) => {
        return Object.values(flatten(results.rows)).join('>;');
    }, err => {
        console.log('getZipTierIds query error: ', err.message);
        return '';
    });
}

async function getDupModifier(lead) {
    try {
        const memcached = AppMemcached.getInstance();
        let mem_key = lead.contact ? lead.contact.email : '';
        let cache_data = await memcached.get(formatMemCachedKey(mem_key, 'email'));
        if (cache_data) {
            return cache_data;
        } else {
            let phone = lead.contact ? (lead.contact.primary_phone || '').replace(/\D/g, '') : '';
            mem_key = phone.substr(phone.length - 10); // Last 10 digits of the phone
            cache_data = await memcached.get(formatMemCachedKey(mem_key, 'phone'));
            if (cache_data) {
                return cache_data;
            } else {
                let ip = lead.ip_address;
                let user_agent = (lead.user_agent || '').split(' ').join('_');
                mem_key = ip + '_' + user_agent;
                cache_data = await memcached.get(formatMemCachedKey(mem_key, 'ip_address'));
                if (cache_data) {
                    return cache_data;
                } else {
                    return null;
                }
            }
        }
    } catch (ex) {
        let errorHandler = new ErrorHandler();
        errorHandler.notify(ex);
        return null;
    }
}

function formatMemCachedKey(key, default_value) {
    // console.log('Mem Key: ', key);
    if (typeof (key) === 'string') {
        return key.replace(/[\n\r]/g, "").replace(/ /g, '') || default_value;
    } else {
        return default_value;
    }
}

function getProjectQueryString(token) {
    if (token.type === 'generic') {
        return `= '${token.project_id}'`;
    }
    return 'IS NULL';
}

function getHomeOwnership(status) {
    if (status === 'Own' || status === 'own') {
        return 'Yes';
    } else {
        return 'No';
    }
}

function getPropertyAge(yearBuilt) {
    const currentYear = new Date().getFullYear();
    yearBuilt = parseInt(yearBuilt || (currentYear - 15));
    const propertyAge = (currentYear - yearBuilt);
    if (propertyAge <= 2) {
        return 'New';
    } else if (propertyAge <= 7) {
        return '5 Years';
    } else if (propertyAge <= 15) {
        return '10 Years';
    } else if (propertyAge <= 25) {
        return '20 Years';
    } else if (propertyAge <= 40) {
        return '30 Years';
    } else {
        return 'Over 40 Years';
    }
}

function getContinouousInsurance(val) {
    val = parseInt(val || 0);
    if (val >= 1) {
        return '1+ years'
    } else {
        return 'Less than 1 year'
    }
}

async function reqThrottle(req, res, token) {
    try {
        let cachedToken = appCache.get(token.access_token);
        if (cachedToken) {
            cachedToken = JSON.parse(cachedToken);
            const time = Date.now();
            const endTime = ((cachedToken.startTime / 1000) + token.request_period) * 1000;
            if (time >= cachedToken.startTime && time <= endTime) {
                cacheToken(token.access_token, cachedToken.startTime, cachedToken.count + 1);
                return cachedToken.count + 1;
            }

            cacheToken(token.access_token, time, 1);
            return 1;
        }

        cacheToken(token.access_token, Date.now(), 1);
        return 1;
    } catch (e) {
        console.log('Throttle: ', e.message);
        return 1;
    }
}

function mapCommercialCoverage(coverage) {
    switch (coverage) {
        case 'general_liability':
            return 'General liability';
        case 'commercial_auto':
            return "Commercial Auto";
        case 'Commercial_property':
            return 'Commercial Property';
        case 'professional_liability':
            return 'Professional liability';
        case 'directors_liability':
            return "Director's liability";
        case 'business_owners_package_policy':
            return 'Business owners package policy';
        case 'workers_comp':
            return 'Workers compensation';
        case 'commercial_crime':
            return 'Commercial crime';
        default:
            return coverage;
    }
}

function cacheToken(access_token, startTime, count) {
    appCache.set(access_token, JSON.stringify({
        startTime: startTime, count: count
    }));
}

function unauthorizedResponse(res, message = 'Unauthorized', code = 403) {
    res.status(code);
    res.json({
        message: message, success: false
    });
}

function getDupeModifierDays(dt) {
    try {
        setUTCTime();
        let cache_time = (new Date(dt)).getUTCTime();
        let current_time = (new Date()).getUTCTime();
        let days = (current_time - cache_time) / (1000 * 60 * 60 * 24);
        return Math.round(days);
    } catch (ex) {
        return 0;
    }
}

function setUTCTime() {
    Date.prototype.getUTCTime = function () {
        return this.getTime() - (this.getTimezoneOffset() * 60000);
    };
}

function mapConsentList(consentList) {
    const consent_list = ["21st Century Insurance",
        "Allstate Insurance",
        "Farm Bureau",
        "Farmers Insurance",
        "GEICO",
        "Nationwide",
        "Progressive Insurance",
        "State Farm",
        "USAA",
        "AAA Insurance Co.",
        "Allied",
        "American Family Insurance",
        "American National Insurance",
        "Amica Insurance",
        "Cotton States Insurance",
        "Country Financial",
        "Erie Insurance Company",
        "Esurance",
        "GMAC Insurance",
        "Infinity Insurance",
        "Liberty Mutual Insurance Company",
        "Mercury",
        "Metropolitan Insurance Co.",
        "SAFECO",
        "Sentry Insurance Company",
        "Shelter Insurance Company",
        "The Hartford",
        "The Hartford AARP",
        "Travelers Insurance Company",
        "Unitrin Direct",
        "Independent Agency",
        "Plymouth Rock",
        "US Health Advisors",
        "Manhattan Life",
        "Gainsco",
        "National General",
        "Direct General",
        "The General",
        "Wealth Wave",
        "TourchMark",
        "Acuity Insurance",
        "Assurance",
        "Health IQ",
        "Tranzact",
        "Healthcare.com",
        "Universal Healthcare Advisors",
        "SeniorCare Benefits",
        "Kemper",
        "Covered by Sage",
        "SafeAuto",
        "AIS Insurance",
        "Jupiter Insurance",
        "Metlife",
        "Gabi Insurance",
        "DayForward",
        "Family First Life",
        "Hippo Insurance",
        "Farmers Hawaii",
        "Kaiser Permanente",
        "Amerilife",
        "Mutual of Omaha",
        "United Health",
        "Comparion",
        "Direct Auto",
        "NASB",
        "Impact Legacy"];

    if (consentList && consentList.length > 0) {
        return consentList.map(function (consent) {
            if (!consent.trim()) {
                return consent;
            }

            const matchedConsent = consent_list.find(item => {
                const regex = new RegExp(consent, 'i');
                return regex.test(item);
            });
            return matchedConsent ? matchedConsent : consent;
        })
    } else {
        return [];
    }
}
