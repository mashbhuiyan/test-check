const PartnerBase = require('../partners/partner_base');
const MapperBase = require('../../lib/mapper/dairyland_data_pass/base');

module.exports = class DairylandDataPass extends PartnerBase {
    partnerUrl() {
        if (process.env.PRODUCTION === '1') {
            return 'https://pl-rtrsvc.sentry.com/realtimerater-ws/api/v1/quotes/lead-pass';
        }
        return 'https://pl-qual-rtrsvc.sentry.com/realtimerater-ws/api/v1/quotes/lead-pass'
    }

    reqMethod() {
        return 'post';
    }

    queryParams(params, lead_type) {
        return (new MapperBase(lead_type)).dataMapping(params);
    }

    getHeaders() {
        return {}
    }

    getResponse(resp) {
        const resp_data = resp.data;
        let success, message;

        if (this.isSuccess(resp)) {
            success = true
            message = resp_data.InfoMessages.join(', ')
        } else {
            success = false
            message = resp_data.ErrorMessages.join(', ')
        }
        return {
            success: success,
            url: resp_data.RetrieveQuoteUrl,
            message: message,
            premium: '',
            term: ''
        }
    }

    isSuccess(response) {
        return !response.data.ErrorMessages.length > 0;
    }
}
