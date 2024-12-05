const Click = require('../../app/models/click');
const db = require('../test_db');
const auto_json = require('../factory/data/auto.json');
const flatten = require('flat');
const util = require('../../app/models/utils');
const assert = require('assert');
const ImportDataset = require('../import_dataset');
const SettingsDataset = require('../factory/data/settings_dataset');
const DatasetOne = require('../factory/data/dataset1');
const ClicksController = require('../controllers/api/v1/mock/clicks_controller');
const uuid = require('uuid');
const sleep = require('../../app/lib/sleep');

describe('Click', () => {
    before(async () => {
        await ImportDataset.import(SettingsDataset.getData());
        await ImportDataset.import(DatasetOne.getData());
    });

    const campaign_id = 1;
    const bid_multiplier = 100;
    let req = {
        brand_conf: {db: db, name: 'smartfinancial'},
        body: {...auto_json, ...{campaign_bid_multipliers: [{"campaign_id": campaign_id, "multiplier": bid_multiplier}]}},
        params: {},
        headers: { authorization: 'Bearer 123456789' },
    };
    const params = req.body ? req.body.lead : {};
    const f_params = flatten(params);
    f_params.age = util.getAge(f_params);

    describe('#scheduleModifier()', () => {
        describe('when campaign_ids has nothing in it', () => {
            it('Should return failed promise response', async () => {
                const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
                const scheduleModifier = await clickModel.scheduleModifier();
                assert.strictEqual(scheduleModifier, 'failed');
            });
        });

        describe('when campaign_ids has campaign id in it', () => {
            describe('when campaign schedule found & hour multiplier in it', () => {
                it('Should return success promise response and set campaign bid multiplier', async () => {
                    const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
                    clickModel.campaign_ids = [campaign_id];
                    clickModel.bid_multipliers[campaign_id] = [];
                    const scheduleModifier = await clickModel.scheduleModifier();
                    assert.strictEqual(scheduleModifier, 'success');
                    assert.strictEqual(clickModel.bid_multipliers[campaign_id][0], bid_multiplier);
                    assert.strictEqual(clickModel.campaign_exclusion.length, 0);
                });
            });

            describe('when campaign schedule found but no hour multiplier found', async () => {
                it('Should return success promise response and campaign added to the campaign_exclusion', async () => {
                    const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
                    let date;
                    const timezone = 'America/Los_Angeles';
                    if (timezone && util.toLowerCase(timezone) === 'local') {
                        date = await clickModel.getLocalDate();
                    } else {
                        date = clickModel.getDate(timezone);
                    }
                    let hour_field = "h" + date.getHours();
                    await db.query(`update campaign_schedules set ${hour_field} = $1 where id = $2`, [0, 1]);
                    clickModel.campaign_ids = [campaign_id];
                    clickModel.bid_multipliers[campaign_id] = [];
                    const scheduleModifier = await clickModel.scheduleModifier();
                    assert.strictEqual(scheduleModifier, 'success');
                    assert.strictEqual(clickModel.bid_multipliers[campaign_id].length, 0);
                    assert.equal(clickModel.campaign_exclusion[0], campaign_id);
                });
            });

            describe('when campaign schedule not found', () => {
                it('Should return success promise response and campaign added to the campaign_exclusion', async () => {
                    const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
                    let date;
                    const timezone = 'America/Los_Angeles';
                    if (timezone && util.toLowerCase(timezone) === 'local') {
                        date = await clickModel.getLocalDate();
                    } else {
                        date = clickModel.getDate(timezone);
                    }
                    let day_id = date.getDay();
                    if (day_id === 6) {
                        day_id = 0;
                    } else {
                        ++day_id;
                    }
                    await db.query(`update campaign_schedules set day_id = $1 where id = $2`, [day_id, 1]);
                    clickModel.campaign_ids = [campaign_id];
                    clickModel.bid_multipliers[campaign_id] = [];
                    const scheduleModifier = await clickModel.scheduleModifier();
                    assert.strictEqual(scheduleModifier, 'success');
                    assert.strictEqual(clickModel.bid_multipliers[campaign_id].length, 0);
                    assert.equal(clickModel.campaign_exclusion[0], campaign_id);
                });
            });
        });
    });

    describe('#getInputValue()', () => {
        describe('when field value boolean true', () => {
            it('Should return Yes', async () => {
                const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
                assert.strictEqual(clickModel.getInputValue('incident_at_fault'), 'Yes');
            });
        });
        describe('when field value boolean false', () => {
            it('Should return No', async () => {
                const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
                clickModel.params['drivers.0.accidents.0.incident_at_fault'] = false;
                assert.strictEqual(clickModel.getInputValue('incident_at_fault'), 'No');
            });
        });
        describe('when field value undefined/null', () => {
            it('Should return empty string', async () => {
                const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
                assert.strictEqual(clickModel.getInputValue('test_data'), '');
            });
        });
        describe('when field value present and type not boolean', () => {
            it('Should return field value from params', async () => {
                const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
                assert.strictEqual(clickModel.getInputValue('email'), 'email@smartfinancial.com');
            });
        });
    });

    describe('#getFreeFormMultiSelectValue()', () => {
        const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
        describe('when got invalid json data to parse in filter_value', () => {
            it('Should return empty array from exception handler', async () => {
                const filter_data = {filter_value: 'Equal To'};
                const res = clickModel.getFreeFormMultiSelectValue('multi-select', filter_data);
                assert.strictEqual(res.length, 0);
            });
        });
        describe('when type multi-select and filter_value null', () => {
            it('Should return empty array', async () => {
                const filter_data = {filter_value: null};
                const res = clickModel.getFreeFormMultiSelectValue('multi-select', filter_data);
                assert.strictEqual(res.length, 0);
            });
        });
        describe('when type multi-select and filter_value is a json string array', () => {
            it('Should return parsed array of filter_value', async () => {
                const filter_data = {filter_value: '["Excellent", "Good", "Average", "Poor", "Unknown"]'};
                const res = clickModel.getFreeFormMultiSelectValue('multi-select', filter_data);
                assert.strictEqual(res.length, 5);
            });
        });
        describe('when type is not multi-select and filter_value_array is an array', () => {
            it('Should return filter_value_array array', async () => {
                const filter_data = {filter_value_array: ['Excellent', 'Good']};
                const res = clickModel.getFreeFormMultiSelectValue('single-select', filter_data);
                assert.strictEqual(res.length, 2);
            });
        });
        describe('when type is not multi-select and filter_value_array is json string array', () => {
            it('Should return parsed filter_value_array array', async () => {
                const filter_data1 = {filter_value_array: '["Excellent", "Good"]'};
                const filter_data2 = {filter_value_array: '{"Excellent", "Good"}'};
                const filter_data3 = {filter_value_array: null};
                let res = clickModel.getFreeFormMultiSelectValue('single-select', filter_data1);
                assert.strictEqual(res.length, 2);
                assert.strictEqual(res[0], "Excellent");
                res = clickModel.getFreeFormMultiSelectValue('single-select', filter_data2);
                assert.strictEqual(res.length, 2);
                assert.strictEqual(res[0], "Excellent");
                res = clickModel.getFreeFormMultiSelectValue('single-select', filter_data3);
                assert.strictEqual(res.length, 0);
            });
        });
    });

    describe('#getMaxMinFilter()', () => {
        const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
        describe('when filter_type min-max and filter_value is Between', () => {
            it('Should return true', () => {
                const filter_data = {filter_value: ["Between"], query_param: 'age', filter_type: 'min-max', include: true, filter_value_max: 50, filter_value_min: 20};
                const res = clickModel.getMaxMinFilter(filter_data, 39);
                assert.strictEqual(res, true);
            });
        });
        describe('when filter_type min-max and filter_value is Equal To', () => {
            it('Should return true', () => {
                const filter_data = {filter_value: ["Equal To"], query_param: 'age', filter_type: 'min-max', include: true, filter_value_max: 39, filter_value_min: 20};
                const res = clickModel.getMaxMinFilter(filter_data, 39);
                assert.strictEqual(res, true);
            });
        });
        describe('when filter_type min-max and filter_value is Less Than', () => {
            it('Should return true', () => {
                const filter_data = {filter_value: ["Less Than"], query_param: 'age', filter_type: 'min-max', include: true, filter_value_max: 50, filter_value_min: 20};
                const res = clickModel.getMaxMinFilter(filter_data, 39);
                assert.strictEqual(res, true);
            });
        });
        describe('when filter_type min-max and filter_value is More Than', () => {
            it('Should return true', () => {
                const filter_data = {filter_value: ["More Than"], query_param: 'age', filter_type: 'min-max', include: true, filter_value_max: 50, filter_value_min: 20};
                const res = clickModel.getMaxMinFilter(filter_data, 39);
                assert.strictEqual(res, true);
            });
        });
    });

    describe('#filterGroup()', () => {
        const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
        describe('when filter_type is single-select and include true', () => {
            it('Should return true', () => {
                const filter_data = {filter_value: 'Active', query_param: 'license_status', filter_type: 'single-select', include: true};
                const res = clickModel.filterGroup(filter_data);
                assert.strictEqual(res, true);
            });
        });
        describe('when filter_type single-select and include false', () => {
            it('Should return false', () => {
                const filter_data = {filter_value: 'Active', query_param: 'license_status', filter_type: 'single-select', include: false};
                const res = clickModel.filterGroup(filter_data);
                assert.strictEqual(res, false);
            });
        });
        describe('when filter_type multi-select and include true', () => {
            it('Should return true', () => {
                const filter_data = {filter_value: '["Excellent", "Good"]', query_param: 'credit', filter_type: 'multi-select', include: true};
                const res = clickModel.filterGroup(filter_data);
                assert.strictEqual(res, true);
            });
        });
        describe('when filter_type min-max and filter_value is Between', () => {
            it('Should return true', () => {
                const filter_data = {filter_value: ["Between"], query_param: 'age', filter_type: 'min-max', include: true, filter_value_max: 50, filter_value_min: 20};
                const res = clickModel.filterGroup(filter_data);
                assert.strictEqual(res, true);
            });
        });
    });

    describe('#filterCampaignGroup()', () => {
        const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
        describe('when accept_unknown is true', () => {
            describe('when input value not found', () => {
                it('Should return true', () => {
                    const filter_data = {accept_unknown: true, filter_value: ["Between"], query_param: 'age_data', filter_type: 'min-max', include: true, filter_value_max: 50, filter_value_min: 20};
                    const res = clickModel.filterCampaignGroup(filter_data);
                    assert.strictEqual(res, true);
                });
            });
            describe('when input value present', () => {
                it('Should return false because age 39 is not between min max value', () => {
                    const filter_data = {accept_unknown: true, filter_value: ["Between"], query_param: 'age', filter_type: 'min-max', include: true, filter_value_max: 50, filter_value_min: 40};
                    const res = clickModel.filterCampaignGroup(filter_data);
                    assert.strictEqual(res, false);
                });
            });
        });
        describe('when accept_unknown is false', () => {
            describe('when input value not found', () => {
                it('Should return false', () => {
                    const filter_data = {accept_unknown: false, filter_value: ["Between"], query_param: 'age_data', filter_type: 'min-max', include: true, filter_value_max: 50, filter_value_min: 20};
                    const res = clickModel.filterCampaignGroup(filter_data);
                    assert.strictEqual(res, false);
                });
            });
            describe('when input value present', () => {
                it('Should return true because age is in between min-max and include is true', () => {
                    const filter_data = {accept_unknown: true, filter_value: ["Between"], query_param: 'age', filter_type: 'min-max', include: true, filter_value_max: 50, filter_value_min: 20};
                    const res = clickModel.filterCampaignGroup(filter_data);
                    assert.strictEqual(res, true);
                });
            });
        });
    });

    describe('#getFilterCondition()', () => {
        const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
        describe('when filter_type is single-select', () => {
            describe('when include is true', () => {
                it('Should return query string with "=="', () => {
                    const filter_data = {filter_value: 'Active', query_param: 'license_status', filter_type: 'single-select', include: true};
                    const res = clickModel.getFilterCondition(filter_data);
                    assert.strictEqual(res, `${filter_data.query_param} (Active) == ${filter_data.filter_value}`);
                });
            });
            describe('when include is false', () => {
                it('Should return query string with "!="', () => {
                    const filter_data = {filter_value: 'Active', query_param: 'license_status', filter_type: 'single-select', include: false};
                    const res = clickModel.getFilterCondition(filter_data);
                    assert.strictEqual(res, `${filter_data.query_param} (Active) != ${filter_data.filter_value}`);
                });
            });
        });
        describe('when filter_type is multi-select or free-form', () => {
            describe('when include is true', () => {
                it('Should return query string with "in"', () => {
                    const filter_data = {filter_value: '["Excellent", "Good"]', query_param: 'credit', filter_type: 'multi-select', include: true};
                    const res = clickModel.getFilterCondition(filter_data);
                    assert.strictEqual(res, `${filter_data.query_param} (Good) in ${JSON.parse(filter_data.filter_value).join(',')}`);
                });
            });
            describe('when include is false', () => {
                it('Should return query string with "not in"', () => {
                    const filter_data = {filter_value: '["Excellent", "Good"]', query_param: 'credit', filter_type: 'multi-select', include: false};
                    const res = clickModel.getFilterCondition(filter_data);
                    assert.strictEqual(res, `${filter_data.query_param} (Good) not in ${JSON.parse(filter_data.filter_value).join(',')}`);
                });
            });
        });
        describe('when filter_type is min-max', () => {
            describe('when include is true', () => {
                describe('when filter_value is "Equal To" or "Less Than"', () => {
                    it('Should return query string with max value', () => {
                        const filter_data = {filter_value: ["Equal To"], query_param: 'age', filter_type: 'min-max', include: true, filter_value_max: 50, filter_value_min: 20};
                        const res = clickModel.getFilterCondition(filter_data);
                        assert.strictEqual(res, `${filter_data.query_param} (39) ${filter_data.filter_value[0]}  ${filter_data.filter_value_max}`);
                    });
                });
                describe('when filter_value is "More Than"', () => {
                    it('Should return query string with min value', () => {
                        const filter_data = {filter_value: ["More Than"], query_param: 'age', filter_type: 'min-max', include: true, filter_value_max: 50, filter_value_min: 20};
                        const res = clickModel.getFilterCondition(filter_data);
                        assert.strictEqual(res, `${filter_data.query_param} (39) ${filter_data.filter_value[0]}  ${filter_data.filter_value_min}`);
                    });
                });
                describe('when filter_value is "Between"', () => {
                    it('Should return query string with min-max value', () => {
                        const filter_data = {filter_value: ["Between"], query_param: 'age', filter_type: 'min-max', include: true, filter_value_max: 50, filter_value_min: 20};
                        const res = clickModel.getFilterCondition(filter_data);
                        assert.strictEqual(res, `${filter_data.query_param} (39) ${filter_data.filter_value[0]}  ${filter_data.filter_value_min} and ${filter_data.filter_value_max}`);
                    });
                });
            });
            describe('when include is false', () => {
                describe('when filter_value is "Equal To" or "Less Than"', () => {
                    it('Should return query string with max value and not', () => {
                        const filter_data = {filter_value: ["Equal To"], query_param: 'age', filter_type: 'min-max', include: false, filter_value_max: 50, filter_value_min: 20};
                        const res = clickModel.getFilterCondition(filter_data);
                        assert.strictEqual(res, `${filter_data.query_param} (39) Not ${filter_data.filter_value[0]}  ${filter_data.filter_value_max}`);
                    });
                });
            });
        });
    });

    describe('#filterGroups()', () => {
        const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
        describe('when campaign_ids has nothing in it', () => {
            it('Should return error promise response', async () => {
                const filterGroup = await clickModel.filterGroups();
                assert.strictEqual(filterGroup, 'error');
            });
        });
        describe('when campaign_ids has campaign id in it', () => {
            beforeEach(() => {
                clickModel.campaign_ids = [campaign_id];
                clickModel.filter_campaign_list = [];
                clickModel.filter_group_price = {};
                clickModel.debug_data.campaigns[campaign_id] = { filter_groups: [] };
            });
            describe('when campaign filters are included', () => {
                it('Should return sum of prices and campaign id', async () => {
                    await clickModel.filterGroups();
                    assert.strictEqual(Object.keys(clickModel.filter_group_price)[0], '1');
                    assert.strictEqual(Object.values(clickModel.filter_group_price)[0], 27);
                    assert.strictEqual(clickModel.filter_campaign_list.length, 1);
                    assert.strictEqual(clickModel.filter_campaign_list[0], '1');
                    assert.strictEqual(clickModel.debug_data.campaigns[campaign_id].filter_groups.length, 4);
                });
            });
            describe('when campaign filters are not all included', () => {
                it('Should return sum of prices and campaign id', async () => {
                    await db.query(`update campaign_filters set filter_value_max = $1 where id = $2`, [50, 2]);
                    await clickModel.filterGroups();
                    assert.strictEqual(Object.keys(clickModel.filter_group_price)[0], '1');
                    assert.strictEqual(Object.values(clickModel.filter_group_price)[0], 0);
                    assert.strictEqual(clickModel.filter_campaign_list.length, 0);
                    assert.strictEqual(clickModel.debug_data.campaigns[campaign_id].filter_groups.length, 4);
                });
            });
        });
    });

    describe('#modifierGroups()', () => {
        const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
        describe('when campaign_ids has nothing in it', () => {
            it('Should return blank promise response', async () => {
                const modifierGroups = await clickModel.modifierGroups();
                assert.strictEqual(modifierGroups.length, 0);
            });
        });
        describe('when campaign_ids has campaign id in it', () => {
            beforeEach(() => {
                clickModel.campaign_ids = [campaign_id];
                clickModel.bid_multipliers[campaign_id] = [];
                clickModel.debug_data.campaigns[campaign_id] = { bid_modifiers_groups: [] };
            });
            describe('when filterGroup return true', () => {
                it('Should return campaign with bid_percent', async () => {
                    const modifierGroups = await clickModel.modifierGroups();
                    assert.strictEqual(modifierGroups[campaign_id][0], 140);
                    assert.strictEqual(clickModel.debug_data.campaigns[campaign_id].bid_modifiers_groups[0].multiplier, 140);
                    assert.strictEqual(clickModel.debug_data.campaigns[campaign_id].bid_modifiers_groups[0].qualified, true);
                });
            });
            describe('when filterGroup return false', () => {
                it('Should return campaign with 0', async () => {
                    await db.query(`update campaign_bid_modifiers set filter_value = $1 where id = $2`, ['No', 1]);
                    const modifierGroups = await clickModel.modifierGroups();
                    assert.strictEqual(modifierGroups[campaign_id][0], 0);
                    assert.strictEqual(clickModel.debug_data.campaigns[campaign_id].bid_modifiers_groups[0].multiplier, 140);
                    assert.strictEqual(clickModel.debug_data.campaigns[campaign_id].bid_modifiers_groups[0].qualified, false);
                });
            });
        });
    });
    describe('#filterAdGroup()', () => {
        const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
        describe('When geo_filter includes filter name', () => {
            it('Should return 1', () => {
                const filterAdGroup = clickModel.filterAdGroup({name: 'State'});
                assert.strictEqual(filterAdGroup, 1);
            });
        });
        describe('When filter name not included in geo_filter', () => {
            describe('When query_param value found in filter_value', () => {
                it('Should return 1 as response', () => {
                    const filter_data = {filter_value: '["Excellent", "Good"]', query_param: 'credit', filter_type: 'multi-select', include: true, name: 'Credit Rating'};
                    const filterAdGroup = clickModel.filterAdGroup(filter_data);
                    assert.strictEqual(filterAdGroup, 1);
                });
            });
            describe('When query_param value not found in filter_value', () => {
                it('Should return 0 as response', () => {
                    const filter_data = {filter_value: ["Test", "Demo"], query_param: 'credit', filter_type: 'multi-select', include: true, name: 'Credit Rating'};
                    const filterAdGroup = clickModel.filterAdGroup(filter_data);
                    assert.strictEqual(filterAdGroup, 0);
                });
            });
        });
    });

    describe('#qualifyAdGroup()', () => {
        const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
        describe('When campaign_ids has nothing in it', () => {
            it('Should return blank promise response', async () => {
                const qualifyAdGroup = await clickModel.qualifyAdGroup();
                assert.strictEqual(qualifyAdGroup.length, 0);
            });
        });
        describe('when campaign_ids has campaign id in it', () => {
            beforeEach(() => {
                clickModel.campaign_ids = [campaign_id];
                clickModel.debug_data.campaigns[campaign_id] = { ad_group_filter_groups: [] };
                clickModel.campaign_exclusion = [];
            });
            describe('When we have qualified ad group', () => {
                it('Should return array with qualified ad group id', async () => {
                    const qualifyAdGroup = await clickModel.qualifyAdGroup();
                    assert.strictEqual(qualifyAdGroup[0], '1');
                    assert.strictEqual(clickModel.campaign_exclusion.length, 0);
                    assert.strictEqual(clickModel.debug_data.campaigns[campaign_id].ad_group_filter_groups[0].id, '1');
                    assert.strictEqual(clickModel.debug_data.campaigns[campaign_id].ad_group_filter_groups[0].qualified, 1);
                });
            });
            describe('When qualified ad group not found', () => {
                it('Should return blank array', async () => {
                    await db.query(`update ad_group_filters set filter_value = $1 where id = $2`, ['["No"]', 1]);
                    const qualifyAdGroup = await clickModel.qualifyAdGroup();
                    assert.strictEqual(qualifyAdGroup.length, 0);
                    assert.strictEqual(clickModel.campaign_exclusion[0], '1');
                    assert.strictEqual(clickModel.debug_data.campaigns[campaign_id].ad_group_filter_groups[0].id, '1');
                    assert.strictEqual(clickModel.debug_data.campaigns[campaign_id].ad_group_filter_groups[0].qualified, 0);
                });
            });
        });
    });

    describe('#adGroups()', () => {
        const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
        describe('When campaign_ids has nothing in it', () => {
            it('Should return blank promise response', async () => {
                const adGroups = await clickModel.adGroups();
                assert.strictEqual(adGroups.length, 0);
            });
        });
        describe('When campaign_ids has campaign_id in it', () => {
            before(async () => {
                await db.query(`update ad_group_filters set filter_value = $1 where id = $2`, ['["Good"]', 1]);
            });
            describe('When we have qualified ad group', () => {
                it('Should return campaign id with qualified ads', async () => {
                    clickModel.campaign_ids = [campaign_id];
                    clickModel.debug_data.campaigns[campaign_id] = {ad_group_filter_groups: []};
                    clickModel.campaign_exclusion = [];
                    clickModel.ads[campaign_id] = [];
                    const adGroups = await clickModel.adGroups();
                    assert.strictEqual(adGroups[campaign_id].length, 2);
                    assert.strictEqual(clickModel.campaign_exclusion.length, 0);
                    assert.strictEqual(clickModel.debug_data.campaigns[campaign_id].ad_group_filter_groups[0].id, '1');
                    assert.strictEqual(clickModel.debug_data.campaigns[campaign_id].ad_group_filter_groups[0].qualified, 1);
                });
            });
            describe('When we have no qualified ad group', () => {
                it('Should return blank promise response', async () => {
                    clickModel.campaign_ids = [2];
                    clickModel.debug_data.campaigns = {};
                    clickModel.debug_data.campaigns[2] = { ad_group_filter_groups: [] };
                    clickModel.campaign_exclusion = [];
                    clickModel.ads = {};
                    clickModel.ads[2] = [];
                    const adGroups = await clickModel.adGroups();
                    assert.strictEqual(adGroups.length, 0);
                });
            });
        });
    });

    describe('#getIntegrations()', () => {
        const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
        describe('When phase is a String', () => {
            it('Should return one integration', async () => {
                const integrations = await clickModel.getIntegrations([campaign_id], 'pre-ping');
                assert.strictEqual(integrations.length, 1);
            });
        });
        describe('When phase is an Array', () => {
            it('Should return one integration under pre-ping', async () => {
                const integrations = await clickModel.getIntegrations([campaign_id], ['ping', 'pre-ping']);
                assert.strictEqual(integrations['pre-ping'].length, 1);
            });
        });
        describe('When phase not sent', () => {
            describe('When no lead integration found', () => {
                it('Should return empty array for accept_reject and general', async () => {
                    const integrations = await clickModel.getIntegrations([campaign_id]);
                    assert.strictEqual(integrations[campaign_id].accept_reject.length, 0);
                    assert.strictEqual(integrations[campaign_id].general.length, 0);
                });
            });
            describe('When lead integration found', () => {
                it('Should return one integration under general', async () => {
                    await db.query(`update lead_integrations set is_ping = $1 where id = $2`, [false, 1]);
                    const integrations = await clickModel.getIntegrations([campaign_id]);
                    assert.strictEqual(integrations[campaign_id].accept_reject.length, 0);
                    assert.strictEqual(integrations[campaign_id].general.length, 1);
                });
            });
        });
    });
    describe('#getFinalPrice()', () => {
        const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
        describe('When bid_multipliers and filter_group_price are empty', () => {
            it('Should return base price in float with 2 decimal digit', () => {
                clickModel.bid_multipliers = {1: []};
                clickModel.filter_group_price = {};
                clickModel.debug_data.campaigns = {1: {}};
                const final_price = clickModel.getFinalPrice(campaign_id, 9.546);
                assert.strictEqual(final_price, 9.55);
                assert.strictEqual(clickModel.debug_data.campaigns[1].modifier_math, 9.55);
            });
        });
        describe('When bid_multipliers and filter_group_price are set', () => {
            it('Should return formatted modifier math', () => {
                clickModel.bid_multipliers = {1: [140]};
                clickModel.filter_group_price = {1: 10};
                clickModel.debug_data.campaigns = {1: {}};
                const final_price = clickModel.getFinalPrice(campaign_id, 9.546);
                const price = util.parseToFloat(((9.546 + 10) * (140 / 100)).toFixed(2));
                assert.strictEqual(final_price, price);
                assert.strictEqual(clickModel.debug_data.campaigns[1].modifier_math, `${9.546 + 10}*(140/100)=${price}`);
            });
        });
    });
    describe('#getCampaignsTimeZoneDate()', () => {
        const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
        describe('When no campaign set', () => {
            it('Should return empty object', async () => {
                const dateData = await clickModel.getCampaignsTimeZoneDate();
                assert.strictEqual(Object.keys(dateData).length, 0);
            });
        });
        describe('When campaign set', () => {
            it('Should return date with timezone', async () => {
                clickModel.campaign_ids = [campaign_id];
                const dateData = await clickModel.getCampaignsTimeZoneDate();
                assert.strictEqual(dateData[campaign_id].timezone, 'America/Los_Angeles');
            });
        });
    });
    describe('#getCampaignScheduleActiveTime()', () => {
        const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
        describe('When campaign schedule not found', () => {
            it('Should return 1 as response', async () => {
                clickModel.campaign_ids = [campaign_id];
                const dateData = await clickModel.getCampaignsTimeZoneDate();
                const getCampaignScheduleActiveTime = await clickModel.getCampaignScheduleActiveTime(1, dateData[1].date, dateData[1].timezone);
                assert.strictEqual(getCampaignScheduleActiveTime, 1);
            });
        });
        describe('When campaign schedule found', () => {
            it('Should return 1 as response', async () => {
                await ImportDataset.importTable('campaign_schedules', DatasetOne.getData()['campaign_schedules']);
                clickModel.campaign_ids = [campaign_id];
                const dateData = await clickModel.getCampaignsTimeZoneDate();
                const getCampaignScheduleActiveTime = await clickModel.getCampaignScheduleActiveTime(1, dateData[1].date, dateData[1].timezone);
                assert.ok(getCampaignScheduleActiveTime > 1);
            });
        });
    });
    describe('#calculateBPFMScore()', () => {
        const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
        describe('When campaign_exclusion includes listing campaign', () => {
            it('Should return same listing', async () => {
                const listing = { campaign_id: 1 };
                clickModel.campaign_ids = [campaign_id];
                clickModel.campaign_exclusion = [campaign_id];
                const dateData = await clickModel.getCampaignsTimeZoneDate();
                const calculatedListing = await clickModel.calculateBPFMScore(listing, dateData[1]);
                assert.strictEqual(Object.keys(calculatedListing).length, 1);
            });
        });
        describe('When listing bpfm_status is false', () => {
            it('Should return listing with bpfm_score 0', async () => {
                const listing = { campaign_id: 1, bpfm_status: false };
                clickModel.campaign_ids = [campaign_id];
                clickModel.campaign_exclusion = [];
                const dateData = await clickModel.getCampaignsTimeZoneDate();
                const calculatedListing = await clickModel.calculateBPFMScore(listing, dateData[1]);
                assert.strictEqual(calculatedListing.bpfm_score, 0);
            });
        });
        describe('When listing price is less than listing floor_cpc', () => {
            it('Should return listing with bpfm_score 200', async () => {
                const listing = { campaign_id: 1, bpfm_status: true, price: 10, floor_cpc: 20 };
                clickModel.campaign_ids = [campaign_id];
                clickModel.campaign_exclusion = [];
                const dateData = await clickModel.getCampaignsTimeZoneDate();
                const calculatedListing = await clickModel.calculateBPFMScore(listing, dateData[1]);
                assert.strictEqual(calculatedListing.bpfm_score, 200);
            });
        });
        describe('When listing attributes meet to calculate bpfm_score', () => {
            it('Should return listing with bpfm_score 200', async () => {
                const listing = { campaign_id: 1, bpfm_status: true, price: 10, floor_cpc: 1, target_cpc: 5, timezone: 'America/Los_Angeles', budgets: 10, volume_budget: 10, spent: 2 };
                clickModel.campaign_ids = [campaign_id];
                clickModel.campaign_exclusion = [];
                const dateData = await clickModel.getCampaignsTimeZoneDate();
                const calculatedListing = await clickModel.calculateBPFMScore(listing, dateData[1]);
                assert.ok(calculatedListing.bpfm_score > 0);
            });
        });
    });
    describe('#applyBPFMScore()', () => {
        const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
        describe('When phase is a String', () => {
            it('Should return one integration', async () => {
                clickModel.campaign_ids = [campaign_id];
                clickModel.campaign_exclusion = [];
                const listings = [
                    { campaign_id: 1, bpfm_status: true, price: 10, floor_cpc: 1, target_cpc: 5, timezone: 'America/Los_Angeles', budgets: 10, volume_budget: 10, spent: 2 },
                    { campaign_id: 2, bpfm_status: false, price: 10, floor_cpc: 1, target_cpc: 5, timezone: 'America/Los_Angeles', budgets: 10, volume_budget: 10, spent: 2 },
                ];
                const calculatedListings = await clickModel.applyBPFMScore(listings);
                assert.ok(calculatedListings[0].bpfm_score > 0);
                assert.strictEqual(calculatedListings[1].bpfm_score, 0);
            });
        });
    });
    describe('#checkPingFunctions()', async () => {
        const clickModel = new Click(req.brand_conf, f_params, req.body.campaign_bid_multipliers);
        const startTime = new Date().getTime();
        beforeEach(async () => {
            clickModel.params.currently_insured = 'No';
            clickModel.params.age = 50;
            await ImportDataset.truncateTable(['click_opportunities', 'click_pings', 'click_listings', 'click_results']);
            const controllerResp = await new ClicksController().index(req);
            clickModel.campaign_list = controllerResp.step1_listings;
            clickModel.initData();
            const phase_integrations = await clickModel.getIntegrations(clickModel.campaign_ids, ['ping', "pre-ping", "price_presentation", "pre_fill"]);
            clickModel.ping_integrations = phase_integrations['ping'] || [];
            await clickModel.scheduleModifier();
            await clickModel.filterGroups();
            await clickModel.modifierGroups();
            await clickModel.adGroups();
            const click_pings = await db.query('select id from click_pings limit 1');
            clickModel.ping_id = click_pings.rows[0].id;
        });
        describe('#processResponse()', () => {
            describe('When all modifiers qualified', () => {
                it('Should return one listing', async () => {
                    const response = await clickModel.processResponse(startTime);
                    assert.strictEqual(response.listings.length, 1);
                });
            });
        });
        describe('#applyClickIntegration()', () => {
            describe('When all modifiers qualified and processed listing returned', () => {
                it('Should return click_id, click_url with campaign', async () => {
                    const response = await clickModel.processResponse(startTime);
                    const listing = response.listings[0];
                    const click_id = uuid.v4().replace(/-/g, '');
                    const data = {
                        click_id: click_id,
                        aid: listing.pub_aid || params.aid,
                        cid: listing.pub_cid || params.cid,
                        clk_cost: listing.price
                    }
                    const campaign = await clickModel.applyClickIntegration(listing, data);
                    assert.strictEqual(campaign.click_id, click_id);
                    assert.strictEqual(campaign.click_url, 'www.google.com');
                });
            });
        });
        describe('#storeClickOpportunity()', () => {
            describe('When all modifiers qualified', () => {
                it('Should add a click_opportunity', async () => {
                    const response = await clickModel.processResponse(startTime);
                    const listing = response.listings[0];
                    const click_id = uuid.v4().replace(/-/g, '');
                    const data = {
                        click_id: click_id,
                        aid: listing.pub_aid || params.aid,
                        cid: listing.pub_cid || params.cid,
                        clk_cost: listing.price
                    }
                    clickModel.source_type_id = 1;
                    await clickModel.applyClickIntegration(listing, data);
                    clickModel.storeClickOpportunity();
                    await sleep(2000);
                    const click_opportunity = await db.query('select count(*) from click_opportunities');
                    assert.strictEqual(click_opportunity.rows[0].count, '1');
                });
            });
        });
        describe('#applyPrePingIntegration()', () => {
            describe('When all modifiers qualified', () => {
                it('Should return one pre_ping_listings', async () => {
                    const response = await clickModel.processResponse(startTime);
                    const listing = response.listings[0];
                    const click_id = uuid.v4().replace(/-/g, '');
                    const data = {
                        click_id: click_id,
                        aid: listing.pub_aid || params.aid,
                        cid: listing.pub_cid || params.cid,
                        clk_cost: listing.price
                    }
                    clickModel.source_type_id = 1;
                    const campaign = await clickModel.applyClickIntegration(listing, data);
                    const pre_ping_listings = await clickModel.applyPrePingIntegration([campaign]);
                    assert.strictEqual(pre_ping_listings.length, 1);
                });
            });
        });
        describe('#storeClickListing()', () => {
            describe('When all modifiers qualified', () => {
                it('Should save one listing', async () => {
                    const response = await clickModel.processResponse(startTime);
                    const listing = response.listings[0];
                    const click_id = uuid.v4().replace(/-/g, '');
                    const data = {
                        click_id: click_id,
                        aid: listing.pub_aid || params.aid,
                        cid: listing.pub_cid || params.cid,
                        clk_cost: listing.price
                    }
                    clickModel.source_type_id = 1;
                    const campaign = await clickModel.applyClickIntegration(listing, data);
                    const pre_ping_listings = await clickModel.applyPrePingIntegration([campaign]);
                    const listingRes = await clickModel.storeClickListing(pre_ping_listings);
                    assert.strictEqual(listingRes.length, 1);
                    await sleep(2000);
                    const click_listings = await db.query('select count(*) from click_listings');
                    const click_results = await db.query('select count(*) from click_results');
                    assert.strictEqual(click_listings.rows[0].count, '1');
                    assert.strictEqual(click_results.rows[0].count, '1');
                });
            });
        });
    });
    // describe('#getMacroFieldValue()', () => {
    //     describe('When all modifiers qualified', () => {
    //         it('Should save one listing', async () => {
    //         });
    //     });
    // });
    // describe('#getMacroUrl()', () => {
    //     describe('When all modifiers qualified', () => {
    //         it('Should save one listing', async () => {
    //         });
    //     });
    // });
    // describe('#applyMacros()', () => {
    //     describe('When all modifiers qualified', () => {
    //         it('Should save one listing', async () => {
    //         });
    //     });
    // });
});
