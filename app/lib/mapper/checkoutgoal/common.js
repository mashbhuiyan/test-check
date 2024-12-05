module.exports = class CommonMapper {
    static mapGender(gender) {
        return gender === 'Non Binary' ? 'Non-binary' : gender;
    }

    static mapMaritalStatus(status) {
        return status === 'Married' ? 'Yes' : 'No';
    }
}
