const SfPrefillBase = require('../partners/sf_prefill_base');
const MapperBase = require('../../lib/mapper/fast_insurance_rates/base');

module.exports = class FastInsuranceRates extends SfPrefillBase {
    queryParams(params, lead_type) {
        return (new MapperBase(lead_type)).dataMapping(params);
    }
}
