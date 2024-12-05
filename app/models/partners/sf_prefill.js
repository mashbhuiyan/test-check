const SfPrefillBase = require('../partners/sf_prefill_base');
const MapperBase = require('../../lib/mapper/sf_prefill/base');

module.exports = class SfPrefill extends SfPrefillBase {
    queryParams(params, lead_type) {
        return (new MapperBase(lead_type)).dataMapping(params);
    }
}
