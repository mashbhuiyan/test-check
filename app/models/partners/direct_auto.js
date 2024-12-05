const PartnerBase = require('../partners/partner_base');
const MapperBase = require('../../lib/mapper/twenty_first_century/base');
const convert = require('xml-js');

module.exports = class DirectAuto extends PartnerBase {
    partnerUrl() {
        if (process.env.PRODUCTION === '1') {
            return 'https://post.leadcloud.us/auto/a86e791f-079f-4d81-b434-394906f5e18d';
        } else {
            return 'https://test.leadcloud.us/auto/55c2df4e-ccf8-4833-b398-1e4e8a965595';
        }
    }

    reqMethod() {
        return 'post';
    }

    queryParams(params, lead_type) {
        let data_mapping = (new MapperBase(lead_type)).dataMapping(params);
        return convert.js2xml(data_mapping, {compact: true, ignoreComment: true, spaces: 4});
    }

    getHeaders() {
        return {Authorization: `Bearer eyfdb8b9bsbf9bbfhbnrjgfjrjffgjmdbuy9.eyJpcjdvnyjfhdhdhmfjFoljkjlfKHRWGwrgwRWGWRGwrgWRgRGHEWdgfbmyktKTyfgj6bn`}
    }

    getResponse(resp) {
        let resp_data = resp.data;
        resp_data = convert.xml2js(resp_data, {compact: true, ignoreComment: true});
        let click_rs = resp_data.LeadCloud.InsuranceSvcRs.PersAutoPolicyQuoteInqRs || {
            MsgStatus: {
                MsgStatusCd: {},
                MsgStatusDesc: {}
            }
        };
        return {
            success: click_rs.MsgStatus.MsgStatusCd._text === 'Success',
            url: click_rs.PaymentPlans && click_rs.PaymentPlans.ConsumerURL ? click_rs.PaymentPlans.ConsumerURL._cdata : '',
            message: click_rs.MsgStatus.MsgStatusDesc._text,
            premium: this.getPremium(click_rs.PaymentPlans),
            term: this.getTerms(click_rs.PaymentPlans)
        }
    }

    isSuccess(response) {
        const resp_data = convert.xml2js(response.data, {compact: true, ignoreComment: true});
        return resp_data.LeadCloud.InsuranceSvcRs && resp_data.LeadCloud.InsuranceSvcRs.PersAutoPolicyQuoteInqRs.MsgStatus.MsgStatusCd._text === 'Success';
    }

    getPremium(click_rs) {
        try {
            if (click_rs && click_rs.PolicySummaryInfo) {
                if (click_rs.PolicySummaryInfo.FullTermAmt) {
                    return click_rs.PolicySummaryInfo.FullTermAmt.Amt._text;
                }
            }
        } catch (ex) {
        }
        return '';
    }

    getTerms(click_rs) {
        try {
            if (click_rs && click_rs.PaymentPlan) {
                let payment_plan = click_rs.PaymentPlan[0];
                if (payment_plan && payment_plan.PolicyTerm) {
                    return payment_plan.PolicyTerm._text;
                }
            }
        } catch (ex) {
        }
        return '';
    }
}
