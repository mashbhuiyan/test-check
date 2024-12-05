require('dotenv').config();
const express_conf = require('./app/config/express');
const express = require('express');
const morgan = require('morgan');
const swaggerUi = require("swagger-ui-express");
const swaggerDocument = require('./consumer_swagger.json');
const swaggerDocumentInternal = require('./swagger.json');
const path = require('path')
const mongoose = require('mongoose');
const requestIp = require('request-ip');
require('./app/models/admin_user');
require('./app/models/request_log');
require('./app/config/passport');
const PartnerAuthentication = require("./app/middlewares/partner_auth.middleware");
const RequestLog = mongoose.model('RequestLog');
const app = express();
const nocache = require('nocache');

const originalSend = app.response.send;
app.response.send = function sendOverWrite(body) {
    originalSend.call(this, body);
    this.__morgan_body_response = body;
};

app.use(morgan(function (tokens, req, res) {
    const req_body = req.body || {};
    return JSON.stringify({
        request_method: tokens.method(req, res),
        url: tokens.url(req, res),
        status: Number.parseFloat(tokens.status(req, res)),
        content_length: tokens.res(req, res, 'content-length'),
        response_time: Number.parseFloat(tokens['response-time'](req, res)),
        http_version: tokens['http-version'](req, res),
        referrer: tokens.referrer(req, res),
        user_agent: tokens['user-agent'](req, res),
        ip: requestIp.getClientIp(req),
        request_header: req.headers,
        request_body: req.body,
        request_query: req.query,
        response_header: res._header,
        lead_type_id: (req_body.lead ? req_body.lead.lead_type_id : ''),
        response_data: res.__morgan_body_response ? JSON.parse(res.__morgan_body_response) : res.__morgan_body_response,
        access_token: req.headers.authorization && req.headers.authorization.startsWith('Bearer ') ? req.headers.authorization.split('Bearer ')[1].trim() : ''
    });
}, {
    stream: {
        write: (message) => {
            // const log = new RequestLog(JSON.parse(message));
            // log.save().then();
        }
    },
    skip: function (req, res) {
        return !req.url.includes('/api/v1/')
    }
}));

const url = process.env.MONGODB_URI;

app.set('views', './app/views');
app.set('view engine', 'ejs');
app.use(nocache());
express_conf(app);

// Internal swagger documents
const swaggerHtml = swaggerUi.generateHTML(swaggerDocumentInternal, {});
app.use('/api-docs', swaggerUi.serveFiles(swaggerDocumentInternal, {}));
app.get('/api-docs', PartnerAuthentication, swaggerUi.serve, (req, res) => {
    res.send(swaggerHtml)
});
app.set('etag', false);
app.use('/assets', express.static(path.join(__dirname, 'public')));

// Consumer swagger documents
app.use('/api-document', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

try {
    mongoose.connect(url)
} catch (error) {
    console.log("Error", "Unable to connect mongoDB database!")
}
const server = app.listen(process.env.PORT, function () {
    const host = server.address().address;
    const port = server.address().port;

    console.log("App listening at http://%s:%s", host, port)
});
