const LeadCloud = require('../partners/lead_cloud');
const MapperBase = require("../../lib/mapper/elephant_insurance/base");
const convert = require("xml-js");

module.exports = class ElephantInsurance extends LeadCloud {
    partnerUrl() {
        if (process.env.PRODUCTION === '1') {
            return 'https://post.leadcloud.us/auto/028bfaaf-49a2-4a52-bab5-1019b00cf1ba';
        } else {
            return 'https://test.leadcloud.us/auto/0f4d886a-3ce6-46d5-accf-642235295498';
        }
    }

    queryParams(params, lead_type) {
        let data_mapping = (new MapperBase(lead_type)).dataMapping(params);
        return convert.js2xml(data_mapping, {compact: true, ignoreComment: true, spaces: 4});
    }
}
