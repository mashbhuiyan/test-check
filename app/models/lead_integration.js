const Base = require('./base');
const util = require('./utils');
const NonRtbPingStat = require('./non_rtb_ping_stat');

module.exports = class LeadIntegration extends Base {
    carriers = [];
    listing_counter = 999;
    non_rtb_ping_stat = null;

    async getPingIntegrationListings(integration, listing, product_type = '') {
        let integration_response = null;
        let ping_listings = [];
        listing.ping_post = false;
        listing.listing_type = listing.exclusive ? 'exclusive' : 'shared';
        if (integration) {
            integration_response = await this.applyIntegration(integration, listing, true);
            if (integration_response) {
                let integration_success = this.integrationResponse(integration, integration_response);
                if (integration_success) {
                    let ping_config = JSON.parse(integration.ping_config);
                    let full_resp = product_type === 'click' && !ping_config.buyers;
                    integration_response = this.parsePingIntegrationResponse(integration_response.data, ping_config, full_resp);
                    let buyers = ping_config.buyers ? (integration_response[ping_config.buyers] || []) : integration_response;
                    if (!Array.isArray(buyers)) {
                        buyers = [buyers];
                    }
                    listing.pp_ping_id = integration_response[ping_config.ping_id];
                    if (buyers.length > 0) {
                        for (let buyer of buyers) {
                            ping_listings.push(this.generatePingListing(listing, buyer, ping_config, product_type, integration.lead_integration_id))
                        }
                    } else {
                        ping_listings.push(this.generatePingListing(listing, integration_response, ping_config, product_type, integration.lead_integration_id));
                    }
                    return ping_listings;
                } else {
                    this.campaign_exclusion.push(listing.campaign_id);
                    this.setDebugData(listing.campaign_id, 'exclusion', 'Ping integrations failed');
                    return [];
                }
            } else {
                this.campaign_exclusion.push(listing.campaign_id);
                this.setDebugData(listing.campaign_id, 'exclusion', 'Ping integrations failed');
                return [];
            }
        }
        return [listing];
    }

    generatePingListing(campaign_listing, buyer, ping_config, product_type, lead_integration_id) {
        buyer = util.flattenJSON(buyer); //Flatten json object to get nested key value
        let listing = Object.assign({}, campaign_listing);
        let min_bid = ping_config.min_bid || 1;
        listing.pp_bid_id = buyer[ping_config.bid_id];
        listing.price = parseFloat(buyer[ping_config.bid] || '0');
        listing.est_payout = parseFloat(buyer[ping_config.bid] || '0');
        listing.company_name = buyer[ping_config.buyer_name];
        if (!listing.company_name) {
            if (listing.insurance_carrier_id == '32') {
                listing.company_name = 'Independent Agent';
            } else {
                listing.company_name = this.getCarrier(listing.insurance_carrier_id);
            }
        }
        listing.ping_post = true;
        listing.listing_type = ping_config.bid_types === 'mixed' ? (buyer[ping_config.leg_type] || campaign_listing.listing_type) : ping_config.bid_types;
        listing.listing_type = (listing.listing_type || '').toLowerCase();
        listing.exclusive = listing.listing_type === 'exclusive';
        listing.id = (Math.random() * 1000000).toFixed(0);
        // Start: Call integration only
        listing = this.updateCallData(listing, buyer, ping_config);
        // End: Call integration only
        if (listing.est_payout < min_bid) {
            console.log(`Ping listing rejected for lower bid -> campaign ${listing.campaign_id} ->`, listing.est_payout);
            listing.est_payout = 0;
        }
        if (listing.company_name) {
            let map_carrier = this.mapCarrier(listing.company_name);
            listing.carrier_id = map_carrier.carrier_id;
            if (map_carrier.license_number) {
                listing.license_number = map_carrier.license_number;
            }
        }
        if (product_type === 'click') {
            listing.title = buyer[ping_config.title || 'title'] || listing.title;
            listing.description = this.parseBuyerDescription(buyer[ping_config.description || 'description'] || listing.description);
            listing.click_url = buyer[ping_config.url || ping_config.click_url || 'url'] || listing.click_url;
            if (listing.append_tracking) {
                let final_append_tracking = this.processAppendTrackingMacros(listing.append_tracking, listing);
                listing.click_url += listing.click_url.includes('?') ? '&' : '?';
                listing.click_url += final_append_tracking;
            }
            if (lead_integration_id == 106) {
                listing.click_url = `https://contactability.com/api/v1/clicks_sc_track?url=${listing.click_url}`
            }
            listing.logo_url = buyer[ping_config.logo_url || 'logo_url'] || listing.logo_url;
            listing.display_url = buyer[ping_config.site_host || 'site_host'] || listing.site_host;
            listing.company_name = buyer[ping_config.company_name || 'company_name'] || listing.company_name;
            listing.display_name = buyer[ping_config.display_name || 'display_name'] || listing.display_name;
            listing.network_id = buyer[ping_config.network_id || 'network_id'] || null;
            listing.description += buyer[ping_config.impression_pixel || 'impression_pixel'] || '';
            listing.id = `${this.listing_counter}${listing.campaign_id}`;
            this.listing_counter += 1;
        }
        return listing;
    }

    postIntegrationBuyers(buyers, ping_config, integration, listings, full_response = null) {
        let listing_buyers = [];
        let listing = {payout: 0};
        for (let buyer of buyers) {
            buyer = util.flattenJSON(buyer); //Flatten json object to get nested key value
            const success_regx = new RegExp(integration.res_success_regex, "i");
            let buyer_success = (success_regx.exec(this.responseToString(integration.res_type, (full_response || buyer))) || []).length > 0;
            let bid_id = buyer[ping_config.bid_id];
            listing = listings.filter(l => l.bid_id === bid_id || l.pp_ping_id === bid_id)[0] || {payout: 0};
            if (listings.length === 1 && buyers.length === 1) {
                listing = listings[0];
            }
            let formatted_buyer = {
                success: buyer_success,
                bid_id: listing.bid_id,
                listing_id: listing.id,
                type: buyer[ping_config.leg_type] || listing.listing_type,
                buyer: buyer[ping_config.buyer_name] || listing.buyer,
                error: buyer_success ? '' : 'Rejected',
                campaign_id: integration.campaign_id,
                payout: this.parsePayout((typeof (buyer[ping_config.bid]) == 'undefined' ? listing.payout : buyer[ping_config.bid])),
                est_payout: this.parsePayout((typeof (buyer[ping_config.bid]) == 'undefined' ? listing.payout : buyer[ping_config.bid]))
            }
            // Start: Call integration only
            listing = this.updateCallData(listing, buyer, ping_config);
            // End: Call integration only
            if (formatted_buyer.payout === 0 || formatted_buyer.success === false) {
                formatted_buyer.error = formatted_buyer.payout === 0 ? 'Rejected as 0 payout' : 'Rejected';
                formatted_buyer.success = false;
                formatted_buyer.payout = 0;
                formatted_buyer.est_payout = 0;
            }
            listing_buyers.push(formatted_buyer);
        }
        return listing_buyers;
    }

    async applyPostIntegrations(integrations, bid_campaigns) {
        let campaigns = []
        for (let campaign_id in integrations) {
            let integration = integrations[campaign_id];
            let accept_reject_integrations = integration.accept_reject;
            if (accept_reject_integrations.length > 0) {
                let status = true;
                for (let accept_reject_integration of accept_reject_integrations) {
                    let integration_status = await this.applyIntegration(accept_reject_integration, bid_campaigns[campaign_id]);
                    if (!integration_status) {
                        status = false;
                        break;
                    }
                }
                if (status) {
                    campaigns.push(campaign_id);
                }
            } else {
                campaigns.push(campaign_id);
            }
        }
        return campaigns
    }

    async applyPingPostIntegrations(integrations, ping_post_campaigns) {
        let campaigns = []
        let post_integration_campaign_response = [];
        for (let integration of integrations) {
            let pp_ping_data = ping_post_campaigns[integration.campaign_id];
            let pp_listings = Object.values(pp_ping_data).flat();
            let bid_ids = pp_listings.map(listing => (listing.pp_bid_id || listing.bid_id));
            let total_price = null;
            try {
                let pp_price = pp_listings.map(listing => parseFloat(listing.payout));
                total_price = pp_price.reduce((a, b) => a + b, 0) || null;
            } catch (e) {
                console.log(`error inside applyPingPostIntegrations: ${e}`);
                total_price = null;
            }
            let post_data = {
                ping_id: Object.keys(pp_ping_data)[0],
                bid_ids: bid_ids,
                pp_price: total_price
            }
            let integration_response = await this.applyIntegration(integration, {}, true, post_data);
            this.integrationResponse(integration, integration_response); // Actually store integration log
            if (integration_response && integration_response.data) {
                let ping_config = JSON.parse(integration.ping_config);
                let parsed_integration_response = this.parsePingIntegrationResponse(integration_response.data, ping_config)
                //console.log('integration_response final: ', parsed_integration_response);
                let buyers = parsed_integration_response[ping_config.buyers] || [];
                let post_integration_buyers = [];
                if (!Array.isArray(buyers)) {
                    buyers = [buyers];
                }
                if (buyers.length > 0) {
                    post_integration_buyers = this.postIntegrationBuyers(buyers, ping_config, integration, pp_listings);
                } else {
                    post_integration_buyers = this.postIntegrationBuyers([parsed_integration_response], ping_config, integration, pp_listings, integration_response.data);
                }
                if (post_integration_buyers.length > 0) {
                    post_integration_campaign_response.push({
                        campaign_id: integration.campaign_id,
                        listing_id: (pp_listings.length > 0 ? pp_listings[0].id : ''),
                        payout: post_integration_buyers.reduce(function (sum, buyer) {
                            return sum + (buyer.success ? buyer.payout : 0);
                        }, 0),
                        buyers: post_integration_buyers
                    });
                }
            }
        }
        return post_integration_campaign_response
    }

    updateCallData(listing, buyer, ping_config) {
        if (buyer[ping_config.transfer_number]) {
            let transfer_number = buyer[ping_config.transfer_number].replace(/\D/g, '')
            listing.transfer_number = transfer_number.substr(transfer_number.length - 10); // Last 10 digits of the phone;
        }
        if (buyer[ping_config.tracking_number]) {
            listing.tracking_number = buyer[ping_config.tracking_number];
        }
        if (buyer[ping_config.billable_duration]) {
            listing.billable_duration = buyer[ping_config.billable_duration];
        }
        return listing;
    }

    async processGeneralIntegrations(integrations, bid_campaigns) {
        let process_integrations = [];
        for (let campaign_id in integrations) {
            let integration = integrations[campaign_id];
            let general_integrations = integration.general;
            if (general_integrations.length > 0) {
                for (let general_integration of general_integrations) {
                    let listing = bid_campaigns.filter(bc => bc.campaign_id === campaign_id)[0] || {};
                    process_integrations.push(this.applyIntegration(general_integration, listing));
                }
            }
        }
        if (process_integrations.length > 0) {
            Promise.all(process_integrations).then(results => {
                console.log(results);
            });
        }
    }

    async applyPrePingIntegration(listings) {
        return new Promise(async (resolve, reject) => {
            let pre_ping_integration_promise = [];
            let campaign_integrations = {};
            for (let integration of this.pre_ping_integrations) {
                campaign_integrations[integration.campaign_id] = integration;
            }
            for (let listing of listings) {
                pre_ping_integration_promise.push(this.prePingIntegration(campaign_integrations[listing.campaign_id], listing));
            }
            Promise.all(pre_ping_integration_promise).then(ping_listings => {
                ping_listings = ping_listings.filter(listing => listing);
                resolve(ping_listings)
            });
        });
    }

    async prePingIntegration(integration, listing) {
        if (integration) {
            let integration_response = await this.applyIntegration(integration, listing, true);
            if (integration_response) {
                let integration_success = this.integrationResponse(integration, integration_response);
                console.log(`pre-ping integration success?: ${integration_success}, Integration id: ${integration.lead_integration_id}`);
                if (integration_success) {
                    return listing;
                }
            }
            this.campaign_exclusion.push(listing.campaign_id); // Does not qualify any ad_group
            this.setDebugData(listing.campaign_id, 'exclusion', 'Does not qualify pre-ping integration');
            return null;
        }
        return listing;
    }

    async storeIntegrationLog(integration, response, success) {
        let failure_reason_id = null;
        let current_date_time = new Date();
        let req_body = response.config.data;
        let req_params = response.config.params;
        let req_headers = response.config.headers;
        let res_headers = response.headers;
        let res_body = response.data;
        let email = util.getParam(this.params, 'email');
        let phone = util.getParam(this.params, 'primary_phone');
        if (response.status !== 200) {
            res_body = res_body || response.message;
            response.status = typeof (response.status) == 'undefined' ? 500 : response.status;
        }
        if (!success) {
            failure_reason_id = await this.leadIntegrationFailureReason(integration, res_body);
        }

        let data = [integration.lead_integration_id, integration.posting_url, integration.req_method, req_body, req_headers, response.status, res_body, res_headers, success, false, integration.campaign_id, integration.account_id, null, email, phone, failure_reason_id, req_params, current_date_time, current_date_time];
        this.db.query('INSERT INTO lead_integration_req_logs (lead_integration_id, posting_url, req_method, req_body, req_headers, res_status, res_body, res_headers, success, is_test, campaign_id, account_id, lead_id, email, phone, lead_integration_failure_reason_id, req_params, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19) RETURNING *', data, (error, results) => {
            if (!error) {
                //console.log("Integration log stored successfully");
            } else {
                console.log(error.message);
            }
        });
    }

    async applyIntegration(integration, lead_listing, ping_integration = false, custom_data = {}) {
        let success = false;
        let req_method = (integration.req_method || 'get').toLowerCase();
        let payout = null;
        try {
            payout = lead_listing.payout || custom_data.pp_price || null;
        } catch (e) {
            console.log(`error inside applyIntegration: ${e}`);
            payout = lead_listing.payout || null;
        }
        custom_data.ad_group_id = lead_listing.ad_group_id;
        let response = await this.integrationRequest(integration, req_method, payout, custom_data);
        if (ping_integration) {
            return response;
        } else {
            if (response) {
                success = this.integrationResponse(integration, response);
            }
            console.log(`Integration ${integration.lead_integration_id} with campaign ${integration.campaign_id} is ${success ? 'success' : 'failed'}`)
            return success;
        }
    }

    integrationResponse(integration, response) {
        let success = false;
        if (response) {
            const success_regx = new RegExp(integration.res_success_regex, "i");
            if (response.data && success_regx.exec(this.responseToString(integration.res_type, response.data))) {
                success = true;
            }
            this.storeIntegrationLog(integration, response, success);
        }
        return success;
    }

    leadIntegrationFailureReason(integration, resp_body = "") {
        let response_body = this.responseToString(integration.res_type, resp_body);
        const query = `select *
                       from lead_integration_failure_reasons
                       where lead_integration_id = ${integration.lead_integration_id}
                         and discarded_at is null`;
        try {
            return this.db.query(query).then((results) => {
                let records = results.rows || [];
                let failure_reason_id = null;
                for (let record of records) {
                    if (response_body.match(record.failure_regex)) {
                        failure_reason_id = record.id;
                        break;
                    }
                }
                return failure_reason_id;
            }, err => {
                return null;
            });
        } catch (ex) {
            return null;
        }
    }

    parseBuyerDescription(description) {
        try {
            if (Array.isArray(description)) {
                let list = ''
                for (let desc of description) {
                    list += `<li>${desc}</li>`;
                }
                return `<ul>${list}</ul>`
            } else {
                return description;
            }
        } catch (ex) {
            console.log('Error on parse description: ', ex.message);
        }
    }

    responseToString(type, resp) {
        if (util.toLowerCase(type) === 'json') {
            return JSON.stringify(resp);
        } else {
            return resp.toString();
        }
    }

    async loadCarriers() {
        if (this.carriers.length > 0) {
            return this.carriers;
        } else {
            return this.db.query('select id as carrier_id, name from insurance_carriers where active = 1 and discarded_at is null').then((results) => {
                return results.rows || [];
            }, err => {
                return [];
            });
        }
    }

    mapCarrier(carrier_name) {
        for (let carrier of this.carriers) {
            let regx = new RegExp(carrier.name, 'i');
            if (regx.test(carrier_name)) {
                return carrier;
            }
        }
        return {carrier_id: '32', license_number: Math.random().toString(36).substring(2, 12)}
    }

    getCarrier(id) {
        for (let carrier of this.carriers) {
            if (carrier.carrier_id == id) {
                return carrier.name;
            }
        }
        return 'Independent Agent';
    }

    async getCarrierId(params) {
        // console.log('carriers: ', this.carriers);
        if (this.carriers.length <= 0) {
            await this.loadCarriers();
        }
        let map_carrier = this.mapCarrier(params.company_name);
        return map_carrier.carrier_id;
    }

    async storeNonRtbPingStat(product_type_id, columns, value_sets) {
        // if (!columns.includes('carrier_id')) {
        //     const company_name_at = columns.indexOf('company_name');
        //     if (company_name_at >= 0) {
        //         columns.push('carrier_id');
        //         const carrier_id = await this.getCarrierId(value_sets[0][company_name_at]);
        //         for (const values of value_sets) {
        //             values.push(carrier_id);
        //         }
        //     }
        // }

        this.initNonRtbPingStat(product_type_id);
        this.non_rtb_ping_stat.storeRtbPing(columns, value_sets);
    }

    async updateNonRtbPingStat(product_type_id, queries, params) {
        this.initNonRtbPingStat(product_type_id);
        // if (params.company_name) {
        //     params.carrier_id = await this.getCarrierId(params.company_name);
        // }
        this.non_rtb_ping_stat.updateRtbPing(queries, params);
    }

    initNonRtbPingStat(product_type_id) {
        if (!this.non_rtb_ping_stat) {
            this.non_rtb_ping_stat = new NonRtbPingStat(this.db, product_type_id);
        }
    }
}
