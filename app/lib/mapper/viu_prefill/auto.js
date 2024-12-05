const Base = require('../base');

module.exports = class Auto extends Base {
    constructor(params) {
        super(params);
        this.params = params;
    }

    createAutoRequest() {
        return {
            firstName: this.getParam('first_name'),
            lastName: this.getParam('last_name'),
            email: this.getParam('email'),
            phone: this.getParam('primary_phone'),
            insuranceLineType: "PersonalAuto",
            prefill: this.contactInfo()
        }
    }

    contactInfo() {
        return {
            address: {
                street: this.getParam('address'),
                houseNumber: "",
                city: this.getParam('city'),
                state: this.getParam('state'),
                zipcode: this.getParam('zip'),
                country: "US",
                unit: ""
            }
        }
    }
}
