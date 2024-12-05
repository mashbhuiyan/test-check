const PartnerBase = require('../partners/partner_base');
const convert = require('xml-js');

module.exports = class LeadCloud extends PartnerBase {
    partnerUrl() {
        return null;
    }

    reqMethod() {
        return 'post';
    }

    queryParams(params, lead_type) {
        return null;
    }

    getHeaders() {
        return {};
    }

    getResponse(resp) {
        let resp_data = resp.data;
        resp_data = convert.xml2js(resp_data, {compact: true, ignoreComment: true});
        let click_rs = resp_data.LeadCloud.LCSuperClickRs || {MsgStatus: {MsgStatusCd: {}, MsgStatusDesc: {}}};
        return {
            success: click_rs.MsgStatus.MsgStatusCd._text === 'Success',
            url: click_rs.PrimaryURL ? click_rs.PrimaryURL._cdata : '',
            message: click_rs.MsgStatus.MsgStatusDesc._text,
            premium: '',
            term: ''
        }
    }

    isSuccess(response) {
        const resp_data = convert.xml2js(response.data, {compact: true, ignoreComment: true});
        return resp_data.LeadCloud.LCSuperClickRs && resp_data.LeadCloud.LCSuperClickRs.MsgStatus.MsgStatusCd._text === 'Success';
    }
}
