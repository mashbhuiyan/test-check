const PartnerBase = require('../partners/partner_base');
const MapperBase = require('../../lib/mapper/nsure_data_pass/base');

module.exports = class NsureDataPass extends PartnerBase {
    partnerUrl() {
        return 'https://api.nsure.com/api/external/click/smartfinancial/home'
    }

    reqMethod() {
        return 'post';
    }

    queryParams(params, lead_type) {
        return (new MapperBase(lead_type)).dataMapping(params);
    }

    getHeaders() {
        return { "X-Nsure-Signature": "b58cdb2bbaab304229a321e8e76dec332e8076d8125d5cfezee4f8ea7d2dad36!"}
    }

    getResponse(resp) {
        const resp_data = resp.data;

        return {
            success: resp_data.statusCode === 200,
            url: resp_data.result,
            message: resp_data.message,
            premium: '',
            term: ''
        }
    }

    isSuccess(response) {
        return response.data.statusCode === 200;
    }
}
