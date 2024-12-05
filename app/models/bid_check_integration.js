const axios = require('axios');
const util = require('./utils');
const ErrorHandler = require('./error_handler');
const errorHandler = new ErrorHandler();

module.exports = class BidCheckIntegration {
    db;
    ping_id;
    listing_id;
    params;
    incidents = [];

    constructor(db, ping_id, listing_id, params) {
        this.db = db;
        this.ping_id = ping_id;
        this.params = params;
        this.listing_id = listing_id;
    }

    shareUrl() {
        if (process.env.PRODUCTION === '1') {
            return 'https://insurance.mediaalpha.com/bid-check.json';
        } else {
            return 'https://insurance-test.mediaalpha.com/bid-check.json';
        }
    }

    requestHeader() {
        return { 'Content-Type': 'application/json' }
    }

    getParam(name) {
        return util.getParam(this.params, name);
    }

    requestParams() {
        return {
            api_token: "Nu7O4KGi0hSm4fJTeZzRQ6qtlNORdNRM",
            data: this.requestParamsData(),
            ip: this.getParam('ip_address'),
            local_hour: (new Date()).getHours(),
            placement_id: "sKufB0KLMS8rsxMGJkVW_b_21GLeAQ",
            ua: this.getParam('user_agent'),
            ua_language: "en_US",
            url: "https://smartfinancial.com/",
            version: 17
        };
    }

    requestParamsData() {
        let reqData = {
            contact: `${this.getParam('first_name')} ${this.getParam('last_name')}`,
            email: this.getParam('email'),
            phone: this.getParam('primary_phone'),
            address: this.getParam('address'),
            zip: this.getParam('zip'),
            home_ownership: this.mapHomeOwnership(this.getParam('own')),
            home_garage: '',
            home_length: '',
            interested_in_home_insurance: '',
            interested_in_condo_insurance: '',
            interested_in_life_insurance: '',
            interested_in_renters_insurance: '',
            interested_in_usage_based_policy: '',
            vehicles: this.mapVehicles(),
            drivers: this.mapDrivers(),
            incidents: this.incidents,
            currently_insured: this.mappingBoolean(this.getParam('currently_insured')),
            military_affiliation: this.mappingBoolean(this.getParam('military_affiliation')),
            coverage_type: this.getParam('coverage_type'),
            bi_per_person: this.getParam('coverage_amount'),
            tcpa: {
                text: this.getParam('tcpa_text')
            }
        };
        if (reqData.currently_insured) {
            reqData['current_company'] = this.getParam('carrier');
            reqData['current_customer'] = parseInt(this.getParam('coverage_years') || '0') * 12;
        }

        return reqData;
    }

    mappingBoolean(status) {
        return status === 'Yes' ? 1 : 0;
    }

    mapHomeOwnership(status) {
        return status === 'Own' || status === 'own' ? 1 : 0;
    }

    mapVehicles() {
        let vehicles = this.params.vehicles || [];
        let mapped_vehicles = [];
        for (let vehicle of vehicles) {
            let objVehicle = {
                year: vehicle.year,
                make: vehicle.make,
                model: vehicle.model,
                submodel: vehicle.submodel,
                vin: vehicle.vin,
                alarm: 1,
                primary_purpose: vehicle.primary_use,
                primary_driver: vehicle.primary_driver_id,
                annual_mileage: vehicle.annual_mileage,
                ownership: this.mapVehicleOwnership(vehicle.ownership),
                collision: vehicle.collision,
                comprehensive: vehicle.comprehensive
            }

            mapped_vehicles.push(objVehicle);
        }
        return mapped_vehicles;
    }

    mapVehicleOwnership(status) {
        return status === 'Owned' || status === 'owned' ? 1 : 0;
    }

    mapDrivers() {
        let drivers = this.params.drivers || []
        let mapped_drivers = [];
        let i = 0;
        for (let driver of drivers) {
            mapped_drivers.push({
                relationship: driver.relationship_to_contact,
                driver: `${driver.first_name} ${driver.last_name}`,
                gender: this.mapDriverGender(driver.gender),
                marital_status: driver.marital_status,
                birth_date: this.formatDate(driver.date_of_birth),
                first_licensed: driver.license_obtained_age,
                education: this.mapEducation(driver.education),
                primary_vehicle: this.getPrimaryVehicleIndex(i),
                credit_rating: this.getParam('credit') || 'Good',
                bankruptcy: this.mappingBoolean(this.getParam('bankruptcy')),
                occupation: this.mapOccupation(driver.occupation),
                license_status: driver.license_status,
                license_state: this.getParam('state'),
                sr_22: this.mappingBoolean(driver.sr22_required)
            });
            this.mapIncidents(driver, i);
            ++i;
        }
        return mapped_drivers;
    }

    mapIncidents(driver, index) {
        let violations = driver.violations || [];
        for (let violation of violations) {
            this.incidents.push({
                type: 'ticket',
                driver: index,
                incident_date: this.formatDate(violation.date),
                description: this.mapViolationDesc(violation.violation_type)
            });
        }

        let claims = driver.claims || [];
        for (let claim of claims) {
            this.incidents.push({
                type: 'claim',
                driver: index,
                incident_date: this.formatDate(claim.date),
                description: this.mapClaimDesc(claim.claim_type),
                claim_at_fault: 0,
                amount_paid: claim.amount
            });
        }
    }

    mapViolationDesc(type) {
        switch (type) {
            case 'Child Seat':
                return 'Child not in car seat';
            case 'Failure to Stop':
                return 'Failure to stop';
            case 'Illegal U-turn':
                return 'Illegal u turn';
            case 'Seat Belt':
                return 'No seatbelt';
            case 'Speeding':
                return 'Reckless driving';
            case 'Other Ticket':
                return 'Other unlisted moving violation';
            default:
                return 'Other unlisted moving violation';
        }
    }

    mapClaimDesc(type) {
        switch (type) {
            case 'Fire Hail Water Damage':
                return 'Car fire';
            case 'Vandalism Damage':
                return 'Vandalism';
            case 'Vehicle Hit Animal':
                return 'Hit an animal';
            case 'Vehicle Stolen':
                return 'Theft of vehicle';
            case 'Windshield Damage':
                return 'Windshield replacement';
            default:
                return 'Other';
        }
    }

    mapEducation(education) {
        switch (education) {
            case 'Less than High School':
                return 'Incomplete';
            case 'Some or No High School':
                return 'Incomplete';
            case 'High School Diploma':
                return 'High School';
            case 'Some College':
                return 'Some College';
            case 'Associate Degree':
                return 'Associate';
            case 'Bachelors Degree':
                return 'Bachelor';
            case 'Masters Degree':
                return 'Master';
            case 'Doctorate Degree':
                return 'PhD';
            case 'Other':
                return 'Other Nonprofessional Degree';
            default:
                return 'Unknown';
        }
    }

    mapOccupation(occupation) {
        switch (occupation) {
            case /Architect/i:
                return 'Architect';
            case /Advertising/i:
                return 'Marketing';
            case /Arts/i:
                return 'Other Not Listed';
            case /Banking/i:
                return 'Other Not Listed';
            case /Business Owner/i:
                return 'Business Owner';
            case /Clerical/i:
                return 'Administrative Clerical';
            case /Clergy/i:
                return 'Clergy';
            case /Construction/i:
                return 'Construction Trades';
            case /CPA|Certified Public Accountant/i:
                return 'Certified Public Accountant';
            case /Customer/i:
                return 'Sales Outside';
            case /Dentist/i:
                return 'Dentist';
            case /Disabled/i:
                return 'Disabled';
            case /Doctor/i:
                return 'Health Care';
            case /Education/i:
                return 'School Teacher';
            case /Engineer/i:
                return 'Engineer';
            case /Financial/i:
                return 'Financial Services';
            case /Government/i:
                return 'Other Not Listed';
            case /Health/i:
                return 'Health Care';
            case /Homemaker/i:
                return 'Homemaker';
            case /Hospitality/i:
                return 'Other Not Listed';
            case /Human/i:
                return 'Human Relations';
            case /Insurance/i:
                return 'Consultant';
            case /Internet/i:
                return 'Other Technical';
            case /Law Enforcement/i:
                return 'Lawyer';
            case /Lawyer/i:
                return 'Lawyer';
            case /Legal/i:
                return 'Lawyer';
            case /Management/i:
                return 'Manager Supervisor';
            case /Manager/i:
                return 'Manager Supervisor';
            case /Manufacturing/i:
                return 'Other Technical';
            case /Marketing/i:
                return 'Marketing';
            case /Military/i:
                return 'Military Enlisted';
            case /Volunteer/i:
                return 'Other Non Technical';
            case /Pharmaceutical/i:
                return 'Health Care';
            case /Physician/i:
                return 'Physician';
            case /Professional Salaried/i:
                return 'Professional Salaried';
            case /Professor/i:
                return 'Professor';
            case /Real Estate/i:
                return 'Construction Trades';
            case /Restaurant/i:
                return 'Self Employed';
            case /Retail/i:
                return 'Retail';
            case /Retired/i:
                return 'Retired';
            case /Sales/i:
                return 'Sales Outside';
            case /Self Employed/i:
                return 'Self Employed';
            case /Scientist/i:
                return 'Scientist';
            case /Skilled/i:
                return 'Skilled Semi Skilled';
            case /Student/i:
                return 'Student';
            case /Teacher/i:
                return 'School Teacher'
            case /Technology/i:
                return 'Other Technical';
            case /Telecommunications/i:
                return 'Other Technical';
            case /Transportation/i:
                return 'Transportation or Logistics';
            case /Unemployed/i:
                return 'Unemployed';
            default:
                return 'Other Not Listed';
        }
    }

    getPrimaryVehicleIndex(index) {
        let vehicles = this.params.vehicles || [];
        for (let i=0; i<vehicles.length; ++i) {
            if (vehicles[i].primary_driver_id == index) {
                return i;
            }
        }
        return 0;
    }

    mapDriverGender(gender) {
        if (gender === 'Non Binary') {
            return 'X';
        } else if (gender === 'Female') {
            return 'F';
        } else {
            return 'M';
        }
    }

    formatDate(date) {
        try {
            date = new Date(date);
            return date.toISOString().slice(0,10);
        } catch (e) {
            console.error('date parse error: ', e.message);
            return '';
        }
    }

    check() {
        try {
            axios.post(this.shareUrl(), this.requestParams(), {
                headers: this.requestHeader()
            })
                .then(res => {
                    if (res.data.error) {
                        console.log('Bid check error: ', res.data.error);
                    } else {
                        // const ads = res.data?.ads || [];
                        // for (let ad of ads) {
                        //     this.setClickPanels(ad);
                        // }
                    }
                }).catch(error => {
                console.log('Bid check error catch: ', error);
            });
        } catch (ex) {
            console.log('Failed to map data: ', ex.message);
        }
    }

    async setClickPanels(ad) {
        const current_date_time = new Date();
        const data = {
            click_listing_id: this.listing_id,
            click_ping_id: this.ping_id,
            advertiser: ad.carrier,
            position: null,
            payout: ad.bid,
            clicked: false,
            created_at: current_date_time,
            updated_at: current_date_time,
        };
        let value_set = [];
        let column_set = [];
        let counter_set = [];
        let counter = 1;
        for (let key in data) {
            counter_set.push(`$${counter}`);
            column_set.push(key);
            value_set.push(data[key]);
            counter += 1;
        }
        this.db.query(`INSERT INTO click_panels (${column_set.join(', ')})
                           VALUES (${counter_set.join(', ')})`, value_set, (error, result) => {
            if (error) {
                errorHandler.notify(error);
                console.log('Error when creating click_panels err: ', error);
            } else {
                // console.log('Inserted to click_panels');
            }
        });
    }
}
