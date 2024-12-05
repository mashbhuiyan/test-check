const PartnerBase = require('../partners/partner_base');
const MapperBase = require('../../lib/mapper/checkoutgoal/base');

module.exports = class Checkoutgoal extends PartnerBase {
    partnerUrl() {
        return 'https://api.portal.checkoutgoal.com/api/v1/prefill_queries';
    }

    reqMethod() {
        return 'post';
    }

    queryParams(params, lead_type) {
        return (new MapperBase(lead_type)).dataMapping(params);
    }

    getHeaders() {
        return { 'Content-Type': 'application/json' }
    }

    getResponse(resp) {
        const resp_data = resp.data;
        return {
            success: this.isSuccess(resp),
            url: resp_data?.data?.redirect_url || '',
            message: '',
            premium: '',
            term: ''
        }
    }

    isSuccess(response) {
        return typeof(response.data?.data?.redirect_url) !== 'undefined';
    }
}
