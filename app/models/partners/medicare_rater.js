const SfPrefillBase = require('../partners/sf_prefill_base');
const MapperBase = require('../../lib/mapper/medicare_rater/base');

module.exports = class MedicareRater extends SfPrefillBase {
    queryParams(params, lead_type) {
        return (new MapperBase(lead_type)).dataMapping(params);
    }
}
