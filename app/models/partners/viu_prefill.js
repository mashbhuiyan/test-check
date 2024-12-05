const PartnerBase = require('../partners/partner_base');
const MapperBase = require('../../lib/mapper/viu_prefill/base');
const axios = require('axios');
const flatten = require('flat');

module.exports = class ViuPrefill extends PartnerBase {
    partnerUrl() {
        if (process.env.PRODUCTION === '1') {
            return 'https://partner-api.viubyhub.com/api/v1/lead/';
        } else {
            return 'https://uat.partner-api.viubyhub.com/api/v1/lead/';
        }
    }

    reqMethod() {
        return 'post';
    }

    queryParams(params, lead_type) {
        return (new MapperBase(lead_type)).dataMapping(params);
    }

    getHeaders() {
        return {'Content-Type': 'application/json', testing: 'viubyhub2022'}
    }

    async pingRequest(partner, query_params) {
        const timeout = partner.attributes.timeout || partner.getTimeout();
        return axios.post(this.partnerUrl(), query_params, {
            headers: await this.getHeaders(),
            timeout: timeout,
            auth: {
                username: 'API-Key',
                password: process.env.PRODUCTION === '1' ? 'B0vr90EzzJt4Vz4b6SchmopDEvtqm-Vg_Tt2MIC_wj4' : 'FA5a5I_cozhPmNvDrgn60X3_QiADJFWHRBPkEVIeIHQ'
            }
        });
    }

    getResponse(resp) {
        const resp_data = resp.data;
        if (this.isSuccess(resp)) {
            return {
                success: true,
                url: resp_data.referralUrl,
                message: '',
                premium: '',
                term: ''
            }
        }
        const flat_data = flatten(resp_data);
        return {
            success: false,
            url: '',
            message: `${Object.keys(flat_data)[0]}: ${flat_data[Object.keys(flat_data)[0]]}`,
            premium: '',
            term: ''
        }
    }

    isSuccess(response) {
        return 'referralUrl' in response.data;
    }
}
