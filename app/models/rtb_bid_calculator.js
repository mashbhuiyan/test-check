const axios = require("axios");

module.exports = class RtbBidCalculator {
    constructor(db_config) {
        this.db = db_config;
    }

    async rtbBidCheck(partner_id, params, ping_id) {
        return new Promise((resolve, reject) => {
            try {
                const created_dt = new Date().toISOString().replace(/T/, ' ').replace(/Z/, '');
                let rtb_req_data = {
                    source_data: {
                        partner_id: partner_id,
                        created_at: created_dt
                    },
                    consumer_data: params
                }
                const headers = {headers: {"Content-Type": 'application/json'}};
                const start_time = new Date().getTime();
                axios.post(process.env.RTB_BID_API, {payload: rtb_req_data}, headers).then(async resp => {
                    this.storeRtbBid(resp.data, ping_id, ((new Date().getTime()) - start_time));
                    resolve(resp.data);
                }).catch(error => {
                    console.log("Error", error.message);
                    resolve({success: false})
                });
            } catch (ex) {
                console.log('Exception: ', ex);
                resolve({success: false})
            }
        });
    }

    async rtbBidLogic(rtb_params) {
        try {
            let headers = {headers: {"Content-Type": 'application/json'}};
            return axios.post(process.env.RTB_BID_LOGIC_API, rtb_params, headers).then(resp => {
                let resp_data = resp.data;
                resp_data.success = true;
                return resp_data;
            }).catch(error => {
                console.log("Error", error.message);
                return {success: true, bid_to_use: 0}
            });
        } catch (ex) {
            return {success: true, bid_to_use: 0}
        }
    }

    async storeRtbBid(data, click_ping_id, latency) {
        let current_date_time = new Date();
        const store_data = [click_ping_id, data.recommended_bid, data.revenue_exp, data.output_code, JSON.stringify(data), latency, current_date_time, current_date_time];
        this.db.query('INSERT INTO rtb_bids (click_ping_id, recommended_bid, revenue_exp, output_code, response_text, latency, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *', store_data, async (error, results) => {
            if (error) {
                console.log(error);
            } else {
                // console.log('Store RTB bid success');
            }
        });
    }

    async updateRtbBid(click_ping_id, bid_to_use, cm) {
        const update_data = [click_ping_id, bid_to_use, cm];
        this.db.query('update rtb_bids set bid_to_use = $2, cm = $3 where click_ping_id = $1', update_data, async (error, results) => {
            if (error) {
                console.log(error);
            } else {
                //console.log('Update RTB bid success');
            }
        });
    }
}
