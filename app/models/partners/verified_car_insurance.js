const SfPrefillBase = require('../partners/sf_prefill_base');
const MapperBase = require('../../lib/mapper/verified_car_insurance/base');

module.exports = class VerifiedCarInsurance extends SfPrefillBase {
    queryParams(params, lead_type) {
        return (new MapperBase(lead_type)).dataMapping(params);
    }
}
