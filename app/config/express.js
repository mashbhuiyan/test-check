const express = require('express');
const bodyParser = require('body-parser');
const routes = require('../routes/base.routes');
const cors = require('cors');
const methodOverride = require('method-override');
const passport = require('passport');
const session = require('express-session');
const Airbrake = require("@airbrake/node");
const airbrakeExpress = require('@airbrake/node/dist/instrumentation/express');
const MongoStore = require('connect-mongo');

const airbrake = new Airbrake.Notifier({
    projectId: process.env.AIRBRAKE_PROJECT_ID,
    projectKey: process.env.AIRBRAKE_PROJECT_KEY,
    environment: process.env.AIRBRAKE_PROJECT_ENV
});

const router = express.Router()

module.exports = (app) => {
    // Parsers
    app.use(methodOverride('_method'));
    app.use(bodyParser.urlencoded({extended: true})); // support encoded bodies
    // app.use(bodyParser.json()); // support json encoded bodies
    app.use((req, res, next) => { // support json encoded bodies & handle invalid JSON
        bodyParser.json()(req, res, err => {
            if (err) {
                console.error('Invalid JSON body: ', err.body);
                return res.json({
                    message: 'Invalid JSON body', success: false
                }); // Bad request
            }
            next();
        });
    });

    // enable CORS - Cross Origin Resource Sharing
    app.use(cors());

    app.use(session({
        secret: 'BAFA6586A1716044CC905654F493A18C7609C9BFB65A66BC303EDE3759557DC4',
        saveUninitialized: true,
        resave: true,
        cookie: {maxAge: 1000 * 60 * 60 * 48},
        store: MongoStore.create({mongoUrl: process.env.MONGODB_URI})
    }));
    app.use(passport.initialize());
    app.use(passport.session());
    if (process.env.AIRBRAKE_PROJECT_ENV !== 'development') {
        app.use(airbrakeExpress.makeMiddleware(airbrake));
    }
    /** set up routes {API Endpoints} */
    routes(router)
    app.use('/', router);
    if (process.env.AIRBRAKE_PROJECT_ENV !== 'development') {
        app.use(airbrakeExpress.makeErrorHandler(airbrake));
    }

    app.use((err, req, res, next) => {
        console.error("Express Error", err.stack)
        res.status(500).send('Something broke!')
    })
}
