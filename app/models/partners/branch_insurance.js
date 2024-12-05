const PartnerBase = require('../partners/partner_base');
const MapperBase = require('../../lib/mapper/branch_insurance/base');
const axios = require("axios");

module.exports = class BranchInsurance extends PartnerBase {
    partnerUrl() {
        return 'https://smartfinancial.ourbranch.com/marketing/url'
    }

    reqMethod() {
        return 'post';
    }

    queryParams(params, lead_type) {
        return (new MapperBase(lead_type)).dataMapping(params);
    }

    async getHeaders() {
        const access_token = await this.get_access_token();
        return {Authorization: `Bearer ${access_token}`}
    }

    getResponse(resp) {
        const resp_data = resp.data;
        let res = '';
        if (resp.status === 200) {
            res = {
                success: true,
                url: resp_data.insurerURL,
                message: "Successfully respond",
                premium: "",
                term: ""
            }
        } else if (resp.status === 400) {
            res = {
                success: false,
                url: '',
                message: "Bad request parameters",
                premium: "",
                term: ""
            }
        } else if (resp.status === 500) {
            res = {
                success: false,
                url: '',
                message: "Internal server error",
                premium: "",
                term: ""
            }
        } else {
            res = {
                success: false,
                url: "",
                message: "Failed",
                premium: "",
                term: ""
            }
        }
        return res;
    }

    isSuccess(response) {
        return response.status === 200;
    }

    async get_access_token() {
        const url = "https://smartfinancial.ourbranch.com/auth";
        let token = '';
        await axios.post(url, {
            withCredentials: true,
            headers: {
                "Accept": "application/json",
                "Content-Type": "application/json"
            }
        }, {
            connectTimeout: 1000,
            auth: {
                //api key
                username: "7ZpGRhgy4zvc2y5Qa26PM5JhXE82Hwj9",
                password: ""
            }
        }).then(function (response) {
            console.log('Authenticated, access_token = ', response.data.access_token);
            token = response.data.access_token;
        }).catch(function (error) {
            console.log('Error on Authentication = ', error);
            token = null;
        });

        return token;
    }
}
