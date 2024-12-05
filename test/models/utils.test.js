const util = require('../../app/models/utils');
const AutoLeadData = require('../../app/data/auto.json');
const flatten = require('flat');
const assert = require('assert');

describe('Utils', () => {
    const params = flatten(AutoLeadData.lead);
    describe('.getParam()', () => {
        describe('when key not present in the params', () => {
            it('should return blank string', () => {
                assert.strictEqual(util.getParam(params, 'source_type_id'), '');
            });
        });
        describe('when key not passed', () => {
            it('should return blank string', () => {
                assert.strictEqual(util.getParam(params, ''), '');
            });
        });
        describe('when object is blank', () => {
            it('should return blank string', () => {
                assert.strictEqual(util.getParam({}, 'source_type_id'), '');
            });
        });
        describe('when both params are blank', () => {
            it('should return blank string', () => {
                assert.strictEqual(util.getParam({}, ''), '');
            });
        });
        describe('when all params are good', () => {
            it('should return expected value', () => {
                assert.strictEqual(util.getParam(params, 'first_name'), AutoLeadData.lead.contact.first_name);
            });
        });
    });

    describe('.getAge() & .getAgeFromDate()', () => {
        describe('when date_of_birth is present, valid', () => {
            describe('when month is less than current month & day is same as today', () => {
                it('should return age 40', () => {
                    const dob = new Date();
                    dob.setMonth(dob.getMonth() - 2);
                    dob.setFullYear(dob.getFullYear() - 40);
                    assert.strictEqual(util.getAge({date_of_birth: dob}), 40);
                });
            });
            describe('when month is same as current month & day is same as today', () => {
                it('should return age 40', () => {
                    const dob = new Date();
                    dob.setFullYear(dob.getFullYear() - 40);
                    assert.strictEqual(util.getAge({date_of_birth: dob}), 40);
                });
            });
            describe('when month is same as current month & day is greater than today', () => {
                it('should return age 39', () => {
                    const dob = new Date();
                    dob.setDate(dob.getDate() + 2);
                    dob.setFullYear(dob.getFullYear() - 40);
                    assert.strictEqual(util.getAge({date_of_birth: dob}), 39);
                });
            });
            describe('when month is greater than current month', () => {
                it('should return age 39', () => {
                    const dob = new Date();
                    dob.setMonth(dob.getMonth() + 2);
                    dob.setFullYear(dob.getFullYear() - 40);
                    assert.strictEqual(util.getAge({date_of_birth: dob}), 39);
                });
            });
        });
        describe('when date_of_birth not present', () => {
            it('should return age 0', () => {
                assert.strictEqual(util.getAge({}), 0);
            });
        });
        describe('when date_of_birth is not valid', () => {
            it('should return age 0', () => {
                assert.strictEqual(util.getAge({date_of_birth: '02/32/2000'}), 0);
            });
        });
        describe('when date_of_birth is in the future', () => {
            it('should return age 0', () => {
                const dob = new Date();
                dob.setFullYear(dob.getFullYear() + 1);
                assert.strictEqual(util.getAge({date_of_birth: dob}), 0);
            });
        });
    });

    describe('.parseToFloat()', () => {
        describe('when place valid string', () => {
            it('should return parsed float of that string', () => {
                assert.strictEqual(util.parseToFloat('12.34'), 12.34);
                assert.strictEqual(util.parseToFloat('0012.34'), 12.34);
                assert.strictEqual(util.parseToFloat('-12.34'), -12.34);
            });
        });
        describe('when place string with characters', () => {
            it('should return parsed float of that string with characters removed', () => {
                assert.strictEqual(util.parseToFloat('12.34qwerty'), 12.34);
                assert.strictEqual(util.parseToFloat('123asd456'), 123456);
            });
        });
        describe('when place blank string or only alphabets', () => {
            it('should return NaN', () => {
                assert.ok(isNaN(util.parseToFloat('')));
                assert.ok(isNaN(util.parseToFloat('abc')));
            });
        });
        describe('when place number', () => {
            it('should return parsed number', () => {
                assert.ok(util.parseToFloat(12) === 12.0);
                assert.ok(util.parseToFloat(-12) === -12.0);
            });
        });
    });

    describe('.toLowerCase()', () => {
        describe('when place valid string', () => {
            it('should return lowercase string', () => {
                assert.ok(util.toLowerCase('QWERTY') === 'qwerty');
            });
        });
        describe('when place blank string', () => {
            it('should return blank string', () => {
                assert.ok(util.toLowerCase('') === '');
            });
        });
        describe('when place number', () => {
            it('should return number', () => {
                assert.ok(util.toLowerCase(12.34) === 12.34);
            });
        });
    });

    describe('.findNestedObj()', () => {
        const dataObject = {united: {data: {bid_info: {amount: 12.34}, bid: 23.45}}};
        describe('when expected keys inside the data object', () => {
            it('should return object with only expected keys', () => {
                const resp = util.findNestedObj(dataObject, ['bid', 'amount']);
                assert.strictEqual(Object.keys(resp).length, 2);
                assert.strictEqual(resp.amount, 12.34);
                assert.strictEqual(resp.bid, 23.45);
            });
        });
        describe('when expected all keys are not inside the data object', () => {
            it('should return object with only founded expected keys', () => {
                const resp = util.findNestedObj(dataObject, ['multiplier', 'amount']);
                assert.strictEqual(Object.keys(resp).length, 2);
                assert.strictEqual(resp.amount, 12.34);
                assert.ok(typeof (resp.multiplier) === 'undefined');
            });
        });
        describe('when the data object blank', () => {
            it('should return blank object', () => {
                const resp = util.findNestedObj({}, ['multiplier', 'amount']);
                assert.strictEqual(Object.keys(resp).length, 2);
                assert.ok(typeof (resp.multiplier) === 'undefined');
                assert.ok(typeof (resp.amount) === 'undefined');
            });
        });
        describe('when data object has the searched keys multiple times', () => {
            it('should return object with only founded expected keys', () => {
                const realDataObject = {
                    'summary': {
                        'resultsCount': {'sponsored': 1, 'organic': 0},
                        'validUntil': '2023-12-06T13:30:20.675-05:00'
                    },
                    'businesses': [
                        {
                            'name': 'Legal Assistance for Personal Injury, Auto Accident, D U I, and General Legal Counsel',
                            'address': '',
                            'city': '',
                            'state': ' ',
                            'zip': '',
                            'latitude': '',
                            'longitude': '',
                            'url': '',
                            'score': '',
                            'verified': 'No',
                            'image': '',
                            'categoryName': 'AUTOMOTIVE',
                            'categoryID': '2',
                            'distance': {'miles': ''},
                            'type': 'Sponsored',
                            'monetizationCritera': {
                                'action': 'CALLED',
                                'criteria': '210',
                                'value': '2.8000',
                                'validUntil': '2023-12-06T13:31:20.285-05:00'
                            },
                            'monetizationCriteria': {
                                'action': 'CALLED',
                                'criteria': '210',
                                'value': '2.8000',
                                'validUntil': '2023-12-06T13:31:20.285-05:00'
                            },
                            'costCritera': {'action': '', 'value': '', 'validUntil': ''},
                            'costCriteria': {'action': '', 'value': '', 'validUntil': ''},
                            'displayPhoneNumber': '8442632896',
                            'completionPhoneNumber': '8444091027',
                            'details': {
                                'isOpen': 'Unknown',
                                'hours': '',
                                'displayHours': '',
                                'timeZone': 'GMT-5',
                                'descriptors': [],
                                'socialMedia': {},
                                'images': {},
                                'associations': [],
                                'thirdPartyData': []
                            },
                            '_links': [
                                {
                                    'rel': 'urn:soleo:businesses:calleddisplaynumber',
                                    'href': 'https://trialapi.soleo.com/SearchNormalizationApplication/sponsored/callback/10dedf9e-d32d-4eab-ab26-2d31d3d0d938;jsessionid=BBD29242BEA5EACDDEF80B62891A6B06.0a0a0e12?displayNumber=8442632896&APIKey=pgp3yk22ncb4pumnqca72d74',
                                    'method': 'POST'
                                },
                                {
                                    'rel': 'urn:soleo:businesses:calledcompletionnumber',
                                    'href': 'https://trialapi.soleo.com/SearchNormalizationApplication/sponsored/callback/10dedf9e-d32d-4eab-ab26-2d31d3d0d938;jsessionid=BBD29242BEA5EACDDEF80B62891A6B06.0a0a0e12?completionNumber=8444091027&APIKey=pgp3yk22ncb4pumnqca72d74',
                                    'method': 'POST'
                                }
                            ]
                        }
                    ],
                    '_links': [
                        {
                            'rel': 'self',
                            'href': 'https://trialapi.soleo.com/SearchNormalizationApplication/sponsored?APIKey=pgp3yk22ncb4pumnqca72d74&Keyword=Auto&PostalCode=92627&ANI=8773237750&ReferenceID=12345678-abcd-1234-cdef-ba9876543210&SourceID=SmartFinancial&IPAddress=192.168.1.6&MaxSponsoredCount=5',
                            'method': 'GET'
                        }
                    ]
                };
                const resp = util.findNestedObj(realDataObject, ['businesses.0.monetizationCriteria.value']);
                assert.strictEqual(Object.keys(resp).length, 1);
                assert.ok(resp['businesses.0.monetizationCriteria.value'] === '2.8000');
            });
        });
    });

    describe('.findKeyValueNestedObj()', () => {
        const dataObject = {united: {data: {bid_info: {amount: 12.34}, bid_value: {bid: 23.45}}}};
        describe('when data object has all the searched keys', () => {
            it('should return object with founded expected keys', () => {
                const resp = util.findKeyValueNestedObj(dataObject, ['bid', 'amount']);
                assert.strictEqual(Object.keys(resp).length, 2);
                assert.strictEqual(resp.amount, 12.34);
                assert.strictEqual(resp.bid, 23.45);
            });
        });

        describe('when data object has some of the searched keys', () => {
            it('should return object with founded expected keys', () => {
                const resp = util.findKeyValueNestedObj(dataObject, ['bid', 'multiplier']);
                assert.strictEqual(Object.keys(resp).length, 1);
                assert.strictEqual(resp.bid, 23.45);
                assert.ok(typeof (resp.multiplier) === 'undefined');
            });
        });
    });

    describe('.flattenJSON()', () => {
        describe('when data object has several nested objects', () => {
            it('should return object with flattened keys', () => {
                const dataObject = {
                    united: {
                        data: {
                            bid_info: {amount: 12.34},
                            bid_value: {bid: 23.45, multiplier: 2}
                        }
                    }
                };
                const resp = util.flattenJSON(dataObject);
                assert.strictEqual(Object.keys(resp).length, 7);
                assert.strictEqual(resp['united.data.bid_info.amount'], 12.34);
                assert.strictEqual(resp['united.data.bid_value.bid'], 23.45);
                assert.strictEqual(resp['united.data.bid_value.multiplier'], 2);
            });
        });

        describe('when data object has array and several nested objects ', () => {
            it('should return object with flattened keys', () => {
                const dataObject = {
                    united: {
                        data: [
                            {bid_info: {amount: 12.34}},
                            {bid_info: {amount: 34.45}}
                        ]
                    },
                    national: {
                        data: [
                            {bid_info: {amount: 23.23}},
                            {bid_info: {amount: 43.45}}
                        ]
                    }
                };
                const resp = util.flattenJSON(dataObject);
                assert.strictEqual(Object.keys(resp).length, 16);
                assert.strictEqual(resp['united.data.0.bid_info.amount'], 12.34);
                assert.strictEqual(resp['united.data.1.bid_info.amount'], 34.45);
                assert.strictEqual(resp['national.data.0.bid_info.amount'], 23.23);
                assert.strictEqual(resp['national.data.1.bid_info.amount'], 43.45);
            });
        });
    });

    describe('.stringToJson()', () => {
        describe('when string has multiple params', () => {
            it('should return object of params', () => {
                const resp = util.stringToJson('aid=12&cid=60&first_name=John&last_name=Doe&zip=1005&state=AK');
                assert.strictEqual(Object.keys(resp).length, 6);
                assert.strictEqual(resp.cid, '60');
                assert.strictEqual(resp.zip, '1005');
            });
        });

        describe('when function param is already object', () => {
            it('should return the submitted object without any processing', () => {
                const resp = util.stringToJson({aid: '12', cid: '60', zip: '1005', state: 'AK'});
                assert.strictEqual(Object.keys(resp).length, 4);
                assert.strictEqual(resp.cid, '60');
                assert.strictEqual(resp.zip, '1005');
            });
        });

        describe('when function param is invalid not object not string', () => {
            it('should return the submitted param from catch', () => {
                const resp = util.stringToJson(123456);
                assert.strictEqual(resp, 123456);
            });
        });
    });

    describe('.mergeDeep()', () => {
        describe('when function param has multiple objects with multiple nested objects and arrays', () => {
            it('should return one single merged object', () => {
                const obj1 = {
                    united: {
                        data: {bid_info: {amount: 12.34}},
                        cids: [1, 2, 3, 4]
                    },
                    national: {
                        data: {bid_info: {amount: 23.23}}
                    }
                };
                const obj2 = {
                    united: {
                        data: {
                            bid_info: {
                                name: 'XYZ',
                                value: {amount: 34.34},
                                percentage: 2,
                                cid: 12
                            }, ask_info: {amount: 23}
                        },
                        cids: []
                    },
                    national: {
                        data: {bid_info: {amount: 43.45}}
                    }
                };

                const obj3 = {
                    twenty_first: {
                        data: {bid_info: {amount: 43.45}}
                    }
                };
                const resp = util.mergeDeep([obj1, obj2, obj3]);
                assert.strictEqual(Object.keys(resp).length, 3);
                assert.strictEqual(resp.united.data.bid_info.amount, 12.34);
                assert.strictEqual(resp.united.data.bid_info.value.amount, 34.34);
                assert.strictEqual(resp.national.data.bid_info.amount, 43.45);
                assert.strictEqual(resp.twenty_first.data.bid_info.amount, 43.45);
            });
        });

        describe('when function param is invalid not object not string', () => {
            it('should return the submitted param from catch', () => {
                const obj1 = {
                    united: {
                        data: {bid_info: {amount: 12.34}},
                    },
                    national: {
                        data: {bid_info: {amount: 23.23}}
                    }
                };
                const obj2 = {};
                // const resp = util.mergeDeep([obj1, obj2]);
                const resp = util.mergeDeep([obj2, obj1]);
                assert.strictEqual(Object.keys(resp).length, 2);
                assert.strictEqual(resp.united.data.bid_info.amount, 12.34);
                assert.strictEqual(resp.national.data.bid_info.amount, 23.23);
            });
        });
    });
});
