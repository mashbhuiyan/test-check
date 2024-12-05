const db = require('./test_db');
const DatasetOne = require('./factory/data/dataset1');

class ImportDataset {
    static async import(dataset) {
        return new Promise(async (resolve, reject) => {
            await ImportDataset.truncateTable(Object.keys(dataset));
            for (let table in dataset) {
                let data = dataset[table];
                await ImportDataset.submitDataToInsert(table, data);
            }
            resolve(true);
        });
    }

    static async importTable(table, data) {
        return new Promise(async (resolve, reject) => {
            await ImportDataset.truncateTable([table]);
            await ImportDataset.submitDataToInsert(table, data);
            resolve(true);
        });
    }

    static async submitDataToInsert(table, data) {
        if (Array.isArray(data)) {
            for (let item of data) {
                await ImportDataset.insertData(table, item);
            }
        } else {
            await ImportDataset.insertData(table, data);
        }
    }

    static async insertData(table, data) {
        let column_set = Object.keys(data);
        let value_set = Object.values(data);
        let value_set_ind = ImportDataset.valueSetInd(value_set);

        let query = `Insert into ${table}(${column_set.join(',')})
                     values (${value_set_ind})
                     RETURNING *`;
        return db.query(query, value_set).then(results => {
            return results.rows;
        }, err => {
            console.log(err);
            return [];
        });
    }

    static valueSetInd(value_set) {
        return value_set.map((v, k) => `$${k + 1}`);
    }

    static truncateTable(tables) {
        return db.query(`TRUNCATE ${tables.reverse().join(',')} CASCADE`).then(result => {
            return true;
        }, err => {
            console.log(err);
            return false;
        });
    }
}

module.exports = ImportDataset;
