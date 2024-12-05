const Base = require('../base');
const Common = require('./common');

module.exports = class Life extends Base {
    constructor(params) {
        super(params);
        this.params = params;
    }

    createLifeRequest() {
        return {
            campaign_id: this.getParam('campaign_id') || 8,
            click_id: this.getParam('click_id') || '1eewfe',
            lead: {
                traffic_tier: this.getParam('traffic_tier'),
                submission_url: this.getParam('submission_url') || 'https://smartfinancial.com',
                pre_existing_condition: this.getParam('pre_existing_condition'),
                applicant_info: this.applicantInfo(),
                requested_coverage: this.requestedCoverage(),
                contact: this.contactInfo()
            }
        }
    }

    applicantInfo() {
        return {
            date_of_birth: this.getParam('date_of_birth'),
            gender: Common.mapGender(this.getParam('gender')),
            marital_status: Common.mapMaritalStatus(this.getParam('marital_status')),
            height_ft: this.getParam('height_ft').toString(),
            height_in: this.getParam('height_in').toString(),
            weight: this.getParam('weight').toString(),
            tobacco: this.getParam('tobacco')
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

    requestedCoverage() {
        return {
            coverage_type: this.getParam('coverage_type'),
            coverage_amount: this.getParam('coverage_amount')
        }
    }
}
