const State = require('../../app/models/state');
var assert = require('assert');

describe('State', () => {
    describe('.getState()', () => {
        describe('when valid state short name passed', () => {
            it('should return states full name', () => {
                assert.strictEqual(State.getState('WY'), "Wyoming");
            });
            it('should be case insensitive', () => {
                assert.strictEqual(State.getState('wy'), "Wyoming");
            });
        });
        describe('when invalid state short name passed', () => {
            it('should return empty string', () => {
                assert.strictEqual(State.getState('XYZ'), "");
            });
        });
        describe('when no params passed', () => {
            it('should return empty string', () => {
                assert.strictEqual(State.getState(), "");
            });
        });
    });
});
