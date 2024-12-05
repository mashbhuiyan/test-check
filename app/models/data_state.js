const ErrorHandler = require("./error_handler");
const errorHandler = new ErrorHandler();

module.exports = class DataState {
    auto_required_fields = [
        'ip_address',
        'lead_type_id',
        'device_type',
        'user_agent',
        'traffic_tier',
        'submission_url',
        'contact.first_name',
        'contact.last_name',
        'contact.address',
        'contact.city',
        'contact.state',
        'contact.zip',
        'contact.county',
        'contact.primary_phone',
        'contact.email',
        'customer_profile.gender',
        'customer_profile.marital_status',
        'customer_profile.residence.own',
        'customer_profile.credit',
        'customer_profile.bankruptcy',
        'customer_profile.date_of_birth',
        'multiple_vehicles',
        'currently_insured',
        'current_coverage.carrier',
        'current_coverage.expiration_date',
        'current_coverage.coverage_years',
        'current_coverage.bodily_injury',
        'military_affiliation',
        'bundle_home',
        'post',
        'source_type_id',
        'dupe_days_lead_modifier',
        'dupe_days_click_modifier',
        'dupe_days_call_modifier',
        'own_home',
        'num_drivers',
        'num_violations',
        'num_accidents',
        'has_accident',
        'num_vehicles'
    ];

    driver_required_fields = ['first_name', 'last_name', 'license_status',
        'license_obtained_age', 'license_ever_suspended_or_revoked', 'sr22_required',
        'gender', 'date_of_birth', 'marital_status', 'occupation', 'education',
        'relationship_to_contact'];

    vehicle_required_fields = ['vin', 'year', 'make', 'model',
        'submodel', 'primary_use', 'garage_type', 'ownership'];

    home_required_fields = [
        'ip_address',
        'lead_type_id',
        'device_type',
        'user_agent',
        'traffic_tier',
        'submission_url',
        'contact.first_name',
        'contact.last_name',
        'contact.address',
        'contact.city',
        'contact.state',
        'contact.zip',
        'contact.county',
        'contact.primary_phone',
        'contact.email',
        'customer_profile.gender',
        'customer_profile.marital_status',
        'customer_profile.credit',
        'customer_profile.date_of_birth',
        'home_info.address',
        'home_info.city',
        'home_info.state',
        'home_info.zip',
        'home_info.square_footage',
        'home_info.num_stories',
        'home_info.year_built',
        'home_info.property_type',
        'home_info.num_bedrooms',
        'home_info.num_bathrooms',
        'home_info.garage',
        'home_info.construction_type',
        'home_info.foundation_type',
        'home_info.roof_type',
        'home_info.roof_age',
        'home_info.purchase_dt',
        'home_info.num_residents',
        'home_info.new_purchase',
        'home_info.interior_wall_type',
        'home_info.exterior_wall_type',
        'home_info.wiring_type',
        'home_info.heating_type',
        'home_info.electric_type',
        'home_info.burglar_alarm',
        'home_info.fire_alarm',
        'home_info.smoke_alarm',
        'home_info.flood_zone',
        'currently_insured',
        'current_coverage.carrier',
        'current_coverage.expiration_date',
        'current_coverage.coverage_years',
        'post',
        'source_type_id',
        'dupe_days_lead_modifier',
        'dupe_days_click_modifier',
        'dupe_days_call_modifier',
        'property_age',
        'has_accident'
    ];

    health_required_fields = [
        'ip_address',
        'lead_type_id',
        'device_type',
        'user_agent',
        'traffic_tier',
        'submission_url',
        'contact.first_name',
        'contact.last_name',
        'contact.address',
        'contact.city',
        'contact.state',
        'contact.zip',
        'contact.county',
        'contact.primary_phone',
        'contact.email',
        'applicant_info.gender',
        'applicant_info.marital_status',
        'applicant_info.credit',
        'applicant_info.date_of_birth',
        'applicant_info.num_children',
        'applicant_info.household_income',
        'applicant_info.height_ft',
        'applicant_info.height_in',
        'applicant_info.weight',
        'applicant_info.tobacco',
        'applicant_info.occupation',
        'applicant_info.qualifying_life_event',
        'applicant_info.expectant',
        'applicant_info.dui',
        'medical_history.heart_disease',
        'medical_history.cancer',
        'medical_history.medications',
        'medical_history.med_list',
        'medical_history.medical_treatment',
        'medical_history.hospitalized',
        'medical_history.pre_existing_condition',
        'currently_insured',
        'current_coverage.carrier',
        'current_coverage.expiration_date',
        'current_coverage.coverage_years',
        'requested_coverage',
        'post',
        'source_type_id',
        'dupe_days_lead_modifier',
        'dupe_days_click_modifier',
        'dupe_days_call_modifier',
        'has_accident'
    ];

    // prefix dependents.0.
    health_dependents_req_fields = [
        'first_name',
        'last_name',
        'dependent_type',
        'date_of_birth',
        'gender',
        'height_ft',
        'height_in',
        'weight',
        'tobacco'
    ];

    life_required_fields = [
        'ip_address',
        'lead_type_id',
        'device_type',
        'user_agent',
        'traffic_tier',
        'submission_url',
        'contact.first_name',
        'contact.last_name',
        'contact.address',
        'contact.city',
        'contact.state',
        'contact.zip',
        'contact.county',
        'contact.primary_phone',
        'contact.email',
        'applicant_info.gender',
        'applicant_info.marital_status',
        'applicant_info.credit',
        'applicant_info.date_of_birth',
        'applicant_info.height_ft',
        'applicant_info.height_in',
        'applicant_info.weight',
        'applicant_info.tobacco',
        'applicant_info.occupation',
        'applicant_info.dui',
        'medical_history.heart_disease',
        'medical_history.cancer',
        'medical_history.medications',
        'medical_history.med_list',
        'medical_history.medical_treatment',
        'medical_history.hospitalized',
        'medical_history.pre_existing_condition',
        'currently_insured',
        'current_coverage.carrier',
        'current_coverage.expiration_date',
        'current_coverage.coverage_years',
        'requested_coverage.coverage_type',
        'requested_coverage.coverage_amount',
        'post',
        'source_type_id',
        'dupe_days_lead_modifier',
        'dupe_days_click_modifier',
        'dupe_days_call_modifier',
        'has_accident'
    ];

    medicare_required_fields = [
        'click_id',
        'ip_address',
        'lead_type_id',
        'device_type',
        'user_agent',
        'traffic_tier',
        'submission_url',
        'contact.first_name',
        'contact.last_name',
        'contact.address',
        'contact.city',
        'contact.state',
        'contact.zip',
        'contact.county',
        'contact.primary_phone',
        'contact.email',
        'applicant_info.date_of_birth',
        'applicant_info.gender',
        'applicant_info.marital_status',
        'post',
        'source_type_id',
        'dupe_days_lead_modifier',
        'dupe_days_click_modifier',
        'dupe_days_call_modifier',
        'has_accident'
    ];

    commercial_required_fields = [
        'ip_address',
        'lead_type_id',
        'device_type',
        'user_agent',
        'traffic_tier',
        'submission_url',
        'contact.first_name',
        'contact.last_name',
        'contact.address',
        'contact.city',
        'contact.state',
        'contact.zip',
        'contact.county',
        'contact.primary_phone',
        'contact.email',
        'business_info.business_name',
        'business_info.legal_entity',
        'business_info.business_address',
        'business_info.business_city',
        'business_info.business_state',
        'business_info.business_zip',
        'business_info.business_desc',
        'business_info.years_in_business',
        'business_info.number_of_partners',
        'business_info.full_time_employees',
        'business_info.part_time_employees',
        'business_info.annual_revenue',
        'business_info.annual_payroll',
        'business_info.commercial_coverage_types.0.general_liability',
        'business_info.commercial_coverage_types.0.liability_coverage',
        'business_info.commercial_coverage_types.1.commercial_auto',
        'business_info.commercial_coverage_types.2.Commercial_property',
        'business_info.commercial_coverage_types.3.professional_liability',
        'business_info.commercial_coverage_types.4.directors_liability',
        'business_info.commercial_coverage_types.5.business_owners_package_policy',
        'business_info.commercial_coverage_types.6.workers_comp',
        'business_info.commercial_coverage_types.7.commercial_crime',
        'currently_insured',
        'current_coverage.carrier',
        'current_coverage.expiration_date',
        'current_coverage.coverage_years',
        'sub1',
        'post',
        'source_type_id',
        'dupe_days_lead_modifier',
        'dupe_days_click_modifier',
        'dupe_days_call_modifier',
        'has_accident',
        'commercial_coverage'
    ];

    // the required fields are same for both lead type (home and renters)
    renters_required_fields = this.home_required_fields;

    async checkLeadData(f_params, xml) {
        let isEmailPresent = true;
        let isPhonePresent = true;
        let missing_fields = [];
        let data_state = {};
        let required_fields = [];
        let lead_type_id = f_params['lead_type_id'];

        switch (lead_type_id) {
            case 1: // Home
                required_fields = this.home_required_fields;
                break;
            case 2: // Life
                required_fields = this.life_required_fields;
                break;
            case 3: // Health
                required_fields = this.health_required_fields;
                break;
            case 4: // Renters
                required_fields = this.renters_required_fields;
                break;
            case 5: // Commercial
                required_fields = this.commercial_required_fields;
                break;
            case 7: // Medicare
                required_fields = this.medicare_required_fields;
                break;
            default: // Auto
                required_fields = this.auto_required_fields;
                break;
        }

        let total_missing_fields = 0;
        let total_required_fields = required_fields.length;
        let currently_insured = f_params['currently_insured'] === 'Yes';

        for (let r = 0; r < total_required_fields; r++) {
            let field = required_fields[r];
            let req_field = f_params[`${field}`];

            if (field.includes('current_coverage')) {
                if (currently_insured) {
                    if (await this.isMissing(req_field)) {
                        missing_fields.push(`${field}`);
                        total_missing_fields++;
                    }
                }
            } else if (await this.isMissing(req_field)) {
                if (field === 'contact.email') {
                    isEmailPresent = false;
                }
                if (field === 'contact.primary_phone') {
                    isPhonePresent = false;
                }
                missing_fields.push(`${field}`);
                total_missing_fields++;
            }
        }

        // auto lead: checking nested drivers and vehicles
        if (lead_type_id === 6) {
            let driver_data_state = await this.checkDrivers(xml);
            let vehicle_data_state = await this.checkVehicles(xml);
            total_required_fields += driver_data_state['total_required_fields'] + vehicle_data_state['total_required_fields'];
            total_missing_fields += driver_data_state['total_missing_fields'] + vehicle_data_state['total_missing_fields'];
            missing_fields.push(driver_data_state['missing_fields']);
            missing_fields.push(vehicle_data_state['missing_fields']);
        }
        // health lead: checking nested dependents
        else if (lead_type_id === 3) {
            let dependents_data_state = await this.checkDependents(xml);
            total_required_fields += dependents_data_state['total_required_fields'];
            total_missing_fields += dependents_data_state['total_missing_fields'];
            missing_fields.push(dependents_data_state['missing_fields']);
        }

        data_state['total_required_fields'] = total_required_fields;
        data_state['total_missing_fields'] = total_missing_fields;
        data_state['missing_fields'] = missing_fields;
        data_state['isEmailPresent'] = isEmailPresent;
        data_state['isPhonePresent'] = isPhonePresent;
        return data_state;
    }

    async prepareDataState(f_params, xml) {
        const state = {
            full_data: false,
            prefill_perc: 0,
            pii: false,
            missing_fields: ''
        };
        try {
            let data_state = await this.checkLeadData(f_params, xml);
            // let total_required_fields = data_state['total_required_fields'] || 0;
            let total_missing_fields = data_state['total_missing_fields'] || 0;
            state.full_data = total_missing_fields <= 0;
            // state.prefill_perc = total_missing_fields > 0 ? 100 - Math.ceil((100 / total_required_fields) * total_missing_fields) : 100;
            state.prefill_perc = xml.prefill_perc;
            state.pii = data_state['isEmailPresent'] && data_state['isPhonePresent'];
            state.missing_fields = (data_state['missing_fields'] ? data_state['missing_fields'].flat() : data_state['missing_fields']).join(', ');
        } catch (ex) {
            console.log('Exception from prepareDataState: ex = ', ex.message);
            state.missing_fields = `${ex.message}`;
        }
        return state;
    }

    async checkDrivers(params) {
        let objects = params.drivers || [];
        return await this.checkArrayObjects('drivers', objects, this.driver_required_fields);
    }

    async checkDependents(params) {
        let objects = params.dependents || [];
        return await this.checkArrayObjects('dependents', objects, this.health_dependents_req_fields);
    }

    async checkVehicles(params) {
        let objects = params.vehicles || [];
        return await this.checkArrayObjects('vehicles', objects, this.vehicle_required_fields);
    }

    async checkArrayObjects(type, objects, required_fields) {
        let missing_fields = [];
        let total_required_fields = required_fields.length;
        let idx = 0;
        for (let object of objects) {
            for (let d = 0; d < total_required_fields; d++) {
                if (await this.isMissing(object[`${required_fields[d]}`])) {
                    missing_fields.push(`${type}.${idx}.${required_fields[d]}`);
                }
            }
            idx++;
        }
        //when there are multiple objects like multiple drivers, vehicles or dependents
        if (objects.length > 0) {
            total_required_fields = total_required_fields * objects.length;
        }
        let data_state = {};
        data_state['total_required_fields'] = total_required_fields;
        data_state['total_missing_fields'] = missing_fields.length;
        data_state['missing_fields'] = missing_fields;
        return data_state;
    }

    async isMissing(field) {
        return (field === undefined || field === '' || field === null);
    }

}
