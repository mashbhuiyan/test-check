require('../../app/models/admin_user');
const mongoose = require('mongoose');
var assert = require('assert');
const AdminUser = mongoose.model('AdminUser');

describe.skip('AdminUser', () => {
    describe('when checking mongoose validations', () => {
        beforeEach((done) => {
            mongoose.connection.collections.adminusers.drop(() => {
                done();
            });
        });
        describe('when creating a new admin user with valid data', () => {
            it('should return the new admin user', (done) => {
                const adminUser = new AdminUser({
                    name: 'Admin',
                    email: 'admin@test.com'
                });
                adminUser.setPassword('123456789');
                adminUser.setOtpSecret();
                adminUser.save().then(async () => {
                    assert.ok(!adminUser.isNew);
                    const count = await AdminUser.count({});
                    assert.strictEqual(count, 1);
                    done();
                }).catch(error => {
                    console.log(error);
                });
            });
        });
        describe('when required data is missing', () => {
            it('should not save user', (done) => {
                const adminUser = new AdminUser({
                    name: '',
                    email: 'admin@test.com'
                });
                adminUser.save().then(() => {}, async err => {
                    assert.strictEqual(err.message, 'AdminUser validation failed: name: Path `name` is required.');
                    const count = await AdminUser.count({});
                    assert.strictEqual(count, 0);
                    done();
                }).catch(error => {
                    console.log('error: ', error);
                });
            });
        });
    });
    describe('#setPassword()', () => {
        const adminUser = new AdminUser();
        describe('when salt was empty', () => {
            it('should add new salt and password to the admin user object', () => {
                assert.strictEqual(typeof(adminUser.salt), 'undefined');
                assert.strictEqual(typeof(adminUser.password), 'undefined');
                adminUser.setPassword('123456789');
                assert.ok(adminUser.salt.length > 0);
                assert.ok(adminUser.password.length > 0);
            });
        });
        describe('when admin user salt and password are present', () => {
            it('should add changed password to the admin user object', () => {
                assert.ok(adminUser.salt.length > 0);
                assert.ok(adminUser.password.length > 0);
                const salt = adminUser.salt;
                const password = adminUser.password;
                adminUser.setPassword('987654321');
                assert.strictEqual(adminUser.salt, salt);
                assert.ok(adminUser.password !== password);
            });
        });
        describe('when password param blank', () => {
            it('should add changed password for blank string to the admin user object', () => {
                assert.ok(adminUser.salt.length > 0);
                assert.ok(adminUser.password.length > 0);
                const salt = adminUser.salt;
                const password = adminUser.password;
                adminUser.setPassword('');
                assert.strictEqual(adminUser.salt, salt);
                assert.ok(adminUser.password.length > 0);
                assert.ok(adminUser.password !== password);
            });
        });
    });

    describe('#validPassword()', () => {
        const adminUser = new AdminUser();
        adminUser.setPassword('123456789');
        it('should return return true when same password submitted', () => {
            assert.ok(adminUser.validPassword('123456789'));
        });
        it('should return return false when different password submitted', () => {
            assert.ok(!adminUser.validPassword('32342424'));
            assert.ok(!adminUser.validPassword(''));
        });
    });

    describe('#setOtpSecret()', () => {
        it('should set otp secret to the admin user object', () => {
            const adminUser = new AdminUser();
            assert.strictEqual(typeof(adminUser.otp_secret), 'undefined');
            adminUser.setOtpSecret();
            assert.ok(adminUser.otp_secret.length > 0);
        });
    });
});

