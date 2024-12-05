const Home = require("../nsure_data_pass/home");

module.exports = class MapperBase {
    constructor(lead_type) {
        this.lead_type_id = lead_type;
    }

    dataMapping(params) {
        switch (this.lead_type_id) {
            case 1: // Home
                return (new Home(params)).createHomeRequest()
            default:
                return {}
        }
    }
}
