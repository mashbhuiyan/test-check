const Base = require('./base');
const util = require('./utils');
module.exports = class ClickIntegration extends Base {

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
}
