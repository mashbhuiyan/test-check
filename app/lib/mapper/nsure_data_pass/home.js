const Base = require("../base");
module.exports = class Home extends Base {
    constructor(params) {
        super(params);
        this.params = params;
    }

    createHomeRequest() {
        return {
            clickId: this.getParam('click_id'),
            AffiliateInfo: this.affiliationInfo(),
            ContactInfo: this.contactInfo(),
            HomeInsurance: this.homeInfo(),
        };
    }

    affiliationInfo() {
        return {}
    }

    contactInfo() {
        return {
            FirstName: this.getParam('first_name'),
            LastName: this.getParam('last_name'),
            Address:  this.getParam('address'),
            ZipCode:  this.getParam('zip'),
            City:  this.getParam('city'),
            State:  this.getParam('state'),
            PhoneDay:  this.getParam('primary_phone'),
            Email:  this.getParam('email'),
        }
    }

    homeInfo() {
        return {
            ApplicantInfo: this.applicantInfo(),
            Property: this.propertyInfo(),
            CurrentInsurance: this.currentInsuranceInfo(),
            RequestedCoverage: this.requestedInsuranceInfo(),
        }
    }

    applicantInfo() {
        return {
            DOB: this.formatDate(this.getParam('date_of_birth')),
            Gender : this.getParam('gender'),
            Marital : this.getParam('marital_status'),
            Credit : this.getParam('credit')
        }
    }

    propertyInfo() {
        return {
            PropertyType: this.getParam('property_type'),
            Garage: this.getParam('garage'),
            Foundation: this.getParam('foundation_type'),
            YearBuilt: this.getParam('year_built'),
            Stories: this.getParam('num_stories'),
            Bedrooms: this.getParam('num_bedrooms'),
            Bathrooms: this.getParam('num_bathrooms'),
            SquareFootage: this.getParam('square_footage'),
            NewlyPurchased: this.mapBoolean(this.getParam('new_purchase')),
            ConstructionType: this.getParam('construction_type'),
            RoofType: this.getParam('roof_type'),
            ExteriorWalls: this.getParam('exterior_wall_type'),
            HeatingType: this.getParam('heating_type'),
            WiringType: this.getParam('wiring_type'),
            PropertyFeatures: {},
        }
    }

    currentInsuranceInfo() {
        let insuranceInfo = {
            CurrentlyInsured: this.mapBoolean(this.getParam('currently_insured')),
        }

        if (insuranceInfo.CurrentlyInsured === 'true') {
            insuranceInfo['CurrentPolicy'] = this.currentPolicy();
        }
        return insuranceInfo;
    }
     
    currentPolicy() {
       return {
           Carrier:  this.getParam('carrier'),
           Expiration:  this.getParam('expiration_date')
       }
    }

    requestedInsuranceInfo() {
        return {
            ZipCode:  this.getParam('zip'),
            Address: this.getParam('address'),
            City: this.getParam('city'),
            State: this.getParam('state')
        }
    }

    mapBoolean(value) {
        return value === 'Yes' ? 'true' : 'false';
    }
}
