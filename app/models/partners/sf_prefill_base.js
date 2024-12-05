const PartnerBase = require('../partners/partner_base');

module.exports = class SfPrefillBase extends PartnerBase {
    partnerUrl() {
        return 'https://forms.smartfinancial.com/forms/pre_fill'
    }

    reqMethod() {
        return 'post';
    }

    getHeaders() {
        return {Authorization: `Bearer eyfdb8b9bsbf9bbfhbnrjgfjrjffgjmdbuy9.eyJpcjdvnyjfhdhdhmfjFoljkjlfKHRWGwrgwRWGWRGwrgWRgRGHEWdgfbmyktKTyfgj6bn`}
    }

    getResponse(resp) {
        const resp_data = resp.data;
        return {
            success: resp_data.status === 'Success',
            url: resp_data.url,
            message: resp_data.message,
            premium: '',
            term: ''
        }
    }

    isSuccess(response) {
        return response.data.status === 'Success';
    }
}
