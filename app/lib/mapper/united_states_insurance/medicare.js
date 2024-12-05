const Base = require('../base');
module.exports = class Medicare extends Base {
    constructor(params) {
        super(params);
        this.params = params;
    }

    createMedicareRequest() {
        return {
            lead: {
                lp_url: 'https://unitedstatesinsurance.com',
                clickId: this.getParam('click_id'),
                clk_cost: this.getParam('clk_cost'),
                products: 'Medicare',
                ip_address: this.getParam('ip_address'),
                device_type: this.getParam('device_type'),
                user_agent: this.getParam('user_agent'),
                aid: this.getParam('aid'),
                cid: this.getParam('cid'),
                traffic_tier: this.getParam('traffic_tier'),
                contact: this.contactInfo(),
                applicantInfo: this.applicantInfo(),
            }
        }
    }

    contactInfo() {
        return {
            firstName: this.getParam('first_name'),
            lastName: this.getParam('last_name'),
            addressLine1: this.getParam('address'),
            city: this.getParam('city'),
            state: this.getParam('state'),
            zipCode: this.getParam('zip'),
            primaryPhone: this.getParam('primary_phone'),
            email: this.getParam('email')
        }
    }

    applicantInfo() {
        return {
            dateOfBirth: this.getParam('date_of_birth'),
            gender: this.getParam('gender'),
            maritalStatus: this.getParam('marital_status')
        }
    }
}
