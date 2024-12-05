const LeadCloudAuto = require('../lead_cloud/auto');

module.exports = class Auto extends LeadCloudAuto {
    currentlyInsured() {
        return this.getParam('currently_insured').toLowerCase() === 'yes' ? 'OwnPolicy' : 'Uninsured';
    }

    contactInfo() {
        return {
            FirstName: this.getParam('first_name'),
            LastName: this.getParam('last_name'),
            Address: [{
                AddressType: 'MailingAddress',
                Addr1: this.getParam('address'),
                City: this.getParam('city'),
                State: this.getParam('state'),
                Zip: this.getParam('zip'),
                County: this.getParam('county'),
            }],
            BusinessPhone: this.getParam('primary_phone'),
            Email: this.getParam('email')
        }
    }
}
