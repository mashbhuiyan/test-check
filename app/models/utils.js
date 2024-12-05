const Util = require("util");
const flatten = require('flat');
module.exports = class Utils {
    static getParam(obj, k) {
        let vals = Object.keys(obj).filter(function (c) {
            return c.split(".").indexOf(k) !== -1;
        });
        if (vals.length > 0) {
            return typeof (obj[vals[0]]) == 'undefined' ? '' : obj[vals[0]];
        } else {
            return '';
        }
    }

    static getAge(obj) {
        let dob = Utils.getParam(obj, 'date_of_birth');
        if (dob) {
            let to_date = new Date(dob);
            if (isNaN(to_date)) {
                return 0;
            } else {
                return Utils.getAgeFromDate(to_date);
            }
        } else {
            return 0;
        }
    }

    static getAgeFromDate(dob) {
        let today = new Date();
        let age = today.getFullYear() - dob.getFullYear();
        let m = today.getMonth() - dob.getMonth();
        if (m < 0 || (m === 0 && today.getDate() < dob.getDate())) {
            age--;
        }
        return age < 0 ? 0 : age;
    }

    static parseToFloat(stringNumber) {
        if (typeof (stringNumber) === 'string') {
            return parseFloat(stringNumber.replace(/[^\d.-]/g, ''));
        } else {
            return parseFloat(stringNumber);
        }
    }

    static toLowerCase(value) {
        if (typeof (value) == 'string') {
            return value.toLowerCase();
        } else {
            return value;
        }
    }

    static findNestedObj(entireObj, keys, full_json) {
        try {
            if (full_json) {
                return entireObj;
            } else {
                let flatten_obj = this.flattenJSON(entireObj);
                let extracted_json = this.findKeyValueNestedObj(entireObj, keys);
                let plain_json = {};
                for (let key of keys) {
                    let dot_notation = key.split('.');
                    if (dot_notation.length > 1) {
                        plain_json[key] = flatten_obj[key];
                    } else {
                        plain_json[key] = extracted_json[key];
                    }
                }
                return plain_json;
            }
        } catch (ex) {
            console.log('findNestedObj: ', ex.message);
            return entireObj;
        }
    }

    static findKeyValueNestedObj(entireObj, keys, plain_json = {}) {
        for (let key in entireObj) {
            let obj = entireObj[key];
            if (keys.includes(key)) {
                plain_json[key] = obj;
            }
            if (typeof (obj) == 'object') {
                this.findKeyValueNestedObj(obj, keys, plain_json);
            }
        }
        return plain_json;
    }

    static flattenJSON = (obj = {}, res = {}, extraKey = '') => {
        try {
            for (let key in obj) {
                if (typeof obj[key] !== 'object') {
                    res[extraKey + key] = obj[key];
                } else {
                    res[extraKey + key] = obj[key];
                    this.flattenJSON(obj[key], res, `${extraKey}${key}.`);
                }
            }
            return res;
        } catch (ex) {
            console.log('Error on flatten json: ', ex.message);
            return obj;
        }
    }

    static stringToJson(str_data) {
        try {
            if (typeof (str_data) === 'object') {
                return str_data;
            } else {
                let arr_str = str_data.split('&');
                let req_params = {};
                for (let param of arr_str) {
                    let params = param.split('=')
                    req_params[params[0]] = params[1];
                }
                return req_params;
            }
        } catch (ex) {
            return str_data
        }
    }

    static mergeDeep(objects) {
        try {
            const isObject = obj => obj && typeof obj === 'object';
            return objects.reduce((prev, obj) => {
                Object.keys(obj).forEach(key => {
                    const prev_val = prev[key];
                    const obj_val = obj[key];
                    if (Array.isArray(prev_val) && Array.isArray(obj_val)) {
                        // prev[key] = prev_val.concat(...obj_val);
                        prev[key] = obj_val || prev_val;
                    } else if (isObject(prev_val) && isObject(obj_val)) {
                        prev[key] = Utils.mergeDeep([prev_val, obj_val]);
                    } else {
                        prev[key] = obj_val || prev_val;
                    }
                });
                return prev;
            }, {});
        } catch (ex) {
            console.log(ex);
        }
    }

    static dynamicReplicaDB(req) {
        if (req.body.token && req.body.token.use_replica) {
            // console.log('Using replica DB');
            return (req.brand_conf.read_replica || req.brand_conf).db;
        } else {
            // console.log('Using primary DB');
            return req.brand_conf.db;
        }
    }

    static sanitizeMemKey(key, sanitizer = '-') {
        try {
            key = key.replace(/[\n\r]/g, "").replace(/ /g, sanitizer);
        } catch (ex) {
            console.log(ex.message);
        }
        return key;
    }
}
