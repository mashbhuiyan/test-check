const Auto = require('../medicare_rater/auto');
const Home = require('../medicare_rater/home');
const Health = require('../medicare_rater/health');
const Life = require('../medicare_rater/life');
const Medicare = require('../medicare_rater/medicare');
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
