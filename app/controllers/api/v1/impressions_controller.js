const ClickListing = require('../../../models/click_listing');
module.exports.pixel = function (req, res) {
    let click_listing_id = req.params.id;
    let position = parseInt(req.query.pos || '');
    position = (position > 0 && position <= 30) ? position : null; // Position must be integer in the range from 1 to 30. If it is not in that range, we should not store it.
    const clickListing = new ClickListing(req.brand_conf);

    clickListing.updateImpression(click_listing_id, position); // Run as background job
    const buffer = Buffer.alloc(43)
    buffer.write('R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=', 'base64')
    res.writeHead(200, {'Content-Type': 'image/gif'});
    res.end(buffer, 'binary');
}
//http://localhost:8081/api/v1/click_listing/4521/impression
