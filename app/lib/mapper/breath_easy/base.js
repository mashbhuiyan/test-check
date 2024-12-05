const Auto = require('../breath_easy/auto');
module.exports = class MapperBase {
    constructor(lead_type) {
        this.lead_type_id = lead_type;
    }

    dataMapping(params) {
        switch (this.lead_type_id) {
            case 6: // Auto
                return (new Auto(params)).createAutoRequest();
            case 1: // Home
                return {};
            case 4: // Renters
                return {};
            case 3: // Health
                return {};
            case 2: // Life
                return {};
            case 7: // Medicare
                return {};
            case 5: // Commercial
                return {};
            default:
                return {};
        }
    }
}
