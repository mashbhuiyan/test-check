const Base = require('../base');
const Common = require('./common');

module.exports = class Auto extends Base {
    constructor(params) {
        super(params);
        this.params = params;
    }

    createAutoRequest() {
        let data = {
            campaign_id: this.getParam('campaign_id') || 5,
            click_id: this.getParam('click_id') || '1eewfe',
            lead: {
                traffic_tier: this.getParam('traffic_tier'),
                submission_url: this.getParam('submission_url') || 'https://smartfinancial.com',
                own_home: this.mapHomeOwnership(this.getParam('own')),
                bundle_home: 'No',
                military_affiliation: (this.getParam('military_affiliation') || 'No'),
                contact: this.contactInfo(),
                vehicles: this.vehicles(),
                drivers: this.drivers(),
                currently_insured: this.getParam('currently_insured')
            }
        }
        if (data.lead.currently_insured === 'Yes') {
            data.lead['continuous_insurance'] = this.mapCoverageYears();
            data.lead['current_coverage'] = { carrier: this.getParam('carrier') };
        }

        return data;
    }

    mapHomeOwnership(status) {
        if (status === 'Own' || status === 'own') {
            return 'Yes';
        } else {
            return 'No';
        }
    }

    contactInfo() {
        return {
            address: this.getParam('address'),
            city: this.getParam('city'),
            state: this.getParam('state'),
            zip: this.getParam('zip'),
            email: this.getParam('email'),
            primary_phone: this.getParam('primary_phone')
        }
    }

    drivers() {
        let drivers = this.params.drivers || []
        let mapped_drivers = [];
        for (let driver of drivers) {
            mapped_drivers.push({
                first_name: driver.first_name,
                last_name: driver.last_name,
                gender: Common.mapGender(driver.gender),
                date_of_birth: driver.date_of_birth,
                marital_status: driver.marital_status,
                at_fault_accidents: this.getAccidentAtFault(driver),
                dui: "No"
            });
        }
        return mapped_drivers;
    }

    getAccidentAtFault(driver) {
        let accidents = driver.accidents || [];
        for (let accident of accidents) {
            if (accident.incident_at_fault) {
                return 'Yes';
            }
        }
        return 'No';
    }

    vehicles() {
        let vehicles = this.params.vehicles || [];
        let mapped_vehicles = [];
        for (let vehicle of vehicles) {
            mapped_vehicles.push({
                year: vehicle.year,
                make: vehicle.make,
                model: vehicle.model
            });
        }
        return mapped_vehicles;
    }

    mapCoverageYears() {
        const coverage_years = parseInt(this.getParam('coverage_years') || 0);
        if (coverage_years > 5) {
            return '5+ years'
        } else if (coverage_years >= 3) {
            return '3-5 years'
        } else if (coverage_years === 2) {
            return '2-3 years'
        } else if (coverage_years === 1) {
            return '1-2 years'
        } else {
            return 'Less than a year';
        }
    }
}
