const Base = require('./base');
const util = require('./utils');
module.exports = class CallIntegration extends Base {

    async getPingIntegrationListings(integration, listing) {
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
                    integration_response = this.parsePingIntegrationResponse(integration_response.data, ping_config)
                    let buyers = integration_response[ping_config.buyers] || [];
                    if (!Array.isArray(buyers)) {
                        buyers = [buyers];
                    }
                    listing.pp_ping_id = integration_response[ping_config.ping_id];
                    if (buyers.length > 0) {
                        for (let buyer of buyers) {
                            ping_listings.push(this.generatePingListing(listing, buyer, ping_config))
                        }
                    } else {
                        ping_listings.push(this.generatePingListing(listing, integration_response, ping_config));
                    }
                    return ping_listings;
                } else {
                    return [];
                }
            } else {
                return [];
            }
        }
        return [listing];
    }

    generatePingListing(campaign_listing, buyer, ping_config, lead_type = 'mixed') {
        let listing = Object.assign({}, campaign_listing);
        let min_bid = ping_config.min_bid || 1;
        listing.pp_bid_id = buyer[ping_config.bid_id];
        listing.price = parseFloat(buyer[ping_config.bid] || '0');
        listing.est_payout = parseFloat(buyer[ping_config.bid] || '0');
        listing.company_name = buyer[ping_config.buyer_name] || 'Independent Agent';
        listing.ping_post = true;
        listing.listing_type = ping_config.bid_types === 'mixed' ? (buyer[ping_config.leg_type] || campaign_listing.listing_type) : ping_config.bid_types;
        listing.listing_type = (listing.listing_type || '').toLowerCase();
        listing.exclusive = listing.listing_type === 'exclusive';
        listing.id = (Math.random() * 1000000).toFixed(0);
        if (buyer[ping_config.transfer_number]) {
            listing.transfer_number = buyer[ping_config.transfer_number];
        }
        if (buyer[ping_config.tracking_number]) {
            listing.transfer_number = buyer[ping_config.tracking_number];
        }
        if (listing.est_payout < min_bid) {
            console.log("Ping listing rejected for lower bid", listing.est_payout);
            listing.est_payout = 0;
        }
        if (listing.company_name) {
            let map_carrier = this.mapCarrier(listing.company_name);
            listing.carrier_id = map_carrier.carrier_id;
            if (map_carrier.license_number) {
                listing.license_number = map_carrier.license_number;
            }
        }
        return listing;
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
            let post_data = {
                ping_id: Object.keys(pp_ping_data)[0],
                bid_ids: bid_ids
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

    postIntegrationBuyers(buyers, ping_config, integration, listings, full_response = null) {
        let listing_buyers = [];
        let listing = {payout: 0};
        for (let buyer of buyers) {
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

    async getReqHeaders(integration, req_method) {
        let headers = {
            "Accept": integration.req_content_type,
            "Content-Type": integration.req_content_type
        }
        if (req_method === 'get') {
            return headers;
        } else {
            return this.db.query(`select *
                             from lead_integration_req_headers
                             where lead_integration_id = ${integration.lead_integration_id}
                               and discarded_at IS NULL`).then(results => {
                for (let header of results.rows) {
                    if (header.key && header.value) {
                        headers[header.key] = header.value;
                    }
                }
                return headers;

            }, err => {
                console.log(err);
                return headers;
            });
        }
    }

    async storeIntegrationLog(integration, response, success) {
        let current_date_time = new Date();
        let req_body = response.config.data;
        let req_headers = response.config.headers;
        let res_headers = response.headers;
        let res_body = response.data;
        let email = util.getParam(this.params, 'email');
        let phone = util.getParam(this.params, 'primary_phone');
        if (response.status !== 200) {
            res_body = res_body || response.message;
            response.status = typeof (response.status) == 'undefined' ? 500 : response.status
        }

        let data = [integration.lead_integration_id, integration.posting_url, integration.req_method, req_body, req_headers, response.status, res_body, res_headers, success, false, integration.campaign_id, integration.account_id, null, email, phone, current_date_time, current_date_time];
        this.db.query('INSERT INTO lead_integration_req_logs (lead_integration_id, posting_url, req_method, req_body, req_headers, res_status, res_body, res_headers, success, is_test, campaign_id, account_id, lead_id, email, phone, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17) RETURNING *', data, (error, results) => {
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
        //headers['SelfIntegration'] = true; // TODO: remove when live
        let response = await this.integrationRequest(integration, req_method, lead_listing.payout, custom_data);
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

    async loadCarriers() {
        return this.db.query('select id as carrier_id, name from insurance_carriers where active = 1 and discarded_at is null').then((results) => {
            return results.rows || [];
        }, err => {
            return [];
        });
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
}
