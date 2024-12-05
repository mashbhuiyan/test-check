const Base = require('../base');

module.exports = class Health extends Base {
    constructor(params) {
        super(params);
        this.params = params;
    }

    createHealthRequest() {
        return {
            campaign_id: this.getParam('campaign_id') || 7,
            click_id: this.getParam('click_id') || '1eewfe',
            lead: {
                traffic_tier: this.getParam('traffic_tier'),
                submission_url: this.getParam('submission_url') || 'https://smartfinancial.com',
                applicant_info: this.applicantInfo(),
                medical_history: { pre_existing_condition: this.getParam('pre_existing_condition') },
                contact: this.contactInfo()
            }
        }
    }

    applicantInfo() {
        return {
            date_of_birth: this.getParam('date_of_birth'),
            household_income: this.getParam('household_income')
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
