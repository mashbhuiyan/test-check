let responseMessage = '';
let params = {};
let responseObj = {};
let post = false;

module.exports = StrongParams = (req, res, next) => {
    params = req.body ? req.body.lead : {};
    post = params.post;
    responseObj = res;

    if (req.body.schema_validation_required && req.body.schema_validation_required === 'No') {
        return next();
    }

    if (post && !req.body.ping_id) {
        requiredResponse('ping_id');
        return response();
    }

    if (!isParamsValid()) {
        return response();
    }

    next();
};

function isParamsValid() {
    if (!params.lead_type_id) {
        return requiredResponse('lead_type_id');
    }
    if (typeof (params.lead_type_id) !== 'number') {
        return invalidResponse('lead_type_id');
    }

    return isLeadParamsValid();
}

function isLeadParamsValid() {
    if (!isCommonParamsValid()) {
        return false;
    }
    switch (params.lead_type_id) {
        case 6: // Auto
            return isAutoParamsValid();
        case 1: // Home
            return isHomeParamsValid();
        case 4: // Renters
            return isRentersParamsValid();
        case 3: // Health
            return isHealthParamsValid();
        case 2: // Life
            return isLifeParamsValid();
        case 7: // Medicare
            return isMedicareParamsValid();
        case 5: // Commercial
            return isCommercialParamsValid();
    }

    return false;
}

function isCommonParamsValid() {
    if (!params.jornaya_lead_id) {
        return requiredResponse('jornaya_lead_id');
    }
    if (!params.trusted_form_token) {
        return requiredResponse('trusted_form_token');
    }
    if (!params.contact) {
        return requiredResponse('contact');
    }
    if (!params.contact.zip) {
        return requiredResponse('contact.zip');
    }
    if (!isValidZipCode(params.contact.zip)) {
        return invalidResponse('contact.zip');
    }
    if (post) {
        if (!params.contact.first_name) {
            return requiredResponse('contact.first_name');
        }
        if (!params.contact.last_name) {
            return requiredResponse('contact.last_name');
        }
        if (!params.contact.address) {
            return requiredResponse('contact.address');
        }
        if (!params.contact.city) {
            return requiredResponse('contact.city');
        }
        if (!params.contact.state) {
            return requiredResponse('contact.state');
        }
        if (!params.contact.email) {
            return requiredResponse('contact.email');
        }
        if (!params.contact.primary_phone) {
            return requiredResponse('contact.primary_phone');
        }
        if (params.contact.primary_phone.length < 10) {
            return invalidResponse('contact.primary_phone');
        }
    }

    return true;
}

function isAutoParamsValid() {
    if (!customerProfileParamsValid()) {
        return false;
    }
    if (!driverParamsValid()) {
        return false;
    }
    if (!['Yes', 'No'].includes(params.multiple_vehicles)) {
        return requiredResponse('multiple_vehicles');
    }
    if (!vehicleParamsValid()) {
        return false;
    }
    if (!coverageParamsValid()) {
        return false;
    }
    if (!params.requested_coverage) {
        return requiredResponse('requested_coverage');
    }

    return tcpaParamsValid();
}

function isHomeParamsValid() {
    if (!homeCustomerProfileParamsValid()) {
        return false;
    }
    if (!homeInfoParamsValid()) {
        return false;
    }
    if (!coverageParamsValid()) {
        return false;
    }

    return tcpaParamsValid();
}

function isRentersParamsValid() {
    return isHomeParamsValid();
}

function isHealthParamsValid() {
    if (!params.applicant_info) {
        return requiredResponse('applicant_info');
    }
    if (!params.medical_history) {
        return requiredResponse('medical_history');
    }
    if (!coverageParamsValid()) {
        return false;
    }
    if (!params.requested_coverage) {
        return requiredResponse('requested_coverage');
    }
    if (!["Individual Family", "Short Term", "Medicare Supplement", "COBRA", "Discount Plan", "Medicaid", "Maternity Only", "Dental Only", "Vision Only", "Prescription Only"].includes(params.requested_coverage)) {
        return invalidResponse('requested_coverage');
    }

    return tcpaParamsValid();
}

function isLifeParamsValid() {
    if (!params.applicant_info) {
        return requiredResponse('applicant_info');
    }
    if (!params.medical_history) {
        return requiredResponse('medical_history');
    }
    if (!coverageParamsValid()) {
        return false;
    }
    if (!params.requested_coverage) {
        return requiredResponse('requested_coverage');
    }

    return tcpaParamsValid();
}

function isMedicareParamsValid() {
    if (!params.applicant_info) {
        return requiredResponse('applicant_info');
    }
    if (!params.medical_history) {
        return requiredResponse('medical_history');
    }
    if (![true, false].includes(params.currently_insured)) {
        return requiredResponse('currently_insured');
    }
    if (!params.requested_coverage) {
        return requiredResponse('requested_coverage');
    }

    return tcpaParamsValid();
}

function isCommercialParamsValid() {
    if (!businessInfoParamsValid()) {
        return false;
    }
    if (!coverageParamsValid()) {
        return false;
    }
    if (!params.requested_coverage) {
        return requiredResponse('requested_coverage');
    }

    return tcpaParamsValid();
}

function businessInfoParamsValid() {
    if (!params.business_info) {
        return requiredResponse('business_info');
    }
    if (post) {
        if (!params.business_info.business_name) {
            return requiredResponse('business_info.business_name');
        }
        if (!params.business_info.business_address) {
            return requiredResponse('business_info.business_address');
        }
        if (!params.business_info.business_city) {
            return requiredResponse('business_info.business_city');
        }
        if (!params.business_info.business_state) {
            return requiredResponse('business_info.business_state');
        }
        if (!params.business_info.business_zip) {
            return requiredResponse('business_info.business_zip');
        }
        if (!isValidZipCode(params.business_info.business_zip)) {
            return invalidResponse('business_info.business_zip');
        }
    }

    return true;
}

function coverageParamsValid() {
    if (![true, false].includes(params.currently_insured)) {
        return requiredResponse('currently_insured');
    }
    if (params.currently_insured) {
        if (!params.current_coverage) {
            return requiredResponse('current_coverage');
        }
        if (!params.current_coverage.carrier) {
            return requiredResponse('current_coverage.carrier');
        }
        if (!params.current_coverage.expiration_date) {
            return requiredResponse('current_coverage.expiration_date');
        }
        if (!isValidDate(params.current_coverage.expiration_date)) {
            return invalidResponse('current_coverage.expiration_date');
        }
        if (!params.current_coverage.coverage_years) {
            if (params.current_coverage.coverage_years !== 0) {
                return requiredResponse('current_coverage.coverage_years');
            }
        }
    }

    return true;
}

function customerProfileParamsValid() {
    if (!params.customer_profile) {
        return requiredResponse('customer_profile');
    }
    if (!params.customer_profile.gender) {
        return requiredResponse('customer_profile.gender');
    }
    if (!['Male', 'Female', 'Non-binary'].includes(params.customer_profile.gender)) {
        return invalidResponse('customer_profile.gender');
    }
    if (!params.customer_profile.marital_status) {
        return requiredResponse('customer_profile.marital_status');
    }
    if (!['Married', 'Single', 'Divorced', 'Widowed'].includes(params.customer_profile.marital_status)) {
        return invalidResponse('customer_profile.marital_status');
    }
    if (!params.customer_profile.residence) {
        return requiredResponse('customer_profile.residence');
    }
    if (!params.customer_profile.residence.years) {
        return requiredResponse('customer_profile.residence.years');
    }
    if (!params.customer_profile.residence.own) {
        return requiredResponse('customer_profile.residence.own');
    }
    if (!['Own', 'Rent', 'Other', 'HotelMotel'].includes(params.customer_profile.residence.own)) {
        return invalidResponse('customer_profile.residence.own');
    }
    if (!params.customer_profile.credit) {
        return requiredResponse('customer_profile.credit');
    }
    if (!['Good', 'Average', 'Poor', 'Excellent'].includes(params.customer_profile.credit)) {
        return invalidResponse('customer_profile.credit');
    }
    if (![true, false].includes(params.customer_profile.bankruptcy)) {
        return requiredResponse('customer_profile.bankruptcy');
    }
    if (!params.customer_profile.date_of_birth) {
        return requiredResponse('customer_profile.date_of_birth');
    }
    if (!isValidDate(params.customer_profile.date_of_birth)) {
        return invalidResponse('customer_profile.date_of_birth');
    }
    if (![true, false].includes(params.customer_profile.military_affiliation)) {
        return requiredResponse('customer_profile.military_affiliation');
    }

    return true;
}

function homeCustomerProfileParamsValid() {
    if (!params.customer_profile) {
        return requiredResponse('customer_profile');
    }
    if (!params.customer_profile.gender) {
        return requiredResponse('customer_profile.gender');
    }
    if (!['Male', 'Female', 'Non-binary'].includes(params.customer_profile.gender)) {
        return invalidResponse('customer_profile.gender');
    }
    if (!params.customer_profile.marital_status) {
        return requiredResponse('customer_profile.marital_status');
    }
    if (!['Married', 'Single', 'Divorced', 'Widowed'].includes(params.customer_profile.marital_status)) {
        return invalidResponse('customer_profile.marital_status');
    }
    if (!params.customer_profile.credit) {
        return requiredResponse('customer_profile.credit');
    }
    if (!['Good', 'Average', 'Poor', 'Excellent'].includes(params.customer_profile.credit)) {
        return invalidResponse('customer_profile.credit');
    }
    if (!params.customer_profile.date_of_birth) {
        return requiredResponse('customer_profile.date_of_birth');
    }
    if (!isValidDate(params.customer_profile.date_of_birth)) {
        return invalidResponse('customer_profile.date_of_birth');
    }

    return true;
}

function driverParamsValid() {
    if (!params.drivers || !Array.isArray(params.drivers)) {
        return requiredResponse('drivers');
    }
    for (let i = 0; i < params.drivers.length; ++i) {
        const driver = params.drivers[i];
        const dRes = `drivers.${i}.`;
        if (!driver.driver_id) {
            return requiredResponse(dRes + 'driver_id');
        }
        if (!driver.license_status) {
            return requiredResponse(dRes + 'license_status');
        }
        if (!['Active', 'Suspended', 'Learner', 'International', 'Restricted', 'Temporary', 'Probation', 'Prob/Negl'].includes(driver.license_status)) {
            return invalidResponse(dRes + 'license_status');
        }
        if (!driver.license_state) {
            return requiredResponse(dRes + 'license_state');
        }
        if (driver.license_state.length !== 2) {
            return invalidResponse(dRes + 'license_state');
        }
        if (!driver.license_obtained_age) {
            return requiredResponse(dRes + 'license_obtained_age');
        }
        if (![true, false].includes(driver.license_ever_suspended_or_revoked)) {
            return requiredResponse(dRes + 'license_ever_suspended_or_revoked');
        }
        if (![true, false].includes(driver.sr22_required)) {
            return requiredResponse(dRes + 'sr22_required');
        }
        if (!driver.gender) {
            return requiredResponse(dRes + 'gender');
        }
        if (!['Male', 'Female', 'Non-binary'].includes(driver.gender)) {
            return invalidResponse(dRes + 'gender');
        }
        if (!driver.date_of_birth) {
            return requiredResponse(dRes + 'date_of_birth');
        }
        if (!isValidDate(driver.date_of_birth)) {
            return invalidResponse(dRes + 'date_of_birth');
        }
        if (!driver.marital_status) {
            return requiredResponse(dRes + 'marital_status');
        }
        if (!['Married', 'Single', 'Divorced', 'Widowed'].includes(driver.marital_status)) {
            return invalidResponse(dRes + 'marital_status');
        }
        if (!driver.occupation) {
            return requiredResponse(dRes + 'occupation');
        }
        if (!['Retired', 'Disabled', 'OtherNonTechnical', 'SelfEmployed', 'ManagerSupervisor', 'OtherTechnical', 'AdministrativeClerical', 'Unemployed', 'SkilledSemiSkilled', 'BusinessOwner', 'ConstructionTrades', 'ProfessionalSalaried', 'Homemaker', 'Retail', 'SalesInside', 'SchoolTeacher', 'SalesOutside', 'Engineer', 'Student', 'Clergy', 'Physician', 'MinorNotApplicable', 'Lawyer', 'CertifiedPublicAccountant', 'Professor', 'Architect', 'Dentist', 'MilitaryEnlisted', 'Scientist', 'MilitaryOfficer'].includes(driver.occupation)) {
            return invalidResponse(dRes + 'occupation');
        }
        if (!driver.education) {
            return requiredResponse(dRes + 'education');
        }
        if (!["SomeCollege", "HighSchoolDiploma", "BachelorsDegree", "AssociateDegree", "GED", "SomeOrNoHighSchool", "MastersDegree", "TradeVocationalSchool", "DoctorateDegree", "OtherProfessionalDegree", "OtherNonProfessionalDegree"].includes(driver.education)) {
            return invalidResponse(dRes + 'education');
        }
        if (!driver.relationship_to_contact) {
            return requiredResponse(dRes + 'relationship_to_contact');
        }
        if (!["Applicant", "Spouse", "Child", "Other", "Parent", "Sibling", "Grandchild", "Grandparent"].includes(driver.relationship_to_contact)) {
            return invalidResponse(dRes + 'relationship_to_contact');
        }
        if (post) {
            if (!driver.first_name) {
                return requiredResponse(dRes + 'first_name');
            }
            if (!driver.last_name) {
                return requiredResponse(dRes + 'last_name');
            }
        }
    }

    return true;
}

function vehicleParamsValid() {
    if (!params.vehicles || !Array.isArray(params.vehicles)) {
        return requiredResponse('vehicles');
    }
    for (let i = 0; i < params.vehicles.length; ++i) {
        const vehicle = params.vehicles[i];
        const vRes = `vehicles.${i}.`;
        if (!vehicle.vehicle_id) {
            return requiredResponse(vRes + 'vehicle_id');
        }
        if (!vehicle.vin) {
            return requiredResponse(vRes + 'vin');
        }
        if (!vehicle.year) {
            return requiredResponse(vRes + 'year');
        }
        if (!vehicle.make) {
            return requiredResponse(vRes + 'make');
        }
        if (!vehicle.model) {
            return requiredResponse(vRes + 'model');
        }
        if (!vehicle.submodel) {
            return requiredResponse(vRes + 'submodel');
        }
        if (!vehicle.primary_use) {
            return requiredResponse(vRes + 'primary_use');
        }
        if (!["Business", "Commute", "Farm", "Pleasure"].includes(vehicle.primary_use)) {
            return invalidResponse(vRes + 'primary_use');
        }
        if (!vehicle.garage_type) {
            return requiredResponse(vRes + 'garage_type');
        }
        if (!["Carport", "Driveway", "ParkingGarage", "ParkingLot", "PrivateGarage", "Street"].includes(vehicle.garage_type)) {
            return invalidResponse(vRes + 'garage_type');
        }
        if (![true, false].includes(vehicle.parked_at_mailing_address)) {
            return requiredResponse(vRes + 'parked_at_mailing_address');
        }
        if (!vehicle.ownership) {
            return requiredResponse(vRes + 'ownership');
        }
        if (!["Owned", "Financed", "Leased"].includes(vehicle.ownership)) {
            return invalidResponse(vRes + 'ownership');
        }

        if (!vehicle.parked_at_mailing_address) {
            if (!vehicle.garaging_address) {
                return requiredResponse(vRes + 'garaging_address');
            }
            if (!vehicle.garaging_city) {
                return requiredResponse(vRes + 'garaging_city');
            }
            if (!vehicle.garaging_state) {
                return requiredResponse(vRes + 'garaging_state');
            }
            if (!vehicle.garaging_zip_code) {
                return requiredResponse(vRes + 'garaging_zip_code');
            }
            if (!isValidZipCode(vehicle.garaging_zip_code)) {
                return invalidResponse(vRes + 'garaging_zip_code');
            }
        }
    }

    return true;
}

function tcpaParamsValid() {
    if (!params.tcpa) {
        return requiredResponse('tcpa');
    }
    if (![true, false].includes(params.tcpa.call_consent)) {
        return requiredResponse('tcpa.call_consent');
    }
    if (![true, false].includes(params.tcpa.sms_consent)) {
        return requiredResponse('tcpa.sms_consent');
    }
    if (![true, false].includes(params.tcpa.email_consent)) {
        return requiredResponse('tcpa.email_consent');
    }
    if (!params.tcpa.text) {
        return requiredResponse('tcpa.text');
    }

    return true;
}

function homeInfoParamsValid() {
    if (!params.home_info) {
        return requiredResponse('home_info');
    }
    if (!params.home_info.state) {
        return requiredResponse('home_info.state');
    }
    if (!params.home_info.zip) {
        return requiredResponse('home_info.zip');
    }
    if (!isValidZipCode(params.home_info.zip)) {
        return invalidResponse('home_info.zip');
    }
    if (!params.home_info.square_footage) {
        return requiredResponse('home_info.square_footage');
    }
    if (!params.home_info.num_stories) {
        return requiredResponse('home_info.num_stories');
    }
    if (!["1", "2", "3", "4+"].includes(params.home_info.num_stories)) {
        return invalidResponse('home_info.num_stories');
    }
    if (!params.home_info.year_built) {
        return requiredResponse('home_info.year_built');
    }
    if (!params.home_info.property_type) {
        return requiredResponse('home_info.property_type');
    }
    if (!["Single Family Home", "Multi Family Home", "Townhome", "Condominium", "Duplex", "Mobile Home", "Apartment"].includes(params.home_info.property_type)) {
        return invalidResponse('home_info.property_type');
    }
    if (!params.home_info.num_bedrooms) {
        return requiredResponse('home_info.num_bedrooms');
    }
    if (!params.home_info.num_bathrooms) {
        return requiredResponse('home_info.num_bathrooms');
    }
    if (!params.home_info.occupancy) {
        return requiredResponse('home_info.occupancy');
    }
    if (!["Primary Residence", "Seasonal Residence", "Vacation Property", "Rental Property"].includes(params.home_info.occupancy)) {
        return requiredResponse('home_info.occupancy');
    }
    if (!params.home_info.garage) {
        return requiredResponse('home_info.garage');
    }
    if (!["AttachedOneCar", "AttachedTwoCar", "AttachedThreeCar", "AttachedFourCar", "DetachedOneCar", "DetachedTwoCar", "DetachedThreeCar", "DetachedFourCar", "Carport", "NoGarage", "Other"].includes(params.home_info.garage)) {
        return requiredResponse('home_info.garage');
    }
    if (post) {
        if (!params.home_info.address) {
            return requiredResponse('home_info.address');
        }
    }

    return true;
}


function invalidResponse(invalidField) {
    responseMessage = `Invalid ${invalidField}`;
    return false;
}

function requiredResponse(requiredField) {
    responseMessage = `Field ${requiredField} is required`;
    return false;
}

function response() {
    return responseObj.status(422).json({
        success: false,
        error: responseMessage
    });
}

function isValidDate(dateString) {
    const regEx = /^\d{2}\/\d{2}\/\d{4}$/;
    if (!dateString.match(regEx)) return false;
    const d = new Date(dateString);
    const dNum = d.getTime();
    return !(!dNum && dNum !== 0);
}

function isValidZipCode(zipCode) {
    return zipCode.replace(/[^\d]/, '').length === 5;
}
