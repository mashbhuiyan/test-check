const PartnerBase = require('../partners/partner_base');
const MapperBase = require('../../lib/mapper/safe_auto/base');
const convert = require('xml-js');
const AutoLeadData = require("../../data/auto.json");

module.exports = class SafeAuto extends PartnerBase {
    partnerUrl() {
        if (process.env.PRODUCTION === '1') {
            return 'https://post.leadcloud.us/auto/8c7ee8d0-bfcd-4aeb-8933-df8bce4e24f9';
        }
        return 'https://test.leadcloud.us/auto/9d028ae6-2cd7-492e-917e-69b1e6494664';
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
        let success = false;
        let url = '';
        let resp_data = resp.data;
        resp_data = convert.xml2js(resp_data, {compact: true, ignoreComment: true});

        if (resp_data && resp_data.LeadCloud) {
            if (resp_data.LeadCloud.InsuranceSvcRs) {
                if (resp_data.LeadCloud.InsuranceSvcRs.PersAutoPolicyQuoteInqRs.MsgStatus.MsgStatusCd._text === 'Success') {
                    success = true;
                    url = resp_data.LeadCloud.InsuranceSvcRs.PersAutoPolicyQuoteInqRs.PaymentPlans.ConsumerURL._cdata;
                }
            }
        }
        return {
            success: success,
            url: url,
            message: success ? 'Success' : 'Failed',
            premium: this.getPremium(resp_data.LeadCloud),
            term: this.getTerms(resp_data.LeadCloud)
        }
    }

    getPremium(click_rs) {
        try {
            if (click_rs && click_rs.InsuranceSvcRs) {
                if (click_rs.InsuranceSvcRs.PersAutoPolicyQuoteInqRs) {
                    let payment_plans = click_rs.InsuranceSvcRs.PersAutoPolicyQuoteInqRs.PaymentPlans.PaymentPlan || [];
                    if (payment_plans.length > 0) {
                        let payment_plan = payment_plans[0];
                        return payment_plan.PremiumAmt._text;
                    }
                }
            }
        } catch (ex) {
        }
        return '';
    }

    getTerms(click_rs) {
        try {
            if (click_rs && click_rs.InsuranceSvcRs) {
                if (click_rs.InsuranceSvcRs.PersAutoPolicyQuoteInqRs) {
                    let payment_plans = click_rs.InsuranceSvcRs.PersAutoPolicyQuoteInqRs.PaymentPlans.PaymentPlan || [];
                    if (payment_plans.length > 0) {
                        let payment_plan = payment_plans[0];
                        return payment_plan.PolicyTerm._text;
                    }
                }
            }
        } catch (ex) {
        }
        return '';
    }

    isSuccess(response) {
        const resp_data = convert.xml2js(response.data, {compact: true, ignoreComment: true});
        if (resp_data && resp_data.LeadCloud) {
            if (resp_data.LeadCloud.InsuranceSvcRs) {
                return resp_data.LeadCloud.InsuranceSvcRs.PersAutoPolicyQuoteInqRs.MsgStatus.MsgStatusCd._text === 'Success';
            }
        }
        return false;
    }

    getSampleLead(leadType) {
        let leadData = AutoLeadData.lead;
        leadData.contact.zip = '43204';
        leadData.contact.state = 'OH';
        leadData.contact.city = 'Columbus';
        return leadData;
    }
}
