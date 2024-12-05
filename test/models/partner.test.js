require('../../app/models/partner');
require('dotenv').config();
const mongoose = require('mongoose');
var assert = require('assert');
const Partner = mongoose.model('Partner');

describe.skip('Partner', () => {
    beforeEach((done) => {
        mongoose.connection.collections.partners.drop(() => {
            done();
        });
    });
    describe('when partner created with valid data', () => {
        it('should return the new partner', (done) => {
            const partner = new Partner({
                name: 'Partner',
                module: 'Module',
                timeout: 7000
            });
            partner.save().then(async () => {
                assert.ok(!partner.isNew);
                const count = await Partner.count({});
                assert.strictEqual(count, 1);
                assert.ok(partner.active);
                assert.strictEqual(partner.timeout, 7000);
                done();
            }).catch(error => {
                console.log(error);
            });
        });
    });
    describe('when required data not present', () => {
        it('should not save partner', (done) => {
            const partner = new Partner({
                name: 'Partner',
                timeout: 7000
            });
            partner.save().then(() => {}, async err => {
                assert.strictEqual(err.message, 'Partner validation failed: module: Path `module` is required.');
                const count = await Partner.count({});
                assert.strictEqual(count, 0);
                done();
            }).catch(error => {
                console.log('error: ', error);
            });
        });
    });
});
