const Auto = require('../sf_kemper/auto');
const Home = require('../sf_kemper/home');
const Health = require('../sf_kemper/health');
const Life = require('../sf_kemper/life');
const Medicare = require('../sf_kemper/medicare');
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
            case 4: // Renters
                return {}
            case 3: // Health
                return (new Health(params)).createHealthRequest()
            case 2: // Life
                return (new Life(params)).createLifeRequest()
            case 7: // Medicare
                return (new Medicare(params)).createMedicareRequest()
            case 5: // Commercial
                return {}
            default:
                return {}
        }
    }
}
