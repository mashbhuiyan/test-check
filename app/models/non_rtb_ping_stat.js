const MiniOrm = require('../lib/mini_orm');

module.exports = class NonRtbPingStat {
    table_name = 'non_rtb_ping_stats';
    product_type_id = null;
    orm = null;
    params = {};
    accepted_keys = [];

    constructor(db_config, product_type_id) {
        this.product_type_id = product_type_id;
        this.orm = new MiniOrm(db_config);
        this.accepted_keys = [
            `${this.mapProductType()}_ping_id`, 'lead_type_id', 'account_id', 'brand_id', 'campaign_id',
            'ad_group_id', 'insurance_carrier_id', 'match', 'opportunity', 'listing', `${this.mapProductType()}_listing_id`,
            'device_type', 'mobile', 'zip', 'state', 'source_type_id', 'aid', 'cid', 'pst_hour', 'pst_day', 'pst_week',
            'pst_month', 'pst_quarter', 'pst_year', 'insured', 'continuous_coverage', 'home_owner', 'gender',
            'marital_status', 'consumer_age', 'education', 'credit_rating', 'military_affiliation', 'num_drivers',
            'num_vehicles', 'violations', 'dui', 'accidents', 'license_status', 'first_name', 'last_name', 'phone',
            'email', 'city', 'county', 'tobacco', 'major_health_conditions', 'life_coverage_type', 'life_coverage_amount',
            'property_type', 'property_age', 'years_in_business', 'commercial_coverage_type', 'household_income',
            'ip_address', 'created_at', 'updated_at', 'excluded', 'active_source', 'de_duped', 'won', 'accepted',
            'payout', 'account_manager_id', 'sales_rep_id', 'billing_type_id'
        ];
    }

    storeRtbPing(keys, value_sets) {
        const columns = ['product_type_id'];
        const accepted_indexes = [];
        const account_id_index = keys.indexOf('account_id');
        for (const index in keys) {
            if (this.accepted_keys.includes(keys[index])) {
                columns.push(this.mapKey(keys[index]));
                accepted_indexes.push(index);

            }
        }

        const filtered_value_sets = [];
        for (const values of value_sets) {
            if (account_id_index < 0 || values[account_id_index] != 5) {
                const filtered_values = [this.product_type_id];
                for (const accepted_index of accepted_indexes) {
                    filtered_values.push(values[accepted_index]);
                }
                filtered_value_sets.push(filtered_values);
            }
        }
        if (filtered_value_sets.length === 0) {
            return;
        }
        this.orm.batchInsert(this.table_name, columns, filtered_value_sets).then(() => {
            // console.log('non_rtb_ping_stats created.......');
        }, err => {
            console.log('error non_rtb_ping_stats: ', err);
        });
    }

    updateRtbPing(queries, params) {
        if (queries.account_id && queries.account_id == 5) {
            return;
        }
        this.params = {...params, ...{updated_at: new Date()}};
        this.orm.update(
            this.table_name,
            this.rtbPingData(),
            this.whereQueryString(queries)
        ).then(() => {
            // console.log('non_rtb_ping_stats updated.......');
        }, err => {
            console.log('error non_rtb_ping_stats update: ', err);
        });
    }

    whereQueryString(queries) {
        let where_queries = [`product_type_id = ${this.product_type_id}`];
        for (let key in queries) {
            if (queries[key] != null && typeof (queries[key]) != 'undefined') {
                where_queries.push(`${key} = ${queries[key]}`);
            }
        }
        return where_queries.join(' AND ');
    }

    rtbPingData() {
        let data = {product_type_id: this.product_type_id};
        for (let key in this.params) {
            if (this.accepted_keys.includes(key)) {
                data[this.mapKey(key)] = this.params[key];
            }
        }
        data = this.mapAcceptance(data);

        return data;
    }

    mapKey(key) {
        if (['click_ping_id', 'call_ping_id', 'lead_ping_id'].includes(key)) {
            return 'ping_id';
        } else if (['click_listing_id', 'call_listing_id', 'lead_listing_id'].includes(key)) {
            return 'listing_id';
        } else if (key === 'payout') {
            return 'bid';
        } else if (key === 'insurance_carrier_id') {
            return 'carrier_id';
        } else {
            return key;
        }
    }

    mapProductType() {
        switch (this.product_type_id) {
            case 2:
                return 'call';
            case 3:
                return 'lead';
            default:
                return 'click';
        }
    }

    mapAcceptance(data) {
        if (this.product_type_id === 1) {
            return this.mapClickAcceptance(data);
        } else if (this.product_type_id === 2) {
            return this.mapCallAcceptance(data);
        }

        return data;
    }

    mapClickAcceptance(data) {
        if (this.params.hasOwnProperty('viewed')) {
            data.won = this.params.viewed;
        }
        if (this.params.hasOwnProperty('clicked')) {
            data.accepted = this.params.clicked;
        }
        return data;
    }

    mapCallAcceptance(data) {
        if (this.params.hasOwnProperty('transferred')) {
            data.won = this.params.transferred;
            data.accepted = this.params.transferred;
        }
        return data;
    }

}
