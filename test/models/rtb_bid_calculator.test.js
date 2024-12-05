const RtbBidCalculator = require('../../app/models/rtb_bid_calculator');
var assert = require('assert');
const db = require('../test_db');
const sleep = require('../../app/lib/sleep');

describe('RtbBidCalculator', () => {
    let rtbBidObj = new RtbBidCalculator(db);
    const lead_data = {
        click_id: '2',
        ip_address: '192.168.1.10',
        lead_type_id: 6,
        device_type: 'desktop',
        user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0',
        aid: '1',
        cid: '2',
        traffic_tier: 'Email',
        submission_url: 'https://smartfinancial.com',
        contact: {
            first_name: 'John',
            last_name: 'Doe',
            address: '1901 Newport Blvd',
            city: 'Costa Mesa',
            state: 'CA',
            zip: '92627',
            county: 'Orange',
            primary_phone: '8773237750',
            email: 'info@smartfinancial.com'
        },
        customer_profile: {
            gender: 'Male',
            marital_status: 'Married',
            residence: {years: 0, own: 'Own'},
            credit: 'Good',
            bankruptcy: 'Yes',
            date_of_birth: '01/01/1982'
        },
        drivers: [
            {
                driver_id: 0,
                first_name: 'John',
                last_name: 'Doe',
                license_status: 'Active',
                license_obtained_age: 16,
                license_ever_suspended_or_revoked: 'Yes',
                sr22_required: 'Yes',
                gender: 'Male',
                date_of_birth: '01/01/1982',
                marital_status: 'Married',
                occupation: 'Retired',
                education: 'SomeCollege',
                relationship_to_contact: 'Applicant',
                violations: [Array],
                claims: [Array],
                accidents: [Array]
            }
        ],
        multiple_vehicles: 'No',
        vehicles: [
            {
                vehicle_id: 1,
                primary_driver_id: 1,
                vin: 'WMEEK9AA0E0000000',
                year: 2020,
                make: 'Toyota',
                model: 'Rav4',
                submodel: 'CX4',
                primary_use: 'Business',
                garage_type: 'Carport',
                parked_at_mailing_address: 'Yes',
                garaging_address: '2230 FAIRVIEW RD STE C',
                garaging_city: 'COSTA MESA',
                garaging_state: 'CA',
                garaging_zip_code: 92627,
                one_way_distance: 10,
                annual_mileage: 12000,
                ownership: 'Owned',
                coverage_package: 'Superior'
            }
        ],
        currently_insured: 'Yes',
        current_coverage: {
            carrier: 'Allstate',
            expiration_date: '01/01/2023',
            coverage_years: 5,
            bodily_injury: '1/0'
        },
        military_affiliation: 'Yes',
        bundle_home: 'Yes',
        sub1: 'Free text',
        post: false,
        zip_tier: '',
        source_type_id: '45',
        dupe_days_lead_modifier: 100000,
        dupe_days_click_modifier: 100000,
        dupe_days_call_modifier: 100000,
        own_home: 'Yes',
        continuous_insurance: '1+ years',
        num_drivers: 1,
        num_violations: 1,
        num_accidents: 1,
        has_accident: 'Yes',
        num_vehicles: 1,
        veh_makes: 'toyota',
        veh_years: '2020',
        prefill_perc: 100
    };

    beforeEach(async () => {
        await db.query('TRUNCATE rtb_bids');
    });

    describe('.rtbBidCheck()', () => {
        it('should get rtb bid', async () => {
            const rtb_bid_check = await rtbBidObj.rtbBidCheck('63466db0cfe25d285297b1a8', lead_data, 35939809);
            assert.ok(rtb_bid_check.output_code === 0 || rtb_bid_check.output_code === 1); // TODO: need to check the assertion
        });
    });

    describe('.rtbBidLogic()', async () => {
        describe('when passing valid data', async () => {
            it('should get logical bid', async () => {
                const rtb_bid_check = await rtbBidObj.rtbBidCheck('63466db0cfe25d285297b1a8', lead_data, 35939809)
                rtb_bid_check.current_bid = 1.2;
                const logic = await rtbBidObj.rtbBidLogic(rtb_bid_check);
                assert.ok(logic.success);
                // assert.ok(logic.output_code); // TODO: need to check the assertion
                assert.equal(logic.bid_to_use, 1.2);
            });
        });

        describe('when passing invalid data', async () => {
            it('should get error response from axios and return 0 as bid_to_use', async () => {
                const logic = await rtbBidObj.rtbBidLogic({});
                assert.ok(logic.success);
                assert.equal(logic.bid_to_use, 0);
            });
        });
    });

    describe('.storeRtbBid()', () => {
        describe('when passing valid data', () => {
            it('should save recommended_bid to a new row of rtb_bids table', async () => {
                const data = {
                    recommended_bid: 1.123456789,
                    revenue_exp: 1.60123456789,
                    output_code: 0,
                }
                let result = await db.query('SELECT COUNT(*) from rtb_bids');
                const count = parseInt(result.rows[0].count);
                await rtbBidObj.storeRtbBid(data, 1234, 80);
                await sleep(1000);
                result = await db.query('SELECT COUNT(*) from rtb_bids');
                assert.equal(result.rows[0].count, count + 1);
            });
        });

        describe('when passing invalid data', () => {
            it('should not save the recommended_bid and get mysql data type mismatch error', async () => {
                const data = { recommended_bid: 'qwerty' }
                let result = await db.query('SELECT COUNT(*) from rtb_bids');
                const count = parseInt(result.rows[0].count);
                await rtbBidObj.storeRtbBid(data, 1234, 80);
                await sleep(1000);
                result = await db.query('SELECT COUNT(*) from rtb_bids');
                assert.equal(result.rows[0].count, count);
            });
        });
    });

    describe('.updateRtbBid()', () => {
        describe('when passing valid data', () => {
            it('should update the bid_to_use and cm column for expected click_ping_id', async () => {
                await rtbBidObj.storeRtbBid({ recommended_bid: 1.123456789, revenue_exp: 1.60123456789, output_code: 0}, 1234, 80);
                await sleep(1000);
                result1 = await db.query('SELECT bid_to_use, cm from rtb_bids where click_ping_id = 1234');
                rtb_bid1 = result1.rows[0];
                assert.strictEqual(rtb_bid1.bid_to_use, null);
                assert.strictEqual(rtb_bid1.cm, null);
                await rtbBidObj.updateRtbBid(1234, 1.2, 2);
                await sleep(1000);
                result2 = await db.query('SELECT bid_to_use, cm from rtb_bids where click_ping_id = 1234');
                rtb_bid2 = result2.rows[0];
                assert.strictEqual(rtb_bid2.bid_to_use, '1.20');
                assert.strictEqual(rtb_bid2.cm, '2.00');
            });
        });

        describe('when passing invalid data', () => {
            it('should not update and get mysql data type mismatch error', async () => {
                await rtbBidObj.storeRtbBid({ recommended_bid: 1.123456789, revenue_exp: 1.60123456789, output_code: 0}, 1234, 80);
                await sleep(1000);
                result1 = await db.query('SELECT bid_to_use, cm from rtb_bids where click_ping_id = 1234');
                rtb_bid1 = result1.rows[0];
                assert.strictEqual(rtb_bid1.bid_to_use, null);
                assert.strictEqual(rtb_bid1.cm, null);
                await rtbBidObj.updateRtbBid(1234, 'qwerty', 2);
                await sleep(1000);
                result2 = await db.query('SELECT bid_to_use, cm from rtb_bids where click_ping_id = 1234');
                rtb_bid2 = result2.rows[0];
                assert.strictEqual(rtb_bid2.bid_to_use, null);
                assert.strictEqual(rtb_bid2.cm, null);
            });
        });
    });

    after(async () => {
        await db.query('TRUNCATE rtb_bids');
    });
});
