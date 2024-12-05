const LeadCloud = require('../partners/lead_cloud');
const MapperBase = require("../../lib/mapper/toggle_prefill/base");
const convert = require("xml-js");

module.exports = class TogglePrefill extends LeadCloud {
    partnerUrl() {
        if (process.env.PRODUCTION === '1') {
            return 'https://post.leadcloud.us/auto/6cab940b-0e68-4f63-a0b4-2703b69398f1';
        } else {
            return 'https://test.leadcloud.us/auto/72d61ebe-e85c-4f9d-ad8f-f08d5f8428a8';
        }
    }

    queryParams(params, lead_type) {
        let data_mapping = (new MapperBase(lead_type)).dataMapping(params);
        return convert.js2xml(data_mapping, {compact: true, ignoreComment: true, spaces: 4});
    }
}
