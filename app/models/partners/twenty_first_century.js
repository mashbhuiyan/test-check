const LeadCloud = require('../partners/lead_cloud');
const MapperBase = require("../../lib/mapper/twenty_first_century/base");
const convert = require("xml-js");

module.exports = class TwentyFirstCentury extends LeadCloud {
    partnerUrl() {
        if (process.env.PRODUCTION === '1') {
            return 'https://post.leadcloud.us/auto/9c1639b0-cd4f-4ad6-a406-990df648547a';
        } else {
            return 'https://test.leadcloud.us/auto/F881B36C-DA99-42DD-B28B-A21A4EA916AA';
        }
    }

    getHeaders() {
        return {Authorization: `Bearer eyfdb8b9bsbf9bbfhbnrjgfjrjffgjmdbuy9.eyJpcjdvnyjfhdhdhmfjFoljkjlfKHRWGwrgwRWGWRGwrgWRgRGHEWdgfbmyktKTyfgj6bn`}
    }

    queryParams(params, lead_type) {
        let data_mapping = (new MapperBase(lead_type)).dataMapping(params);
        return convert.js2xml(data_mapping, {compact: true, ignoreComment: true, spaces: 4});
    }
}
