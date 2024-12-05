const Base = require('../base');
const Common = require('./common');

module.exports = class Home extends Base {
    constructor(params) {
        super(params);
        this.params = params;
    }

    createHomeRequest() {
        let data = {
            campaign_id: this.getParam('campaign_id') || 6,
            click_id: this.getParam('click_id') || '1eewfe',
            lead: {
                traffic_tier: this.getParam('traffic_tier'),
                submission_url: this.getParam('submission_url') || 'https://smartfinancial.com',
                marital_status: Common.mapMaritalStatus(this.getParam('marital_status')),
                military_affiliation: (this.getParam('military_affiliation') || 'No'),
                home_info: this.homeInfo(),
                customer_profile: this.customerProfile(),
                contact: this.contactInfo(),
                currently_insured: this.getParam('currently_insured')
            }
        }
        if (data.lead.currently_insured === 'Yes') {
            data.lead['continuous_insurance'] = this.mapCoverageYears();
            data.lead['current_coverage'] = { carrier: this.getParam('carrier') };
        }

        return data;
    }

    customerProfile() {
        return {
            date_of_birth: this.getParam('date_of_birth'),
            gender: Common.mapGender(this.getParam('gender'))
        }
    }

    homeInfo() {
        return {
            property_type: this.mapPropertyType(this.getParam('property_type')),
            occupancy: this.mapOccupancy(this.getParam('occupancy')),
            property_age: (this.getParam('property_age') || '10 Years'),
            square_footage: ((this.getParam('square_footage') || '1,000 to 2,000').toString()),
            num_stories: (this.mapNumStories(this.getParam('num_stories')) || '2'),
            year_built: this.getParam('year_built') || 1,
            num_bedrooms: this.getParam('num_bedrooms') || 1,
            num_bathrooms: this.getParam('num_bathrooms') || 1
        }
    }

    mapNumStories(stories) {
        stories = parseInt(stories || '1');
        return stories >= 4 ? '4+' : stories.toString();
    }

    mapPropertyType(type) {
        switch (type) {
            case 'Single Family':
                return 'Single Family Home';
            case 'Duplex':
                return 'Duplex';
            case 'Multi Family':
                return 'Multi Family Home';
            case 'Townhome':
                return 'Townhome';
            case 'Condominium':
                return 'Condominium';
            case 'Mobile Home':
                return 'Mobile Home';
            default:
                return 'Single Family Home';
        }
    }

    mapOccupancy(type) {
        return type === 'Vacation' ? 'Vacation Home' : (type || 'Primary Residence');
    }

    contactInfo() {
        return {
            first_name: this.getParam('first_name'),
            last_name: this.getParam('last_name'),
            address: this.getParam('address'),
            city: this.getParam('city'),
            state: this.getParam('state'),
            zip: this.getParam('zip'),
            email: this.getParam('email'),
            primary_phone: this.getParam('primary_phone')
        }
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
