const Base = require('../base');
module.exports = class Auto extends Base {
    constructor(params) {
        super(params);
        this.params = params;
    }

    createAutoRequest() {
        let dt = new Date();
        return {
            LeadCloud: {
                Source: 'Contactability.com LLC',
                RequestDt: dt.toISOString(),
                Browser: this.getParam('user_agent'),
                SubmissionURL: this.getParam('submission_url') || 'https://smartfinancial.com',
                ConsentLanguage: this.getParam('tcpa_text'),
                SessionId: '',
                ConsumerSourceIP: this.getParam('ip_address') || '1.1.1.1',
                UniversalLeadID: this.getParam('lead_id_token'),
                SellerCampaignName: this.getParam('traffic_tier'),
                SellerCampaignSubSource: '',
                // SellerLeadPrice: 6.75,
                LeadIdentifier: this.getParam('click_id'),
                ContactInfo: this.contactInfo(),
                CreditAuthorization: {
                    Allowed: 'No'
                },
                InsuranceInfo: this.insuranceInfo(),
                ResidenceInfo: {
                    ResidenceStatus: this.getParam('own'),
                    ResidenceType: this.get_residence_type(this.getParam('own')),
                    ResidenceLength: this.get_length_of_residence(this.getParam('years'))
                },
                Driver: this.drivers(),
                Vehicle: this.vehicles(),
                AAAMember: this.getParam('AAAMember'),
                Military: 'No Military Experience'
            }
        }
    }

    contactInfo() {
        return {
            FirstName: this.getParam('first_name'),
            LastName: this.getParam('last_name'),
            Addr1: this.getParam('address'),
            City: this.getParam('city'),
            State: this.getParam('state'),
            Zip: this.getParam('zip'),
            DayPhone: this.getParam('primary_phone'),
            Email: this.getParam('email')
        }
    }

    insuranceInfo() {
        let insurance_info = {}
        let dt = new Date();
        let requested_coverage = this.getParam('requested_coverage') || 'Standard';
        let coverage = this.state_requested_coverage(this.getParam('state'))[requested_coverage];
        let bodily_injury1 = coverage[0] / 1000;
        let bodily_injury2 = coverage[1] / 1000;
        let property_damage = coverage[2];
        let umbi1 = 0;
        let umbi2 = 0;
        let umpd = 0;
        if (coverage[3]) {
            umbi1 = coverage[3] / 1000;
        }
        if (coverage[4]) {
            umbi2 = coverage[4] / 1000;
        }
        if (coverage[5]) {
            umpd = coverage[5] / 1000;
        }
        insurance_info.CurrentlyInsured = this.currentlyInsured();
        if (this.getParam('currently_insured').toLowerCase() === 'yes') {
            let insured_since = (new Date()).setMonth(dt.getMonth() - 6);
            let diff_ins_days = (dt - insured_since) / (1000 * 60 * 60 * 24);
            insurance_info.CurrentInsurerName = this.getParam('carrier')
            insurance_info.LengthTimeWithInsurer = diff_ins_days
            insurance_info.LengthTimeCC = diff_ins_days
            insurance_info.CurrentCoverageLevel = requested_coverage
            insurance_info.PolicyExpirationDt = this.formatDate(this.getParam('expiration_date'))
        } else {
            insurance_info.NoInsuranceLength = 'Unknown';
            insurance_info.CoverageLapseLengthDays = '1WEEK';
        }
        insurance_info.EverDenied = 'No'
        insurance_info.ExcludedDrivers = 'No'
        insurance_info.RequestedBI = bodily_injury1.toString() + '/' + bodily_injury2.toString();
        insurance_info.RequestedPD = property_damage.toString();
        if (['VA'].includes(this.getParam('State'))) {
            insurance_info.RequestedUMBI = umbi1.toString() + '/' + umbi2.toString();
            insurance_info.RequestedUMPD = umpd.toString();
        }
        insurance_info.RequestedStartDt = this.formatDate(this.getParam('expiration_date'))
        insurance_info.MultiPolicyDiscount = 'No';
        return insurance_info;
    }

    currentlyInsured() {
        return this.getParam('currently_insured').toLowerCase() === 'yes' ? 'Yes' : 'Uninsured';
    }

    drivers() {
        let drivers = this.params.drivers || []
        let mapped_drivers = [];
        let index = 1;
        for (let driver of drivers) {
            mapped_drivers.push({
                Id: index,
                Type: 'Rated',
                FirstName: driver.first_name,
                LastName: driver.last_name,
                Gender: (driver.gender || 'M')[0].toUpperCase(),
                BirthDt: this.formatDate(driver.date_of_birth),
                MaritalStatus: this.map_marital_status(driver.marital_status),
                Occupation: this.map_occupation(driver.occupation),
                OccupationLength: '3',
                Education: this.map_education(driver.education),
                LicenseStatus: this.map_license_status(driver.license_status),
                AgeLicensed: driver.license_obtained_age || '16',
                LicenseState: this.getParam('state'),
                SelfCreditRating: this.map_credit(this.getParam('credit') || 'Good'),
                SuspRevoked: (driver.suspension ? 'Yes' : 'No'),
                SR22: driver.sr22_required,
                DriverTraining: 'No',
                MatureDriver: 'No',
                GoodStudent: 'No',
                DistantStudent: 'No',
                ChildCustody: 'No',
                Bankruptcy: this.getParam('bankruptcy'),
                Repossessions: 'No',
                Military: 'No Military Experience',
                Relationship: this.map_relationship(driver.relationship_to_contact),
                Accident: this.accidents(driver),
                Claim: this.claims(driver),
            });
            index += 1;
        }
        return mapped_drivers;
    }

    accidents(driver) {
        let accidents = driver.accidents || [];
        let mapped_accidents = [];
        for (let acc of accidents) {
            mapped_accidents.push({
                Type: this.map_accident_code(acc.incident_description),
                Date: this.formatDate(acc.incident_date),
                WhatDamaged: this.map_accident_damage(acc.damage_type),
                AtFault: acc.incident_at_fault ? 'Yes' : 'No'
            })
        }
        return mapped_accidents;
    }

    claims(driver) {
        let claims = driver.claims || [];
        let mapped_claims = [];
        for (let claim of claims) {
            mapped_claims.push({
                Type: this.map_claim_type(claim.claim_type),
                Date: this.formatDate(claim.date),
                DamageAmount: (parseInt(claim.amount, 500) > 0 ? parseInt(claim.amount) : this.randBetween(500, 1500))
            })
        }
        return mapped_claims;
    }

    vehicles() {
        let vehicles = this.params.vehicles || [];
        let mapped_vehicles = [];
        let index = 1;
        let requested_coverage = this.getParam('requested_coverage');
        for (let vehicle of vehicles) {
            let dt = new Date();
            let comp_ded = parseInt((parseInt(vehicle.year, 0) <= (dt.getFullYear() - 10) || requested_coverage === 'Minimum') ? 0 : vehicle.comprehensive, 0)
            let coll_ded = parseInt((parseInt(vehicle.year, 0) <= (dt.getFullYear() - 10) || requested_coverage === 'Minimum') ? 0 : vehicle.collision, 0)
            let obj_vehicle = {
                Id: index,
                VIN: vehicle.vin,
                Year: vehicle.year,
                Make: vehicle.make,
                Model: vehicle.model,
                Submodel: vehicle.submodel,
                PrimaryDriver: 1,
                RegisteredTo: 'Self',
                Alarm: 'Yes',
                DriverAirbag: 'Yes',
                DualAirbag: 'Yes',
                SideImpactSafety: 'Yes',
                AntiLockBrakes: parseInt(vehicle.year, 0) > 2012 ? 'Yes' : 'No',
                DrivenDays: '5',
                AnnualMileage: vehicle.annual_mileage || 510,
                Ownership: vehicle.ownership,
                Garage: this.map_garage_type(vehicle.garage_type),
                Use: this.map_primary_use(vehicle.primary_use),
                OneWayDistance: vehicle.one_way_distance,
                coveragePackage: vehicle.coverage_package || 'Standard',
                Salvaged: vehicle.salvaged ? 'Yes' : 'No',
                ExistDamage: vehicle.salvaged ? 'Yes' : 'No',
                Addr1: this.getParam('address'),
                City: this.getParam('city'),
                State: this.getParam('state'),
                Zip: this.getParam('zip')
            }
            if (comp_ded > 0 && coll_ded > 0) {
                obj_vehicle.COMP = vehicle.comprehensive
                obj_vehicle.COLL = vehicle.collision
            }
            mapped_vehicles.push(obj_vehicle);
            index += 1;
        }
        return mapped_vehicles;
    }

    get_length_of_residence(val) {
        switch (val) {
            case 0:
                return '6';
            case 1:
                return '12';
            case 2:
                return '24';
            case 3:
            case 4:
                return '60';
            case 5:
            case 6:
            case 7:
            case 8:
            case 9:
            case 10:
                return '120';
            case 11:
            case 12:
            case 13:
            case 14:
            case 15:
                return '130';
            default:
                return '12';
        }
    }

    get_residence_type(val) {
        switch (val) {
            case 'Single Family':
                return 'SingleFamilyHome';
            case 'Multi Family':
                return 'MultiFamilyHome';
            case 'Duplex':
                return 'Rowhouse';
            case 'Apartment':
                return 'Apartment';
            case 'Townhome':
                return 'Townhome';
            case 'Condominium':
                return 'Condo';
            case 'Mobile Home':
                return 'MobileHome';
            default:
                return 'Apartment';
        }
    }

    map_credit(credit) {
        switch (credit) {
            case 'Poor':
                return 'Poor';
            case 'Average':
                return 'Average';
            case 'Good':
                return 'Good';
            case 'Excellent':
                return 'Excellent';
            default:
                return 'Good';
        }
    }

    map_relationship(val) {
        if (val == 'Applicant') {
            return 'Self';
        } else {
            return val;
        }
    }

    map_license_status(license_status) {
        switch (license_status) {
            case 'Active':
                return 'Active';
            case 'Expired':
                return 'Expired';
            case 'Suspended':
                return 'Suspended';
            case 'Probation':
                return 'Temporary';
            case 'Restricted':
                return 'Temporary';
            case 'Learner':
                return 'Learner';
            case 'Temporary':
                return 'Temporary';
            case 'International':
                return 'International';
            default:
                return 'Active';
        }
    }

    map_education(education) {
        switch (education) {
            case 'Less than High School':
                return 'LessThanHighSchoolDiploma';
            case 'Some or No High School':
                return 'LessThanHighSchoolDiploma';
            case 'High School Diploma':
                return 'HighSchool';
            case 'Some College':
                return 'SomeCollegeNoDegree';
            case 'Associate Degree':
                return 'AssociateDegree';
            case 'Bachelors Degree':
                return 'BachelorsDegree';
            case 'Masters Degree':
                return 'MastersDegree';
            case 'Doctorate Degree':
                return 'Doctorate';
            default:
                return 'OtherProfessionalDegree';
        }
    }

    map_marital_status(marital) {
        switch (marital) {
            case /Single/i:
                return 'Single';
            case /Married/i:
                return 'Married';
            case /Separated/i:
                return 'Separated';
            case /Divorced/i:
                return 'Divorced';
            case /Widowed/i:
                return 'Widowed';
            case /Domestic Partner/i:
                return 'DomesticPartner';
            default:
                return 'Single';
        }
    }

    map_garage_type(garage) {
        switch (garage) {
            case 'Private':
                return 'PrivateGarage';
            case 'Locked':
                return 'PrivateGarage';
            case 'Carport':
                return 'Carport';
            case 'No Cover':
                return 'Driveway';
            default:
                return 'Street';
        }
    }

    map_primary_use(usage) {
        switch (usage) {
            case 'Commute Work':
                return 'CommuteWork';
            case 'Commute School':
                return 'CommuteSchool';
            case 'Commute Varies':
                return 'Commute';
            case 'Pleasure':
                return 'Pleasure';
            case 'Business':
                return 'Business Use';
            case /Farm/i:
                return 'Farm';
            case 'Government':
                return 'Government';
            default:
                return 'Commute';
        }
    }

    map_occupation(occupation) {
        switch (occupation) {
            case /Architect/i:
                return 'AR';
            case /Advertising/i:
                return 'WRT';
            case /Arts/i:
                return 'ART';
            case /Banking/i:
                return 'BMG';
            case /Business Owner/i:
                return 'CTR';
            case /Clerical/i:
                return 'ADM';
            case /Clergy/i:
                return 'CLR';
            case /Construction/i:
                return 'CONF';
            case /CPA|Certified Public Accountant/i:
                return 'CPA';
            case /Customer/i:
                return 'BFI';
            case /Dentist/i:
                return 'DEN';
            case /Disabled/i:
                return 'DIS';
            case /Doctor/i:
                return 'DR';
            case /Education/i:
                return 'EDU';
            case /Engineer/i:
                return 'ENG';
            case /Financial/i:
                return 'PAD';
            case /Government/i:
                return 'CRT';
            case /Health/i:
                return 'FIT';
            case /Homemaker/i:
                return 'HO';
            case /Hospitality/i:
                return 'HOT';
            case /Human/i:
                return 'PAY';
            case /Insurance/i:
                return 'IAB';
            case /Internet/i:
                return 'INT';
            case /Law Enforcement/i:
                return 'POL';
            case /Lawyer/i:
                return 'LAW';
            case /Legal/i:
                return 'LEGL';
            case /Management/i:
                return 'COT';
            case /Manager/i:
                return 'MGR';
            case /Manufacturing/i:
                return 'FAC';
            case /Marketing/i:
                return 'MKT';
            case /Military/i:
                return 'MI';
            case /Volunteer/i:
                return 'CS';
            case /Pharmaceutical/i:
                return 'PHR';
            case /Physician/i:
                return 'PHY';
            case /Professional Salaried/i:
                return 'SA';
            case /Professor/i:
                return 'PRO';
            case /Real Estate/i:
                return 'REA';
            case /Restaurant/i:
                return 'RSC';
            case /Retail/i:
                return 'RTS';
            case /Retired/i:
                return 'RET';
            case /Sales/i:
                return 'SAL';
            case /Self Employed/i:
                return 'SE';
            case /Scientist/i:
                return 'SC';
            case /Skilled/i:
                return 'SK';
            case /Student/i:
                return 'ST';
            case /Teacher/i:
                return 'SCT'
            case /Technology/i:
                return 'TECH';
            case /Telecommunications/i:
                return 'TEC';
            case /Transportation/i:
                return 'PTO';
            case /Unemployed/i:
                return 'UNEM';
            default:
                // return 'OTH';
                return 'SA';
        }
    }

    map_insco(insco) {
        switch (insco) {
            case /''/i:
                return '';
            default:
                return '';
        }
    }

    map_accident_code(desc) {
        switch (desc) {
            case 'Collided with another car':
                return 'ACC';
            case 'Rear-ended by another person':
                return 'REARMY';
            case 'Hit while stopped':
                return 'PARK';
            case 'Single car accident':
                return 'ACCMY';
            case 'Hit by another person':
                return 'PARK';
            default:
                return 'ACC';
        }
    }

    map_claim_type(desc) {
        switch (desc) {
            case 'Act of nature':
                return 'FHWD';
            case 'Car fire':
                return 'FIRE';
            case 'Flood damage':
                return 'FLOOD';
            case 'Hail damage':
                return 'HAIL';
            case 'Hit an animal':
                return 'ANIM';
            case 'Theft of stereo':
                return 'STER';
            case 'Theft of vehicle':
                return 'THEFT';
            case 'Towing service':
                return 'TOW';
            case 'Vandalism':
                return 'VAND';
            case 'Windshield replacement':
                return 'WD';
            default:
                return 'LC';
        }
    }

    map_accident_damage(damage_type) {
        switch (damage_type) {
            case 'Property':
                return 'Property';
            case 'People':
                return 'People';
            case 'Both':
                return 'Both';
            case 'No damage':
                return 'Not Applicable';
            default:
                return 'Property';
        }
    }

    map_ticket_code(ticket) {
        switch (ticket) {
            case 'Expired drivers license':
                return 'EXLIC';
            case 'Speeding more than 10 mph over':
                return 'SPEED10';
            case 'Speeding less than 10 mph over':
                return 'SPEEDOT';
            case 'Illegal turn':
                return 'TURN';
            case 'Failure to yield':
                return 'MYR';
            case 'Careless driving':
                return 'CARE';
            case 'Driving without a license':
                return 'NDL';
            case 'Following too close':
                return 'FOLL';
            case 'No Insurance':
                return 'MIN';
            case 'Failure to obey traffic signal':
                return 'TSIG';
            case 'Defective Equipment':
                return 'EQUIP';
            case 'Speeding more than 20 mph over':
                return 'SPEED20';
            case 'Illegal U-Turn':
                return 'UTURN';
            case 'Ran a stop sign':
                return 'FSSS';
            case 'Speeding':
                return 'SPEED'
            case 'Carpool lane violation':
                return 'CARP';
            case 'Reckless driving':
                return 'RECKL';
            case 'Failure to signal':
                return 'NOSIG';
            case 'Inattentive driving':
                return 'INATT';
            case 'Wrong way on a one way':
                return 'WW';
            case 'Child not in car seat':
                return 'CHILD';
            case 'Reckless endangerment':
                return 'SRWI';
            case 'Passing a school bus':
                return 'FTSSB';
            case 'Failure to stop':
                return 'FTS';
            case 'Driving too fast for conditions':
                return 'FAST';
            case 'No seatbelt':
                return 'MBV';
            case 'Illegal passing':
                return 'PASS';
            case 'Illegal lane change':
                return 'LANE';
            case 'Passing on shoulder':
                return 'SHO';
            case 'Defective vehicle':
                return 'DEFV';
            case 'Expired registration':
                return 'EXREG';
            case 'Ran a red light':
                return 'FSRL';
            case 'Illegal turn on red':
                return 'RTURN';
            case 'Expired emissions':
                return 'EXEMM';
            case 'Excessive noise':
                return 'NOISE';
            case 'Passing in a no-passing zone':
                return 'NOPASS';
            case 'Drug possession':
                return 'DPO';
            case 'Minor in possession':
                return 'MINOR';
            case 'Open container':
                return 'DOC';
            case 'DUI/DWAI':
                return 'DWI';
            case 'Exhibition driving':
                return 'RACE';
            default:
                return 'VIO';
        }
    }

    state_requested_coverage(state) {
        switch (state) {
            case 'AL':
                return {
                    'Minimum': [25000, 50000, 25000, 25000, 50000, null],
                    'Standard': [50000, 100000, 50000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            case 'AR':
                return {
                    'Minimum': [25000, 50000, 25000, 25000, 50000, 25000],
                    'Standard': [50000, 100000, 50000, 50000, 100000, 50000],
                    'Superior': [100000, 300000, 100000, 100000, 300000, 100000]
                };
            case 'AZ':
                return {
                    'Minimum': [15000, 30000, 10000, 15000, 30000, null],
                    'Standard': [50000, 100000, 25000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            case 'CA':
                return {
                    'Minimum': [15000, 30000, 5000],
                    'Standard': [50000, 100000, 25000],
                    'Superior': [100000, 300000, 100000]
                };
            case 'CO':
                return {
                    'Minimum': [25000, 50000, 15000, 25000, 50000, null],
                    'Standard': [50000, 100000, 50000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            case 'CT':
                return {
                    'Minimum': [25000, 50000, 25000, 25000, 50000, null],
                    'Standard': [50000, 100000, 50000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            case 'FL':
                return {
                    'Minimum': [10000, 20000, 10000, 10000, 20000, null],
                    'Standard': [50000, 100000, 50000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            case 'GA':
                return {
                    'Minimum': [25000, 50000, 25000, 25000, 50000, 25000],
                    'Standard': [50000, 100000, 50000, 50000, 100000, 50000],
                    'Superior': [100000, 300000, 100000, 100000, 300000, 100000]
                };
            case 'IA':
                return {
                    'Minimum': [20000, 40000, 15000, 20000, 40000, null],
                    'Standard': [50000, 100000, 50000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            case 'ID':
                return {
                    'Minimum': [25000, 50000, 15000, 25000, 50000, null],
                    'Standard': [50000, 100000, 50000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            case 'IL':
                return {
                    'Minimum': [25000, 50000, 20000, 25000, 50000, null],
                    'Standard': [50000, 100000, 50000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            case 'IN':
                return {
                    'Minimum': [25000, 50000, 25000, 25000, 50000, 25000],
                    'Standard': [50000, 100000, 50000, 50000, 100000, 50000],
                    'Superior': [100000, 300000, 100000, 100000, 300000, 100000]
                };
            case 'KY':
                return {
                    'Minimum': [25000, 50000, 25000, 25000, 50000, null],
                    'Standard': [50000, 100000, 50000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            case 'LA':
                return {
                    'Minimum': [15000, 30000, 25000, 15000, 30000, null],
                    'Standard': [50000, 100000, 50000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            case 'MD':
                return {
                    'Minimum': [30000, 60000, 15000, 30000, 60000, 15000],
                    'Standard': [50000, 100000, 50000, 50000, 100000, 50000],
                    'Superior': [100000, 300000, 100000, 100000, 300000, 100000]
                };
            case 'MN':
                return {
                    'Minimum': [30000, 60000, 10000, 30000, 60000, null],
                    'Standard': [50000, 100000, 50000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            case 'MO':
                return {
                    'Minimum': [25000, 50000, 10000, 25000, 50000, null],
                    'Standard': [50000, 100000, 50000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            case 'NE':
                return {
                    'Minimum': [25000, 50000, 25000, 25000, 50000, null],
                    'Standard': [50000, 100000, 50000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            case 'NJ':
                return {
                    'Minimum': [15000, 30000, 5000, 15000, 30000, 5000],
                    'Standard': [50000, 100000, 50000, 50000, 100000, 25000],
                    'Superior': [100000, 300000, 100000, 100000, 300000, 100000]
                };
            case 'NM':
                return {
                    'Minimum': [25000, 50000, 10000, 25000, 50000, 10000],
                    'Standard': [50000, 100000, 50000, 50000, 100000, 50000],
                    'Superior': [100000, 300000, 100000, 100000, 300000, 100000]
                };
            case 'OH':
                return {
                    'Minimum': [25000, 50000, 25000, 25000, 50000, null],
                    'Standard': [50000, 100000, 50000, 25000, 50000, null],
                    'Superior': [100000, 300000, 100000, 25000, 50000, null]
                };
            case 'OK':
                return {
                    'Minimum': [25000, 50000, 25000, 25000, 50000, null],
                    'Standard': [50000, 100000, 50000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            case 'OR':
                return {
                    'Minimum': [25000, 50000, 20000, 25000, 50000, null],
                    'Standard': [50000, 100000, 50000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            case 'SC':
                return {
                    'Minimum': [25000, 50000, 25000, 25000, 50000, 25000],
                    'Standard': [50000, 100000, 50000, 50000, 100000, 25000],
                    'Superior': [100000, 300000, 100000, 100000, 300000, 50000]
                };
            case 'SD':
                return {
                    'Minimum': [25000, 50000, 25000, 25000, 50000, null],
                    'Standard': [50000, 100000, 50000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            case 'TN':
                return {
                    'Minimum': [25000, 50000, 15000, 25000, 50000, 15000],
                    'Standard': [50000, 100000, 50000, 50000, 100000, 50000],
                    'Superior': [100000, 300000, 100000, 100000, 300000, 100000]
                };
            case 'TX':
                return {
                    'Minimum': [30000, 60000, 25000, 30000, 60000, 25000],
                    'Standard': [50000, 100000, 50000, 50000, 100000, 50000],
                    'Superior': [100000, 300000, 100000, 100000, 300000, 100000]
                };
            case 'UT':
                return {
                    'Minimum': [25000, 65000, 15000, 25000, 65000, null],
                    'Standard': [50000, 100000, 50000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            case 'VA':
                return {
                    'Minimum': [25000, 50000, 20000, 25000, 50000, 20000],
                    'Standard': [50000, 100000, 50000, 50000, 100000, 50000],
                    'Superior': [100000, 300000, 100000, 100000, 300000, 100000]
                };
            case 'WI':
                return {
                    'Minimum': [25000, 50000, 10000, 25000, 50000, null],
                    'Standard': [50000, 100000, 50000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            case 'WY':
                return {
                    'Minimum': [25000, 50000, 20000, 25000, 50000, null],
                    'Standard': [50000, 100000, 50000, 50000, 100000, null],
                    'Superior': [100000, 300000, 100000, 100000, 300000, null]
                };
            default:
                return {
                    'Minimum': [25000, 50000, 25000],
                    'Standard': [50000, 100000, 50000],
                    'Superior': [100000, 300000, 100000]
                };
        }
    }

    randBetween(min, max) {
        return Math.floor(
            Math.random() * (max - min) + min
        )
    }
}
