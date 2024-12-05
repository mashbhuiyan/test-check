const db = require('../../../test_db');
const ClicksController = require('./mock/clicks_controller');
const auto_json = require('../../../factory/data/auto.json');
const DatasetOne = require("../../../factory/data/dataset1");
const SettingsDataset = require("../../../factory/data/settings_dataset");
const ImportDataset = require("../../../import_dataset");
const assert = require('assert');

describe('ClickController', () => {
    before(async () => {
        await ImportDataset.import(SettingsDataset.getData());
        await ImportDataset.import(DatasetOne.getData());
    });

    describe('First step query', () => {
        let clicksController = new ClicksController();
        let req = {
            brand_conf: {db: db},
            body: {...auto_json, ...{campaign_bid_multipliers: [{"campaign_id":1,"multiplier":100}]}},
            params: {},
            headers: { authorization: 'Bearer 123456789' },
        };
        it('Should return one listing', async () => {
            let response = await clicksController.index(req);
            assert.strictEqual(response.step1_listings.length, 1);
        });
    });
});
