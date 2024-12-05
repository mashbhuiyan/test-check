const clickRoutes = require('./click.routes');

const api_brand = '/api/v2/:brand?'
module.exports = (router) => {
    clickRoutes(router, api_brand);
}
