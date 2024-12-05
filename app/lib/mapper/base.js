const Utils = require('../../models/utils');
const flatten = require("flat");
module.exports = class Base {
    constructor(params) {
        this.f_params = flatten(params);
    }

    getParam(name) {
        return Utils.getParam(this.f_params, name);
    }

    // format date to 'YYYY-mm-dd'
    formatDate(date) {
        try {
            date = new Date(date);
            return date.toISOString().slice(0,10);
        } catch (e) {
            console.error('date parse error: ', e.message);
            return '';
        }
    }
}
