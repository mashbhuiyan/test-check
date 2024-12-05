const SfPrefillBase = require('../partners/sf_prefill_base');
const MapperBase = require('../../lib/mapper/compare_health_plans_net/base');

module.exports = class CompareHealthPlansNet extends SfPrefillBase {
    queryParams(params, lead_type) {
        return (new MapperBase(lead_type)).dataMapping(params);
    }
}
