const Base = require('../base');
const Common = require('./common');

module.exports = class Auto extends Base {
    constructor(params) {
        super(params);
        this.params = params;
    }

    createAutoRequest() {
        return {
            leadID: this.getParam('click_id'),
            propertyInformation: {
                address: {
                    address1: this.getParam('address'),
                    city: this.getParam('city'),
                    state: this.getParam('state'),
                    zip: this.getParam('zip')
                }
            },
            policyTypeCode: "AUTO",
            insuredInformation: {
                firstName: this.getParam('first_name'),
                lastName: this.getParam('last_name'),
                email: this.getParam('email'),
                phone: [
                    {
                        type: "HOME",
                        number: this.getParam('primary_phone')
                    }
                ],
                dob: this.getParam('date_of_birth'),
                gender: Common.mapGender(this.getParam('gender')),
                maritalStatus: Common.mapMaritalStatus(this.getParam('marital_status'))
            },
            vins: this.vehicles(),
            bodilyInjuryLimit: "100/300",
        };
    }

    vehicles() {
        let vehicles = this.params.vehicles || [];
        let mapped_vehicles = [];
        for (let vehicle of vehicles) {
            mapped_vehicles.push(vehicle.vin)
        }
        return mapped_vehicles;
    }
}
