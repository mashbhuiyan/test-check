require('../partner');
const SfPrefill = require('./sf_prefill');
const TwentyFirstCentury = require('./twenty_first_century');
const BranchInsurance = require('./branch_insurance');
const DairylandDataPass = require('./dairyland_data_pass');
const NsureDataPass = require('./nsure_data_pass');
const DirectAuto = require('./direct_auto');
const SafeAuto = require('./safe_auto');
const TogglePrefill = require('./toggle_prefill');
const ElephantInsurance = require('./elephant_insurance');
const BreathEasy = require('./breath_easy');
const ViuPrefill = require('./viu_prefill');
const Checkoutgoal = require('./checkoutgoal');
const FastInsuranceRates = require('./fast_insurance_rates');
const CompareHealthPlansNet = require('./compare_health_plans_net');
const SfKembper = require('./sf_kemper');
const UnitedStatesInsurance = require('./united_states_insurance');
const MedicareRater = require('./medicare_rater');
const VerifiedCarInsurance = require('./verified_car_insurance');

const mongoose = require('mongoose');
const Partner = mongoose.model('Partner');

module.exports = class Partners {
    partner = {};

    constructor(brand_conf, id) {
        this.brand_conf = brand_conf;
        this.db = brand_conf.db;
        this.partner_id = id;
    }

    async integrationPartner() {
        return new Promise((resolve, reject) => {
            Partner.findById(this.partner_id, (err, partner) => {
                if (err || partner == null) {
                    resolve(false, "");
                } else {
                    this.partner = partner
                    resolve(this.getPartner(partner));
                }
            });
        })
    }

    getPartner(partner) {
        switch (partner.module) {
            case 'SfPrefill': {
                return (new SfPrefill(partner));
            }
            case 'TwentyFirstCentury': {
                return (new TwentyFirstCentury(partner));
            }
            case 'BranchInsurance': {
                return (new BranchInsurance(partner));
            }
            case 'DairylandDataPass': {
                return (new DairylandDataPass(partner));
            }
            case 'NsureDataPass': {
                return (new NsureDataPass(partner));
            }
            case 'DirectAuto': {
                return (new DirectAuto(partner));
            }
            case 'SafeAuto': {
                return (new SafeAuto(partner));
            }
            case 'TogglePrefill': {
                return (new TogglePrefill(partner));
            }
            case 'ElephantInsurance': {
                return (new ElephantInsurance(partner));
            }
            case 'BreathEasy': {
                return (new BreathEasy(partner));
            }
            case 'ViuPrefill': {
                return (new ViuPrefill(partner));
            }
            case 'Checkoutgoal': {
                return (new Checkoutgoal(partner));
            }
            case 'FastInsuranceRates': {
                return (new FastInsuranceRates(partner));
            }
            case 'CompareHealthPlansNet': {
                return (new CompareHealthPlansNet(partner));
            }
            case 'SfKembper': {
                return (new SfKembper(partner));
            }
            case 'UnitedStatesInsurance': {
                return (new UnitedStatesInsurance(partner));
            }
            case 'MedicareRater': {
                return (new MedicareRater(partner));
            }
            case 'VerifiedCarInsurance': {
                return (new VerifiedCarInsurance(partner));
            }
            default: {
                return false;
            }
        }
    }

    async storeLogs(debug) {
        let current_date_time = new Date();
        let data = [this.partner.name, debug.click_integration_id, debug.request, debug.response, debug.success, current_date_time, current_date_time];
        this.db.query('INSERT INTO click_integration_logs (partner_name, click_integration_id, request, response, success, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *', data, (error, results) => {
            if (error) {
                console.log("Store Click Integration Error: ", error.message);
            } else {
                // console.log("Store Click Integration Success!");
            }
        });
    }
}
