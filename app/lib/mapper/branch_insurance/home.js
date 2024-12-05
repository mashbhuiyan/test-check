const Base = require("../base");
const Common = require('./common');

module.exports = class Home extends Base {
    constructor(params) {
        super(params);
        this.params = params;
    }

    createHomeRequest() {
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
            policyTypeCode: "Home",
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
                dob: this.params.customerProfile ? this.params.customerProfile.date_of_birth : this.getParam('date_of_birth'),
                gender: Common.mapGender(this.getParam('gender')),
                maritalStatus: Common.mapMaritalStatus(this.getParam('marital_status'))
            }
        };
    }
}
