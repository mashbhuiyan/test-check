const Call = require('../../app/models/call');

module.exports = class CallEvent {
    update_event_schema = ['transferred', 'position', 'de_duped', 'excluded'];

    constructor(brand_conf, listing) {
        this.db = brand_conf.db;
        this.brand_conf = brand_conf;
        this.call_listing = listing;
    }

    async updateCallListing(params) {
        return new Promise((resolve, reject) => {
            let call_result_data = {};
            let query = "update call_listings set ";
            let index = 1;
            let values = [];
            for (let field in params) {
                if (this.update_event_schema.includes(field)) {
                    query += field + '=$' + index + ',';
                    let value = params[field];
                    if (typeof (value) == "boolean") {
                        values.push(value ? 1 : 0);
                        call_result_data[field] = value ? 1 : 0;
                    } else {
                        values.push(value);
                        call_result_data[field] = value;
                    }
                    index += 1;
                }
            }
            if (index > 1) {
                query = query.slice(0, -1);
                query += ` where id = ${this.call_listing.id}`;
                this.db.query(query, values, (error, results) => {
                    if (error) {
                        resolve('post event failed');
                    } else {
                        resolve('post event success');
                    }
                });
                (new Call(this.brand_conf, {}, [])).updateCallResult(this.call_listing.call_ping_id, this.call_listing.account_id, this.call_listing.campaign_id, this.call_listing.ad_group_id, call_result_data, this.call_listing.id);
            } else {
                resolve('post event failed');
            }
        });
    }
}
