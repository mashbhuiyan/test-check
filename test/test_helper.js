const mongoose = require('mongoose');
require('dotenv').config();

// tell mongoose to use es6 implementation of promises
// mongoose.Promise = global.Promise;
const url = process.env.MONGODB_TEST_URI;
mongoose.connect(url);
mongoose.connection
    .once('open', () => console.log('Connected!'))
    .on('error', (error) => {
        console.warn('Error : ', error);
    });
