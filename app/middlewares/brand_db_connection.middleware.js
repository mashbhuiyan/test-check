const {brands} = require('../config/database');

module.exports = BrandDBConnection = (req, res, next) => {
    req.brand_conf = brands[(req.params.brand || 'smartfinancial')];
    req.brand_conf.read_replica = brands[`${(req.params.brand || 'smartfinancial')}_read_replica`];
    next();
};
