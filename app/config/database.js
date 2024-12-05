const BrandDbConfigs = require("../config/db_brands.json");
const Pool = require('pg').Pool;

const brands = {}

function createBrandPools() {
    for (const brand in BrandDbConfigs) {
        let brand_conf = BrandDbConfigs[brand];
        brands[brand] = {
            name: brand,
            template_api: brand_conf.template_api,
            lead_post_url: brand_conf.lead_post_url,
            tracking_host: brand_conf.tracking_host,
            template_api_token: brand_conf.template_api_token,
            db: new Pool({
                user: brand_conf.user,
                database: brand_conf.database,
                password: brand_conf.password,
                host: brand_conf.host,
                port: brand_conf.port,
                max: 100  // maximum number of clients the pool should contain
            })
        }
    }
}

createBrandPools();

module.exports = {
    brands
}
