const Base = require('../base');
module.exports = class Auto extends Base {
    constructor(params) {
        super(params);
        this.params = params;
    }

    createAutoRequest() {
        return {
            AgencyInfo: this.agencyInfo(),
            PolicyInfo: this.policyInfo(),
            Drivers: this.drivers(),
            Vehicles: this.vehicles(),
            State: this.getParam('state'),
            Vendor: 'CON'
        }
    }

    agencyInfo() {
        return {
            AmsId: '1176547',
            Username: 'VendorLeadPass@sentry.com',
            Channel: 'DIRECT'
        }
    }

    policyInfo() {
        return {
            AddressLine1: this.getParam('address'),
            City: this.getParam('city'),
            EmailAddress: this.getParam('email'),
            PhoneNumber: this.getParam('primary_phone'),
            PhoneType: 'MOBILE',
            Product: 'NonStandardAuto',
            State: this.getParam('state'),
            ZipCode: this.getParam('zip')
        }
    }

    drivers() {
        let drivers = this.params.drivers || []
        let mapped_drivers = [];
        for (let driver of drivers) {
            mapped_drivers.push({
                DateOfBirth: this.formatDate(driver.date_of_birth),
                FirstName: driver.first_name,
                LastName: driver.last_name,
                Gender: this.mapGender(driver.gender),
                MaritalStatus: this.mapMaritalStatus(driver.marital_status),
                PNI: drivers.length === 1
            });
        }
        return mapped_drivers;
    }

    mapGender(gender) {
        switch (gender) {
            case 'Male':
                return 'MALE';
            case 'Female':
                return 'FEMALE';
            default:
                return 'NON_SPECIFIED'
        }
    }

    mapMaritalStatus(status) {
        switch (status) {
            case 'Single':
                return 'SINGLE';
            case 'Married':
                return 'MARRIED';
            case 'Separated':
                return 'DIVORCED';
            case 'Divorced':
                return 'DIVORCED';
            case 'Widowed':
                return 'WIDOWED';
            default:
                return 'SINGLE';
        }
    }

    vehicles() {
        let vehicles = this.params.vehicles || [];
        let mapped_vehicles = [];
        let index = 1;
        for (let vehicle of vehicles) {
            mapped_vehicles.push({
                VIN: vehicle.vin,
                Year: vehicle.year,
                Make: vehicle.make,
                Model: vehicle.model
            });
            index += 1;
        }
        return mapped_vehicles;
    }
}
