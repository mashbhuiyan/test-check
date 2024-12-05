const LeadCloudAuto = require('../lead_cloud/auto');
module.exports = class Auto extends LeadCloudAuto {
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
                SellerLeadPrice: this.getParam('clk_cost') || 0.6,
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
                License: {
                    LicenseStatus: this.map_license_status(driver.license_status),
                    AgeLicensed: driver.license_obtained_age || '16',
                    LicenseState: this.getParam('state')
                },
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
                Relationship: driver.relationship_to_contact,
                Accident: this.accidents(driver),
                Claim: this.claims(driver),
            });
            index += 1;
        }
        return mapped_drivers;
    }
}
