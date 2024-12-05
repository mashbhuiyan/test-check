const Pool = require('pg').Pool;
require('dotenv').config();

const db = new Pool({
    user: process.env.TEST_DB_USER,
    database: process.env.TEST_DB_NAME,
    password: process.env.TEST_DB_PASSWORD,
    host: process.env.TEST_DB_HOST,
    port: process.env.TEST_DB_PORT,
    max: 100  // maximum number of clients the pool should contain
});

module.exports = db
