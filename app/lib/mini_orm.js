class MiniOrm {
    constructor(db_config) {
        this.db = db_config;
    }

    select(table_name, select_columns, where, order = null, limit = null) {
        let select = '*';
        if (select_columns.length && typeof (select_columns) !== 'string') {
            select = select_columns.join(',');
        }
        let query = `SELECT ${select}
                     FROM ${table_name}
                     WHERE ${where}`;
        if (order) {
            query = `${query} ORDER BY ${order}`;
        }
        if (limit) {
            query = `${query} LIMIT ${limit}`;
        }
        return this.db.query(query);
    }

    insert(table_name, data) {
        const values = [];
        const columns = [];
        const counters = [];
        let counter = 1;
        for (let key in data) {
            counters.push(`$${counter}`);
            columns.push(key);
            values.push(data[key]);
            counter += 1;
        }
        return this.insertDb(table_name, columns, counters, values);
    }

    batchInsert(table_name, columns, value_sets) {
        const counter_set = [];
        let counter = 1;
        for (const values of value_sets) {
            const counters = [];
            for (let key in values) {
                counters.push(`$${counter}`);
                counter += 1;
            }
            counter_set.push(`(${counters})`);
        }
        return this.insertDb(table_name, columns, counter_set, value_sets.flat());
    }

    insertDb(table_name, columns, counters, values) {
        return this.db.query(`INSERT INTO ${table_name} (${columns.join(', ')})
        VALUES
        ${counters.join(', ')}`, values)
    }

    update(table_name, data, where) {
        let counter = 1;
        const column_set = [];
        const value_set = [];
        data.updated_at = new Date();
        for (let field in data) {
            value_set.push(data[field]);
            column_set.push(`${field} = $${counter}`);
            counter += 1;
        }
        return this.db.query(`UPDATE ${table_name}
                              set ${column_set.join(',')}
                              where ${where}`, value_set);
    }
}

module.exports = MiniOrm;
