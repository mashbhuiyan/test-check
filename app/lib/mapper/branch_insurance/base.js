const Auto = require('../branch_insurance/auto');
const Home = require("../branch_insurance/home");

module.exports = class MapperBase {
    constructor(lead_type) {
        this.lead_type_id = lead_type;
    }

    dataMapping(params) {
        switch (this.lead_type_id) {
            case 6: // Auto
                return (new Auto(params)).createAutoRequest()
            case 1: // Home
                return (new Home(params)).createHomeRequest()
            default:
                return {}
        }
    }
}
