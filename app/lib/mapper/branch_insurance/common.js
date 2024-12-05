module.exports = class CommonMapper {
    static mapGender(gender) {
        return gender === 'Male' ? 'MALE' : 'FEMALE'
    }

    static mapMaritalStatus(status) {
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
            case 'Domestic':
                return 'DOMESTICPARTNER';
            default:
                return 'SINGLE';
        }
    }
}
