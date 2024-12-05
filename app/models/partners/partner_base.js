const axios = require('axios');
const querystring = require('querystring');
const AutoLeadData = require("../../data/auto.json");
const HomeLeadData = require("../../data/home.json");
const HealthLeadData = require("../../data/health.json");
const LifeLeadData = require("../../data/life.json");
const MedicareLeadData = require("../../data/medicare.json");
module.exports = class PartnerBase {
    constructor(attr) {
        this.attributes = attr;
    }

    requestMethod() {
        return 'get'
    }

    async pingRequest(partner, query_params) {
        const timeout = partner.attributes.timeout || partner.getTimeout();
        if (partner.reqMethod() === 'get' || partner.reqMethod() === 'GET') {
            return axios.get(partner.partnerUrl() + this.urlParams(query_params), {
                headers: await partner.getHeaders(),
                timeout: timeout
            })
        } else {
            return axios.post(partner.partnerUrl(), query_params, {
                headers: await partner.getHeaders(),
                timeout: timeout
            });
        }
    }

    urlParams(query_params) {
        return querystring.escape(JSON.stringify(query_params));
    }

    getTimeout() {
        return 7000; // `timeout` specifies the number of milliseconds before the request times out.
    }

    getSampleLead(leadType) {
        switch (leadType) {
            case 6:
                return AutoLeadData.lead;
            case 1:
                return HomeLeadData.lead;
            case 3:
                return HealthLeadData.lead;
            case 2:
                return LifeLeadData.lead;
            case 7:
                return MedicareLeadData.lead;
            default:
                return AutoLeadData.lead;
        }
    }
}
