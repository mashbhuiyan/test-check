const Base = require('../base');
const Common = require('./common');
module.exports = class Commercial extends Base {
    constructor(params) {
        super(params);
        this.params = params;
    }

    createCommercialRequest() {
        return {
            campaign_id: this.getParam('campaign_id') || 9,
            click_id: this.getParam('click_id') || '1eewfe',
            lead: {
                traffic_tier: this.getParam('traffic_tier'),
                submission_url: this.getParam('submission_url') || 'https://smartfinancial.com',
                requested_coverage: this.coverageTypes(),
                general_liability_coverage: this.getParam('liability_coverage'),
                business_info: this.businessInfo(),
                contact: this.contactInfo()
            }
        }
    }

    coverageTypes() {
        let coverage_types = this.params.business_info.commercial_coverage_types || []
        let mapped_types = [];
        for (let covs of coverage_types) {
            for (let cov_type of Object.keys(covs)) {
                if (typeof(covs[cov_type]) === 'boolean' && covs[cov_type]) {
                    mapped_types.push(cov_type);
                }
            }
        }
        return mapped_types.join(',');
    }

    businessInfo() {
        return {
            business_name: this.getParam('business_name'),
            legal_entity: this.getParam('legal_entity'),
            business_desc: this.getParam('business_desc'),
            years_in_business: this.getParam('years_in_business'),
            number_of_partners: this.getParam('number_of_partners'),
            full_time_employees: this.getParam('full_time_employees'),
            part_time_employees: this.getParam('part_time_employees'),
            annual_revenue: this.getParam('annual_revenue'),
            annual_payroll: this.getParam('annual_payroll')
        }
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
}
