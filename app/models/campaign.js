module.exports = class Campaign {
    constructor(brand_conf) {
        this.db = brand_conf.db;
    }

    async find(id) {
        const query = `select *
                       from campaigns
                       where id = ${id}`
        return this.db.query(query).then((results) => {
            return results.rows[0];
        }, err => {
            return null;
        });
    }
}
