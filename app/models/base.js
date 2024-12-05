const util = require("./utils");
const ErrorHandler = require("./error_handler");
const axios = require("axios");
const xmlToJson = require("xml-to-json-stream");
const decode = require("unescape");
const errorHandler = new ErrorHandler();
const MiniOrm = require('../lib/mini_orm');
const AppMemcached = require("../lib/app_memcached");

module.exports = class Base {
    date = new Date();
    db = '';
    read_replica_db = '';
    brand_conf = {};
    lead_uid = '';
    source_type_id = '';
    debug_data = {
        campaigns: {}
    }
    brand_url = '';
    campaign_ids = [];
    partner_id = '';
    campaign_exclusion = []
    campaign_list = []
    filter_campaign_list = []
    filter_ad_group_list = []
    pre_ping_integrations = []
    price_presentation_integrations = []
    ping_integrations = [];
    pre_fill_integrations = [];
    filter_group_price = {}
    bid_multipliers = {}
    device_types = ["'both'"];
    mobile_device = true;
    token_type = '';
    token_id = '';
    click_ping = 0;
    ads = {}
    ping_id = null;
    req_token = "";
    req_params = {};
    self_integration = false;
    params = {};
    click_listings = {};
    campaign_timezones = {};
    geo_filter = ['State', 'Country', 'County', 'City', 'Zip Code', 'Zip Code (Bulk)', 'Area Code'];
    orm = null;

    setInitialDebugData(campaign) {
        this.debug_data.campaigns[campaign.campaign_id] = {
            id: campaign.campaign_id,
            name: campaign.campaign_name,
            account_id: campaign.account_id,
            user_id: campaign.user_id,
            bid_modifiers_groups: [],
            filter_groups: [],
            ad_group_filter_groups: [],
            token_bid_multiplier: [],
            base_bid: campaign.base_bid_price,
            qualified: true,
            final_bid: (campaign.base_bid_price || 0).toFixed(2)
        };
    }

    setDebugData(campaign_id, field, data, push_data = false) {
        if (this.debug_data.campaigns[campaign_id]) {
            if (push_data) {
                this.debug_data.campaigns[campaign_id][field].push(data);
            } else {
                this.debug_data.campaigns[campaign_id][field] = data;
            }
        }
    }

    getHomeOwner() {
        if (this.req_params.lead_type_id == '1') {
            return true;
        } else {
            let home_owner = util.getParam(this.params, 'own_home');
            return typeof (home_owner) == 'boolean' ? home_owner : util.toLowerCase(home_owner) === 'yes';
        }
    }

    checkSourceSettings() {
        let source_modifier = {};
        for (let campaign of this.campaign_list) {
            let debug_source_modifier = {
                source: this.params.traffic_tier,
                active: campaign.active_source,
                multiplier: campaign.source_weight
            };
            if (campaign.active_source === false || campaign.active_source == 0 || campaign.source_weight <= 0) {
                this.campaign_exclusion.push(campaign.campaign_id);
                this.setDebugData(campaign.campaign_id, 'exclusion', 'Inactive Source');
            } else {
                if (typeof (campaign.source_weight) == 'undefined') {
                    source_modifier[campaign.campaign_id] = 100;
                    debug_source_modifier.multiplier = 100;
                } else {
                    source_modifier[campaign.campaign_id] = campaign.source_weight;
                }
                debug_source_modifier.active = true
            }
            this.setDebugData(campaign.campaign_id, 'source_modifier', debug_source_modifier);
        }
        for (let campaign_id in source_modifier) {
            this.bid_multipliers[campaign_id].push(source_modifier[campaign_id]);
        }
    }

    async scheduleModifier() {
        return new Promise((resolve, reject) => {
            if (this.campaign_ids.length > 0) {
                let query = "select distinct campaign_id, timezone from campaign_schedules where campaign_id in (" + this.campaign_ids + ") and discarded_at IS NULL";
                this.db.query(query, async (error, results) => {
                    if (error) {
                        errorHandler.notify(error);
                        resolve('database query error');
                    } else {
                        for (let row of results.rows) {
                            await this.checkScheduleModifier(row.campaign_id, (row.timezone || 'PST'));
                        }
                        resolve('success');
                    }
                });
            } else {
                resolve('failed');
            }
        });
    }

    async checkScheduleModifier(campaign_id, timezone) {
        let date = new Date();
        if (timezone && util.toLowerCase(timezone) === 'local') {
            date = await this.getLocalDate();
        } else {
            date = this.getDate(timezone);
        }
        const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
        let query = `select *
                     from campaign_schedules
                     where campaign_id = ${campaign_id}
                       and discarded_at IS NULL
                       and day_id = ${date.getDay()}`;
        return this.db.query(query).then(results => {
            let schedule = results.rows[0];
            let hour_field = "h" + date.getHours();
            let debug_schedule_multiplier = {active: false, day: days[date.getDay()]};
            debug_schedule_multiplier.hour = this.numberToTime(date.getHours())
            debug_schedule_multiplier.timezome = timezone;
            if (schedule) {
                debug_schedule_multiplier.multiplier = schedule[hour_field];
                if (schedule.active && schedule[hour_field] !== 0) {
                    this.bid_multipliers[campaign_id].push(schedule[hour_field]);
                    debug_schedule_multiplier.active = true
                } else {
                    this.campaign_exclusion.push(campaign_id);
                    this.setDebugData(campaign_id, 'exclusion', 'Inactive Schedule');
                }
                this.setDebugData(campaign_id, 'schedule_modifier', debug_schedule_multiplier);
            } else {
                this.campaign_exclusion.push(campaign_id);
                this.setDebugData(campaign_id, 'schedule_modifier', debug_schedule_multiplier);
                this.setDebugData(campaign_id, 'exclusion', 'Schedule No Found');
            }
            return 'success';
        }, error => {
            errorHandler.notify(error);
            return 'error';
        });
    }

    async filterGroups() {
        return new Promise((resolve, reject) => {
            if (this.campaign_ids.length <= 0) {
                return resolve("error");
            }
            let filter_groups = {}
            let filter_group_prices = {}
            for (let campaign_id of this.campaign_ids) {
                filter_groups[campaign_id] = {};
                filter_group_prices[campaign_id] = {};
            }
            let query = "select cfg.id, cfg.campaign_id, cf.price::FLOAT, cf.accept_unknown, cf.filter_value, cf.filter_value_array, cf.filter_value_min, cf.filter_value_max, cf.include, cf.sf_filter_id, sf.name, sf.query_param, sf.filter_type from campaign_filter_groups cfg inner join campaign_filters cf on cf.campaign_filter_group_id = cfg.id inner join sf_filters sf on cf.sf_filter_id = sf.id where cfg.discarded_at IS NULL and cf.discarded_at IS NULL and cfg.campaign_id in (" + this.campaign_ids + ")"
            this.db.query(query, (error, results) => {
                if (error) {
                    errorHandler.notify(error);
                    return resolve("error");
                }
                let res = results.rows;
                for (let rs of res) {
                    let camp_id = rs.campaign_id;
                    let c_group_id = rs.id;
                    let qualify_filter = this.filterCampaignGroup(rs);
                    if (filter_groups[camp_id] && typeof (filter_groups[camp_id][c_group_id]) != 'undefined') {
                        filter_groups[camp_id][c_group_id] = filter_groups[camp_id][c_group_id] * (qualify_filter ? 1 : 0); // AND within filter group which is *
                        filter_group_prices[camp_id][c_group_id] += qualify_filter ? rs.price : 0; // get qualified filter price
                    } else {
                        filter_groups[camp_id][c_group_id] = qualify_filter ? 1 : 0;
                        filter_group_prices[camp_id][c_group_id] = qualify_filter ? rs.price : 0;
                    }
                    this.setDebugData(camp_id, 'filter_groups', {
                        id: c_group_id,
                        condition: this.getFilterCondition(rs),
                        qualified: this.filterCampaignGroup(rs),
                        include: rs.include ? 'Yes' : 'No',
                        price: rs.price
                    }, true);
                }
                for (let campaign_id in filter_groups) {
                    let filter_group = filter_groups[campaign_id];
                    let filter_group_value = Object.values(filter_group);
                    this.filter_group_price[campaign_id] = 0;
                    if (filter_group_value.length > 0) {
                        let total_fg_value = 0;
                        for (let filter_group_id in filter_group) {
                            if (filter_group[filter_group_id] > 0) {
                                total_fg_value += 1; // OR groups within a campaign which is +
                                if (filter_group_prices[campaign_id][filter_group_id] > this.filter_group_price[campaign_id]) {
                                    this.filter_group_price[campaign_id] = filter_group_prices[campaign_id][filter_group_id]; // Get highest price between filter groups of a campaign
                                }
                            }
                        }
                        if (total_fg_value > 0) {
                            this.filter_campaign_list.push(campaign_id)
                        }
                    } else if (filter_group_value.length <= 0) { // Qualify campaign if no filter found of the campaign
                        this.filter_campaign_list.push(campaign_id)
                    } else {
                        this.filter_campaign_list.push(campaign_id)
                    }
                }
                for (let campaign of this.campaign_list) {
                    if (campaign.locked_price && this.filter_group_price[campaign.campaign_id]) { // Reset filter group price for campaign which price is locked locked_price = true
                        this.filter_group_price[campaign.campaign_id] = 0;
                    }
                }
                resolve("filter_campaign_list" + this.filter_campaign_list);
            });
        });
    }

    filterCampaignGroup(filter_data) {
        let input_value = this.getInputValue(filter_data.query_param);
        if (filter_data.accept_unknown === false) {
            // user does not want to accept unknown data
            if (!input_value) {
                // inout value is empty. Do not accept. Filter fails. Return false.
                return false;
            } else {
                // input value is present. Process filter normally.
                return this.filterGroup(filter_data);
            }
        } else {
            // user is ok with the unknown data
            if (!input_value) {
                // input value is empty. Accept it. Filter pass.
                return true;
            } else {
                // input value is present. Process filter normally.
                return this.filterGroup(filter_data);
            }
        }

        // TODO: We can remove the above code and use the below code.
        // if (!input_value) {
        //     return filter_data.accept_unknown;
        // }
        // return this.filterGroup(filter_data);
    }

    filterGroup(filter_data, accept_unknown_source = false) {
        let input_value = this.getInputValue(filter_data.query_param);
        let filter_type = filter_data.filter_type;
        let result = true;
        switch (filter_type) {
            case 'single-select': {
                result = util.toLowerCase(filter_data.filter_value) == util.toLowerCase(input_value);
                break;
            }
            case 'free-form':
            case 'multi-select': {
                try {
                    let filter_value = this.getFreeFormMultiSelectValue(filter_type, filter_data);
                    let arr_value = input_value.split('>;');
                    if (arr_value.length > 1) {
                        input_value = arr_value.map(el => util.toLowerCase(el));
                    }
                    result = filter_value.some(value => {
                        if (Array.isArray(input_value)) {
                            // few filters that stores IDs are failing the comparison
                            // because we compare string to numbers
                            let f_value = (typeof value == 'number') ? value.toString() : util.toLowerCase(value);
                            return input_value.includes(f_value);
                        } else {
                            return util.toLowerCase(value) === util.toLowerCase(input_value);
                        }
                    });
                } catch (ex) {
                    console.log("Failed to parsed filter value", ex.message);
                    result = false;
                }
                break;
            }
            case 'min-max': {
                result = this.getMaxMinFilter(filter_data, input_value);
                break;
            }
        }
        return filter_data.include ? result : !result;
    }

    getFreeFormMultiSelectValue(key, filter_data) {
        try {
            if (key === 'multi-select') {
                return JSON.parse(filter_data.filter_value || '[]');
            } else {
                if (Array.isArray(filter_data.filter_value_array)) {
                    return filter_data.filter_value_array;
                } else if (typeof (filter_data.filter_value_array) === 'string') {
                    let free_form_filter_val = (filter_data.filter_value_array || '[]').replace("{", "[").replace("}", "]");
                    return JSON.parse(free_form_filter_val);
                } else {
                    return [];
                }
            }
        } catch (ex) {
            console.log("Failed to parsed filter value", ex.message);
            return [];
        }
    }

    getFilterCondition(filter_data) {
        let input_value = this.getInputValue(filter_data.query_param);
        let filter_type = filter_data.filter_type;
        let type_symbol = '';
        let filter_value = filter_data.filter_value;
        switch (filter_type) {
            case 'single-select': {
                type_symbol = filter_data.include ? '==' : '!=';
                break;
            }
            case 'free-form':
            case 'multi-select': {
                filter_value = this.getFreeFormMultiSelectValue(filter_type, filter_data);
                type_symbol = filter_data.include ? 'in' : 'not in';
                break;
            }
            case 'min-max': {
                type_symbol = Array.isArray(filter_data.filter_value) ? filter_data.filter_value[0] : filter_data.filter_value;
                if (type_symbol === 'Equal To' || type_symbol === 'Less Than') {
                    filter_value = ' ' + filter_data.filter_value_max;
                } else if (type_symbol === 'More Than') {
                    filter_value = ' ' + filter_data.filter_value_min;
                } else if (type_symbol === 'Between') {
                    filter_value = ' ' + filter_data.filter_value_min + ' and ' + filter_data.filter_value_max;
                }
                if (!filter_data.include) {
                    type_symbol = 'Not ' + type_symbol
                }
                break;
            }
        }
        return `${filter_data.query_param} (${(input_value || '').toString()}) ${type_symbol} ${filter_value}`
    }

    getMaxMinFilter(filter_data, pv) {
        if (typeof (pv) == 'undefined' || pv == null || pv === '') {
            return false;
        }
        let input_value = util.parseToFloat(pv || '0');
        let filter_value = Array.isArray(filter_data.filter_value) ? filter_data.filter_value[0] : filter_data.filter_value;
        let max_val = util.parseToFloat(filter_data.filter_value_max);
        let min_val = util.parseToFloat(filter_data.filter_value_min);
        switch (filter_value) {
            case 'Equal To': {
                return max_val == input_value;
            }
            case 'Less Than': {
                return input_value < max_val;
            }
            case 'More Than': {
                return input_value > min_val;
            }
            case 'Between': {
                return input_value >= min_val && input_value <= max_val;
            }
            default: {
                return false;
            }
        }
    }

    async modifierGroups(check_call_availibility = false) {
        return new Promise((resolve, reject) => {
            if (this.campaign_ids.length <= 0) {
                return resolve([]);
            }
            let modifier_groups = {}
            let query = "select cbg.id, cbg.campaign_id, cbm.filter_value, cbm.filter_value_array, cbm.filter_value_min, cbm.filter_value_max, cbm.include, cbm.sf_filter_id, sf.name, sf.query_param, sf.filter_type, cbg.bid_percent from campaign_bid_modifier_groups cbg inner join campaign_bid_modifiers cbm on cbm.campaign_bid_modifier_group_id = cbg.id inner join sf_filters sf on cbm.sf_filter_id = sf.id where cbm.discarded_at IS NULL and cbg.discarded_at IS NULL and cbg.bid_percent >= 0 and cbg.campaign_id in (" + this.campaign_ids + ")"
            this.db.query(query, (error, results) => {
                if (error) {
                    errorHandler.notify(error);
                    return resolve(this.bid_multipliers);
                }
                let res = results ? results.rows : [];
                let modifier_group_percentage = {};
                for (let rs of res) {
                    let camp_id = rs.campaign_id;
                    let m_group_id = rs.id;
                    if (check_call_availibility) {
                        let input_value = this.getInputValue(rs.query_param);
                        if (!input_value) {
                            continue; // Don't process modifier if no input value present for call availability API
                        }
                    }
                    if (modifier_groups[camp_id] && typeof (modifier_groups[camp_id][m_group_id]) != 'undefined') {
                        modifier_groups[camp_id][m_group_id] = modifier_groups[camp_id][m_group_id] * (this.filterGroup(rs) ? 1 : 0); // AND within filter group which is *
                    } else {
                        if (typeof (modifier_groups[camp_id]) == 'undefined') {
                            modifier_groups[camp_id] = {}
                        }
                        modifier_groups[camp_id][m_group_id] = this.filterGroup(rs) ? 1 : 0;
                        modifier_group_percentage[m_group_id] = rs.bid_percent;
                    }
                    this.setDebugData(camp_id, 'bid_modifiers_groups', {
                        id: m_group_id,
                        multiplier: rs.bid_percent,
                        condition: this.getFilterCondition(rs),
                        qualified: this.filterGroup(rs),
                        include: rs.include ? 'Yes' : 'No'
                    }, true);
                }
                for (let campaign_id in modifier_groups) {
                    let campaign_modifier_groups = modifier_groups[campaign_id];
                    for (let modifier_group_id in campaign_modifier_groups) {
                        if (campaign_modifier_groups[modifier_group_id] > 0) { // Qualify modifier group
                            let bid_percent = modifier_group_percentage[modifier_group_id]; // Modifier group percentage
                            this.bid_multipliers[campaign_id].push(bid_percent);
                        }
                    }
                }
                resolve(this.bid_multipliers);
            });
        });
    }

    addSourceType(source, project_id, token_type) {
        let current_date_time = new Date();
        let active_source = (token_type === 'admin' || process.env.PRODUCTION == 0); //make source type active on staging or dev env.
        const data = [source, 'Added by API', false, active_source, project_id, current_date_time, current_date_time];
        let query = `SELECT id
                     FROM source_types
                     WHERE LOWER(name) = '${util.toLowerCase(source)}'`;
        if (project_id) {
            query += ` and project_id = '${project_id}'`
        }
        query += ' limit 1';
        return this.db.query(query).then(results => {
            if (results.rows.length > 0) {
                return results.rows[0].id || null;
            } else {
                return this.db.query('INSERT INTO source_types (name, description, internal, active, project_id, created_at, updated_at) VALUES($1, $2, $3, $4, $5, $6, $7) RETURNING *', data).then((results) => {
                    return results.rows[0] ? results.rows[0].id : null;
                }, err => {
                    errorHandler.notify(err);
                    return null;
                });
            }
        }, err => {
            errorHandler.notify(err);
            return null;
        });
    }

    async updateCampaignSourceSettings(source_type_id, product_ids) {
        let campaigns_to_add = this.token_bid_multipliers.map(item => item.campaign_id);
        if (this.token_type === 'admin') {
            let admin_query = `SELECT *
                               from campaigns
                               where account_id in
                                     (SELECT id from accounts where internal = false and status = 'active')
                                 and lead_type_id = ${this.req_params.lead_type_id}
                                 and product_type_id in (${product_ids})`;
            this.db.query(admin_query, (error, results) => {
                if (error) {
                    errorHandler.notify(error);
                } else {
                    campaigns_to_add = results.rows.map(cp => cp.id);
                    if (campaigns_to_add.length > 0) {
                        this.checkExistingSourceSettings(source_type_id, campaigns_to_add);
                    }
                }
            });
        } else {
            if (campaigns_to_add.length > 0) {
                const memcached = AppMemcached.getInstance();
                let cache_data = null;
                let mem_key = util.sanitizeMemKey(`source_settings_t_${this.token_id}_l_${this.req_params.lead_type_id}_p_${product_ids.join('_')}`);
                try {
                    cache_data = await memcached.get(mem_key);
                } catch (ex) {
                    errorHandler.notify(ex);
                }
                if (cache_data) {
                    if (cache_data.length > 0) {
                        this.checkExistingSourceSettings(source_type_id, cache_data);
                    }
                } else {
                    let generic_query = `SELECT distinct cp.id
                                         from campaigns cp
                                                  inner join source_types st on st.project_id = cp.account_id::varchar(255)
                                         where cp.id in (${campaigns_to_add})
                                           and lead_type_id = ${this.req_params.lead_type_id}
                                           and product_type_id in (${product_ids})`;
                    this.db.query(generic_query, (error, results) => {
                        if (error) {
                            errorHandler.notify(error);
                        } else {
                            campaigns_to_add = results.rows.map(campaign => campaign.id);
                            memcached.set(mem_key, campaigns_to_add, 300);
                            if (campaigns_to_add.length > 0) {
                                this.checkExistingSourceSettings(source_type_id, campaigns_to_add);
                            }
                        }
                    });
                }
            }
        }
    }

    async checkExistingSourceSettings(source_type_id, campaigns_to_add) {
        let existing_campaigns = [];
        this.db.query(`SELECT campaign_id, source_type_id
                       from campaign_source_settings
                       where source_type_id = ${source_type_id}
                         and campaign_id in (${campaigns_to_add})`, (error, results) => {
            if (error) {
                errorHandler.notify(error);
                console.log('Unable to get campaigns', error.message);
            } else {
                campaigns_to_add = campaigns_to_add.map(cta => cta.toString());
                let new_campaigns_to_add = campaigns_to_add;
                if (results.rows.length > 0) {
                    existing_campaigns = results.rows.map(css => css.campaign_id.toString());
                    new_campaigns_to_add = campaigns_to_add.filter(ca => !existing_campaigns.includes(ca));
                }
                if (new_campaigns_to_add.length > 0) {
                    this.campaignSourceSettings(new_campaigns_to_add, source_type_id);
                }
                // let add_source_setting = [];
                // for (let campaign_id of new_campaigns_to_add) {
                //     // let air_message = {
                //     //     message: 'Source Settings Debug',
                //     //     source_type_id: source_type_id,
                //     //     ping_id: this.ping_id,
                //     //     source: this.req_params.traffic_tier,
                //     //     type: this.token_type,
                //     //     campaigns_to_add: campaigns_to_add,
                //     //     tbm: this.token_bid_multipliers,
                //     //     campaign_id: campaign_id,
                //     //     query: qry
                //     // }
                //     // errorHandler.notify({
                //     //     message: JSON.stringify(air_message)
                //     // });
                //     add_source_setting.push(this.campaignSourceSettings(campaign_id, source_type_id));
                // }
                // Promise.all(add_source_setting);
            }
        });
    }

    async campaignSourceSettings(campaigns_to_add, source_type_id) {
        const current_date_time = new Date();
        const columns = ['source_type_id', 'campaign_id', 'weight', 'active', `"desc"`, 'created_at', 'updated_at'];
        const is_admin = this.token_type === 'admin';
        const values = campaigns_to_add.map(campaign_id => [source_type_id, campaign_id, 100, is_admin, 'Added by API', current_date_time, current_date_time]);
        this.orm.batchInsert('campaign_source_settings', columns, values).then(() => {
            console.log('added campaign_source_settings', values);
        }, error => {
            errorHandler.notify(error);
            console.log('Unable to add campaign_source_settings', error.message);
        });
        // this.db.query(`select source_type_id, campaign_id
        //                from campaign_source_settings
        //                where campaign_id = ${campaign_id}
        //                  and source_type_id = ${source_type_id}`, (error, results) => {
        //     if (error) {
        //         errorHandler.notify(error);
        //     } else {
        //         if (results.rows.length <= 0) {
        //             const data = [source_type_id, campaign_id, 100, (this.token_type === 'admin'), 'Added by API', current_date_time, current_date_time];
        //             this.db.query(`INSERT INTO campaign_source_settings (source_type_id, campaign_id, weight, active,
        //                                                                  "desc", created_at, updated_at)
        //                            values ($1, $2, $3, $4, $5, $6, $7)
        //                            RETURNING *`, data, (error, results) => {
        //                 if (error) {
        //                     errorHandler.notify(error);
        //                     console.log(this.db.options.database);
        //                     console.log('Unable to add campaign_source_settings', error.message);
        //                 } else {
        //                     console.log('added campaign_source_settings');
        //                 }
        //             });
        //         }
        //     }
        // });
    }

    getIntegrations(campaign_ids, phase = '') {
        let phases = ' and is_ping = false';
        if (phase) {
            if (Array.isArray(phase)) {
                phases = " and phase in ('" + phase.join("','") + "') and is_ping = true";
            } else {
                phases = ` and phase = '${phase}' and is_ping = true`;
            }
        }
        let lead_integrations = {};
        for (let id of campaign_ids) {
            lead_integrations[id] = {
                accept_reject: [],
                general: []
            };
        }
        let query = `SELECT li.id,
                            cli.lead_integration_id,
                            cli.campaign_id,
                            li.req_method,
                            li.req_content_type,
                            li.posting_url,
                            li.req_type,
                            li.res_type,
                            li.res_success_regex,
                            li.status,
                            li.accept_reject,
                            li.priority,
                            li.req_timeout,
                            li.account_id,
                            li.is_ping,
                            li.phase,
                            li.ping_config,
                            li.is_template
                     FROM campaign_lead_integrations cli
                              inner join lead_integrations li on li.id = cli.lead_integration_id
                     WHERE cli.campaign_id in (${campaign_ids.length > 0 ? campaign_ids : [0]})
                       and li.status = 'active'
                       and li.discarded_at IS NULL
                       and cli.discarded_at IS NULL`;
        query += phases;
        // if (phases.length > 0) {
        //     query += " and phase in ('" + phases.join("','") + "')";
        //     query += ` and is_ping = true`;
        // } else {
        //     query += ` and is_ping = false`;
        // }
        // if (phase === 'pre-ping') {
        //     query += ` and phase = 'pre-ping'`;
        // } else if (phase === 'ping') {
        //     query += ` and is_ping = true and phase = 'ping'`;
        // } else if (phase === 'post') {
        //     query += ` and is_ping = true and phase = 'post'`;
        // } else if (phase === 'price_presentation') {
        //     query += ` and phase = 'price_presentation'`;
        // } else if (phase === 'pre_fill') {
        //     query += ` and phase = 'pre_fill'`;
        // } else {
        //     query += ` and is_ping = false`;
        // }
        query += ` order by li.priority desc`;
        return this.db.query(query).then((results) => {
            let integrations = results.rows;
            if (phase) {
                if (Array.isArray(phase)) {
                    let phase_integrations = {};
                    for (let integration of integrations) {
                        if (phase_integrations[integration.phase]) {
                            phase_integrations[integration.phase].push(integration);
                        } else {
                            phase_integrations[integration.phase] = [integration];
                        }
                    }
                    return phase_integrations;
                } else {
                    return integrations;
                }
            } else {
                for (let integration of integrations) {
                    if (integration.accept_reject) {
                        lead_integrations[integration.campaign_id].accept_reject.push(integration);
                    } else {
                        lead_integrations[integration.campaign_id].general.push(integration);
                    }
                }
                return lead_integrations;
            }
        }, err => {
            console.log('integrations query errors:', err.message);
            return lead_integrations;
        });
    }

    parsePingIntegrationResponse(response_data, ping_config, full_json = false) {
        let key_to_parse = Object.values(ping_config).filter(item => item); // Keys we need to parse from the integration response
        if (ping_config.api_response_type === 'xml') {
            const parser = xmlToJson({attributeMode: false});
            response_data = decode(response_data, 'all');
            response_data = response_data.replace(/<\?xml.*?\?>/g, ''); // Remove <?xml root element
            response_data = response_data.replace(/<!\[CDATA\[/ig, "").replace(/]]>/ig, ""); // Remove all CDATA
            response_data = parser.xmlToJson(response_data, (err, json) => {
                return err ? {} : json;
            });
        }
        return util.findNestedObj(response_data, key_to_parse, full_json);
    }

    getFinalPrice(campaign_id, base_bid) {
        let base_price = util.parseToFloat(base_bid || 0); // convert the bids into float as it was appending to string
        base_price += this.filter_group_price[campaign_id] || 0;
        if (this.bid_multipliers[campaign_id].length <= 0) {
            this.setDebugData(campaign_id, 'modifier_math', util.parseToFloat(base_price.toFixed(2)));
            return util.parseToFloat(base_price.toFixed(2));
        } else {
            let update_price = base_price;
            let modifier_math = `${base_price}`;
            for (let multiplier of this.bid_multipliers[campaign_id]) {
                if (multiplier >= 0) {
                    update_price = update_price * (multiplier / 100);
                    modifier_math += `*(${multiplier}/100)`
                }
            }
            modifier_math += `=${util.parseToFloat(update_price.toFixed(2))}`;
            this.setDebugData(campaign_id, 'modifier_math', modifier_math);
            return util.parseToFloat(update_price.toFixed(2));
        }
    }

    filterAdGroup(ag_data) {
        let filter_name = ag_data.name;
        if (this.geo_filter.includes(filter_name)) {
            return 1;
        } else {
            return this.filterGroup(ag_data) ? 1 : 0;
        }
    }

    async getIntegrationTemplate(integration, lead_price, data, custom_data = {}) {
        let req_body = {
            token: this.brand_conf.template_api_token,
            lead_integration_id: integration.lead_integration_id,
            campaign_id: integration.campaign_id,
            lead_price: lead_price || 14,
            data: data
        }
        req_body = {
            ...custom_data,
            ...req_body
        }
        let headers = {
            "Accept": 'application/json',
            "Content-Type": 'application/json'
        }
        let resp_body = {data: {}}
        //console.log('template_api: ', this.brand_conf.template_api);
        await axios.post(this.brand_conf.template_api, req_body, {headers: headers}).then(response => {
            resp_body = response.data;
        }).catch(error => {
            errorHandler.notify(error);
            console.log('Error on integration template = ', error.message);
        });
        return {
            template_data: resp_body.data.body || {},
            req_params: resp_body.data.req_params || "",
            url: resp_body.data.posting_url || null,
            headers: resp_body.data.headers || headers
        };
    }

    async integrationRequest(integration, req_method, payout, custom_data = {}) {
        let response = null;
        let integration_template_data = await this.getIntegrationTemplate(integration, payout, this.req_params, custom_data);
        let template_data = integration_template_data.template_data;
        let template_req_params = integration_template_data.req_params;
        let headers = integration_template_data.headers || {};
        integration.posting_url = integration_template_data.url || integration.posting_url;
        headers['SelfIntegration'] = true; // TODO: remove when live
        const request = {
            method: req_method,
            url: integration.posting_url,
            timeout: this.reqIntegrationTimeout(integration.req_timeout)
        }
        if (req_method === 'get') {
            request['params'] = util.stringToJson(template_req_params); // template_data;
            request['headers'] = headers;
        } else if (['post', 'put', 'patch'].includes(req_method)) {
            request['data'] = template_data;
            request['headers'] = headers;
        }
        await axios(request).then(resp => {
            response = resp
        }).catch(error => {
            response = error.response || error;
            console.log(`Error on integrations = url: ${integration.posting_url} -> integration_id: ${integration.id} -> campaign: ${integration.campaign_id}`, error.message);
        });
        return response;
    }

    async getPingMatches(zip, lead_type_id, product, token_bid_multiplier = []) {
        const memcached = AppMemcached.getInstance();
        let mem_key = util.sanitizeMemKey(`ping_match_z_${zip}_p_${product}_l_${lead_type_id}_${this.token_id}`);
        let cached_data = null;
        let cache_secs = 300;
        try {
            cached_data = await memcached.get(mem_key);
        } catch (ex) {
            errorHandler.notify(ex);
        }
        if (cached_data) {
            return cached_data;
        } else {
            let query = `select t4.id                   as account_id,
                                t4.account_manager_id   as account_manager_id,
                                t4.sales_manager_id     as sales_manager_id,
                                t4.insurance_carrier_id as insurance_carrier_id,
                                t3.id                   as campaign_id,
                                t2.id                   as ad_group_id,
                                t3.brand_id             as brand_id,
                                t2.active               as ad_group_active,
                                t2.base_bid_price       as payout,
                                t3.product_type_id      as product_type_id,
                                t5.invoice              as invoice
                         from ad_group_locations t1
                                  inner join ad_groups t2 on t1.ad_group_id = t2.id
                                  inner join campaigns t3 on t3.id = t2.campaign_id
                                  inner join accounts t4 on t3.account_id = t4.id
                                  inner join billing_settings t5 on t5.account_id = t4.id
                         where t1.zip = '${zip}'
                           and t3.product_type_id = ${product}
                           and t3.lead_type_id = '${lead_type_id}'
                           and t2.discarded_at is null
                           and t4.status = 'active'
                           and t3.active is true
                           and t3.discarded_at is null`;
            if (this.token_type === 'admin') {
                query += " and t4.internal = false";
            } else {
                const token_campaign_ids = token_bid_multiplier.map(tbm => tbm.campaign_id);
                if (token_campaign_ids.length > 0) {
                    query += " and t3.id in (" + token_campaign_ids + ")";
                }
            }
            if (this.token_type != 'admin') {
                cache_secs = 3600;
            }
            return (this.read_replica_db || this.db).query(query).then((results) => {
                memcached.set(mem_key, (results.rows || []), cache_secs);
                return results.rows || [];
            }, err => {
                return [];
            });
        }
    }

    getCampaignsTimeZoneDate() {
        return new Promise((resolve, reject) => {
            if (this.campaign_ids.length > 0) {
                let query = "select distinct campaign_id, timezone from campaign_schedules where campaign_id in (" + this.campaign_ids + ") and discarded_at IS NULL";
                this.db.query(query, async (error, results) => {
                    if (error) {
                        resolve({});
                    } else {
                        let campaign_timezones = {};
                        for (let row of results.rows) {
                            let timezone = (row.timezone || 'PST');
                            let date = new Date();
                            if (timezone && util.toLowerCase(timezone) === 'local') {
                                date = await this.getLocalDate();
                            } else {
                                date = this.getDate(timezone);
                            }
                            campaign_timezones[row.campaign_id] = {date: date, timezone: timezone};
                        }
                        resolve(campaign_timezones);
                    }
                });
            } else {
                resolve({});
            }
        });
    }

    selectedListings(listings) {
        let selected_listings = {};
        listings.map(listing => {
            let select_key = `${listing.carrier_id}_${listing.listing_type}`;
            if (listing.carrier_id === '32') {
                select_key = `${listing.license_number}_${listing.listing_type}`;
            }
            if (selected_listings[select_key]) {
                if (selected_listings[select_key].price < listing.price) {
                    selected_listings[select_key] = listing;
                }
            } else {
                selected_listings[select_key] = listing;
            }
            return listing;
        });
        return Object.values(selected_listings);
    }

    applyBrandDedupe(campaigns) {
        let brand_campaigns = {};
        for (let campaign of campaigns) {
            if (brand_campaigns[campaign.brand_id]) {
                let existing_campaign = brand_campaigns[campaign.brand_id];
                if (existing_campaign.price < campaign.price) {
                    brand_campaigns[campaign.brand_id] = campaign;
                }
            } else {
                brand_campaigns[campaign.brand_id] = campaign;
            }
        }
        return Object.values(brand_campaigns);
    }

    reqIntegrationTimeout(timeout) {
        try {
            return (timeout || 30) * 1000;
        } catch (ex) {
            return 5000
        }
    }

    commercialCoverageTypes() {
        let lead = this.req_params;
        if (lead.lead_type_id == '5') {
            let types = [];
            const business_info = lead.business_info || {}
            for (let type of (business_info.commercial_coverage_types || [])) {
                for (const [key, value] of Object.entries(type)) {
                    if (value === true) {
                        types.push(key);
                    }
                }
            }
            return types.join(',');
        } else {
            return '';
        }
    }

    async getPSTColumns() {
        try {
            const timestamp = this.getTimeZoneDate();
            const query = `SELECT DATE_TRUNC('hour', TIMESTAMP '${timestamp}') as pst_hour, DATE_TRUNC('day', TIMESTAMP '${timestamp}') as pst_day, DATE_TRUNC('week', TIMESTAMP '${timestamp}') as pst_week, DATE_TRUNC('month', TIMESTAMP '${timestamp}') as pst_month, DATE_TRUNC('quarter', TIMESTAMP '${timestamp}') as pst_quarter, DATE_TRUNC('year', TIMESTAMP '${timestamp}') as pst_year`;
            return this.db.query(query).then((results) => {
                if (results.rows[0]) {
                    return results.rows[0];
                } else {
                    return {};
                }
            }, err => {
                return {};
            });
        } catch (ex) {
            errorHandler.notify(ex);
            return {};
        }
    }

    getSQLValueSet(results) {
        let value_set = [];
        let counter = 1;
        for (let result of results) {
            let val = []
            for (let key in result) {
                val.push(`$${counter}`);
                counter += 1;
            }
            value_set.push(`(${val})`);
        }
        return value_set.join(', ');
    }

    getTimeZoneDate(dt) {
        const d = new Date(new Date());
        // let timezone_date = d.toLocaleString('en-US', {timeZone: 'America/Los_Angeles', hour12: false})
        let timezone_date = d.toLocaleString('en-US', {timeZone: 'America/Los_Angeles', hourCycle: 'h23'})
        let times = timezone_date.split(', ')[1];
        let date_parts = timezone_date.split(', ')[0].split('/');
        let year = date_parts[2];
        let month = parseInt(date_parts[0]);
        let day = parseInt(date_parts[1]);
        return `${year}${month < 10 ? '0' + month.toString() : month}${day < 10 ? '0' + day.toString() : day} ${times}`
    }

    majorHealthConditions() {
        if (this.req_params.lead_type_id == '2') {
            let medical_histories = this.req_params.medical_history || {};
            for (let key in medical_histories) {
                if (typeof (medical_histories[key]) == 'boolean') {
                    if (medical_histories[key]) {
                        return true;
                    }
                } else if (util.toLowerCase(medical_histories[key]) === 'yes') {
                    return true;
                }
            }
        }
        return false;
    }

    parsePayout(payout, default_payout = 0) {
        if (typeof (payout) === 'string') {
            return parseFloat(payout);
        } else if (typeof (payout) === 'number') {
            return payout
        } else {
            return default_payout;
        }
    }

    responseToString(type, resp) {
        if (util.toLowerCase(type) === 'json') {
            return JSON.stringify(resp);
        } else {
            return resp.toString();
        }
    }

    estimatedPayout(campaign) {
        if (!campaign.enterprise && campaign.allowable_return_perc > 0) {
            return campaign.price - ((campaign.price * (campaign.allowable_return_perc / 100)));
        }
        return campaign.price;
    }

    getDate(timezone) {
        try {
            if (timezone) {
                return new Date(new Date().toLocaleString("en-US", {timeZone: this.getTimezoneID(timezone)}));
            } else {
                return this.date
            }
        } catch (ex) {
            console.log("TimeZone Error: ", ex.message);
            console.log("TimeZone Error: ", timezone);
            return this.date;
        }
    }

    async getLocalDate() {
        let state = util.getParam(this.params, 'state');
        let zip = util.getParam(this.params, 'zip');
        state = util.toLowerCase(state);
        // Update: remove lower(state) condition from the query as it is not using the index and its slowing down the query
        let query = `select zipcodes.timezone
                     from zipcodes
                     where (zipcode = '${zip}')
                       and timezone is not null
                     limit 1`;
        return this.db.query(query).then(results => {
            let timezone_record = results.rows[0] || {timezone: 'PST'};
            let local_timezone = timezone_record.timezone;
            return this.getDate(local_timezone || 'PST');
        }, error => {
            errorHandler.notify(error);
            return this.getDate('PST');
        });
    }

    weekendDiscount(campaign) {
        let discount = 0;
        if (this.isWeekend(campaign.timezone) && campaign.weekend_discount > 0) {
            discount = ((campaign.price * campaign.weekend_discount) / 100)
            this.setDebugData(campaign.campaign_id, 'weekend_discount', discount);
        }
        return discount;
    }

    isWeekend(timezone) {
        let dt = this.getDate(timezone || 'PST');
        return dt.getDay() === 6 || dt.getDay() === 0;
    }

    getInputValue(field) {
        let value = util.getParam(this.params, field);
        if (typeof (value) == 'boolean') {
            return value ? 'Yes' : 'No'
        } else {
            if (typeof (value) === 'undefined' || value == null) {
                return '';
            } else {
                return value;
            }
        }
    }

    numberToTime(number) {
        if (number === 12) {
            return '12pm';
        } else if (number > 12) {
            return `${number - 12}pm`;
        } else {
            return `${number}am`;
        }
    }

    getTimezoneID(timezone) {
        switch (timezone) {
            case 'AKST':
            case 'AK':
                return 'US/Alaska';
            case 'CT':
            case 'CST':
                return 'America/Chicago';
            case 'ET':
            case 'EST':
                return 'America/New_York';
            case 'HST':
                return 'HST';
            case 'MT':
            case 'MST':
                return 'America/Denver';
            case 'HI':
                return 'US/Hawaii';
            case 'PT':
            case 'PST':
                return 'America/Los_Angeles';
            default:
                return timezone;
        }
    }

    collectNonRtbDataExt(listing) {
        return {
            account_manager_id: listing.account_manager_id,
            sales_rep_id: listing.sales_manager_id,
            billing_type_id: listing.invoice ? 1 : 2,
            carrier_id: listing.insurance_carrier_id
        }
    }
}
