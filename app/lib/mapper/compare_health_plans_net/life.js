const Base = require('../base');
module.exports = class Life extends Base {
    constructor(params) {
        super(params);
        this.params = params;
    }

    createLifeRequest() {
        return {
            lead: {
                lp_url: 'https://compare-health-plans.net',
                clickId: this.getParam('click_id'),
                clk_cost: this.getParam('clk_cost'),
                products: 'Life',
                ip_address: this.getParam('ip_address'),
                device_type: this.getParam('device_type'),
                user_agent: this.getParam('user_agent'),
                aid: this.getParam('aid'),
                cid: this.getParam('cid'),
                traffic_tier: this.getParam('traffic_tier'),
                contact: this.contactInfo(),
                lifeInsurance: this.lifeInsurance(),
                requestedCoverage: {
                    coverageType:  this.getParam('coverage_type'),
                    coverageAmount: this.getParam('coverage_amount')
                },
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

    lifeInsurance() {
        return {
            applicantInfo: this.applicantInfo(),
            medicalHistory: this.medicalHistory(),
            currentCoverage: this.currentCoverage()
        }
    }

    applicantInfo() {
        return {
            gender: this.getParam('gender'),
            maritalStatus: this.getParam('marital_status'),
            credit: {
                credit: this.getParam('credit')
            },
            dateOfBirth: this.getParam('date_of_birth'),
            heightFt: this.getParam('height_ft'),
            heightIn: this.getParam('height_in'),
            weight: this.getParam('weight'),
            tobacco: this.getParam('tobacco'),
            occupation: this.getParam('occupation'),
            dui: this.getParam('dui'),
        }
    }

    medicalHistory() {
        return {
            heartDisease: this.getParam('heart_disease'),
            cancer: this.getParam('cancer'),
            medications: this.getParam('medications'),
            medList: this.getParam('med_list'),
            medicalTreatment: this.getParam('medical_treatment'),
            hospitalized: this.getParam('hospitalized'),
        }
    }

    currentCoverage() {
        return {
            carrier: this.getParam('carrier'),
            expirationDate: this.getParam('carrier'),
            coverageYears: this.getParam('carrier')
        }
    }
}
