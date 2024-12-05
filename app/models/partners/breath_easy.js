const LeadCloud = require('../partners/lead_cloud');
const MapperBase = require("../../lib/mapper/breath_easy/base");
const convert = require("xml-js");

module.exports = class BreathEasy extends LeadCloud {
    partnerUrl() {
        if (process.env.PRODUCTION === '1') {
            return 'https://post.leadcloud.us/auto/75796b91-86dc-45c3-99ca-c707ac2e42c8';
        } else {
            return 'https://test.leadcloud.us/auto/8f29889b-7746-4144-8a6d-943ff551616c';
        }
    }

    queryParams(params, lead_type) {
        let data_mapping = (new MapperBase(lead_type)).dataMapping(params);
        return convert.js2xml(data_mapping, {compact: true, ignoreComment: true, spaces: 4});
    }
}
