const Base = require('../base');
module.exports = class Auto extends Base {
    constructor(params) {
        super(params);
        this.params = params;
    }

    createAutoRequest() {
        return {
            lead: {
                lp_url: 'https://smartfinancial.com/kemper',
                clickId: this.getParam('click_id'),
                clk_cost: this.getParam('clk_cost'),
                products: 'Auto',
                ip_address: this.getParam('ip_address'),
                device_type: this.getParam('device_type'),
                user_agent: this.getParam('user_agent'),
                aid: this.getParam('aid'),
                cid: this.getParam('cid'),
                traffic_tier: this.getParam('traffic_tier'),
                contact: this.contactInfo(),
                autoInsurance: this.autoInsurance(),
                AAAMember: this.getParam('AAAMember'),
                militaryService: this.getParam('military_affiliation'),
                leadSource: {
                    name: this.getParam('source_type'),
                    version: ''
                }
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

    autoInsurance() {
        return {
            customerProfile: this.customerProfile(),
            drivers: this.drivers(),
            vehicles: this.vehicles(),
            currentCoverage: this.currentCoverage()
        }
    }

    customerProfile() {
        return {
            gender: this.getParam('gender'),
            maritalStatus: this.getParam('marital_status'),
            residence: {
                years: this.getParam('years'),
                own: this.getParam('own')
            },
            credit: {
                credit: this.getParam('credit'),
                bankruptcy: this.getParam('bankruptcy')
            },
            dateOfBirth: this.params.customerProfile ? this.params.customerProfile.date_of_birth : this.getParam('date_of_birth'),
            currentlyInsured: this.getParam('currently_insured')
        }
    }

    drivers() {
        let drivers = this.params.drivers || []
        let mapped_drivers = [];
        let index = 1;
        for (let driver of drivers) {
            mapped_drivers.push({
                driverId: index,
                firstName: driver.first_name || this.getParam('first_name'),
                lastName: driver.last_name || this.getParam('last_name'),
                licenseStatus: driver.license_status,
                licenseObtainedAge: driver.license_obtained_age,
                licenseEverSuspendedOrRevoked: driver.license_ever_suspended_or_revoked,
                sr22Required: driver.sr22_required,
                gender: driver.gender,
                dateOfBirth: driver.date_of_birth,
                maritalStatus: driver.marital_status,
                occupation: driver.occupation,
                educationLevel: driver.education,
                relationshipToContact: driver.relationship_to_contact,
                violations: this.violations(driver),
                claims: this.claims(driver),
            });
        }
        return mapped_drivers;
    }

    violations(driver) {
        let violations = driver.violations || [];
        let mapped_violation = [];
        for (let violation of violations) {
            mapped_violation.push({
                date: violation.date,
                violationType: violation.violation_type,
            })
        }
        return mapped_violation;
    }

    claims(driver) {
        let claims = driver.claims || [];
        let mapped_claims = [];
        for (let claim of claims) {
            mapped_claims.push({
                date: claim.date,
                claimType: claim.claim_type,
                amount: claim.amount,
            });
        }
        return mapped_claims;
    }

    vehicles() {
        let vehicles = this.params.vehicles || [];
        let mapped_vehicles = [];
        let index = 1;
        for (let vehicle of vehicles) {
            mapped_vehicles.push({
                vehicleId: index,
                primaryDriverId: 1,
                vin: vehicle.vin,
                year: vehicle.year,
                make: vehicle.make,
                model: vehicle.model,
                submodel: vehicle.submodel,
                primaryUse: vehicle.primary_use,
                garageType: vehicle.garage_type,
                parkedAtMailingAddress: vehicle.parked_at_mailing_address || '',
                garagingAddress: vehicle.garaging_address || '',
                garagingCity: vehicle.garaging_city || '',
                garagingState: vehicle.garaging_state || '',
                garagingZipCode: vehicle.garaging_zip_code || '',
                oneWayDistance: vehicle.one_way_distance,
                annualMileage: vehicle.annual_mileage,
                ownership: vehicle.ownership,
                coveragePackage: vehicle.coverage_package || 'Standard',
            });
            index += 1;
        }
        return mapped_vehicles;
    }

    currentCoverage() {
        if (this.getParam('currently_insured') == 'Yes') {
            return {
                carrier: this.getParam('carrier'),
                expirationDate: this.getParam('expiration_date'),
                coverageYears: this.getParam('coverage_years'),
                bodilyInjury: this.getParam('bodily_injury')
            }
        } else {
            return {};
        }
    }
}
