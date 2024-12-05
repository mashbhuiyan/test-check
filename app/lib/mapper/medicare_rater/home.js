const Base = require('../base');
module.exports = class Home extends Base {
    constructor(params) {
        super(params);
        this.params = params;
    }

    createHomeRequest() {
        return {
            lead: {
                lp_url: 'https://medicarerater.org',
                clickId: this.getParam('click_id'),
                clk_cost: this.getParam('clk_cost'),
                products: 'Home',
                ip_address: this.getParam('ip_address'),
                device_type: this.getParam('device_type'),
                user_agent: this.getParam('user_agent'),
                aid: this.getParam('aid'),
                cid: this.getParam('cid'),
                traffic_tier: this.getParam('traffic_tier'),
                contact: this.contactInfo(),
                homeInsurance: this.homeInsurance(),
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

    homeInsurance() {
        return {
            customerProfile: this.customerProfile(),
            homeInfo: this.homeInfo(),
            currentCoverage: this.currentCoverage()
        }
    }

    customerProfile() {
        return {
            gender: this.getParam('gender'),
            maritalStatus: this.getParam('marital_status'),
            credit: {
                credit: this.getParam('credit')
            },
            dateOfBirth: this.params.customerProfile ? this.params.customerProfile.date_of_birth : this.getParam('date_of_birth')
        }
    }

    homeInfo() {
        return {
            addressLine1: this.getParam('addressLine1'),
            city: this.getParam('city'),
            state: this.getParam('state'),
            zipCode: this.getParam('zipCode'),
            squareFootage: this.getParam('square_footage'),
            numStories: this.getParam('num_stories'),
            yearBuilt: this.getParam('year_built'),
            propertyType: this.getParam('property_type'),
            numBedrooms: this.getParam('num_bedrooms'),
            numBathrooms: this.getParam('num_bathrooms'),
            garage: this.getParam('garage'),
            constructionType: this.getParam('construction_type'),
            foundationType: this.getParam('foundation_type'),
            roofType: this.getParam('roof_type'),
            roofAge: this.getParam('roof_age'),
            purchaseDt: this.getParam('purchase_dt'),
            numResidents: this.getParam('num_residents'),
            newPurchase: this.getParam('new_purchase'),
            interiorWallType: this.getParam('interior_wall_type'),
            exteriorWallType: this.getParam('exterior_wall_type'),
            wiringType: this.getParam('wiring_type'),
            heatingType: this.getParam('heating_type'),
            electricType: this.getParam('electric_type'),
            burglarAlarm: this.getParam('burglar_alarm'),
            FireAlarm: this.getParam('fire_alarm'),
            smokeAlarm: this.getParam('smoke_alarm'),
            floodZone: this.getParam('flood_zone')
        }
    }

    currentCoverage() {
        return {
            carrier: this.getParam('carrier'),
            expirationDate: this.getParam('carrier'),
            coverageYears: this.getParam('carrier'),
        }
    }
}
