const Base = require('../base');
module.exports = class Health extends Base {
    constructor(params) {
        super(params);
        this.params = params;
    }

    createHealthRequest() {
        return {
            lead: {
                lp_url: 'https://unitedstatesinsurance.com',
                clickId: this.getParam('click_id'),
                clk_cost: this.getParam('clk_cost'),
                products: 'Health',
                ip_address: this.getParam('ip_address'),
                device_type: this.getParam('device_type'),
                user_agent: this.getParam('user_agent'),
                aid: this.getParam('aid'),
                cid: this.getParam('cid'),
                traffic_tier: this.getParam('traffic_tier'),
                contact: this.contactInfo(),
                healthInsurance: this.healthInsurance(),
                requestedCoverage: 'Individual'
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

    healthInsurance() {
        return {
            applicantInfo: this.applicantInfo(),
            dependents: this.dependents(),
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
            numChildren: this.getParam('num_children'),
            householdIncome: this.getParam('household_income'),
            heightFt: this.getParam('height_ft'),
            heightIn: this.getParam('height_in'),
            weight: this.getParam('weight'),
            tobacco: this.getParam('tobacco'),
            occupation: this.getParam('occupation'),
            qualifyingLifeEvent: this.getParam('qualifying_life_event'),
            expectant: this.getParam('expectant'),
            dui: this.getParam('dui'),
        }
    }

    dependents() {
        let dependents = this.getParam('dependents')
        let mapped_dependents = [];
        let index = 1;
        for (let dependent of dependents) {
            mapped_dependents.push({
                driverId: index,
                firstName: dependent.first_name,
                lastName: dependent.last_name,
                dependentType: dependent.dependent_type,
                dateOfBirth: dependent.date_of_birth,
                gender: dependent.gender,
                heightFt: dependent.height_ft,
                heightIn: dependent.height_in,
                weight: dependent.weight,
                tobacco: dependent.tobacco
            });
        }
        return mapped_dependents;
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
