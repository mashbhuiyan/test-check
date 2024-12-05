require('../../app/models/token');
const mongoose = require('mongoose');
const Token = mongoose.model('Token');
var assert = require('assert');

describe.skip('Token', () => {
    describe('when checking mongoose validations', () => {
        beforeEach((done) => {
            mongoose.connection.collections.tokens.drop(() => {
                done();
            });
        });
        describe('when creating a new token with valid data', () => {
            it('should return the new token', (done) => {
                const token = new Token({ label: 'Token' });
                token.save().then(async () => {
                    assert.ok(!token.isNew);
                    const count = await Token.count({});
                    assert.strictEqual(count, 1);
                    done();
                }).catch(error => {
                    console.log(error);
                });
            });
        });
        describe('when required data is missing', () => {
            it('should not save token', (done) => {
                const token = new Token({
                    label: 'Token',
                    campaign_bid_multipliers: [{campaign_id: 1}]
                });
                token.save().then(() => {}, async err => {
                    assert.strictEqual(err.message, 'Token validation failed: campaign_bid_multipliers.0.multiplier: Path `multiplier` is required.');
                    const count = await Token.count({});
                    assert.strictEqual(count, 0);
                    done();
                }).catch(error => {
                    console.log('error: ', error);
                });
            });
        });
    });
    describe('.generateToken()', () => {
        it('should return a string with 120+ length', () => {
            assert.ok(Token.generateToken().length >= 120);
        });
    });

    describe('#assignWhitelistedIPs()', () => {
        const token = new Token();
        describe('when no params passed', () => {
            it('should return blank array', () => {
                token.assignWhitelistedIPs();
                assert.strictEqual(token.whitelisted_ips.length, 0);
            });
        });

        describe('when string has unnecessary spaces', () => {
            it('should return space removed ips array', () => {
                token.assignWhitelistedIPs('127.0.0.1 , 192.168.0.1 ');
                const expectedIPs = ['127.0.0.1', '192.168.0.1'];
                assert.strictEqual(token.whitelisted_ips.length, 2);
                assert.ok(token.whitelisted_ips.every((val, index) => val === expectedIPs[index]));
            });
        });
    });
});
